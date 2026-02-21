#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WARMUP="${WARMUP:-3}"
ITERATIONS="${ITERATIONS:-10}"

echo "═══════════════════════════════════════════════════════════"
echo "  FluxMarkdown Full Benchmark Suite"
echo "═══════════════════════════════════════════════════════════"
echo "  Warmup: $WARMUP  Iterations: $ITERATIONS"
echo ""

build_renderer() {
    echo "── Building web renderer..."
    (cd "$SCRIPT_DIR/../web-renderer" && npm install --silent && npm run build --silent)
    echo "   ✅ Renderer built"
}

run_js_bench() {
    echo ""
    echo "── Layer 1: JS rendering benchmark"
    local bench_dir="$SCRIPT_DIR/js-bench"
    (cd "$bench_dir" && \
        npm install --silent 2>/dev/null && \
        node bench.mjs --warmup "$WARMUP" --iterations "$ITERATIONS")
}

run_ql_bench() {
    echo ""
    echo "── Layer 3: QuickLook system benchmark"
    bash "$SCRIPT_DIR/ql-bench/ql-bench.sh" --warmup "$WARMUP" --iterations "$ITERATIONS"
}

print_summary() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "  All benchmarks complete. Results in: $SCRIPT_DIR/results/"
    echo "═══════════════════════════════════════════════════════════"
    echo "  Files:"
    ls -lh "$SCRIPT_DIR/results/"*-latest.json 2>/dev/null | awk '{print "    " $NF}'
    echo ""
    echo "  To compare with a previous run:"
    echo "    python3 $SCRIPT_DIR/compare.py <before.json> <after.json>"
}

build_renderer
run_js_bench
run_ql_bench
print_summary
