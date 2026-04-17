jest.mock('mermaid', () => ({
    initialize: jest.fn(),
    render: jest.fn().mockResolvedValue({ svg: '<svg>mocked</svg>' }),
}));

import '../src/index';

describe('Issue #19 — preloadStylesheets must not use fetch() to load stylesheets', () => {
    beforeEach(() => {
        document.head.innerHTML = '';
        document.body.innerHTML = `
            <div id="markdown-preview"></div>
            <div id="toc-container"></div>
            <div id="search-container"></div>
        `;
    });

    afterEach(() => {
        document.querySelectorAll('base').forEach(el => { el.remove(); });
        jest.restoreAllMocks();
    });

    test('preloadStylesheets does not call fetch() for stylesheet links', async () => {
        const fetchMock = jest.fn().mockResolvedValue({ ok: false, text: async () => '' });
        (global as any).fetch = fetchMock;

        const link = document.createElement('link');
        link.rel = 'stylesheet';
        link.setAttribute('href', './assets/index-test.css');
        document.head.appendChild(link);

        await window.renderMarkdown('# Hello', {
            baseUrl: '/Users/testuser/documents',
            theme: 'light',
        });

        await new Promise(resolve => setTimeout(resolve, 600));

        const cssRequests = fetchMock.mock.calls.filter(
            ([url]: [unknown]) => typeof url === 'string' && url.includes('.css')
        );
        expect(cssRequests).toHaveLength(0);

        delete (global as any).fetch;
    });

    test('exportHTML includes CSS from inline styles without relying on fetch()', async () => {
        const fetchMock = jest.fn().mockResolvedValue({ ok: false, text: async () => '' });
        (global as any).fetch = fetchMock;

        const style = document.createElement('style');
        style.textContent = 'body { color: red; }';
        document.head.appendChild(style);

        const link = document.createElement('link');
        link.rel = 'stylesheet';
        link.setAttribute('href', './assets/index-test.css');
        document.head.appendChild(link);

        await window.renderMarkdown('# Export test', {
            baseUrl: '/Users/testuser/documents',
            theme: 'light',
        });

        await new Promise(resolve => setTimeout(resolve, 600));

        const html = window.exportHTML();
        expect(html).toContain('color: red');

        const cssRequests = fetchMock.mock.calls.filter(
            ([url]: [unknown]) => typeof url === 'string' && url.includes('.css')
        );
        expect(cssRequests).toHaveLength(0);

        delete (global as any).fetch;
    });
});
