// web-renderer/test/blockquote-collapse-integration.test.ts
import '../src/index';

describe('BlockquoteCollapse integration with renderMarkdown', () => {
    beforeEach(() => {
        document.body.innerHTML = `
            <div id="collapse-btn-container"></div>
            <div id="markdown-preview"></div>
            <div id="toc-container"></div>
            <div id="search-container"></div>
        `;
    });

    test('collapse toggle button is created in DOM after renderMarkdown', async () => {
        await window.renderMarkdown('> A blockquote');
        const button = document.querySelector('.blockquote-collapse-toggle');
        expect(button).toBeTruthy();
    });

    test('collapseBlockquotes: true option inserts placeholder and hides blockquote', async () => {
        await window.renderMarkdown('> A blockquote', { collapseBlockquotes: true });
        const preview = document.getElementById('markdown-preview')!;
        const bq = preview.querySelector('blockquote') as HTMLElement;
        expect(bq.style.display).toBe('none');
        expect(preview.querySelector('.blockquote-placeholder')).toBeTruthy();
    });

    test('collapseBlockquotes: false (default) leaves blockquote visible', async () => {
        await window.renderMarkdown('> A blockquote', { collapseBlockquotes: false });
        const preview = document.getElementById('markdown-preview')!;
        expect(preview.querySelector('.blockquote-placeholder')).toBeFalsy();
    });

    test('collapseBlockquotes defaults to false when option omitted', async () => {
        await window.renderMarkdown('> A blockquote');
        const preview = document.getElementById('markdown-preview')!;
        expect(preview.querySelector('.blockquote-placeholder')).toBeFalsy();
    });
});
