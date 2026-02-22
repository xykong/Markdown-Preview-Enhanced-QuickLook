import '../src/index';

describe('Extended Code Highlight', () => {
    beforeEach(() => {
        document.body.innerHTML = `
            <div id="markdown-preview"></div>
            <div id="toc-container"></div>
            <div id="search-container"></div>
        `;
    });

    test('Kotlin code block is highlighted', async () => {
        const markdown = '```kotlin\nfun main() {\n    println("Hello")\n}\n```';
        await window.renderMarkdown(markdown);
        const preview = document.getElementById('markdown-preview')!;
        const code = preview.querySelector('pre.hljs code');
        expect(code).toBeTruthy();
        expect(code!.innerHTML).toContain('<span');
    });

    test('Rust code block is highlighted', async () => {
        const markdown = '```rust\nfn main() {\n    println!("Hello");\n}\n```';
        await window.renderMarkdown(markdown);
        const preview = document.getElementById('markdown-preview')!;
        const code = preview.querySelector('pre.hljs code');
        expect(code).toBeTruthy();
        expect(code!.innerHTML).toContain('<span');
    });

    test('js alias resolves to javascript highlighting', async () => {
        const markdown = '```js\nconst x = 1;\n```';
        await window.renderMarkdown(markdown);
        const preview = document.getElementById('markdown-preview')!;
        const code = preview.querySelector('pre.hljs code');
        expect(code).toBeTruthy();
        expect(code!.innerHTML).toContain('<span');
    });

    test('py alias resolves to python highlighting', async () => {
        const markdown = '```py\ndef hello():\n    pass\n```';
        await window.renderMarkdown(markdown);
        const preview = document.getElementById('markdown-preview')!;
        const code = preview.querySelector('pre.hljs code');
        expect(code).toBeTruthy();
        expect(code!.innerHTML).toContain('<span');
    });

    test('unknown language renders as plain text without error', async () => {
        const markdown = '```unknownlang9999\nsome code\n```';
        await window.renderMarkdown(markdown);
        const preview = document.getElementById('markdown-preview')!;
        const pre = preview.querySelector('pre.hljs');
        expect(pre).toBeTruthy();
        expect(pre!.textContent).toContain('some code');
    });
});
