#!/usr/bin/env node
/**
 * Layer 1: JavaScript Rendering Layer Benchmark
 *
 * Measures rendering performance inside a real browser (Chromium via Playwright),
 * closely approximating WKWebView behavior.
 *
 * Metrics captured:
 *   - T3: md.render() — markdown-it parse + render time
 *   - T4: mermaid render time (when diagrams present)
 *   - T_js_total: total window.renderMarkdown() execution time
 *   - T_dom: DOM update time (innerHTML assignment)
 *   - heap_used_mb: JS heap after render
 *
 * Run modes:
 *   Cold: new browser page per iteration (simulates WKWebView cold start)
 *   Warm: same page, multiple renders (simulates switching files in QuickLook)
 */

import { chromium } from 'playwright';
import { readFileSync, readdirSync, writeFileSync, mkdirSync } from 'fs';
import { resolve, dirname, basename } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '../..');
const FIXTURES_DIR = resolve(__dirname, '../fixtures');
const RESULTS_DIR = resolve(__dirname, '../results');
const INDEX_HTML = resolve(ROOT, 'web-renderer/dist/index.html');

// ─── CLI args ────────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
const getArg = (name, defaultVal) => {
  const idx = args.indexOf(name);
  return idx >= 0 ? args[idx + 1] : defaultVal;
};
const WARMUP_RUNS = parseInt(getArg('--warmup', '3'));
const BENCH_RUNS = parseInt(getArg('--iterations', '10'));
const FIXTURE_FILTER = getArg('--fixture', null); // e.g. "03-medium-code"

// ─── Statistics helpers ──────────────────────────────────────────────────────
function stats(samples) {
  if (samples.length === 0) return { n: 0, mean: 0, median: 0, p95: 0, p99: 0, min: 0, max: 0, stddev: 0, cv: 0 };
  const sorted = [...samples].sort((a, b) => a - b);
  const n = sorted.length;
  const mean = sorted.reduce((a, b) => a + b, 0) / n;
  const variance = sorted.reduce((s, x) => s + (x - mean) ** 2, 0) / (n - 1);
  const stddev = Math.sqrt(variance);
  const pct = (p) => sorted[Math.min(Math.ceil((p / 100) * n) - 1, n - 1)];
  return {
    n,
    mean: +mean.toFixed(3),
    median: +pct(50).toFixed(3),
    p95: +pct(95).toFixed(3),
    p99: +pct(99).toFixed(3),
    min: +sorted[0].toFixed(3),
    max: +sorted[n - 1].toFixed(3),
    stddev: +stddev.toFixed(3),
    cv: mean > 0 ? +(stddev / mean).toFixed(4) : 0,
  };
}

// ─── Instrumented renderMarkdown ─────────────────────────────────────────────
// This script is injected into the page to wrap the original renderMarkdown
// and capture fine-grained timings via performance.now().
const INSTRUMENT_SCRIPT = `
(function() {
  if (window.__benchmarkInstrumented) return;
  window.__benchmarkInstrumented = true;

  const _originalRender = window.renderMarkdown.bind(window);

  window.renderMarkdownBench = async function(text, options) {
    const result = {
      t_js_total_start: performance.now(),
      t_md_render_ms: null,
      t_mermaid_ms: null,
      t_dom_ms: null,
      t_js_total_ms: null,
      html_length: 0,
      mermaid_count: 0,
      heap_used_mb: null,
    };

    // Wrap md.render to capture its time
    const _originalMdRender = window.__md_render_original || null;

    // Patch: intercept innerHTML assignment to measure DOM time
    const outputDiv = document.getElementById('markdown-preview');
    let domStart = null;
    let domEnd = null;

    const originalDescriptor = Object.getOwnPropertyDescriptor(Element.prototype, 'innerHTML');
    let patchActive = true;
    Object.defineProperty(outputDiv, 'innerHTML', {
      set(value) {
        if (patchActive) {
          domStart = performance.now();
          originalDescriptor.set.call(this, value);
          domEnd = performance.now();
          patchActive = false; // only capture first assignment (the main render)
        } else {
          originalDescriptor.set.call(this, value);
        }
      },
      get() {
        return originalDescriptor.get.call(this);
      },
      configurable: true,
    });

    // Capture md.render time by wrapping before the call
    const mdRenderStart = performance.now();
    
    // Call original (async)
    const callStart = performance.now();
    await _originalRender(text, options);
    const callEnd = performance.now();

    result.t_js_total_ms = +(callEnd - callStart).toFixed(3);

    // DOM time
    if (domStart !== null && domEnd !== null) {
      result.t_dom_ms = +(domEnd - domStart).toFixed(3);
    }

    // Restore innerHTML descriptor
    delete outputDiv.innerHTML;

    // Count mermaid diagrams in output
    result.mermaid_count = outputDiv.querySelectorAll('.mermaid svg').length;
    result.html_length = outputDiv.innerHTML.length;

    // Heap (Chrome only)
    if (performance.memory) {
      result.heap_used_mb = +(performance.memory.usedJSHeapSize / 1024 / 1024).toFixed(2);
    }

    return result;
  };
})();
`;

// ─── Run one fixture on an existing page ─────────────────────────────────────
async function measureOnPage(page, fixtureContent) {
  // Inject instrumentation if not done
  const instrumented = await page.evaluate(() => window.__benchmarkInstrumented === true);
  if (!instrumented) {
    await page.evaluate(INSTRUMENT_SCRIPT);
  }

  const options = { theme: 'light' };

  const result = await page.evaluate(
    async ({ text, opts }) => {
      return await window.renderMarkdownBench(text, opts);
    },
    { text: fixtureContent, opts: options }
  );

  return result;
}

// ─── Wait for renderer to be ready ───────────────────────────────────────────
async function waitForRenderer(page) {
  await page.waitForFunction(
    () => typeof window.renderMarkdown === 'function',
    { timeout: 15000 }
  );
  // Extra settle time for any async initialization in index.ts
  await page.waitForTimeout(100);
}

// ─── Benchmark a single fixture ──────────────────────────────────────────────
async function benchmarkFixture(browser, fixturePath, fixtureName) {
  const content = readFileSync(fixturePath, 'utf8');
  const contentLengthKB = (Buffer.byteLength(content, 'utf8') / 1024).toFixed(1);

  console.log(`\n  📄 ${fixtureName} (${contentLengthKB} KB)`);

  const coldSamples = [];
  const warmSamples = [];
  const allRuns = [];

  // ── COLD runs (new page per iteration) ──────────────────────────────────
  console.log(`     Cold runs (${WARMUP_RUNS + 3} iterations, first 3 discarded as browser warmup)...`);
  const coldTotal = WARMUP_RUNS + 3; // 3 extra browser-level warmup
  for (let i = 0; i < coldTotal; i++) {
    const page = await browser.newPage();
    await page.goto(`file://${INDEX_HTML}`);
    await waitForRenderer(page);
    await page.evaluate(INSTRUMENT_SCRIPT);

    const result = await measureOnPage(page, content);
    await page.close();

    if (i >= 3) { // discard first 3 (browser-level warmup, not WKWebView cold)
      coldSamples.push(result.t_js_total_ms);
      allRuns.push({ run_type: 'cold', iteration: i - 3, ...result });
    }

    const tag = i < 3 ? '(warmup)' : `cold-${i - 3}`;
    process.stdout.write(`     [${tag}] ${result.t_js_total_ms.toFixed(1)}ms\n`);
  }

  // ── WARM runs (same page, multiple renders) ──────────────────────────────
  console.log(`     Warm runs (${WARMUP_RUNS} warmup + ${BENCH_RUNS} measured)...`);
  const warmPage = await browser.newPage();
  await warmPage.goto(`file://${INDEX_HTML}`);
  await waitForRenderer(warmPage);
  await warmPage.evaluate(INSTRUMENT_SCRIPT);

  // Warmup on the warm page
  for (let i = 0; i < WARMUP_RUNS; i++) {
    const result = await measureOnPage(warmPage, content);
    process.stdout.write(`     [warmup-${i}] ${result.t_js_total_ms.toFixed(1)}ms\n`);
  }

  // Measured warm runs
  for (let i = 0; i < BENCH_RUNS; i++) {
    const result = await measureOnPage(warmPage, content);
    warmSamples.push(result.t_js_total_ms);
    allRuns.push({ run_type: 'warm', iteration: i, ...result });
    process.stdout.write(`     [warm-${i}] ${result.t_js_total_ms.toFixed(1)}ms\n`);
  }

  await warmPage.close();

  const mermaidCount = allRuns.find(r => r.run_type === 'warm')?.mermaid_count ?? 0;
  const htmlLengthKB = ((allRuns.find(r => r.run_type === 'warm')?.html_length ?? 0) / 1024).toFixed(1);

  return {
    fixture: fixtureName,
    content_length_kb: parseFloat(contentLengthKB),
    html_length_kb: parseFloat(htmlLengthKB),
    mermaid_diagrams: mermaidCount,
    cold: stats(coldSamples),
    warm: stats(warmSamples),
    raw_runs: allRuns,
  };
}

// ─── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  console.log('═══════════════════════════════════════════════════════════');
  console.log('  FluxMarkdown JS Rendering Benchmark (Layer 1)');
  console.log('═══════════════════════════════════════════════════════════');
  console.log(`  Renderer:   ${INDEX_HTML}`);
  console.log(`  Fixtures:   ${FIXTURES_DIR}`);
  console.log(`  Warmup:     ${WARMUP_RUNS} runs`);
  console.log(`  Bench runs: ${BENCH_RUNS} runs`);
  console.log('');

  // Verify dist exists
  try {
    readFileSync(INDEX_HTML);
  } catch {
    console.error(`ERROR: dist/index.html not found at ${INDEX_HTML}`);
    console.error('Run "cd web-renderer && npm run build" first.');
    process.exit(1);
  }

  // Collect fixtures
  let fixtures = readdirSync(FIXTURES_DIR)
    .filter(f => f.endsWith('.md'))
    .sort()
    .map(f => ({ name: f, path: resolve(FIXTURES_DIR, f) }));

  if (FIXTURE_FILTER) {
    fixtures = fixtures.filter(f => f.name.includes(FIXTURE_FILTER));
    if (fixtures.length === 0) {
      console.error(`No fixtures match filter: ${FIXTURE_FILTER}`);
      process.exit(1);
    }
  }

  console.log(`  Fixtures to run: ${fixtures.map(f => f.name).join(', ')}`);

  const browser = await chromium.launch({
    headless: true,
    args: ['--allow-file-access-from-files', '--disable-web-security'],
  });
  const results = [];

  try {
    for (const fixture of fixtures) {
      const result = await benchmarkFixture(browser, fixture.path, fixture.name);
      results.push(result);
    }
  } finally {
    await browser.close();
  }

  // ── Summary table ──────────────────────────────────────────────────────
  console.log('\n\n═══════════════════════════════════════════════════════════');
  console.log('  Results Summary (T_js_total ms)');
  console.log('═══════════════════════════════════════════════════════════');
  console.log(
    `  ${'Fixture'.padEnd(22)} ${'Size'.padStart(7)} ${'Cold p50'.padStart(9)} ${'Cold p95'.padStart(9)} ${'Warm p50'.padStart(9)} ${'Warm p95'.padStart(9)} ${'Mermaid'.padStart(8)}`
  );
  console.log('  ' + '─'.repeat(80));

  for (const r of results) {
    console.log(
      `  ${r.fixture.padEnd(22)} ${(r.content_length_kb + 'KB').padStart(7)} ` +
      `${(r.cold.median + 'ms').padStart(9)} ${(r.cold.p95 + 'ms').padStart(9)} ` +
      `${(r.warm.median + 'ms').padStart(9)} ${(r.warm.p95 + 'ms').padStart(9)} ` +
      `${String(r.mermaid_diagrams).padStart(8)}`
    );
  }

  // ── Save results ───────────────────────────────────────────────────────
  mkdirSync(RESULTS_DIR, { recursive: true });

  const timestamp = new Date().toISOString().slice(0, 19).replace('T', '_').replace(/:/g, '-');
  const report = {
    meta: {
      layer: 'js',
      timestamp: new Date().toISOString(),
      warmup_runs: WARMUP_RUNS,
      bench_runs: BENCH_RUNS,
      renderer_path: INDEX_HTML,
      node_version: process.version,
      platform: process.platform,
      arch: process.arch,
    },
    results,
  };

  const outPath = resolve(RESULTS_DIR, `js-bench-${timestamp}.json`);
  writeFileSync(outPath, JSON.stringify(report, null, 2));

  // Also write a "latest" symlink-equivalent (overwrite)
  writeFileSync(resolve(RESULTS_DIR, 'js-bench-latest.json'), JSON.stringify(report, null, 2));

  console.log(`\n  ✅ Results saved to:`);
  console.log(`     ${outPath}`);
  console.log(`     ${resolve(RESULTS_DIR, 'js-bench-latest.json')} (latest)`);
}

main().catch(err => {
  console.error('Benchmark failed:', err);
  process.exit(1);
});
