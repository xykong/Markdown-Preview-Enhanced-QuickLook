import { LineDiff, computeCharDiff } from './diff-engine';

function escapeHtml(s: string): string {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function renderCharDiffHtml(oldText: string, newText: string): string {
  const parts = computeCharDiff(oldText, newText);
  return parts.map(p => {
    if (p.type === 'equal')   return escapeHtml(p.value);
    if (p.type === 'added')   return `<span class="diff-char-added">${escapeHtml(p.value)}</span>`;
    if (p.type === 'removed') return `<span class="diff-char-removed">${escapeHtml(p.value)}</span>`;
    return escapeHtml(p.value);
  }).join('');
}

export class DiffAnimator {
  buildSourceHTML(diffs: LineDiff[], theme: string): string {
    const themeClass = theme === 'dark' ? 'source-view-dark' : 'source-view-light';
    let gutterHtml = '';
    let contentHtml = '';
    let staggerIdx = 0;

    for (const diff of diffs) {
      const lineNum = diff.newLineNumber ?? diff.oldLineNumber ?? '';
      let gutterClass = 'source-diff-line-num';
      let contentClass = 'source-diff-line';
      let badge = '';
      let lineContent = '';
      let staggerStyle = '';

      switch (diff.type) {
        case 'added':
          gutterClass += ' diff-added diff-entering';
          contentClass += ' diff-entering';
          badge = `<span class="diff-gutter-badge">+</span>`;
          lineContent = escapeHtml(diff.newContent);
          staggerStyle = `style="animation-delay:${staggerIdx * 25}ms"`;
          staggerIdx++;
          break;

        case 'removed':
          gutterClass += ' diff-removed';
          badge = `<span class="diff-gutter-badge">\u2212</span>`;
          lineContent = `<span class="diff-char-removed">${escapeHtml(diff.oldContent)}</span>`;
          break;

        case 'modified':
          gutterClass += ' diff-modified diff-entering';
          contentClass += ' diff-entering';
          badge = `<span class="diff-gutter-badge">~</span>`;
          lineContent = renderCharDiffHtml(diff.oldContent, diff.newContent);
          staggerStyle = `style="animation-delay:${staggerIdx * 25}ms"`;
          staggerIdx++;
          break;

        case 'equal':
        default:
          lineContent = escapeHtml(diff.newContent ?? diff.oldContent ?? '');
          break;
      }

      gutterHtml  += `<span class="${gutterClass}" ${staggerStyle}>${lineNum}${badge}</span>`;
      contentHtml += `<span class="${contentClass}" ${staggerStyle}>${lineContent}</span>`;
    }

    return `<div class="source-diff-wrap ${themeClass}">` +
             `<div class="source-diff-gutter">${gutterHtml}</div>` +
             `<div class="source-diff-content">${contentHtml}</div>` +
           `</div>`;
  }

  annotateRenderDOM(container: HTMLElement, diffs: LineDiff[]): void {
    const diffByNewLine = new Map<number, LineDiff>();
    for (const d of diffs) {
      if (d.newLineNumber !== null) diffByNewLine.set(d.newLineNumber, d);
    }

    const elements = container.querySelectorAll<HTMLElement>('[data-source-line]');
    let staggerIdx = 0;

    for (const el of elements) {
      const lineAttr = el.getAttribute('data-source-line');
      if (!lineAttr) continue;
      const lineNum = parseInt(lineAttr, 10);
      if (isNaN(lineNum)) continue;

      const diff = diffByNewLine.get(lineNum);
      if (!diff || diff.type === 'equal') continue;

      if (diff.type === 'added') {
        el.classList.add('render-diff-block-enter');
        el.style.animationDelay = `${staggerIdx * 30}ms`;
        staggerIdx++;
      } else if (diff.type === 'modified') {
        // Only add the amber pulse class — do NOT inject char diffs into rendered HTML,
        // as oldContent/newContent are raw markdown text that would corrupt the rendered DOM.
        el.classList.add('render-diff-block-modified');
      }
    }
  }
}
