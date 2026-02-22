import '../src/index';

describe('GitHub Alerts / Callouts', () => {
    beforeEach(() => {
        document.body.innerHTML = `
            <div id="markdown-preview"></div>
            <div id="toc-container"></div>
            <div id="search-container"></div>
        `;
    });

    test.each([
        ['NOTE', 'note'],
        ['TIP', 'tip'],
        ['IMPORTANT', 'important'],
        ['WARNING', 'warning'],
        ['CAUTION', 'caution'],
    ])('renders > [!%s] as callout with type "%s"', async (type, expectedType) => {
        const markdown = `> [!${type}]\n> This is a ${type} callout.`;
        await window.renderMarkdown(markdown);
        const preview = document.getElementById('markdown-preview')!;
        const callout = preview.querySelector(`[data-callout-type="${expectedType}"]`);
        expect(callout).toBeTruthy();
    });

    test('unknown callout type falls back to normal blockquote', async () => {
        const markdown = `> [!CUSTOM]\n> This is a custom type.`;
        await window.renderMarkdown(markdown);
        const preview = document.getElementById('markdown-preview')!;
        const callout = preview.querySelector('[data-callout-type]');
        expect(callout).toBeNull();
        const blockquote = preview.querySelector('blockquote');
        expect(blockquote).toBeTruthy();
    });

    test('callout content renders nested markdown correctly', async () => {
        const markdown = `> [!NOTE]\n> **Bold text** and \`inline code\` inside callout.`;
        await window.renderMarkdown(markdown);
        const preview = document.getElementById('markdown-preview')!;
        const callout = preview.querySelector('[data-callout-type="note"]');
        expect(callout).toBeTruthy();
        expect(callout!.querySelector('strong')).toBeTruthy();
        expect(callout!.querySelector('code')).toBeTruthy();
    });

    test('normal blockquote without [!TYPE] is unaffected', async () => {
        const markdown = `> This is a normal blockquote.`;
        await window.renderMarkdown(markdown);
        const preview = document.getElementById('markdown-preview')!;
        const callout = preview.querySelector('[data-callout-type]');
        expect(callout).toBeNull();
        const blockquote = preview.querySelector('blockquote');
        expect(blockquote).toBeTruthy();
        expect(blockquote!.textContent).toContain('normal blockquote');
    });
});
