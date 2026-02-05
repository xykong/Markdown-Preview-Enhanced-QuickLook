function escapeHtml(text: string): string {
    const map: Record<string, string> = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, (char) => map[char]);
}

function logToSwift(message: string) {
    try {
        // @ts-ignore
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.logger) {
            // @ts-ignore
            window.webkit.messageHandlers.logger.postMessage(message);
        } else {
            console.log("Swift logger not found: " + message);
        }
    } catch (e) {
        // Fallback
        console.log("Failed to log to Swift:", e);
    }
}

// Global error handler for debugging
window.onerror = function(message, source, lineno, colno, error) {
    const errorMsg = `JS Error: ${message} at ${source}:${lineno}`;
    logToSwift(errorMsg);
};

logToSwift("JS: index.ts loaded, starting execution...");

import 'github-markdown-css/github-markdown.css';
import './styles/highlight-adaptive.css';
import 'katex/dist/katex.min.css';
import './styles/table-of-contents.css';
import './styles/image-fallback.css';
import './styles/search.css';

import MarkdownIt from 'markdown-it';
import hljs from 'highlight.js';

// Import MarkdownIt plugins
// @ts-ignore
import mk from '@iktakahiro/markdown-it-katex';
// @ts-ignore
import emoji from 'markdown-it-emoji';
// @ts-ignore
import footnote from 'markdown-it-footnote';
// @ts-ignore
import taskLists from 'markdown-it-task-lists';
// @ts-ignore
import mark from 'markdown-it-mark';
// @ts-ignore
import sub from 'markdown-it-sub';
// @ts-ignore
import sup from 'markdown-it-sup';
// @ts-ignore
import anchor from 'markdown-it-anchor';

import { extractOutline } from './outline';
import { TableOfContents } from './table-of-contents';
import { SearchEngine } from './search';
import { SearchUI } from './search-ui';

// Configure MarkdownIt
let md: MarkdownIt;
try {
    md = new MarkdownIt({
        html: true,
        breaks: true,
        linkify: false,
        typographer: true,
        highlight: function (str: string, lang: string): string {
            if (lang && hljs.getLanguage(lang)) {
                try {
                    return '<pre class="hljs"><code>' +
                        hljs.highlight(str, { language: lang, ignoreIllegals: true }).value +
                        '</code></pre>';
                } catch (__) { }
            }
            const codeClass = lang ? 'language-' + lang : '';
            return '<pre class="hljs"><code class="' + codeClass + '">' + md.utils.escapeHtml(str) + '</code></pre>';
        }
    });
    
    const originalValidateLink = md.validateLink.bind(md);
    md.validateLink = function(url: string): boolean {
        if (url.startsWith('data:')) {
            return true;
        }
        return originalValidateLink(url);
    };

    // Use plugins
    md.use(mk);
    md.use(emoji);
    md.use(footnote);
    md.use(taskLists);
    md.use(mark);
    md.use(sub);
    md.use(sup);
    md.use(anchor, {
        permalink: false,
        slugify: (s: string) => s.toLowerCase().replace(/[^\w\u4e00-\u9fa5]+/g, '-').replace(/^-+|-+$/g, '')
    });

    const defaultImageRender = md.renderer.rules.image || function(tokens, idx, options, env, self) {
        return self.renderToken(tokens, idx, options);
    };

    md.renderer.rules.image = function (tokens, idx, options, env, self) {
        const token = tokens[idx];
        const srcIndex = token.attrIndex('src');
        if (srcIndex >= 0) {
            const originalSrc = token.attrs[srcIndex][1];
            logToSwift(`[Image] Original src: "${originalSrc}"`);
            
            const isNetworkUrl = /^(http:\/\/|https:\/\/)/.test(originalSrc);
            const isEmbeddedBase64Image = originalSrc.startsWith('data:');
            const isLocalFile = !isNetworkUrl && !isEmbeddedBase64Image;
            
            logToSwift(`[Image] Type: ${isEmbeddedBase64Image ? 'embedded-base64' : isNetworkUrl ? 'network' : 'local-file'}, has imageData: ${!!env?.imageData}`);
            
            if (isEmbeddedBase64Image) {
                logToSwift(`[Image] Keeping embedded base64: "${originalSrc.substring(0, 50)}..."`);
            } else if (isLocalFile && env?.imageData) {
                const base64DataUrl = env.imageData[originalSrc];
                if (base64DataUrl) {
                    token.attrs[srcIndex][1] = base64DataUrl;
                    logToSwift(`[Image] Replaced with base64 data for: "${originalSrc}"`);
                } else {
                    logToSwift(`[Image] No base64 data found for: "${originalSrc}"`);
                    if (env.imageData) {
                        logToSwift(`[Image] Available keys: ${Object.keys(env.imageData).join(', ')}`);
                    }
                }
            } else if (isNetworkUrl) {
                logToSwift(`[Image] Keeping network URL: "${originalSrc}"`);
            }
        }
        return defaultImageRender(tokens, idx, options, env, self);
    };
    
} catch (e) {
    logToSwift("JS: MarkdownIt init failed: " + e);
}

let toc: TableOfContents | null = null;
let searchEngine: SearchEngine | null = null;
let searchUI: SearchUI | null = null;

declare global {
    interface Window {
        renderMarkdown: (text: string, options?: { baseUrl?: string, theme?: string, imageData?: Record<string, string> }) => Promise<void>;
        setZoomLevel: (level: number) => void;
        showSearch: () => void;
        hideSearch: () => void;
        toggleSearch: () => void;
    }
}

window.renderMarkdown = async function (text: string, options: { baseUrl?: string, theme?: string, imageData?: Record<string, string> } = {}) {
    const outputDiv = document.getElementById('markdown-preview');
    const loadingDiv = document.getElementById('loading-status');
    
    if (loadingDiv) {
        loadingDiv.style.display = 'none';
    }
    
    if (!outputDiv) {
        logToSwift("JS Error: markdown-preview element not found");
        return;
    }

    let currentTheme = options.theme || 'default';
    if (currentTheme === 'system') {
        currentTheme = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'default';
    } else if (currentTheme === 'light') {
        currentTheme = 'default';
    }
    
    const mermaidTheme = currentTheme === 'dark' ? 'dark' : 'default';

    try {
        if (!toc) {
            try {
                toc = new TableOfContents('toc-container');
            } catch (e) {
                logToSwift("JS Warning: TOC initialization failed: " + e);
            }
        }

        if (!searchEngine || !searchUI) {
            try {
                searchEngine = new SearchEngine();
                searchUI = new SearchUI('search-container', searchEngine);
            } catch (e) {
                logToSwift("JS Warning: Search initialization failed: " + e);
            }
        }

        const outline = extractOutline(md, text);
        if (toc) {
            toc.render(outline);
        }

        let html = md.render(text, { baseUrl: options.baseUrl, imageData: options.imageData });
        
        logToSwift(`[Render] Generated HTML length: ${html.length}`);
        if (html.includes('data:image')) {
            const snippet = html.match(/<img[^>]*data:image[^>]*>/g);
            if (snippet) {
                logToSwift(`[Render] Sample img tags with data:image: ${snippet.length} found`);
                snippet.forEach((s, i) => logToSwift(`[Render]   ${i + 1}. ${s.substring(0, 120)}...`));
            }
        }
        if (html.includes('data:image')) {
            logToSwift('[Render] HTML contains Base64 images - converting to blob URLs');
            const imgMatches = html.match(/<img[^>]+src="(data:image\/[^"]+)"/g);
            if (imgMatches) {
                logToSwift(`[Render] Found ${imgMatches.length} Base64 img tags`);
                imgMatches.forEach((match, index) => {
                    logToSwift(`[Render] Processing match ${index + 1}: ${match.substring(0, 100)}...`);
                    const dataUrlMatch = match.match(/src="(data:image\/([^;]+);base64,([^"]+))"/);
                    if (dataUrlMatch) {
                        const [, dataUrl, mimeType, base64Data] = dataUrlMatch;
                        logToSwift(`[Render] Extracted - MIME: ${mimeType}, Base64 length: ${base64Data.length}`);
                        try {
                            logToSwift(`[Render] Decoding Base64 (${base64Data.length} chars)...`);
                            const binaryString = atob(base64Data);
                            logToSwift(`[Render] Decoded to binary (${binaryString.length} bytes)`);
                            const bytes = new Uint8Array(binaryString.length);
                            for (let i = 0; i < binaryString.length; i++) {
                                bytes[i] = binaryString.charCodeAt(i);
                            }
                            logToSwift(`[Render] Creating blob with MIME: image/${mimeType}`);
                            const blob = new Blob([bytes], { type: `image/${mimeType}` });
                            logToSwift(`[Render] Blob created: ${blob.size} bytes, type: ${blob.type}`);
                            const blobUrl = URL.createObjectURL(blob);
                            logToSwift(`[Render] Blob URL created: ${blobUrl}`);
                            const beforeReplace = html.includes(dataUrl);
                            html = html.replace(dataUrl, blobUrl);
                            const afterReplace = html.includes(blobUrl);
                            logToSwift(`[Render] Replacement: before=${beforeReplace}, after=${afterReplace}`);
                            logToSwift(`[Render] ✅ Converted to blob: ${blobUrl}`);
                        } catch (e) {
                            logToSwift(`[Render] ❌ Conversion failed: ${e}`);
                        }
                    } else {
                        logToSwift(`[Render] ❌ Regex didn't match for: ${match.substring(0, 100)}...`);
                    }
                });
            } else {
                logToSwift('[Render] ❌ No img tags found with regex');
            }
        } else {
            logToSwift('[Render] No data:image URLs in HTML');
        }

        const tempDiv = document.createElement('div');
        tempDiv.innerHTML = html;
        
        const mermaidBlocks = tempDiv.querySelectorAll('pre code.language-mermaid');
        mermaidBlocks.forEach((block, index) => {
            const pre = block.parentElement;
            if (pre) {
                const div = document.createElement('div');
                div.classList.add('mermaid');
                div.textContent = block.textContent || '';
                div.id = `mermaid-${index}`;
                pre.replaceWith(div);
            }
        });

        outputDiv.innerHTML = tempDiv.innerHTML;

        // 3. Trigger Mermaid rendering if needed
        if (mermaidBlocks.length > 0) {
            try {
                const mermaidModule = await import('mermaid');
                const mermaid = mermaidModule.default;
                mermaid.initialize({
                    startOnLoad: false,
                    theme: mermaidTheme as any,
                    suppressErrorRendering: true
                });
                
                // Render each mermaid block individually to capture per-block errors
                const mermaidDivs = outputDiv.querySelectorAll('.mermaid');
                for (const div of mermaidDivs) {
                    const code = div.textContent || '';
                    const id = div.id || `mermaid-${Date.now()}`;
                    
                    try {
                        const { svg } = await mermaid.render(id + '-svg', code);
                        div.innerHTML = svg;
                    } catch (renderErr: any) {
                        const errorMessage = renderErr?.message || String(renderErr);
                        logToSwift(`JS Mermaid render error for ${id}: ${errorMessage}`);
                        
                        div.innerHTML = `
                            <div class="mermaid-error" style="
                                background-color: #fff5f5;
                                border: 1px solid #feb2b2;
                                border-radius: 6px;
                                padding: 16px;
                                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
                            ">
                                <div style="
                                    color: #c53030;
                                    font-weight: 600;
                                    margin-bottom: 8px;
                                    display: flex;
                                    align-items: center;
                                    gap: 6px;
                                ">
                                    <span style="font-size: 16px;">⚠️</span>
                                    <span>Mermaid Syntax Error</span>
                                </div>
                                <pre style="
                                    background-color: #fed7d7;
                                    color: #742a2a;
                                    padding: 12px;
                                    border-radius: 4px;
                                    overflow-x: auto;
                                    font-size: 13px;
                                    line-height: 1.5;
                                    margin: 0 0 12px 0;
                                    white-space: pre-wrap;
                                    word-break: break-word;
                                ">${escapeHtml(errorMessage)}</pre>
                                <details style="margin-top: 8px;">
                                    <summary style="
                                        cursor: pointer;
                                        color: #718096;
                                        font-size: 12px;
                                    ">Show source code</summary>
                                    <pre style="
                                        background-color: #f7fafc;
                                        color: #2d3748;
                                        padding: 12px;
                                        border-radius: 4px;
                                        margin-top: 8px;
                                        overflow-x: auto;
                                        font-size: 12px;
                                        line-height: 1.4;
                                        white-space: pre-wrap;
                                        word-break: break-word;
                                    ">${escapeHtml(code)}</pre>
                                </details>
                            </div>
                        `;
                        if (currentTheme === 'dark') {
                            const errorDiv = div.querySelector('.mermaid-error') as HTMLElement;
                            if (errorDiv) {
                                errorDiv.style.backgroundColor = '#2d2020';
                                errorDiv.style.borderColor = '#742a2a';
                                const pre = errorDiv.querySelector('pre') as HTMLElement;
                                if (pre) {
                                    pre.style.backgroundColor = '#3d2020';
                                    pre.style.color = '#feb2b2';
                                }
                                const details = errorDiv.querySelector('details pre') as HTMLElement;
                                if (details) {
                                    details.style.backgroundColor = '#1a202c';
                                    details.style.color = '#e2e8f0';
                                }
                            }
                        }
                    }
                }
            } catch (err) {
                 logToSwift("JS Error loading/running mermaid: " + err);
            }
        }
        
    } catch (e) {
        logToSwift("JS Error during render: " + e);
        if (outputDiv) {
            outputDiv.innerHTML = `<div style="color: red; padding: 20px; border: 1px solid red; border-radius: 5px;">
                <h3>Rendering Error</h3>
                <pre>${e}</pre>
            </div>`;
        }
    }
};

function handleAnchorClick(e: Event) {
    const target = e.target as HTMLElement;
    const anchor = target.closest('a');
    if (!anchor) return;
    
    const href = anchor.getAttribute('href');
    if (!href) return;
    
    if (href.startsWith('#')) {
        e.preventDefault();
        e.stopPropagation();
        const targetId = decodeURIComponent(href.substring(1));
        const targetElement = document.getElementById(targetId);
        if (targetElement) {
            targetElement.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    } else if (href.startsWith('http://') || href.startsWith('https://')) {
        e.preventDefault();
        e.stopPropagation();
        logToSwift("openExternalURL:" + href);
    }
}

document.addEventListener('click', handleAnchorClick, { capture: true, passive: false });

let currentZoomLevel = 1.0;

window.setZoomLevel = function(level: number) {
    currentZoomLevel = level;
    const outputDiv = document.getElementById('markdown-preview');
    if (outputDiv) {
        outputDiv.style.transform = `scale(${level})`;
        outputDiv.style.transformOrigin = 'top left';
        outputDiv.style.width = `${100 / level}%`;
        logToSwift(`Zoom level set to ${level}`);
    }
};

function applyZoomLevel(level: number) {
    currentZoomLevel = Math.max(0.5, Math.min(3.0, level));
    window.setZoomLevel(currentZoomLevel);
}

document.addEventListener('keydown', (e: KeyboardEvent) => {
    if (e.metaKey || e.ctrlKey) {
        if (e.key === 'f') {
            e.preventDefault();
            window.toggleSearch();
            logToSwift('Search toggled via Cmd+F');
        } else if (e.key === '+' || e.key === '=') {
            e.preventDefault();
            applyZoomLevel(currentZoomLevel + 0.1);
            logToSwift(`Zoom in: ${currentZoomLevel}`);
        } else if (e.key === '-' || e.key === '_') {
            e.preventDefault();
            applyZoomLevel(currentZoomLevel - 0.1);
            logToSwift(`Zoom out: ${currentZoomLevel}`);
        } else if (e.key === '0') {
            e.preventDefault();
            applyZoomLevel(1.0);
            logToSwift(`Zoom reset: ${currentZoomLevel}`);
        }
    }
});

window.showSearch = function() {
    if (searchUI) {
        searchUI.show();
    } else {
        logToSwift("JS Warning: Search UI not initialized");
    }
};

window.hideSearch = function() {
    if (searchUI) {
        searchUI.hide();
    }
};

window.toggleSearch = function() {
    if (searchUI) {
        searchUI.toggle();
    }
};

logToSwift("rendererReady");
