declare module 'vega-lite' {
    export function compile(spec: any, options?: any): { spec: any };
}

declare module '@iktakahiro/markdown-it-katex' {
    import MarkdownIt from 'markdown-it';
    const plugin: (md: MarkdownIt) => void;
    export default plugin;
}

interface WebkitMessageHandlers {
    logger: { postMessage: (msg: string) => void };
    linkClicked: { postMessage: (href: string) => void };
}

interface Window {
    webkit?: {
        messageHandlers: WebkitMessageHandlers;
    };
}
