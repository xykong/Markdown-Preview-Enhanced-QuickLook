jest.mock('mermaid', () => ({
    initialize: jest.fn(),
    render: jest.fn().mockResolvedValue({ svg: '<svg>mocked</svg>' }),
}));

import '../src/index';

describe('Extended Syntax', () => {
    beforeEach(() => {
        document.body.innerHTML = '<div id="markdown-preview"></div>';
    });

    describe('Footnotes (markdown-it-footnote)', () => {
        test('renders footnote reference as superscript link', async () => {
            const md = 'Hello world.[^1]\n\n[^1]: This is a footnote.';
            await window.renderMarkdown(md);
            const preview = document.getElementById('markdown-preview')!;
            expect(preview.innerHTML).toContain('footnote');
            expect(preview.querySelector('sup')).toBeTruthy();
        });

        test('renders footnote definition section', async () => {
            const md = 'Text[^note]\n\n[^note]: The note content.';
            await window.renderMarkdown(md);
            const preview = document.getElementById('markdown-preview')!;
            expect(preview.innerHTML).toContain('The note content.');
        });
    });

    describe('Subscript and Superscript (markdown-it-sub / markdown-it-sup)', () => {
        test('renders subscript with ~text~', async () => {
            const md = 'H~2~O';
            await window.renderMarkdown(md);
            const preview = document.getElementById('markdown-preview')!;
            expect(preview.querySelector('sub')).toBeTruthy();
            expect(preview.querySelector('sub')?.textContent).toBe('2');
        });

        test('renders superscript with ^text^', async () => {
            const md = 'x^2^';
            await window.renderMarkdown(md);
            const preview = document.getElementById('markdown-preview')!;
            expect(preview.querySelector('sup')).toBeTruthy();
            expect(preview.querySelector('sup')?.textContent).toBe('2');
        });

        test('renders both in same document', async () => {
            const md = 'H~2~O and E=mc^2^';
            await window.renderMarkdown(md);
            const preview = document.getElementById('markdown-preview')!;
            expect(preview.querySelector('sub')).toBeTruthy();
            expect(preview.querySelector('sup')).toBeTruthy();
        });
    });

    describe('Mark / Highlight (markdown-it-mark)', () => {
        test('renders ==text== as <mark>', async () => {
            const md = 'This is ==highlighted== text.';
            await window.renderMarkdown(md);
            const preview = document.getElementById('markdown-preview')!;
            const mark = preview.querySelector('mark');
            expect(mark).toBeTruthy();
            expect(mark?.textContent).toBe('highlighted');
        });

        test('renders multiple highlights in same paragraph', async () => {
            const md = '==first== and ==second==';
            await window.renderMarkdown(md);
            const preview = document.getElementById('markdown-preview')!;
            const marks = preview.querySelectorAll('mark');
            expect(marks.length).toBe(2);
            expect(marks[0].textContent).toBe('first');
            expect(marks[1].textContent).toBe('second');
        });
    });

    describe('Typographer (Smart quotes and dashes)', () => {
        test('converts double hyphens to en dash', async () => {
            const md = 'Pages 10--20';
            await window.renderMarkdown(md);
            const preview = document.getElementById('markdown-preview')!;
            expect(preview.textContent).toContain('\u2013');
        });

        test('converts triple hyphens to em dash', async () => {
            const md = 'Yes---no';
            await window.renderMarkdown(md);
            const preview = document.getElementById('markdown-preview')!;
            expect(preview.textContent).toContain('\u2014');
        });

        test('converts straight quotes to curly quotes', async () => {
            const md = '"Hello world"';
            await window.renderMarkdown(md);
            const preview = document.getElementById('markdown-preview')!;
            const text = preview.textContent || '';
            expect(text).toContain('\u201c');
            expect(text).toContain('\u201d');
        });
    });

    describe('renderSource (Raw Toggle)', () => {
        test('renders raw markdown as syntax-highlighted source', () => {
            document.body.innerHTML = '<div id="markdown-preview"></div>';
            const md = '# Hello\n\nThis is **bold**.';
            window.renderSource(md, 'light');
            const preview = document.getElementById('markdown-preview')!;
            expect(preview.querySelector('.source-diff-wrap')).toBeTruthy();
        });

        test('applies dark class when theme is dark', () => {
            document.body.innerHTML = '<div id="markdown-preview"></div>';
            window.renderSource('# test', 'dark');
            const preview = document.getElementById('markdown-preview')!;
            expect(preview.querySelector('.source-view-dark')).toBeTruthy();
        });

        test('applies light class when theme is light', () => {
            document.body.innerHTML = '<div id="markdown-preview"></div>';
            window.renderSource('# test', 'light');
            const preview = document.getElementById('markdown-preview')!;
            expect(preview.querySelector('.source-view-light')).toBeTruthy();
        });

        test('preserves markdown source content in output', () => {
            document.body.innerHTML = '<div id="markdown-preview"></div>';
            const md = '## Section\n\n- item one\n- item two';
            window.renderSource(md, 'light');
            const preview = document.getElementById('markdown-preview')!;
            expect(preview.textContent).toContain('Section');
            expect(preview.textContent).toContain('item one');
        });
    });
});
