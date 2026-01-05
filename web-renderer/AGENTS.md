# AGENTS.md - web-renderer

## OVERVIEW
TypeScript/Webpack-based Markdown renderer for macOS QuickLook.
Transforms Markdown into HTML with math, diagrams, and syntax highlighting.

## STRUCTURE
- `src/`: TypeScript source code and HTML template.
- `test/`: Jest test suites for rendering logic.
- `dist/`: Compiled assets (bundle.js, main.css, index.html).
- `node_modules/`: Project dependencies.

## WHERE TO LOOK
- `src/index.ts`: Main entry. Exposes `window.renderMarkdown`.
- `src/template.html`: Base HTML structure for WebView.
- `webpack.config.js`: Bundle config; handles CSS/font inlining.
- `package.json`: Dependency list and build scripts.

## CONVENTIONS
- **Renderer**: `markdown-it` with KaTeX, Mermaid, and Highlight.js.
- **Testing**: Jest tests required for all rendering logic.
- **Inter-op**: JS-to-Swift via `window.webkit.messageHandlers.logger`.
- **Styling**: GitHub-style CSS; fonts/assets inlined via Webpack.
- **Build**: Output to `dist/` is directly referenced by Xcode project.

## COMMANDS
- `npm install`: Install dev/prod dependencies.
- `npm run build`: Production build (Webpack).
- `npm run watch`: Development build with file watching.
- `npm test`: Execute Jest test suites.
