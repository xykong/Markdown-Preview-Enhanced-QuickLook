jest.mock('mermaid', () => ({
    initialize: jest.fn(),
    render: jest.fn().mockResolvedValue({ svg: '<svg>mocked</svg>' }),
}));

import '../src/index';

describe('RTL auto-detection in renderMarkdown', () => {
    beforeEach(() => {
        document.body.innerHTML = '<div id="markdown-preview" class="markdown-body"></div>';
    });

    test('sets dir="rtl" on markdown-preview when content is mostly Arabic', async () => {
        const arabicDoc = `# مرحبا بالعالم

هذا مستند مكتوب باللغة العربية ويحتوي على محتوى طويل بما يكفي للكشف.
`;
        await window.renderMarkdown(arabicDoc);

        const preview = document.getElementById('markdown-preview');
        expect(preview?.getAttribute('dir')).toBe('rtl');
    });

    test('sets dir="rtl" on markdown-preview when content is mostly Hebrew', async () => {
        const hebrewDoc = `# שלום עולם

זהו מסמך הכתוב בעברית ומכיל תוכן ארוך מספיק לזיהוי.
`;
        await window.renderMarkdown(hebrewDoc);

        const preview = document.getElementById('markdown-preview');
        expect(preview?.getAttribute('dir')).toBe('rtl');
    });

    test('does not set dir attribute when content is English', async () => {
        const englishDoc = `# Hello World

This is a standard English markdown document with no RTL content.
`;
        await window.renderMarkdown(englishDoc);

        const preview = document.getElementById('markdown-preview');
        expect(preview?.getAttribute('dir')).toBeNull();
    });

    test('does not set dir attribute when content is Chinese', async () => {
        const chineseDoc = `# 你好世界

这是一篇用中文写的文档，没有任何阿拉伯文或希伯来文。
`;
        await window.renderMarkdown(chineseDoc);

        const preview = document.getElementById('markdown-preview');
        expect(preview?.getAttribute('dir')).toBeNull();
    });

    test('removes dir="rtl" when re-rendering with LTR content after RTL content', async () => {
        const arabicDoc = '# مرحبا\n\nهذا نص عربي طويل بما يكفي للكشف عنه.';
        await window.renderMarkdown(arabicDoc);

        const preview = document.getElementById('markdown-preview');
        expect(preview?.getAttribute('dir')).toBe('rtl');

        const englishDoc = '# Hello\n\nThis is English content now.';
        await window.renderMarkdown(englishDoc);

        expect(preview?.getAttribute('dir')).toBeNull();
    });

    test('renders English content correctly without RTL interference', async () => {
        const englishDoc = '# Test\n\nSome **bold** and *italic* text.';
        await window.renderMarkdown(englishDoc);

        const preview = document.getElementById('markdown-preview');
        expect(preview?.querySelector('h1')?.textContent).toBe('Test');
        expect(preview?.querySelector('strong')?.textContent).toBe('bold');
        expect(preview?.getAttribute('dir')).toBeNull();
    });
});
