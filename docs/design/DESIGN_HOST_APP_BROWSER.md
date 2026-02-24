# Design: Host App Markdown Browser

**Date**: 2026-01-05
**Status**: Draft

## 1. Objective
Enable the Host App (`Markdown.app`) to fully browse, read, and render Markdown files, including:
- Opening local `.md` files via Finder or "Open" dialog.
- Rendering local images referenced in Markdown (e.g., `![Alt](img/foo.png)`).
- Handling links (external to browser, internal `.md` to app).
- Basic interactions (scrolling, copy).

## 2. Technical Architecture

### 2.1 Component Structure
The Host App will use SwiftUI's document-based app lifecycle (`DocumentGroup`) to manage windows and files.

```mermaid
graph TD
    A[App (SwiftUI)] --> B[DocumentGroup]
    B --> C[MarkdownDocument]
    C --> D[MarkdownEditorView]
    D --> E[MarkdownWebView]
    E --> F[WKWebView (AppKit)]
    F --> G[WebRenderer (JS/TS)]
```

### 2.2 Core Components

#### `MarkdownDocument` (Swift)
- Conforms to `FileDocument`.
- Responsibilities: Reading/Writing text content. (Initially Read-Only focus, but ready for Write).
- **Crucial**: Maintains the `URL` of the file to determine the Base Path for images.

#### `MarkdownWebView` (Swift / NSViewRepresentable)
- Wraps `WKWebView`.
- Loads the `index.html` from the **App Bundle** (to ensure `bundle.js` and CSS load correctly).
- Communicates with JS via `evaluateJavaScript` and `WKScriptMessageHandler`.
- **Config**:
  - `allowFileAccessFromFileURLs = true`: To allow loading local images from `file://` when the main page is also `file://` (bundle).
  - `developerExtrasEnabled = true` (Debug only).

#### `WebRenderer` (TypeScript)
- Updates required in `web-renderer/src/index.ts`.
- **New Function**: `renderMarkdown(content: string, options: { baseUrl: string })`.
- **Logic**:
  - When rendering, if an image path is relative, prepend `baseUrl`.
  - Use `markdown-it` custom image rule or post-processing.

## 3. Key Solutions

### 3.1 The "Local Image" Problem
**Challenge**: The WebView loads `index.html` from the App Bundle (`/Applications/.../Resources/dist/index.html`). A markdown file is in `~/Documents/Doc.md`. A relative image `![img](pic.png)` resolves to `/Applications/.../Resources/dist/pic.png` (Fail).

**Solution**:
1. **Swift Side**:
   - Obtain the absolute path of the Markdown file (e.g., `/Users/me/Docs/`).
   - Pass this path to JS as `baseUrl` (must end with `/`).
   - **Sandbox Note**: The App has access to the file via `DocumentGroup` (Security Scoped URL). The `WKWebView` generally inherits the App's read capabilities for file URLs if `readAccessURL` is handled or if "User Selected File" entitlement is active and we use absolute paths.

2. **JS Side**:
   - Customize `markdown-it` image renderer.
   - If `src` is not absolute (doesn't start with `http`, `https`, `file:`), prepend `baseUrl`.
   - Result: `<img src="file:///Users/me/Docs/pic.png">`.

### 3.2 Link Navigation
**Challenge**: Users click links.
- `[Google](https://google.com)` -> Should open in Safari.
- `[Next Chapter](part2.md)` -> Should open in a new App Window.

**Solution**:
- Implement `WKNavigationDelegate.webView(_:decidePolicyFor:decisionHandler:)`.
- **Logic**:
  - `navigationType == .linkActivated`
  - If URL is `http/https`: `NSWorkspace.shared.open(url)`, `decision = .cancel`.
  - If URL is `file` and ends with `.md`: `NSWorkspace.shared.open(url)` (Triggers App to open new document), `decision = .cancel`.
  - Else: `decision = .allow`.

## 4. Implementation Steps

### Phase 1: Renderer Update (TypeScript)
1.  Modify `web-renderer/src/index.ts`.
    -   Update `renderMarkdown` signature to accept `config` object.
    -   Implement image path rewriting logic.
2.  Rebuild renderer (`npm run build`).

### Phase 2: Host App UI (Swift)
1.  Create `MarkdownDocument` struct.
2.  Update `MarkdownApp` to use `DocumentGroup`.
3.  Create `MarkdownWebView` (wrapping the existing logic from `PreviewViewController` but adapted for SwiftUI).

### Phase 3: Wiring & Verification
1.  Test opening a file with images.
2.  Verify sandbox access (may need `startAccessingSecurityScopedResource` for the folder if strict).
    -   *Note*: Usually `DocumentGroup` handles the file access, but images *next to* the file might technically be outside the "file's" scope unless we ask for Folder access or macOS assumes related resources.
    -   *Fallback*: If images fail to load due to sandbox, we might need to ask user for permission to the *Folder*, or use a "Project" based approach. For now, we assume macOS's standard `user-selected.read-only` might be lenient enough for adjacent files, or we might hit a wall.
    -   *Correction*: `user-selected.read-only` grants access ONLY to the selected file. Adjacent images will **FAIL** to load in Sandboxed app unless the user selects the Folder or we use a specific entitlement/hack.
    -   **Refined Solution for Images**: 
        -   Start simple: Try to read.
        -   If blocked: We might need to implement a mechanism where the user grants access to the "Parent Folder".
        -   **Alternative**: Disable Sandbox (Not recommended/allowed for App Store).
        -   **Realistic MVP**: Just handle the file for now. If images fail, we log it. *Addendum*: For a robust "Markdown Editor/Viewer", opening the *Folder* is the standard pattern (VSCode style), or relying on the OS believing the image is related.

## 5. Future Extensions
- **Auto-Refresh**: Watch file for changes.
- **Scroll Sync**: Bi-directional scrolling.
- **Dark Mode Sync**: Real-time theme switching.
