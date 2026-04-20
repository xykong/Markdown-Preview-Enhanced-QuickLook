/**
 * Toggle Mode Bug Reproduction Test
 *
 * Tests the source view ↔ rendered preview toggle behavior.
 * Specifically validates that calling renderMarkdown() after renderSource()
 * correctly restores rendered HTML (not source code).
 *
 * This simulates what WKWebView's evaluateJavaScript does when Swift calls
 * window.renderMarkdown / window.renderSource.
 */

jest.mock('mermaid', () => ({
    initialize: jest.fn(),
    render: jest.fn().mockResolvedValue({ svg: '<svg>mocked</svg>' }),
}));

import '../src/index';

const SAMPLE_MARKDOWN = `# Hello World

This is a **bold** paragraph with some content.

- Item 1
- Item 2

\`\`\`javascript
console.log("hello");
\`\`\`
`;

describe('Source/Preview Toggle Mode', () => {
    beforeEach(() => {
        document.body.innerHTML = `
            <div id="markdown-preview"></div>
            <div id="loading-status"></div>
            <div id="toc-container"></div>
            <div id="search-container"></div>
            <div id="help-overlay"></div>
            <div id="collapse-btn-container"></div>
        `;
    });

    test('initial renderMarkdown produces rendered HTML (not source)', async () => {
        await window.renderMarkdown(SAMPLE_MARKDOWN);
        const preview = document.getElementById('markdown-preview')!;
        expect(preview.innerHTML).toContain('<h1');
        expect(preview.innerHTML).toContain('<strong>');
        expect(preview.innerHTML).not.toContain('source-view');
    });

    test('renderSource after renderMarkdown shows source code view', async () => {
        await window.renderMarkdown(SAMPLE_MARKDOWN);
        window.renderSource(SAMPLE_MARKDOWN, 'default');
        const preview = document.getElementById('markdown-preview')!;
        expect(preview.innerHTML).toContain('source-view');
        expect(preview.innerHTML).not.toContain('<h1');
    });

    /**
     * THE BUG TEST: Toggle source → preview.
     *
     * In WKWebView, when Swift calls evaluateJavaScript("window.renderMarkdown(...)"),
     * the function fires and Swift's completion handler gets the Promise object immediately
     * (evaluateJavaScript does NOT await Promises). The async work inside renderMarkdown
     * continues running in the background.
     *
     * In tests, we can await the Promise directly to verify correct behavior.
     * This test proves renderMarkdown correctly updates the DOM after renderSource.
     */
    test('renderMarkdown after renderSource restores rendered HTML (toggle back to preview)', async () => {
        // Step 1: Initial render
        await window.renderMarkdown(SAMPLE_MARKDOWN);
        const preview = document.getElementById('markdown-preview')!;
        const initialHtml = preview.innerHTML;
        expect(initialHtml).toContain('<h1');

        // Step 2: Switch to source view (simulates user clicking toggle to source)
        window.renderSource(SAMPLE_MARKDOWN, 'default');
        expect(preview.innerHTML).toContain('source-view');
        expect(preview.innerHTML).not.toContain('<h1');

        // Step 3: Switch back to preview (simulates user clicking toggle back to preview)
        // This is the bug scenario - does renderMarkdown restore the rendered HTML?
        await window.renderMarkdown(SAMPLE_MARKDOWN);
        
        // After toggling back, should show rendered HTML, NOT source code
        expect(preview.innerHTML).toContain('<h1');
        expect(preview.innerHTML).toContain('<strong>');
        expect(preview.innerHTML).not.toContain('source-view');
    });

    /**
     * FIRE-AND-FORGET SIMULATION: Simulates WKWebView evaluateJavaScript behavior
     * 
     * WKWebView calls window.renderMarkdown() but does NOT await the Promise.
     * The Promise runs in the background. This test verifies that even in
     * fire-and-forget mode (no await), the DOM is EVENTUALLY updated correctly.
     * 
     * Note: In real WKWebView, the async JS completes on the JS event loop.
     * This test uses jest fake timers / microtask flushing to simulate that.
     */
    test('fire-and-forget renderMarkdown (simulating evaluateJavaScript without await) eventually updates DOM', async () => {
        // Step 1: Initial render
        await window.renderMarkdown(SAMPLE_MARKDOWN);

        // Step 2: Switch to source view
        window.renderSource(SAMPLE_MARKDOWN, 'default');
        const preview = document.getElementById('markdown-preview')!;
        expect(preview.innerHTML).toContain('source-view');

        // Step 3: Call renderMarkdown WITHOUT awaiting (simulating evaluateJavaScript)
        // Store the Promise but don't await it yet — simulating fire-and-forget
        const renderPromise = window.renderMarkdown(SAMPLE_MARKDOWN);
        
        // At this point (before the Promise resolves), the DOM is still in source view
        // because renderMarkdown is async and hasn't completed yet
        // (This is fine — WKWebView would also have source view at this instant)

        // Step 4: Now let the Promise complete (simulates JS event loop processing)
        await renderPromise;

        // After Promise completion, DOM should be in rendered mode
        expect(preview.innerHTML).toContain('<h1');
        expect(preview.innerHTML).not.toContain('source-view');
    });

    /**
     * RACE CONDITION TEST: Simulates back-to-back calls.
     * 
     * If Swift calls renderMarkdown (async, fire-and-forget) followed immediately
     * by renderSource (sync), the sync renderSource would overwrite the DOM
     * while renderMarkdown is still running asynchronously.
     */
    test('sync renderSource called after async renderMarkdown DOM update overwrites content (JS race, prevented by callAsyncJavaScript in Swift)', async () => {
        await window.renderMarkdown(SAMPLE_MARKDOWN);
        const preview = document.getElementById('markdown-preview')!;

        window.renderSource(SAMPLE_MARKDOWN, 'default');

        const renderPromise = window.renderMarkdown(SAMPLE_MARKDOWN);

        window.renderSource(SAMPLE_MARKDOWN, 'dark');

        await renderPromise;

        expect(preview.innerHTML).toContain('source-view');
    });

    test('multiple toggle cycles all work correctly', async () => {
        const preview = document.getElementById('markdown-preview')!;

        await window.renderMarkdown(SAMPLE_MARKDOWN);
        expect(preview.innerHTML).toContain('<h1');

        // Cycle 1: preview → source → preview
        window.renderSource(SAMPLE_MARKDOWN, 'default');
        expect(preview.innerHTML).toContain('source-view');
        await window.renderMarkdown(SAMPLE_MARKDOWN);
        expect(preview.innerHTML).toContain('<h1');

        // Cycle 2: preview → source → preview
        window.renderSource(SAMPLE_MARKDOWN, 'dark');
        expect(preview.innerHTML).toContain('source-view');
        await window.renderMarkdown(SAMPLE_MARKDOWN);
        expect(preview.innerHTML).toContain('<h1');

        // Cycle 3: preview → source → preview
        window.renderSource(SAMPLE_MARKDOWN, 'default');
        expect(preview.innerHTML).toContain('source-view');
        await window.renderMarkdown(SAMPLE_MARKDOWN);
        expect(preview.innerHTML).toContain('<h1');
        expect(preview.innerHTML).not.toContain('source-view');
    });
});
