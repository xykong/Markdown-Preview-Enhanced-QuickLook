// Helper to send logs to Swift
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

import 'github-markdown-css/github-markdown.css';
import 'highlight.js/styles/github.css';
import 'katex/dist/katex.min.css';

import MarkdownIt from 'markdown-it';
import mermaid from 'mermaid';
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

// Configure Mermaid
try {
    mermaid.initialize({
        startOnLoad: false,
        theme: 'default'
    });
} catch (e) {
    logToSwift("JS: Mermaid init failed: " + e);
}

// Configure MarkdownIt
let md: MarkdownIt;
try {
    md = new MarkdownIt({
        html: true,
        breaks: true,
        linkify: true,
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

    // Use plugins
    md.use(mk);
    md.use(emoji);
    md.use(footnote);
    md.use(taskLists);
    md.use(mark);
    md.use(sub);
    md.use(sup);

    const defaultImageRender = md.renderer.rules.image || function(tokens, idx, options, env, self) {
        return self.renderToken(tokens, idx, options);
    };

    md.renderer.rules.image = function (tokens, idx, options, env, self) {
        const token = tokens[idx];
        const srcIndex = token.attrIndex('src');
        if (srcIndex >= 0) {
            const src = token.attrs[srcIndex][1];
            const isAbsolute = /^(http:\/\/|https:\/\/|file:\/\/|\/)/.test(src);
            
            if (!isAbsolute && env && env.baseUrl) {
                 const base = env.baseUrl.endsWith('/') ? env.baseUrl : env.baseUrl + '/';
                 token.attrs[srcIndex][1] = "file://" + base + src;
            }
        }
        return defaultImageRender(tokens, idx, options, env, self);
    };
    
} catch (e) {
    logToSwift("JS: MarkdownIt init failed: " + e);
}

// Define global interface for window
declare global {
    interface Window {
        renderMarkdown: (text: string, options?: { baseUrl?: string }) => void;
    }
}

// Render function called by Swift
window.renderMarkdown = function (text: string, options: { baseUrl?: string } = {}) {
    const outputDiv = document.getElementById('markdown-preview');
    if (!outputDiv) {
        logToSwift("JS Error: markdown-preview element not found");
        return;
    }

    try {
        // 1. Render Markdown to HTML
        let html = md.render(text, { baseUrl: options.baseUrl });

        // 2. Render Mermaid diagrams
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

        // 3. Trigger Mermaid rendering
        mermaid.run({
            querySelector: '.mermaid'
        });
        
    } catch (e) {
        logToSwift("JS Error during render: " + e);
    }
};
