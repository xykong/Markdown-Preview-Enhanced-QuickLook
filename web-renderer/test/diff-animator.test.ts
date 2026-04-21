import { DiffAnimator } from '../src/diff-animator';
import { computeLineDiff } from '../src/diff-engine';

describe('DiffAnimator.buildSourceHTML', () => {
  let animator: DiffAnimator;

  beforeEach(() => {
    animator = new DiffAnimator();
  });

  test('equal lines render with line numbers, no diff classes', () => {
    const diffs = computeLineDiff('', 'hello\nworld');
    const html = animator.buildSourceHTML(diffs, 'light');
    expect(html).toContain('class="source-diff-line-num"');
    expect(html).toContain('>1<');
    expect(html).toContain('>2<');
    expect(html).not.toContain('diff-added');
    expect(html).not.toContain('diff-removed');
  });

  test('added line gets diff-added class on gutter and content', () => {
    const diffs = computeLineDiff('hello', 'hello\nworld');
    const html = animator.buildSourceHTML(diffs, 'light');
    expect(html).toContain('diff-added');
    expect(html).toContain('diff-entering');
  });

  test('removed line gets diff-removed class', () => {
    const diffs = computeLineDiff('hello\nworld', 'hello');
    const html = animator.buildSourceHTML(diffs, 'light');
    expect(html).toContain('diff-removed');
  });

  test('modified line contains char diff spans', () => {
    const diffs = computeLineDiff('hello world', 'hello earth');
    const html = animator.buildSourceHTML(diffs, 'light');
    expect(html).toContain('diff-char-removed');
    expect(html).toContain('diff-char-added');
  });
});

describe('DiffAnimator.annotateRenderDOM', () => {
  let animator: DiffAnimator;

  beforeEach(() => {
    animator = new DiffAnimator();
    document.body.innerHTML = '<div id="markdown-preview"></div>';
  });

  test('elements with data-source-line matching added lines get enter class', () => {
    const container = document.getElementById('markdown-preview')!;
    container.innerHTML = `
      <p data-source-line="1">Hello</p>
      <p data-source-line="2">World</p>
    `;
    const diffs = computeLineDiff('Hello', 'Hello\nWorld');
    animator.annotateRenderDOM(container, diffs);
    const p2 = container.querySelector('[data-source-line="2"]');
    expect(p2?.classList.contains('render-diff-block-enter')).toBe(true);
  });

  test('modified source lines get amber pulse class without corrupting rendered HTML', () => {
    const container = document.getElementById('markdown-preview')!;
    container.innerHTML = `<p data-source-line="1">hello world</p>`;
    const diffs = computeLineDiff('hello world', 'hello earth');
    animator.annotateRenderDOM(container, diffs);
    const p = container.querySelector('p')!;
    expect(p.classList.contains('render-diff-block-modified')).toBe(true);
    expect(p.innerHTML).toBe('hello world');
  });
});
