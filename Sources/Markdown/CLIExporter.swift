import AppKit
import WebKit
import os.log

final class CLIAppDelegate: NSObject, NSApplicationDelegate {
    private var exporter: CLIExporter?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let args = CommandLine.arguments
        guard let idx = args.firstIndex(of: "--export-pdf"), idx + 1 < args.count else {
            fputs("Usage: FluxMarkdown --export-pdf <input.md> [output.pdf]\n", stderr)
            exit(1)
        }

        let inputPath  = args[idx + 1]
        let outputPath = args.count > idx + 2 ? args[idx + 2] : nil
        let inputURL   = URL(fileURLWithPath: inputPath).standardizedFileURL

        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            fputs("Error: file not found: \(inputURL.path)\n", stderr)
            exit(1)
        }

        let outputURL: URL
        if let op = outputPath {
            outputURL = URL(fileURLWithPath: op).standardizedFileURL
        } else {
            outputURL = inputURL.deletingPathExtension().appendingPathExtension("pdf")
        }

        exporter = CLIExporter(input: inputURL, output: outputURL)
        exporter?.run()
    }
}

final class CLIExporter: NSObject {

    private static let a4WidthPt:         CGFloat = 595.28
    private static let a4HeightPt:        CGFloat = 841.89
    private static let sideMarginPt:      CGFloat = 20.0
    private static var a4ContentWidthPt:  CGFloat { a4WidthPt - 2 * sideMarginPt }

    private let inputURL:  URL
    private let outputURL: URL
    private let logger = OSLog(subsystem: "com.markdownquicklook.app", category: "CLIExporter")

    private var webView: WKWebView!
    private var offscreenWindow: NSWindow!
    private var rendererReady = false

    init(input: URL, output: URL) {
        self.inputURL  = input
        self.outputURL = output
    }

    func run() {
        setupWebView()
        loadRenderer()
    }

    private static let renderWidthPt: CGFloat = 900

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

        let renderWidth: CGFloat  = Self.renderWidthPt
        let renderHeight: CGFloat = 100_000
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: renderWidth, height: renderHeight),
                            configuration: config)
        webView.appearance = NSAppearance(named: .aqua)
        webView.navigationDelegate = self

        offscreenWindow = NSWindow(
            contentRect: NSRect(x: -10000, y: -10000, width: renderWidth, height: 1000),
            styleMask:   [.borderless],
            backing:     .buffered,
            defer:       false
        )
        offscreenWindow.isOpaque = false
        offscreenWindow.contentView = webView
        offscreenWindow.orderBack(nil)
    }

    private func loadRenderer() {
        var bundleURL: URL?
        if let u = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "WebRenderer") {
            bundleURL = u
        } else if let u = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "dist") {
            bundleURL = u
        } else {
            bundleURL = Bundle.main.url(forResource: "index", withExtension: "html")
        }
        guard let url = bundleURL else {
            fputs("Error: index.html not found in bundle\n", stderr)
            exit(1)
        }
        fputs("Loading renderer from: \(url.path)\n", stderr)
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }

    private func renderAndExport() {
        guard let content = try? String(contentsOf: inputURL, encoding: .utf8) else {
            fputs("Error: cannot read \(inputURL.path)\n", stderr)
            exit(1)
        }

        guard let contentData = try? JSONSerialization.data(withJSONObject: [content]),
              let jsonArray   = String(data: contentData, encoding: .utf8) else {
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
              let optJson  = String(data: optData, encoding: .utf8) else {
            fputs("Error: cannot encode options\n", stderr)
            exit(1)
        }

        let injectPrintCSS = """
            (function() {
                var s = document.createElement('style');
                s.id = '__cli_pdf_styles__';
                s.textContent = [
                    'pre, code,',
                    '.markdown-body pre, .markdown-body code,',
                    '.markdown-body pre > code,',
                    '.highlight pre, .highlight code {',
                    '  white-space: pre-wrap !important;',
                    '  word-wrap: break-word !important;',
                    '  overflow-wrap: break-word !important;',
                    '  word-break: break-word !important;',
                    '}',
                    'pre { overflow: visible !important; max-width: 100% !important; }',
                    'table { display: table; max-width: 100% !important; width: 100%; }',
                    'td, th { word-break: break-word; overflow-wrap: break-word; }',
                    'td code, th code {',
                    '  font-size: 0.75em !important;',
                    '  white-space: normal !important;',
                    '  overflow-wrap: anywhere !important;',
                    '  word-break: break-word !important;',
                    '}',
                    '#toc-container, #search-container, #outline-panel,',
                    '.toc-toggle-btn, .search-toggle-btn, .md-sidebar-toc { display: none !important; }',
                    'body { color: #000 !important; background: #fff !important; }',
                    '.markdown-body, .markdown-body.dark { background: #fff !important; color: #000 !important; }'
                ].join('\\n');
                document.head.appendChild(s);
            })();
            """

        let js = "window.renderMarkdown(\(safeArg), \(optJson)); undefined;"
        webView.evaluateJavaScript(js) { [weak self] _, error in
            if let error = error {
                fputs("Error: renderMarkdown JS failed: \(error.localizedDescription)\n", stderr)
                exit(1)
            }
            guard let self else { return }
            self.webView.evaluateJavaScript(injectPrintCSS) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.capturePDF()
                }
            }
        }
    }

    private static let tileHeightPt: CGFloat = 6000

    private func capturePDF() {
        let scrollHeightJS = """
            Math.max(
                document.documentElement.scrollHeight,
                document.body ? document.body.scrollHeight : 0,
                document.documentElement.offsetHeight
            )
            """
        webView.evaluateJavaScript(scrollHeightJS) { [weak self] result, _ in
            guard let self else { return }
            let rawH: CGFloat
            if let n = result as? NSNumber { rawH = CGFloat(n.doubleValue) }
            else { rawH = 50_000 }
            let contentH = rawH + 80
            fputs("Content height: \(Int(rawH))pt → capturing \(Int(contentH))pt\n", stderr)

            let w = Self.renderWidthPt
            self.webView.frame = CGRect(x: 0, y: 0, width: w, height: contentH)
            self.offscreenWindow.setContentSize(NSSize(width: w, height: contentH))

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.captureTiledSnapshots(totalHeight: contentH, width: w)
            }
        }
    }

    private func captureTiledSnapshots(totalHeight: CGFloat, width: CGFloat) {
        let tileH  = Self.tileHeightPt
        let nTiles = Int(ceil(totalHeight / tileH))
        fputs("Tiling: \(nTiles) tiles of \(Int(tileH))pt for \(Int(totalHeight))pt\n", stderr)

        var images:    [NSImage] = []
        var tileRects: [CGRect]  = []

        for i in 0 ..< nTiles {
            let yTop    = CGFloat(i) * tileH
            let yBottom = min(yTop + tileH, totalHeight)
            tileRects.append(CGRect(x: 0, y: yTop, width: width, height: yBottom - yTop))
        }

        func captureNext(_ idx: Int) {
            guard idx < tileRects.count else {
                fputs("All \(images.count) tiles captured, stitching PDF…\n", stderr)
                guard let pdfData = self.stitchToPDF(images: images, tileRects: tileRects,
                                                     totalHeight: totalHeight, width: width) else {
                    fputs("Error: PDF stitching failed\n", stderr)
                    exit(1)
                }
                do {
                    try pdfData.write(to: self.outputURL, options: .atomic)
                    print("✅ PDF exported to: \(self.outputURL.path)")
                    exit(0)
                } catch {
                    fputs("Error: write failed: \(error.localizedDescription)\n", stderr)
                    exit(1)
                }
            }

            let rect = tileRects[idx]
            let config = WKSnapshotConfiguration()
            config.rect = rect
            if #available(macOS 10.15, *) {
                config.snapshotWidth = NSNumber(value: Double(rect.width))
            }

            self.webView.takeSnapshot(with: config) { image, error in
                if let error = error {
                    fputs("Snapshot error tile \(idx): \(error.localizedDescription)\n", stderr)
                    let blank = NSImage(size: NSSize(width: rect.width, height: rect.height))
                    images.append(blank)
                } else if let image = image {
                    images.append(image)
                    fputs("  Tile \(idx+1)/\(tileRects.count): \(Int(rect.height))pt\n", stderr)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    captureNext(idx + 1)
                }
            }
        }

        captureNext(0)
    }

    private func stitchToPDF(images: [NSImage], tileRects: [CGRect],
                             totalHeight: CGFloat, width: CGFloat) -> Data? {
        let scale = Self.a4ContentWidthPt / width
        let outW  = Self.a4WidthPt
        let outH  = totalHeight * scale

        let outputData = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: outW, height: outH)
        guard let consumer = CGDataConsumer(data: outputData as CFMutableData),
              let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return nil }

        ctx.beginPDFPage(nil)

        for (i, image) in images.enumerated() {
            guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { continue }
            let tileRect = tileRects[i]

            // WebKit y=0 is top; CoreGraphics y=0 is bottom. Convert tile's top-left
            // position into CG coords: distance from CG bottom = outH minus the tile's bottom edge.
            let destY = outH - (tileRect.origin.y + tileRect.height) * scale
            let destRect = CGRect(
                x:      Self.sideMarginPt,
                y:      destY,
                width:  tileRect.width  * scale,
                height: tileRect.height * scale
            )
            ctx.draw(cgImage, in: destRect)
        }

        ctx.endPDFPage()
        ctx.closePDF()

        return outputData as Data
    }
}

extension CLIExporter: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        fputs("CLIExporter: webView didFinish navigation\n", stderr)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        fputs("CLIExporter: webView didFail: \(error.localizedDescription)\n", stderr)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation nav: WKNavigation!, withError error: Error) {
        fputs("CLIExporter: didFailProvisional: \(error.localizedDescription)\n", stderr)
    }
}

extension CLIExporter: WKScriptMessageHandler {
    func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "logger", let body = message.body as? String else { return }
        os_log("CLIExporter JS: %{public}@", log: logger, type: .debug, body)

        if body == "rendererReady" && !rendererReady {
            rendererReady = true
            renderAndExport()
        }
    }
}
