# Development Guide

## Principles
(See `.clinerules` for strict rules applied by AI Agent)

1. **TDD (Test-Driven Development)**: 
   - Always write verifiable test cases before implementation.
   - For `web-renderer`, use `npm test` (Jest).
   - For Swift code, define clear acceptance criteria.

2. **Ecosystem & Dependencies**: 
   - Prioritize established npm packages (`markdown-it`, `mermaid`, etc.) over custom wheels.
   - Strictly manage versions in `package.json`.

3. **Documentation (Doc-First)**: 
   - All design decisions and changes must be recorded in `docs/`.

## Web Renderer
The web renderer is a TypeScript project that bundles the rendering logic.

### Setup
```bash
cd web-renderer
npm install
```

### Testing
```bash
cd web-renderer
npm test
```

### Building
```bash
cd web-renderer
npm run build
```
This generates `dist/index.html` (Single file with inlined assets).

## Swift Extension
The Xcode project is generated using **XcodeGen** (Configuration as Code).

### Prerequisites
- XcodeGen (`brew install xcodegen`)

### Generating the Project
Run:
```bash
make generate
```
This command will:
1. Build the web renderer (npm install & build)
2. Generate `MarkdownQuickLook.xcodeproj` from `project.yml`

### Building the App
```bash
make app
```
Or open `MarkdownQuickLook.xcodeproj` in Xcode.

**Note**: Do not commit `MarkdownQuickLook.xcodeproj` to git. Commit `project.yml` instead.
