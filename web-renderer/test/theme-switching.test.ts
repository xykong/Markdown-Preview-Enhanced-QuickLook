jest.mock('mermaid', () => ({
  initialize: jest.fn(),
  render: jest.fn().mockResolvedValue({ svg: '<svg>mocked</svg>' }),
}));

declare global {
  interface Window {
    updateTheme: (theme: string) => void;
  }
}

import '../src/index';

describe('window.updateTheme', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="markdown-preview"></div>';
    document.documentElement.removeAttribute('data-theme');
  });

  test('sets data-theme="dark" on documentElement when called with "dark"', () => {
    window.updateTheme('dark');
    expect(document.documentElement.getAttribute('data-theme')).toBe('dark');
  });

  test('sets data-theme="light" on documentElement when called with "light"', () => {
    window.updateTheme('light');
    expect(document.documentElement.getAttribute('data-theme')).toBe('light');
  });

  test('sets data-theme="default" on documentElement when called with "default"', () => {
    window.updateTheme('default');
    expect(document.documentElement.getAttribute('data-theme')).toBe('default');
  });

  test('does NOT replace outputDiv innerHTML when theme changes', async () => {
    await window.renderMarkdown('# Hello\n\nsome content');
    const preview = document.getElementById('markdown-preview');
    const domBeforeSwitch = preview?.innerHTML;

    window.updateTheme('dark');

    expect(preview?.innerHTML).toBe(domBeforeSwitch);
  });

  test('can be called multiple times without resetting DOM content', async () => {
    await window.renderMarkdown('# Persistent Content');
    const preview = document.getElementById('markdown-preview');
    const snapshot = preview?.innerHTML;

    window.updateTheme('dark');
    window.updateTheme('light');
    window.updateTheme('dark');

    expect(preview?.innerHTML).toBe(snapshot);
  });

  test('updates theme from dark to light correctly', () => {
    window.updateTheme('dark');
    expect(document.documentElement.getAttribute('data-theme')).toBe('dark');
    window.updateTheme('light');
    expect(document.documentElement.getAttribute('data-theme')).toBe('light');
  });
});

describe('renderMarkdown initializes data-theme', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="markdown-preview"></div>';
    document.documentElement.removeAttribute('data-theme');
  });

  test('sets data-theme="dark" when options.theme is "dark"', async () => {
    await window.renderMarkdown('# Hello', { theme: 'dark' });
    expect(document.documentElement.getAttribute('data-theme')).toBe('dark');
  });

  test('sets data-theme="default" when options.theme is "light"', async () => {
    await window.renderMarkdown('# Hello', { theme: 'light' });
    expect(document.documentElement.getAttribute('data-theme')).toBe('default');
  });

  test('sets data-theme="default" when no theme option provided', async () => {
    await window.renderMarkdown('# Hello');
    expect(document.documentElement.getAttribute('data-theme')).toBe('default');
  });

  test('sets data-theme="default" when options.theme is "system" (jsdom is light env)', async () => {
    // jsdom 中 matchMedia 默认返回 false（light），system → default
    await window.renderMarkdown('# Hello', { theme: 'system' });
    expect(document.documentElement.getAttribute('data-theme')).toBe('default');
  });
});

describe('renderSource initializes data-theme', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="markdown-preview"></div>';
    document.documentElement.removeAttribute('data-theme');
  });

  test('sets data-theme="dark" when called with "dark"', () => {
    window.renderSource('const x = 1;', 'dark');
    expect(document.documentElement.getAttribute('data-theme')).toBe('dark');
  });

  test('sets data-theme="default" when called with "light"', () => {
    window.renderSource('const x = 1;', 'light');
    expect(document.documentElement.getAttribute('data-theme')).toBe('default');
  });

  test('sets data-theme="default" when called with "default"', () => {
    window.renderSource('const x = 1;', 'default');
    expect(document.documentElement.getAttribute('data-theme')).toBe('default');
  });

  test('source-view-dark class is present when theme is "dark"', () => {
    window.renderSource('const x = 1;', 'dark');
    const sourceView = document.querySelector('.source-view');
    expect(sourceView?.classList.contains('source-view-dark')).toBe(true);
    expect(sourceView?.classList.contains('source-view-light')).toBe(false);
  });

  test('source-view-light class is present when theme is "light"', () => {
    window.renderSource('const x = 1;', 'light');
    const sourceView = document.querySelector('.source-view');
    expect(sourceView?.classList.contains('source-view-light')).toBe(true);
    expect(sourceView?.classList.contains('source-view-dark')).toBe(false);
  });

  test('does NOT wipe existing markdown preview when updateTheme is called', async () => {
    await window.renderMarkdown('# Document Title');
    const previewBefore = document.getElementById('markdown-preview')?.innerHTML;

    window.updateTheme('dark');

    const previewAfter = document.getElementById('markdown-preview')?.innerHTML;
    expect(previewAfter).toBe(previewBefore);
  });
});

describe('renderSource CSS class assignment', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="markdown-preview"></div>';
  });

  test('source-view-dark class applied when theme is "dark"', () => {
    window.renderSource('# code', 'dark');
    const el = document.querySelector('.source-view');
    expect(el?.classList.contains('source-view-dark')).toBe(true);
    expect(el?.classList.contains('source-view-light')).toBe(false);
  });

  test('source-view-light class applied when theme is "light"', () => {
    window.renderSource('# code', 'light');
    const el = document.querySelector('.source-view');
    expect(el?.classList.contains('source-view-light')).toBe(true);
    expect(el?.classList.contains('source-view-dark')).toBe(false);
  });

  test('source-view-light class applied when theme is "default"', () => {
    window.renderSource('# code', 'default');
    const el = document.querySelector('.source-view');
    expect(el?.classList.contains('source-view-light')).toBe(true);
  });
});
