// web-renderer/test/blockquote-collapse.test.ts
import { BlockquoteCollapse } from '../src/blockquote-collapse';

describe('BlockquoteCollapse', () => {
    let container: HTMLElement;
    let preview: HTMLElement;

    beforeEach(() => {
        document.body.innerHTML = `
            <div id="collapse-btn-container"></div>
            <div id="markdown-preview">
                <blockquote><p>Normal quote</p></blockquote>
                <div class="markdown-alert" data-callout-type="note"><p>Note alert</p></div>
                <p>Regular paragraph</p>
            </div>
        `;
        container = document.getElementById('collapse-btn-container')!;
        preview = document.getElementById('markdown-preview')!;
    });

    test('creates toggle button in container on construction', () => {
        new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        const button = container.querySelector('.blockquote-collapse-toggle');
        expect(button).toBeTruthy();
    });

    test('throws if container element not found', () => {
        expect(() => {
            new BlockquoteCollapse('nonexistent-id', 'markdown-preview');
        }).toThrow('BlockquoteCollapse: container element not found: nonexistent-id');
    });

    test('throws if preview element not found', () => {
        expect(() => {
            new BlockquoteCollapse('collapse-btn-container', 'nonexistent-preview');
        }).toThrow('BlockquoteCollapse: preview element not found: nonexistent-preview');
    });

    test('isCollapsed() returns false by default', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        expect(bc.isCollapsed()).toBe(false);
    });

    test('setInitialState(true) collapses preview on load', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        bc.setInitialState(true);
        expect(bc.isCollapsed()).toBe(true);
    });

    test('setInitialState(false) leaves preview expanded', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        bc.setInitialState(false);
        expect(bc.isCollapsed()).toBe(false);
    });

    test('toggle() collapses when expanded', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        bc.toggle();
        expect(bc.isCollapsed()).toBe(true);
    });

    test('toggle() expands when collapsed', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        bc.setInitialState(true);
        bc.toggle();
        expect(bc.isCollapsed()).toBe(false);
    });

    test('toggle() updates isCollapsed() state', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        expect(bc.isCollapsed()).toBe(false);
        bc.toggle();
        expect(bc.isCollapsed()).toBe(true);
        bc.toggle();
        expect(bc.isCollapsed()).toBe(false);
    });

    test('button click triggers toggle', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        const button = container.querySelector('.blockquote-collapse-toggle') as HTMLButtonElement;
        button.click();
        expect(bc.isCollapsed()).toBe(true);
        button.click();
        expect(bc.isCollapsed()).toBe(false);
    });

    test('button has aria-label="Collapse blockquotes" when expanded', () => {
        new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        const button = container.querySelector('.blockquote-collapse-toggle') as HTMLButtonElement;
        expect(button.getAttribute('aria-label')).toBe('Collapse blockquotes');
    });

    test('button aria-label updates to "Expand blockquotes" when collapsed', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        bc.toggle();
        const button = container.querySelector('.blockquote-collapse-toggle') as HTMLButtonElement;
        expect(button.getAttribute('aria-label')).toBe('Expand blockquotes');
    });

    test('does not affect non-blockquote elements', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        bc.setInitialState(true);
        const para = preview.querySelector('p');
        expect(para?.style.display).not.toBe('none');
    });

    test('button has active class when collapsed', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        const button = container.querySelector('.blockquote-collapse-toggle') as HTMLButtonElement;
        expect(button.classList.contains('active')).toBe(false);
        bc.toggle();
        expect(button.classList.contains('active')).toBe(true);
        bc.toggle();
        expect(button.classList.contains('active')).toBe(false);
    });

    // ── Placeholder behaviour ──

    test('collapsing hides blockquote elements (display:none)', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        bc.toggle();
        const bq = preview.querySelector('blockquote') as HTMLElement;
        expect(bq.style.display).toBe('none');
    });

    test('collapsing hides markdown-alert elements (display:none)', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        bc.toggle();
        const alert = preview.querySelector('.markdown-alert') as HTMLElement;
        expect(alert.style.display).toBe('none');
    });

    test('collapsing inserts a placeholder for each collapsed element', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        bc.toggle();
        const placeholders = preview.querySelectorAll('.blockquote-placeholder');
        expect(placeholders.length).toBe(2);
    });

    test('expanding removes all placeholders', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        bc.toggle();
        bc.toggle();
        const placeholders = preview.querySelectorAll('.blockquote-placeholder');
        expect(placeholders.length).toBe(0);
    });

    test('expanding restores blockquote visibility', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        bc.toggle();
        bc.toggle();
        const bq = preview.querySelector('blockquote') as HTMLElement;
        expect(bq.style.display).not.toBe('none');
    });

    test('clicking placeholder expands that individual block', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        bc.toggle();
        const placeholder = preview.querySelector('.blockquote-placeholder') as HTMLElement;
        placeholder.click();
        const bq = preview.querySelector('blockquote') as HTMLElement;
        expect(bq.style.display).not.toBe('none');
        expect(preview.querySelectorAll('.blockquote-placeholder').length).toBe(1);
    });

    test('clicking placeholder removes only that placeholder', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        bc.toggle();
        const placeholders = preview.querySelectorAll('.blockquote-placeholder');
        (placeholders[0] as HTMLElement).click();
        expect(preview.querySelectorAll('.blockquote-placeholder').length).toBe(1);
    });

    test('placeholder is inserted adjacent to its collapsed element', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        bc.toggle();
        const bq = preview.querySelector('blockquote') as HTMLElement;
        const placeholder = bq.previousElementSibling;
        expect(placeholder?.classList.contains('blockquote-placeholder')).toBe(true);
    });
});
