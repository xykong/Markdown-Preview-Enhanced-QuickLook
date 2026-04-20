export class BlockquoteCollapse {
    private container: HTMLElement;
    private preview: HTMLElement;
    private collapsed: boolean = false;
    private button: HTMLButtonElement;

    constructor(containerId: string, previewId: string) {
        const containerEl = document.getElementById(containerId);
        if (!containerEl) {
            throw new Error(`BlockquoteCollapse: container element not found: ${containerId}`);
        }
        const previewEl = document.getElementById(previewId);
        if (!previewEl) {
            throw new Error(`BlockquoteCollapse: preview element not found: ${previewId}`);
        }
        this.container = containerEl;
        this.preview = previewEl;
        this.button = this.createButton();
        this.container.appendChild(this.button);
    }

    private createButton(): HTMLButtonElement {
        const button = document.createElement('button');
        button.className = 'blockquote-collapse-toggle';
        button.setAttribute('aria-label', 'Collapse blockquotes');
        button.innerHTML = `
            <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                <path d="M3 5h14v1.5H3V5zm2 4h10v1.5H5V9zm2 4h6v1.5H7V13z"/>
            </svg>
        `;
        button.addEventListener('click', () => this.toggle());
        return button;
    }

    setInitialState(collapsed: boolean): void {
        this.collapsed = collapsed;
        this.applyState();
    }

    toggle(): void {
        this.collapsed = !this.collapsed;
        this.applyState();
    }

    isCollapsed(): boolean {
        return this.collapsed;
    }

    private applyState(): void {
        if (this.collapsed) {
            this.preview.classList.add('blockquotes-collapsed');
            this.button.setAttribute('aria-label', 'Expand blockquotes');
            this.button.classList.add('active');
        } else {
            this.preview.classList.remove('blockquotes-collapsed');
            this.button.setAttribute('aria-label', 'Collapse blockquotes');
            this.button.classList.remove('active');
        }
    }
}
