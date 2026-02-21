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
import './styles/source-view.css';

import MarkdownIt from 'markdown-it';
import hljs from 'highlight.js/lib/core';

// Tree-shaking: only register languages that cover ~95% of real-world usage.
// Unregistered languages fall back to an unhighlighted code block gracefully.
import langJavascript from 'highlight.js/lib/languages/javascript';
import langTypescript from 'highlight.js/lib/languages/typescript';
import langPython from 'highlight.js/lib/languages/python';
import langBash from 'highlight.js/lib/languages/bash';
import langShell from 'highlight.js/lib/languages/shell';
import langSql from 'highlight.js/lib/languages/sql';
import langJson from 'highlight.js/lib/languages/json';
import langYaml from 'highlight.js/lib/languages/yaml';
import langMarkdown from 'highlight.js/lib/languages/markdown';
import langCss from 'highlight.js/lib/languages/css';
import langXml from 'highlight.js/lib/languages/xml';
import langGo from 'highlight.js/lib/languages/go';
import langRust from 'highlight.js/lib/languages/rust';
import langJava from 'highlight.js/lib/languages/java';
import langC from 'highlight.js/lib/languages/c';
import langCpp from 'highlight.js/lib/languages/cpp';
import langSwift from 'highlight.js/lib/languages/swift';
import langKotlin from 'highlight.js/lib/languages/kotlin';
import langRuby from 'highlight.js/lib/languages/ruby';
import langPhp from 'highlight.js/lib/languages/php';
import langCsharp from 'highlight.js/lib/languages/csharp';
import langDiff from 'highlight.js/lib/languages/diff';
import langDockerfile from 'highlight.js/lib/languages/dockerfile';
import langNginx from 'highlight.js/lib/languages/nginx';

hljs.registerLanguage('javascript', langJavascript);
hljs.registerLanguage('typescript', langTypescript);
hljs.registerLanguage('python', langPython);
hljs.registerLanguage('bash', langBash);
hljs.registerLanguage('shell', langShell);
hljs.registerLanguage('sql', langSql);
hljs.registerLanguage('json', langJson);
hljs.registerLanguage('yaml', langYaml);
hljs.registerLanguage('markdown', langMarkdown);
hljs.registerLanguage('css', langCss);
hljs.registerLanguage('xml', langXml);
hljs.registerLanguage('html', langXml); // html uses xml grammar
hljs.registerLanguage('go', langGo);
hljs.registerLanguage('rust', langRust);
hljs.registerLanguage('java', langJava);
hljs.registerLanguage('c', langC);
hljs.registerLanguage('cpp', langCpp);
hljs.registerLanguage('swift', langSwift);
hljs.registerLanguage('kotlin', langKotlin);
hljs.registerLanguage('ruby', langRuby);
hljs.registerLanguage('php', langPhp);
hljs.registerLanguage('csharp', langCsharp);
hljs.registerLanguage('diff', langDiff);
hljs.registerLanguage('dockerfile', langDockerfile);
hljs.registerLanguage('nginx', langNginx);

// Import MarkdownIt plugins

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
        if (url.startsWith('data:') || url.startsWith('local-md://')) {
            return true;
        }
        return originalValidateLink(url);
    };

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
            const isNetworkUrl = /^(http:\/\/|https:\/\/)/.test(originalSrc);
            const isEmbeddedBase64Image = originalSrc.startsWith('data:');
            const isLocalFile = !isNetworkUrl && !isEmbeddedBase64Image && !originalSrc.startsWith('local-md://');

            if (isLocalFile && env?.baseUrl) {
                const basePath = env.baseUrl.replace(/\/$/, '');
                const absolutePath = originalSrc.startsWith('/')
                    ? originalSrc
                    : `${basePath}/${originalSrc}`;
                token.attrs[srcIndex][1] = `local-md://${absolutePath}`;
                logToSwift(`[Image] Resolved to scheme URL: "${token.attrs[srcIndex][1]}"`);
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
let mermaidInstance: typeof import('mermaid')['default'] | null = null;
let mermaidCurrentTheme: string | null = null;
let katexPlugin: ((md: MarkdownIt) => void) | null = null;

declare global {
    interface Window {
        renderMarkdown: (text: string, options?: { baseUrl?: string, theme?: string }) => Promise<void>;
        renderSource: (text: string, theme: string) => void;
        setZoomLevel: (level: number) => void;
        showSearch: () => void;
        hideSearch: () => void;
        toggleSearch: () => void;
    }
}

window.renderMarkdown = async function (text: string, options: { baseUrl?: string, theme?: string } = {}) {
    const outputDiv = document.getElementById('markdown-preview');
    const loadingDiv = document.getElementById('loading-status');
    
    if (loadingDiv) {
        loadingDiv.style.display = 'none';
    }
    
    if (!outputDiv) {
        logToSwift("JS Error: markdown-preview element not found");
        return;
    }

    if (options.baseUrl) {
        let existingBase = document.querySelector('base');
        if (!existingBase) {
            existingBase = document.createElement('base');
            document.head.insertBefore(existingBase, document.head.firstChild);
        }
        const baseHref = options.baseUrl.endsWith('/') ? options.baseUrl : options.baseUrl + '/';
        existingBase.setAttribute('href', 'file://' + baseHref);
        logToSwift(`[Base URL] Set to: file://${baseHref}`);
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

        if (/\$[\s\S]+?\$|\$\$[\s\S]+?\$\$/.test(text)) {
            if (!katexPlugin) {
                const m = await import('@iktakahiro/markdown-it-katex');
                katexPlugin = (m as any).default ?? m;
            }
            md.use(katexPlugin as (md: MarkdownIt) => void);
        }

        const outline = extractOutline(md, text);
        if (toc) {
            toc.render(outline);
        }

        let html = md.render(text, { baseUrl: options.baseUrl });

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
                if (!mermaidInstance) {
                    const mermaidModule = await import('mermaid');
                    mermaidInstance = mermaidModule.default;
                }
                const mermaid = mermaidInstance;
                if (mermaidCurrentTheme !== mermaidTheme) {
                    mermaid.initialize({
                        startOnLoad: false,
                        theme: mermaidTheme as any,
                        suppressErrorRendering: true
                    });
                    mermaidCurrentTheme = mermaidTheme;
                }
                
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

        setTimeout(() => {
            if (!mermaidInstance) {
                import('mermaid').then(m => { mermaidInstance = m.default; });
            }
        }, 0);

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

window.renderSource = function(text: string, theme: string) {
    const outputDiv = document.getElementById('markdown-preview');
    const loadingDiv = document.getElementById('loading-status');
    
    if (loadingDiv) {
        loadingDiv.style.display = 'none';
    }
    
    if (!outputDiv) {
        logToSwift("JS Error: markdown-preview element not found");
        return;
    }

    try {
        const highlighted = hljs.highlight(text, { language: 'markdown', ignoreIllegals: true });
        
        outputDiv.innerHTML = `
            <div class="source-view ${theme === 'dark' ? 'source-view-dark' : 'source-view-light'}">
                <pre class="source-pre"><code class="hljs language-markdown">${highlighted.value}</code></pre>
            </div>
        `;
        
        logToSwift(`[Source View] Rendered ${text.length} characters with theme: ${theme}`);
    } catch (e) {
        logToSwift("JS Error during source rendering: " + e);
        if (outputDiv) {
            outputDiv.innerHTML = `<div style="color: red; padding: 20px; border: 1px solid red; border-radius: 5px;">
                <h3>Source Rendering Error</h3>
                <pre>${e}</pre>
            </div>`;
        }
    }
};

function compressMultipleHyphens(text: string): string {
    return text.replace(/-+/g, '-');
}

function unifyUnderscoreAndHyphen(text: string): string {
    return text.replace(/[_-]/g, '~');
}

function findElementByAnchor(anchorId: string): HTMLElement | null {
    const allElementsWithId = document.querySelectorAll('[id]');
    
    const exactMatch = document.getElementById(anchorId);
    if (exactMatch) return exactMatch;
    
    const level2NormalizedTarget = compressMultipleHyphens(anchorId);
    for (const element of allElementsWithId) {
        const elementId = element.getAttribute('id');
        if (elementId && compressMultipleHyphens(elementId) === level2NormalizedTarget) {
            return element as HTMLElement;
        }
    }
    
    const level3NormalizedTarget = unifyUnderscoreAndHyphen(compressMultipleHyphens(anchorId));
    for (const element of allElementsWithId) {
        const elementId = element.getAttribute('id');
        if (elementId && unifyUnderscoreAndHyphen(compressMultipleHyphens(elementId)) === level3NormalizedTarget) {
            return element as HTMLElement;
        }
    }
    
    return null;
}

function handleAnchorClick(e: Event) {
    const target = e.target as HTMLElement;
    const anchor = target.closest('a');
    if (!anchor) return;
    
    const href = anchor.getAttribute('href');
    if (!href) return;
    
    logToSwift(`[Click] href="${href}"`);
    
    if (href.startsWith('#')) {
        e.preventDefault();
        e.stopPropagation();
        const targetId = decodeURIComponent(href.substring(1));
        const targetElement = findElementByAnchor(targetId);
        if (targetElement) {
            targetElement.scrollIntoView({ behavior: 'smooth', block: 'start' });
            logToSwift(`[Click] Scrolled to anchor: #${targetId}`);
        } else {
            logToSwift(`[Click] Anchor not found: #${targetId}`);
        }
        return;
    }
    
    e.preventDefault();
    e.stopPropagation();
    
    try {
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.linkClicked) {
            // @ts-ignore
            window.webkit.messageHandlers.linkClicked.postMessage(href);
            logToSwift(`[Click] Sent link to Swift: ${href}`);
        } else {
            logToSwift(`[Click] ERROR: linkClicked handler not found`);
        }
    } catch (error) {
        logToSwift(`[Click] ERROR: ${error}`);
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
