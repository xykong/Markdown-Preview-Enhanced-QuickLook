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
        expect(preview.classList.contains('blockquotes-collapsed')).toBe(true);
        expect(bc.isCollapsed()).toBe(true);
    });

    test('setInitialState(false) leaves preview expanded', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        bc.setInitialState(false);
        expect(preview.classList.contains('blockquotes-collapsed')).toBe(false);
        expect(bc.isCollapsed()).toBe(false);
    });

    test('toggle() adds blockquotes-collapsed class when expanded', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        bc.toggle();
        expect(preview.classList.contains('blockquotes-collapsed')).toBe(true);
    });

    test('toggle() removes blockquotes-collapsed class when collapsed', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        bc.setInitialState(true);
        bc.toggle();
        expect(preview.classList.contains('blockquotes-collapsed')).toBe(false);
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
        expect(para?.classList.contains('blockquotes-collapsed')).toBeFalsy();
    });

    // CSS class behavior tests
    test('blockquotes-collapsed class is on preview element (not on blockquote itself)', () => {
        const bc = new BlockquoteCollapse('collapse-btn-container', 'markdown-preview');
        bc.toggle();
        expect(preview.classList.contains('blockquotes-collapsed')).toBe(true);
        const bq = preview.querySelector('blockquote');
        expect(bq?.classList.contains('blockquotes-collapsed')).toBeFalsy();
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
});
