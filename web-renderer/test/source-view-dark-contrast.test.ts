jest.mock('mermaid', () => ({
    initialize: jest.fn(),
    render: jest.fn().mockResolvedValue({ svg: '<svg>mocked</svg>' }),
}));

import '../src/index';

describe('Source View dark mode contrast with GitHub theme', () => {
    beforeEach(() => {
        document.body.innerHTML = '<div id="markdown-preview"></div>';
        document.documentElement.removeAttribute('data-theme');
        document.getElementById('hljs-override-theme')?.remove();
    });

    test('renderSource with dark theme sets data-theme to dark', () => {
        window.renderSource('const x = 1;', 'dark');
        expect(document.documentElement.getAttribute('data-theme')).toBe('dark');
    });

    test('renderMarkdown with github theme in dark mode injects dark override rules', async () => {
        await window.renderMarkdown('```js\nconst x = 1;\n```', {
            theme: 'dark',
            codeHighlightTheme: 'github',
        });
        const overrideStyle = document.getElementById('hljs-override-theme') as HTMLStyleElement | null;
        expect(overrideStyle).not.toBeNull();
        const css = overrideStyle!.textContent || '';
        expect(css).toContain('[data-theme="dark"]');
    });

    test('github dark override uses high-contrast foreground color for dark background', async () => {
        await window.renderMarkdown('```js\nconst x = 1;\n```', {
            theme: 'dark',
            codeHighlightTheme: 'github',
        });
        const overrideStyle = document.getElementById('hljs-override-theme') as HTMLStyleElement | null;
        const css = overrideStyle!.textContent || '';
        const darkRuleMatch = css.match(/\[data-theme="dark"\][^{]*\{([^}]+)\}/);
        expect(darkRuleMatch).not.toBeNull();
        const darkBaseRule = darkRuleMatch![1];
        expect(darkBaseRule).toContain('background');
        expect(darkBaseRule).not.toContain('#fff');
        expect(darkBaseRule).not.toContain('background:#fff');
    });

    test('github light theme in light mode still injects light base rules', async () => {
        await window.renderMarkdown('```js\nconst x = 1;\n```', {
            theme: 'light',
            codeHighlightTheme: 'github',
        });
        const overrideStyle = document.getElementById('hljs-override-theme') as HTMLStyleElement | null;
        const css = overrideStyle?.textContent || '';
        expect(css).toContain('background:#fff');
    });
});
