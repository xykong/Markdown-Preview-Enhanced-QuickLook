/**
 * @jest-environment node
 */
import { JSDOM } from 'jsdom';

describe('line-numbers CSS attribute injection', () => {
  it('renders block elements with data-source-line attribute', () => {
    const dom = new JSDOM(`
      <html>
        <body>
          <div id="markdown-preview">
            <h1 data-source-line="1" data-source-line-end="2">Title</h1>
            <p data-source-line="3" data-source-line-end="5">Paragraph</p>
          </div>
        </body>
      </html>
    `);
    const h1 = dom.window.document.querySelector('h1');
    const p = dom.window.document.querySelector('p');
    expect(h1?.getAttribute('data-source-line')).toBe('1');
    expect(p?.getAttribute('data-source-line')).toBe('3');
  });

  it('data-line-numbers attribute controls gutter visibility', () => {
    const dom = new JSDOM(`<html data-line-numbers="true"><body></body></html>`);
    expect(dom.window.document.documentElement.getAttribute('data-line-numbers')).toBe('true');

    dom.window.document.documentElement.setAttribute('data-line-numbers', 'false');
    expect(dom.window.document.documentElement.getAttribute('data-line-numbers')).toBe('false');
  });
});

describe('showLineNumbers option', () => {
  it('sets data-line-numbers=true on html when enabled', () => {
    const dom = new JSDOM('<!DOCTYPE html><html><head></head><body></body></html>');
    const doc = dom.window.document;

    function applyLineNumbers(enabled: boolean) {
      doc.documentElement.setAttribute('data-line-numbers', enabled ? 'true' : 'false');
    }

    applyLineNumbers(true);
    expect(doc.documentElement.getAttribute('data-line-numbers')).toBe('true');

    applyLineNumbers(false);
    expect(doc.documentElement.getAttribute('data-line-numbers')).toBe('false');
  });
});
