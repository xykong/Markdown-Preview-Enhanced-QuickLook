# PDF Export Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix three issues: (1) Cmd+Shift+P triggers multiple save dialogs when multiple files are open; (2) exported PDF content is badly cut at page boundaries; (3) PDF pages should use standard A4 with proper margins (Option C) so they look clean in Preview.app continuous scroll.

**Architecture:**
- Bug 1: The multi-dialog issue comes from every `MarkdownWebView.Coordinator` subscribing to `.exportPDF` via `NotificationCenter`. The `isKeyWindow` guard is unreliable when SwiftUI updates the view hierarchy. Fix by posting a targeted notification carrying the key-window identifier, or by checking `NSApp.keyWindow` reliably at handler time.
- Bug 2 + Issue 3: Replace the current "render one tall PDF page then manually slice with CoreGraphics" approach with WKWebView's native multi-page PDF creation driven by proper `@page` CSS (standard A4, 15mm margins). `WKPDFConfiguration` can specify exact paper rect; the browser engine handles page breaks automatically, respecting `page-break-inside: avoid` rules already in `print.css`.

**Tech Stack:** Swift/AppKit, WKWebView (`createPDF`), `WKPDFConfiguration`, CSS `@media print` / `@page`.

---

## File Map

| File | Change |
|------|--------|
| `Sources/Markdown/MarkdownApp.swift` | Fix export command to only act on key window |
| `Sources/Markdown/MarkdownWebView.swift` | Replace `exportPDF` + `slicePDFToA4Pages` with native WKWebView multi-page PDF |
| `Sources/Markdown/CLIExporter.swift` | Replace snapshot-stitch approach with `createPDF` + `@page` CSS |
| `web-renderer/src/styles/print.css` | Add standard A4 margins to `@page` rule |

---

## Task 1: Fix Multi-Window Export — Only Key Window Exports

**Problem:** When multiple `.md` files are open, pressing `Cmd+Shift+P` causes every `Coordinator` to receive `.exportPDF`. Although `handleExportPDF` guards with `webView.window?.isKeyWindow == true`, in some SwiftUI lifecycle states `window` may be nil or `isKeyWindow` may transiently return true for multiple windows. The fix: make `handleExportPDF` additionally guard that the webView's window is the `NSApp.mainWindow` (the frontmost document window), which is always unambiguous.

**Files:**
- Modify: `Sources/Markdown/MarkdownWebView.swift` — `handleExportPDF` and `handleExportHTML`

- [ ] **Step 1: Strengthen the key-window guard in `handleExportPDF`**

Replace lines 230-244 in `Sources/Markdown/MarkdownWebView.swift`:

```swift
@objc func handleExportPDF() {
    guard let webView = currentWebView,
          let win = webView.window,
          win.isKeyWindow || win == NSApp.mainWindow else { return }
    
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.pdf]
    panel.nameFieldStringValue = defaultExportFilename(extension: "pdf")
    if let fileURL = currentFileURL {
        panel.directoryURL = fileURL.deletingLastPathComponent()
    }
    panel.begin { [weak self] response in
        guard let self, response == .OK, let saveURL = panel.url else { return }
        self.exportPDF(webView: webView, to: saveURL)
    }
}
```

- [ ] **Step 2: Apply the same guard to `handleExportHTML`**

Replace line 205-228 in `Sources/Markdown/MarkdownWebView.swift`:

```swift
@objc func handleExportHTML() {
    guard let webView = currentWebView,
          let win = webView.window,
          win.isKeyWindow || win == NSApp.mainWindow else { return }
    exportHTML(webView: webView) { [weak self] htmlString in
        DispatchQueue.main.async {
            guard let htmlString = htmlString else {
                os_log("exportHTML: received nil HTML", log: self?.logger ?? .default, type: .error)
                return
            }
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.html]
            panel.nameFieldStringValue = self?.defaultExportFilename(extension: "html") ?? "export.html"
            panel.begin { response in
                guard response == .OK, let url = panel.url else { return }
                do {
                    try htmlString.write(to: url, atomically: true, encoding: .utf8)
                    os_log("Exported HTML to: %{public}@", log: self?.logger ?? .default, type: .default, url.path)
                } catch {
                    os_log("Failed to write HTML: %{public}@", log: self?.logger ?? .default, type: .error, error.localizedDescription)
                }
            }
        }
    }
}
```

- [ ] **Step 3: Build and manually test multi-window scenario**

```bash
make app
```

Open 2+ `.md` files → press `Cmd+Shift+P` → confirm only ONE save panel appears (for the front window).

- [ ] **Step 4: Commit**

```bash
git add Sources/Markdown/MarkdownWebView.swift
git commit -m "fix(app): only export from key/main window when multiple files open"
```

---

## Task 2: Fix Print CSS — Add Standard A4 Margins to `@page`

**Problem:** The current `@page` rule has `margin: 0`, which means the browser renders content flush to the edge of each page. This causes content elements (paragraphs, code blocks) to be cut right at the page edge with no padding. Standard printing uses `~15mm` margins so content breathes and never gets cut at boundaries. WKWebView's `createPDF` respects these CSS `@page` margins for natural pagination.

**Files:**
- Modify: `web-renderer/src/styles/print.css`

- [ ] **Step 1: Update `@page` margins in `print.css`**

Replace lines 1-5 in `web-renderer/src/styles/print.css`:

```css
@media print {
  @page {
    margin: 15mm 15mm 15mm 15mm;
    size: A4 portrait;
  }
```

- [ ] **Step 2: Add `page-break-inside: avoid` to paragraphs and list items**

After the existing `h1, h2, h3, h4, h5, h6` rule (after line 16), add:

```css
  p, li, blockquote {
    page-break-inside: avoid;
    orphans: 3;
    widows: 3;
  }
```

- [ ] **Step 3: Build renderer**

```bash
cd web-renderer && npm run build && cd ..
```

Expected: exits 0, `web-renderer/dist/index.html` updated.

- [ ] **Step 4: Commit**

```bash
git add web-renderer/src/styles/print.css web-renderer/dist/index.html
git commit -m "style(renderer): add standard A4 margins to print CSS for clean page breaks"
```

---

## Task 3: Replace Slice-Based PDF Export with Native WKWebView Pagination

**Problem:** `exportPDF` in `MarkdownWebView.Coordinator` resizes the webview to a tall frame, calls `createPDF`, then manually slices the single tall page into A4 strips using CoreGraphics transforms. This approach has subtle coordinate bugs that cause content to be cut mid-element. The correct approach: set `WKPDFConfiguration.rect` to an A4 paper size and let WKWebView use CSS `@page` rules to paginate naturally — the browser engine correctly avoids breaking inside headings, code blocks, images, etc.

**Files:**
- Modify: `Sources/Markdown/MarkdownWebView.swift` — `exportPDF` method and `slicePDFToA4Pages`

- [ ] **Step 1: Replace `exportPDF` with native pagination approach**

Replace the entire `exportPDF` method (lines 478–511) and `slicePDFToA4Pages` (lines 513–564) with:

```swift
func exportPDF(webView: WKWebView, to destinationURL: URL) {
    // Inject print CSS trigger so @media print styles apply
    let triggerPrintCSS = """
        (function() {
            var existing = document.getElementById('__pdf_print_mode__');
            if (!existing) {
                var s = document.createElement('style');
                s.id = '__pdf_print_mode__';
                s.textContent = 'body { -webkit-print-color-adjust: exact !important; }';
                document.head.appendChild(s);
            }
        })();
        """
    webView.evaluateJavaScript(triggerPrintCSS) { [weak self] _, error in
        guard let self else { return }
        if let error = error {
            os_log("exportPDF: inject CSS error: %{public}@", log: self.logger, type: .error, error.localizedDescription)
        }

        // A4 paper in points (1pt = 1/72 inch; A4 = 210×297mm)
        let a4Rect = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
        let config = WKPDFConfiguration()
        config.rect = a4Rect

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            webView.createPDF(configuration: config) { [weak self] result in
                guard let self else { return }
                switch result {
                case .failure(let error):
                    os_log("exportPDF createPDF error: %{public}@",
                           log: self.logger, type: .error, error.localizedDescription)
                case .success(let pdfData):
                    do {
                        try pdfData.write(to: destinationURL, options: .atomic)
                        os_log("Exported PDF to: %{public}@",
                               log: self.logger, type: .default, destinationURL.path)
                    } catch {
                        os_log("exportPDF write error: %{public}@",
                               log: self.logger, type: .error, error.localizedDescription)
                    }
                }
                // Clean up injected style
                webView.evaluateJavaScript(
                    "document.getElementById('__pdf_print_mode__')?.remove();",
                    completionHandler: nil
                )
            }
        }
    }
}
```

Also remove the now-unused constants at lines 473–476:

```swift
// DELETE these lines:
// private static let a4WidthPt:        CGFloat = 595.28
// private static let a4HeightPt:       CGFloat = 841.89
// private static let sideMarginPt:     CGFloat = 20.0
// private static var a4ContentWidthPt: CGFloat { a4WidthPt - 2 * sideMarginPt }
```

- [ ] **Step 2: Build the app**

```bash
make app
```

Expected: builds without errors or warnings related to unused variables.

- [ ] **Step 3: Manual export test**

1. Open a `.md` file with code blocks, headings, images, and tables
2. Press `Cmd+Shift+P` → save as `test_export.pdf`
3. Open `test_export.pdf` in Preview.app
4. Verify: content is NOT cut mid-sentence or mid-code-block at page boundaries
5. Switch to Continuous Scroll view in Preview → verify pages look clean with standard margins

- [ ] **Step 4: Commit**

```bash
git add Sources/Markdown/MarkdownWebView.swift
git commit -m "fix(app): replace manual PDF slicing with native WKWebView pagination"
```

---

## Task 4: Fix CLIExporter to Use `createPDF` Instead of Snapshot Stitching

**Problem:** `CLIExporter` uses `takeSnapshot` + CoreGraphics stitching — the same category of problem as Task 3. It produces a single-page image-based PDF which:
- Is not searchable (text is rasterized)
- Has the same page-cut issues
- Is slow and memory-intensive for large documents

Replace with `createPDF` + `WKPDFConfiguration` using the same A4 paper size.

**Files:**
- Modify: `Sources/Markdown/CLIExporter.swift`

- [ ] **Step 1: Simplify `renderAndExport` — remove snapshot injection, add `createPDF` call**

Replace the entire `renderAndExport` method (lines 117–192) with:

```swift
private func renderAndExport() {
    guard let content = try? String(contentsOf: inputURL, encoding: .utf8) else {
        fputs("Error: cannot read \(inputURL.path)\n", stderr)
        exit(1)
    }

    guard let contentData = try? JSONSerialization.data(withJSONObject: [content]),
          let jsonArray = String(data: contentData, encoding: .utf8) else {
        fputs("Error: cannot encode content\n", stderr)
        exit(1)
    }
    let safeArg = String(jsonArray.dropFirst().dropLast())

    let options: [String: Any] = [
        "context":            "app",
        "baseUrl":            inputURL.deletingLastPathComponent().path,
        "theme":              "light",
        "fontSize":           16,
        "codeHighlightTheme": "default",
        "enableMermaid":      true,
        "enableKatex":        true,
        "enableEmoji":        true,
        "uiLanguage":         "en",
    ]
    guard let optData = try? JSONSerialization.data(withJSONObject: options),
          let optJson = String(data: optData, encoding: .utf8) else {
        fputs("Error: cannot encode options\n", stderr)
        exit(1)
    }

    let js = "window.renderMarkdown(\(safeArg), \(optJson)); undefined;"
    webView.evaluateJavaScript(js) { [weak self] _, error in
        if let error = error {
            fputs("Error: renderMarkdown JS failed: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
        guard let self else { return }
        // Wait for async rendering (Mermaid, KaTeX, etc.) to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.capturePDF()
        }
    }
}
```

- [ ] **Step 2: Replace `capturePDF`, `captureTiledSnapshots`, and `stitchToPDF` with a single `capturePDF` using `createPDF`**

Delete the methods `capturePDF` (lines 196–219), `captureTiledSnapshots` (lines 222–277), and `stitchToPDF` (lines 279–312).

Replace them all with this single method:

```swift
private func capturePDF() {
    fputs("Capturing PDF via WKWebView createPDF…\n", stderr)

    // A4 paper in points
    let a4Rect = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
    let config = WKPDFConfiguration()
    config.rect = a4Rect

    webView.createPDF(configuration: config) { [weak self] result in
        guard let self else { return }
        switch result {
        case .failure(let error):
            fputs("Error: createPDF failed: \(error.localizedDescription)\n", stderr)
            exit(1)
        case .success(let pdfData):
            do {
                try pdfData.write(to: self.outputURL, options: .atomic)
                print("✅ PDF exported to: \(self.outputURL.path)")
                exit(0)
            } catch {
                fputs("Error: write failed: \(error.localizedDescription)\n", stderr)
                exit(1)
            }
        }
    }
}
```

- [ ] **Step 3: Remove now-unused constants and properties from `CLIExporter`**

Remove these now-unused lines from the `CLIExporter` class definition:

```swift
// DELETE:
// private static let a4WidthPt:         CGFloat = 595.28
// private static let a4HeightPt:        CGFloat = 841.89
// private static let sideMarginPt:      CGFloat = 20.0
// private static var a4ContentWidthPt:  CGFloat { a4WidthPt - 2 * sideMarginPt }
// private static let tileHeightPt: CGFloat = 6000
// private static let renderWidthPt: CGFloat = 900
```

Also simplify `setupWebView` — the offscreen window height no longer needs to be `100_000`. Change the webView frame height to a normal value and remove unused `renderWidthPt` reference:

```swift
private func setupWebView() {
    let config = WKWebViewConfiguration()
    let ucc    = WKUserContentController()
    ucc.add(self, name: "logger")

    let debugScript = WKUserScript(source: """
        window.onerror = function(msg, url, line) {
            window.webkit.messageHandlers.logger.postMessage("JS Error: " + msg + " at " + line);
        };
        """, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    ucc.addUserScript(debugScript)

    config.userContentController = ucc

    let handler = LocalSchemeHandler()
    handler.baseDirectory = inputURL.deletingLastPathComponent()
    config.setURLSchemeHandler(handler, forURLScheme: "local-md")
    config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")

    let renderWidth: CGFloat = 595.28  // A4 width in points
    let renderHeight: CGFloat = 1200

    webView = WKWebView(frame: CGRect(x: 0, y: 0, width: renderWidth, height: renderHeight),
                        configuration: config)
    webView.appearance = NSAppearance(named: .aqua)
    webView.navigationDelegate = self

    offscreenWindow = NSWindow(
        contentRect: NSRect(x: -10000, y: -10000, width: renderWidth, height: renderHeight),
        styleMask:   [.borderless],
        backing:     .buffered,
        defer:       false
    )
    offscreenWindow.isOpaque = false
    offscreenWindow.contentView = webView
    offscreenWindow.orderBack(nil)
}
```

- [ ] **Step 4: Build the app**

```bash
make app
```

Expected: builds without errors.

- [ ] **Step 5: Manual CLI export test**

```bash
# Build app first if not already done
make app

# Find the built binary (adjust path for your Xcode build dir)
APP_PATH=$(find build -name "FluxMarkdown.app" -type d | head -1)
echo "App: $APP_PATH"

# Export a real test file
"$APP_PATH/Contents/MacOS/FluxMarkdown" --export-pdf README.md /tmp/cli_test_export.pdf
```

Expected output to stderr:
```
Loading renderer from: .../index.html
CLIExporter: webView didFinish navigation
Capturing PDF via WKWebView createPDF…
```
Expected output to stdout:
```
✅ PDF exported to: /tmp/cli_test_export.pdf
```

Then verify the PDF:
```bash
open /tmp/cli_test_export.pdf
```

Verify: multi-page PDF, text is selectable (not rasterized), content not cut mid-element.

- [ ] **Step 6: Commit**

```bash
git add Sources/Markdown/CLIExporter.swift
git commit -m "fix(cli): replace snapshot-stitch PDF with native WKWebView createPDF"
```

---

## Task 5: End-to-End Real Export Test + Build Verification

**Goal:** Confirm all three fixes work together before the branch is merged.

**Files:** No file changes — testing only.

- [ ] **Step 1: Build renderer + app**

```bash
make build_renderer && make app
```

Expected: both exit 0.

- [ ] **Step 2: Multi-window test (Bug 1)**

1. Open `README.md` → new window appears
2. Open any other `.md` file (drag to dock icon) → second window appears
3. Click on the first window to make it active
4. Press `Cmd+Shift+P`
5. **Expected:** exactly ONE save panel appears, for the first window only
6. Dismiss → click second window → press `Cmd+Shift+P`
7. **Expected:** exactly ONE save panel, for the second window

- [ ] **Step 3: PDF quality test (Bug 2)**

1. Open a `.md` file with: long code blocks (> 30 lines), a large table, and headings
2. Export as PDF with `Cmd+Shift+P`
3. Open in Preview.app
4. Switch to View → Continuous Scroll
5. **Expected:** content is not cut mid-line at page boundaries; headings appear at top of their section's page or have whitespace before next heading starts a new page; standard margins visible on all sides

- [ ] **Step 4: CLI export test (Bug 2 in CLI mode)**

```bash
APP_PATH=$(find build -name "FluxMarkdown.app" -type d | head -1)
"$APP_PATH/Contents/MacOS/FluxMarkdown" --export-pdf README.md /tmp/readme_test.pdf
open /tmp/readme_test.pdf
```

**Expected:** multi-page PDF, text selectable, clean page breaks.

- [ ] **Step 5: Verify no regressions on HTML export**

1. Open a `.md` file
2. Press `Cmd+Shift+E`
3. Save as `test_export.html`
4. Open in Safari
5. **Expected:** renders correctly, images load

- [ ] **Step 6: Final commit (if any minor fixes were needed during testing)**

```bash
git add -A
git commit -m "test: verify PDF export fixes across multi-window and CLI scenarios"
```

---

## Self-Review Checklist

- [x] **Bug 1 coverage** → Task 1 strengthens the `isKeyWindow || isMainWindow` guard
- [x] **Bug 2 coverage** → Tasks 2 + 3 replace manual slicing with CSS-native pagination
- [x] **Issue 3 (Option C) coverage** → Task 2 adds `15mm` A4 margins to `@page`; `createPDF` respects them
- [x] **CLI exporter coverage** → Task 4 brings CLIExporter in line with the same `createPDF` approach
- [x] **No placeholders** → all steps have exact code or commands
- [x] **Type consistency** → `exportPDF(webView:to:)` signature unchanged; `capturePDF()` is internal to CLIExporter
- [x] **Real test required** → Task 5 is a dedicated manual test pass
- [x] **Build verified at each task** → every task ends with `make app` or `make build_renderer`
