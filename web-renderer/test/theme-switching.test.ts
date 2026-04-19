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
