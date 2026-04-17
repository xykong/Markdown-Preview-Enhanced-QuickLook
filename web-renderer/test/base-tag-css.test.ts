import '../src/index';

function setupDOM(cssHref: string) {
    document.head.innerHTML = `<link rel="stylesheet" href="${cssHref}">`;
    document.body.innerHTML = `<div id="markdown-preview"></div>`;
}

describe('Issue #19 — renderMarkdown base tag must not break stylesheet href', () => {
    afterEach(() => {
        document.querySelectorAll('base').forEach(el => { el.remove(); });
    });

    test('stylesheet href (resolved) does not point to user directory after renderMarkdown inserts base tag', async () => {
        setupDOM('./assets/index-test.css');

        const linkBefore = document.querySelector<HTMLLinkElement>('link[rel="stylesheet"]')!;
        const hrefBefore = linkBefore.href;
        expect(hrefBefore).not.toContain('/Users/testuser');

        await window.renderMarkdown('# Hello', {
            baseUrl: '/Users/testuser/documents',
            theme: 'light',
        });

        const linkAfter = document.querySelector<HTMLLinkElement>('link[rel="stylesheet"]')!;
        expect(linkAfter.href).not.toContain('/Users/testuser');
        expect(linkAfter.href).toBe(hrefBefore);
    });

    test('stylesheet href is not re-resolved when base tag is inserted for deeply nested file', async () => {
        setupDOM('./assets/index-test.css');

        const hrefBefore = document.querySelector<HTMLLinkElement>('link[rel="stylesheet"]')!.href;

        await window.renderMarkdown('# Hello', {
            baseUrl: '/Users/testuser/projects/my-project/docs',
            theme: 'light',
        });

        const base = document.querySelector('base');
        expect(base).toBeTruthy();
        expect(base?.getAttribute('href')).toContain('/Users/testuser/projects/my-project/docs');

        const linkAfter = document.querySelector<HTMLLinkElement>('link[rel="stylesheet"]')!;
        expect(linkAfter.href).not.toContain('/Users/testuser');
        expect(linkAfter.href).toBe(hrefBefore);
    });

    test('base tag is still inserted to allow relative image path resolution', async () => {
        setupDOM('./assets/index-test.css');

        await window.renderMarkdown('![img](./pic.png)', {
            baseUrl: '/Users/testuser/notes',
            theme: 'light',
        });

        const base = document.querySelector('base');
        expect(base).toBeTruthy();
        expect(base?.getAttribute('href')).toContain('/Users/testuser/notes');
    });
});
