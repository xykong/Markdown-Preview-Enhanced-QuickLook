jest.mock('mermaid', () => ({
  initialize: jest.fn(),
  render: jest.fn().mockResolvedValue({ svg: '<svg>mocked diagram</svg>' }),
}));

// We import the index file to trigger the side-effect of setting window.renderMarkdown
import '../src/index';
import mermaid from 'mermaid'; // This will be the mocked version

describe('Markdown Renderer', () => {
  beforeEach(() => {
    // Setup the DOM element that index.ts expects
    document.body.innerHTML = '<div id="markdown-preview"></div>';
    jest.clearAllMocks();
  });

  test('should render mermaid diagram using mermaid.render API', async () => {
    const markdown = `
# Title
\`\`\`mermaid
graph TD;
    A-->B;
\`\`\`
    `;

    await window.renderMarkdown(markdown);

    const preview = document.getElementById('markdown-preview');
    expect(preview).toBeTruthy();
    
    const mermaidDiv = preview?.querySelector('.mermaid');
    expect(mermaidDiv).toBeTruthy();
    expect(mermaidDiv?.innerHTML).toContain('<svg>mocked diagram</svg>');
    
    expect(mermaid.render).toHaveBeenCalled();
  });

  test('should display error message when mermaid syntax is invalid', async () => {
    const mermaidMock = require('mermaid');
    mermaidMock.render.mockRejectedValueOnce(new Error('Parse error on line 1'));

    const markdown = `
\`\`\`mermaid
invalid syntax here
\`\`\`
    `;

    await window.renderMarkdown(markdown);

    const preview = document.getElementById('markdown-preview');
    const errorDiv = preview?.querySelector('.mermaid-error');
    expect(errorDiv).toBeTruthy();
    expect(errorDiv?.textContent).toContain('Mermaid Syntax Error');
    expect(errorDiv?.textContent).toContain('Parse error on line 1');
  });

  test('should replace relative image paths with base64 data from imageData', async () => {
    const markdown = '![img](./pic.png)';
    const imageData = {
      './pic.png': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='
    };
    
    await window.renderMarkdown(markdown, { baseUrl: '/Users/me/docs', imageData });

    const preview = document.getElementById('markdown-preview');
    const img = preview?.querySelector('img');
    expect(img).toBeTruthy();
    expect(img?.getAttribute('src')).toBe(imageData['./pic.png']);
  });

  test('should preserve embedded base64 images without modification', async () => {
    const base64Data = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
    const markdown = `![Red Pixel](${base64Data})`;
    
    await window.renderMarkdown(markdown);

    const preview = document.getElementById('markdown-preview');
    const img = preview?.querySelector('img');
    expect(img).toBeTruthy();
    expect(img?.getAttribute('src')).toBe(base64Data);
    expect(img?.getAttribute('alt')).toBe('Red Pixel');
  });

  test('should preserve network image URLs without modification', async () => {
    const networkUrl = 'https://example.com/image.png';
    const markdown = `![Network Image](${networkUrl})`;
    
    await window.renderMarkdown(markdown);

    const preview = document.getElementById('markdown-preview');
    const img = preview?.querySelector('img');
    expect(img).toBeTruthy();
    expect(img?.getAttribute('src')).toBe(networkUrl);
  });

  test('should handle multiple image types in the same document', async () => {
    const base64Data = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
    const networkUrl = 'https://example.com/image.png';
    const localImageData = 'data:image/jpeg;base64,/9j/4AAQSkZJRg==';
    
    const markdown = `
![Base64](${base64Data})
![Network](${networkUrl})
![Local](./local.jpg)
    `;
    
    const imageData = {
      './local.jpg': localImageData
    };
    
    await window.renderMarkdown(markdown, { imageData });

    const preview = document.getElementById('markdown-preview');
    const images = preview?.querySelectorAll('img');
    
    expect(images?.length).toBe(3);
    expect(images?.[0].getAttribute('src')).toBe(base64Data);
    expect(images?.[1].getAttribute('src')).toBe(networkUrl);
    expect(images?.[2].getAttribute('src')).toBe(localImageData);
  });
});
