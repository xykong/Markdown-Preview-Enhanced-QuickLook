import SwiftUI
import AppKit
import WebKit
import os.log
import CoreGraphics

enum ViewMode {
    case preview
    case source
}

struct MarkdownWebView: NSViewRepresentable {
    var content: String
    var fileURL: URL?
    var appearanceMode: AppearanceMode = .light
    var viewMode: ViewMode = .preview
    var baseFontSize: Double = 16
    var enableMermaid: Bool = true
    var enableKatex: Bool = true
    var enableEmoji: Bool = true
    var codeHighlightTheme: String = "default"
    var collapseBlockquotesByDefault: Bool = false
    
    private let localSchemeHandler = LocalSchemeHandler()
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    

    func makeNSView(context: Context) -> WKWebView {
        let coordinator = context.coordinator
        
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.processPool = WKProcessPool()
        webConfiguration.websiteDataStore = .nonPersistent()
        let userContentController = WKUserContentController()
        userContentController.add(coordinator, name: "logger")
        userContentController.add(coordinator, name: "linkClicked")
        
        let debugSource = """
        window.onerror = function(msg, url, line, col, error) {
            window.webkit.messageHandlers.logger.postMessage("JS Error: " + msg + " at " + line + ":" + col);
        };
        var originalLog = console.log;
        console.log = function(msg) {
            window.webkit.messageHandlers.logger.postMessage("JS Log: " + msg);
            if (originalLog) originalLog(msg);
        };
        console.error = function(msg) {
            window.webkit.messageHandlers.logger.postMessage("JS Error Log: " + msg);
        };
        window.addEventListener('load', function() {
             window.webkit.messageHandlers.logger.postMessage("Window Loaded");
        });
        """
        let userScript = WKUserScript(source: debugSource, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        userContentController.addUserScript(userScript)
        
        webConfiguration.userContentController = userContentController

        webConfiguration.setURLSchemeHandler(localSchemeHandler, forURLScheme: "local-md")

        webConfiguration.setValue(true, forKey: "allowUniversalAccessFromFileURLs")


        #if DEBUG
        webConfiguration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        #endif

        let webView = ResizableWKWebView(frame: .zero, configuration: webConfiguration)
        webView.appearance = NSAppearance(named: .aqua)
        webView.navigationDelegate = coordinator
        coordinator.currentWebView = webView
        
        var bundleURL: URL?
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "WebRenderer") {
            bundleURL = url
        } else if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "dist") {
            bundleURL = url
        } else {
            bundleURL = Bundle.main.url(forResource: "index", withExtension: "html")
        }
        
        if let url = bundleURL {
            // Ensure read access to the directory containing index.html and assets
            let dir = url.deletingLastPathComponent()
            os_log("Loading HTML from: %{public}@", log: coordinator.logger, type: .debug, url.path)
            webView.loadFileURL(url, allowingReadAccessTo: dir)
        } else {
             os_log("Failed to find index.html in bundle", log: coordinator.logger, type: .error)
        }
        
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if let appearance = appearanceMode.nsAppearance {
            webView.appearance = appearance
        } else {
            webView.appearance = nil
        }

        context.coordinator.render(webView: webView, content: content, fileURL: fileURL, viewMode: viewMode, appearanceMode: appearanceMode, baseFontSize: baseFontSize, enableMermaid: enableMermaid, enableKatex: enableKatex, enableEmoji: enableEmoji, codeHighlightTheme: codeHighlightTheme, collapseBlockquotesByDefault: collapseBlockquotesByDefault)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let logger = OSLog(subsystem: "com.markdownquicklook.app", category: "MarkdownWebView")
        var isWebViewLoaded = false
        var pendingRender: (() -> Void)?
        weak var currentWebView: WKWebView?
        var currentFileURL: URL?
        var pendingAnchor: String?

        // File monitoring
        private var fileMonitor: DispatchSourceFileSystemObject?
        private var monitoredFileDescriptor: Int32 = -1
        private var lastKnownFileSize: UInt64 = 0
        private var lastKnownFileModificationDate: Date?
        private var lastViewMode: ViewMode = .preview
        private var lastAppearanceMode: AppearanceMode = .light
        private var lastBaseFontSize: Double = 16
        private var lastEnableMermaid: Bool = true
        private var lastEnableKatex: Bool = true
        private var lastEnableEmoji: Bool = true
        private var lastCodeHighlightTheme: String = "default"
        private var lastCollapseBlockquotesByDefault: Bool = false
        private var lastRenderedContent: String = ""
        private var pollingTimer: Timer?
        private let pollingInterval: TimeInterval = 2.0
        private var hasAppliedInitialZoomReset: Bool = false

        override init() {
            super.init()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleToggleSearch),
                name: .toggleSearch,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleExportHTML),
                name: .exportHTML,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleExportPDF),
                name: .exportPDF,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleToggleHelp),
                name: .toggleHelp,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleZoomIn),
                name: .zoomIn,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleZoomOut),
                name: .zoomOut,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleResetZoom),
                name: .resetZoom,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleReloadFile),
                name: .reloadFile,
                object: nil
            )
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
            stopFileMonitoring()
        }
        
        @objc func handleToggleSearch() {
            guard let webView = currentWebView,
                  webView.window?.isKeyWindow == true else { return }
            let js = "window.toggleSearch();"
            webView.evaluateJavaScript(js) { [weak self] _, error in
                if let error = error {
                    os_log("Failed to toggle search: %{public}@", log: self?.logger ?? .default, type: .error, error.localizedDescription)
                }
            }
        }

        @objc func handleToggleHelp() {
            guard let webView = currentWebView,
                  webView.window?.isKeyWindow == true else { return }
            webView.evaluateJavaScript("window.toggleHelp();", completionHandler: nil)
        }

        @objc func handleZoomIn() {
            guard let webView = currentWebView,
                  webView.window?.isKeyWindow == true else { return }
            webView.pageZoom = min(3.0, webView.pageZoom + 0.1)
        }

        @objc func handleZoomOut() {
            guard let webView = currentWebView,
                  webView.window?.isKeyWindow == true else { return }
            webView.pageZoom = max(0.5, webView.pageZoom - 0.1)
        }

        @objc func handleResetZoom() {
            guard let webView = currentWebView,
                  webView.window?.isKeyWindow == true else { return }
            webView.pageZoom = 1.0
            os_log("🔵 pageZoom reset to 1.0", log: logger, type: .debug)
        }

        @objc func handleReloadFile() {
            guard let url = currentFileURL else { return }
            os_log("🔄 Manual reload triggered: %{public}@", log: logger, type: .default, url.lastPathComponent)
            reloadFromDisk(url: url)
        }
        
        @objc func handleExportHTML() {
            guard let webView = currentWebView,
                  let win = webView.window,
                  win.isKeyWindow || win.windowController?.document === NSDocumentController.shared.currentDocument else { return }
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
        
        @objc func handleExportPDF() {
            guard let webView = currentWebView,
                  let win = webView.window,
                  win.isKeyWindow || win.windowController?.document === NSDocumentController.shared.currentDocument else { return }

            let effectiveFontSize = AppearancePreference.shared.baseFontSize * webView.pageZoom

            let panel = NSSavePanel()
            panel.allowedContentTypes = [.pdf]
            panel.nameFieldStringValue = defaultExportFilename(extension: "pdf")
            if let fileURL = currentFileURL {
                panel.directoryURL = fileURL.deletingLastPathComponent()
            }

            let accessory = PDFFontSizeAccessoryView(initialFontSize: effectiveFontSize)
            panel.accessoryView = accessory.view

            panel.begin { [weak self] response in
                guard let self, response == .OK, let saveURL = panel.url else { return }
                self.exportPDF(webView: webView, to: saveURL, fontSize: accessory.fontSize)
            }
        }
        
        private func defaultExportFilename(extension ext: String) -> String {
            guard let fileURL = currentFileURL else { return "export.\(ext)" }
            return fileURL.deletingPathExtension().lastPathComponent + ".\(ext)"
        }
        
        func render(webView: WKWebView, content: String, fileURL: URL?, viewMode: ViewMode, appearanceMode: AppearanceMode, baseFontSize: Double, enableMermaid: Bool, enableKatex: Bool, enableEmoji: Bool, codeHighlightTheme: String, collapseBlockquotesByDefault: Bool) {
            lastViewMode = viewMode
            lastAppearanceMode = appearanceMode
            lastBaseFontSize = baseFontSize
            lastEnableMermaid = enableMermaid
            lastEnableKatex = enableKatex
            lastEnableEmoji = enableEmoji
            lastCodeHighlightTheme = codeHighlightTheme

            if fileURL != currentFileURL {
                currentFileURL = fileURL
                startFileMonitoring()
                webView.pageZoom = 1.0
            }

            if let url = fileURL {
                // Configure the scheme handler with the base directory
                // This allows loading local images via local-md:// scheme
                // which is critical for sandboxed access and proper relative path resolution
                let baseDir = url.deletingLastPathComponent()
                // We need to access the security scoped resource for the directory
                // The handler will manage its own access, but we need to pass the URL
                // Note: In the main app, we might already have access via the document
                // but passing the URL allows the handler to work consistently
                if let handler = webView.configuration.urlSchemeHandler(forURLScheme: "local-md") as? LocalSchemeHandler {
                    handler.baseDirectory = baseDir
                }
            }

            pendingRender = { [weak self] in
                self?.executeRender(webView: webView, content: content, fileURL: fileURL, viewMode: viewMode, appearanceMode: appearanceMode, baseFontSize: baseFontSize, enableMermaid: enableMermaid, enableKatex: enableKatex, enableEmoji: enableEmoji, codeHighlightTheme: codeHighlightTheme, collapseBlockquotesByDefault: collapseBlockquotesByDefault)
            }

            if isWebViewLoaded {
                pendingRender?()
                pendingRender = nil
            } else {
                os_log("Coordinator: WebView not ready, queuing render", log: logger, type: .debug)
            }
        }

        private func executeRender(webView: WKWebView, content: String, fileURL: URL?, viewMode: ViewMode, appearanceMode: AppearanceMode, baseFontSize: Double, enableMermaid: Bool, enableKatex: Bool, enableEmoji: Bool, codeHighlightTheme: String, collapseBlockquotesByDefault: Bool) {
            let onlyThemeChanged = (content == lastRenderedContent) && (viewMode == .preview) && (collapseBlockquotesByDefault == lastCollapseBlockquotesByDefault)
            if onlyThemeChanged {
                let theme: String
                switch appearanceMode {
                case .dark:   theme = "dark"
                case .light:  theme = "light"
                case .system: theme = "system"
                }
                lastAppearanceMode = appearanceMode
                webView.evaluateJavaScript("window.updateTheme('\(theme)');") { [weak self] _, error in
                    if let error = error {
                        os_log("JS updateTheme error: %{public}@", log: self?.logger ?? .default, type: .error, error.localizedDescription)
                    }
                }
                return
            }

            lastRenderedContent = content
            lastCollapseBlockquotesByDefault = collapseBlockquotesByDefault

            guard let contentData = try? JSONSerialization.data(withJSONObject: [content], options: []),
                  let contentJsonArray = String(data: contentData, encoding: .utf8) else {
                os_log("Failed to encode content", log: logger, type: .error)
                return
            }

            let safeContentArg = String(contentJsonArray.dropFirst().dropLast())

            var options: [String: Any] = ["context": "app"]

            if let url = fileURL {
                let baseUrlString = url.deletingLastPathComponent().path
                options["baseUrl"] = baseUrlString
            }

            let appearanceName = webView.effectiveAppearance.name
            var theme = "system"
            if appearanceName == .darkAqua || appearanceName == .vibrantDark || appearanceName == .accessibilityHighContrastDarkAqua || appearanceName == .accessibilityHighContrastVibrantDark {
                theme = "dark"
            } else if appearanceName == .aqua || appearanceName == .vibrantLight || appearanceName == .accessibilityHighContrastAqua || appearanceName == .accessibilityHighContrastVibrantLight {
                theme = "light"
            }
            options["theme"] = theme

            options["fontSize"] = baseFontSize
            options["codeHighlightTheme"] = codeHighlightTheme
            options["enableMermaid"] = enableMermaid
            options["enableKatex"] = enableKatex
            options["enableEmoji"] = enableEmoji
            options["collapseBlockquotes"] = collapseBlockquotesByDefault
            options["uiLanguage"] = AppearancePreference.shared.uiLanguage
            
            guard let optionsData = try? JSONSerialization.data(withJSONObject: options, options: []),
                  let optionsJson = String(data: optionsData, encoding: .utf8) else {
                os_log("Failed to encode options", log: logger, type: .error)
                return
            }
            
            let js: String
            if viewMode == .source {
                var themeStr = "light"
                if let appearance = appearanceMode.nsAppearance?.name {
                    if appearance == .darkAqua {
                        themeStr = "dark"
                    }
                }
                js = "window.renderSource(\(safeContentArg), \"\(themeStr)\");"
            } else {
                js = "window.renderMarkdown(\(safeContentArg), \(optionsJson));"
            }
            
            webView.evaluateJavaScript(js) { [weak self] _, error in
                if let error = error {
                    os_log("JS Error: %{public}@", log: self?.logger ?? .default, type: .error, error.localizedDescription)
                }
                // After render completes, scroll to any pending anchor for this file
                if let fileURL = fileURL,
                   let anchor = PendingAnchorStore.shared.consume(for: fileURL.path),
                   viewMode == .preview {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        self?.scrollToAnchor(anchor, in: webView)
                    }
            }
        }
    }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            os_log("WebView didFinish navigation", log: logger, type: .debug)
        }

        /// Scroll to an anchor in the given WebView using the same five-level fuzzy matching
        /// logic as `findElementByAnchor` in the JS renderer.
        private func scrollToAnchor(_ anchor: String, in webView: WKWebView) {
            guard let anchorData = try? JSONSerialization.data(withJSONObject: [anchor]),
                  let anchorArg = String(data: anchorData, encoding: .utf8) else { return }
            let js = """
                (function() {
                    var id = \(anchorArg)[0];
                    function compress(s){ return s.replace(/-+/g,'-'); }
                    function unify(s){ return s.replace(/[_-]/g,'~'); }
                    function stripH(s){ return s.toLowerCase().replace(/-/g,''); }
                    function stripHU(s){ return s.toLowerCase().replace(/[-_]/g,''); }
                    var all = document.querySelectorAll('[id]');
                    var el = document.getElementById(id);
                    var l2=compress(id), l3=unify(l2), l4=stripH(id), l5=stripHU(id);
                    if(!el) for(var i=0;i<all.length;i++){ var aid=all[i].getAttribute('id'); if(compress(aid)===l2){el=all[i];break;} }
                    if(!el) for(var i=0;i<all.length;i++){ var aid=all[i].getAttribute('id'); if(unify(compress(aid))===l3){el=all[i];break;} }
                    if(!el) for(var i=0;i<all.length;i++){ var aid=all[i].getAttribute('id'); if(stripH(aid)===l4){el=all[i];break;} }
                    if(!el) for(var i=0;i<all.length;i++){ var aid=all[i].getAttribute('id'); if(stripHU(aid)===l5){el=all[i];break;} }
                    if(el){ el.scrollIntoView({behavior:'smooth',block:'start'}); }
                })();
                """
            webView.evaluateJavaScript(js) { [weak self] _, error in
                if let error = error {
                    os_log("🔴 scrollToAnchor failed: %{public}@", log: self?.logger ?? .default, type: .error, error.localizedDescription)
                } else {
                    os_log("🟢 scrollToAnchor: %{public}@", log: self?.logger ?? .default, type: .default, anchor)
                }
            }
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            os_log("WebView didStartProvisionalNavigation", log: logger, type: .debug)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            os_log("WebView didFail navigation: %{public}@", log: logger, type: .error, error.localizedDescription)
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            os_log("WebView didFailProvisionalNavigation: %{public}@", log: logger, type: .error, error.localizedDescription)
        }
        
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            os_log("🔴 WebView WebContent process terminated! Attempting reload...", log: logger, type: .error)
            webView.reload()
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "logger", let body = message.body as? String {
                os_log("JS Log: %{public}@", log: logger, type: .debug, body)
                
                if body == "rendererReady" {
                    os_log("Coordinator: Renderer Handshake Received!", log: logger, type: .default)
                    if !isWebViewLoaded {
                        isWebViewLoaded = true
                        if !hasAppliedInitialZoomReset {
                            hasAppliedInitialZoomReset = true
                            if let webView = message.webView {
                                webView.pageZoom = 1.0
                                os_log("🔵 Initial pageZoom reset to 1.0 at rendererReady", log: logger, type: .debug)
                            }
                        }
                        pendingRender?()
                        pendingRender = nil
                    }
                }
            } else if message.name == "linkClicked", let href = message.body as? String {
                os_log("🔵 Link clicked from JS: %{public}@", log: logger, type: .default, href)
                handleLinkClick(href: href)
            }
        }
        
        func exportHTML(webView: WKWebView, completion: @escaping (String?) -> Void) {
            webView.evaluateJavaScript("window.exportHTML()") { [weak self] result, error in
                if let error = error {
                    os_log("exportHTML JS error: %{public}@", log: self?.logger ?? .default, type: .error, error.localizedDescription)
                    completion(nil)
                } else if var html = result as? String {
                    // Convert local file URLs (e.g. file:///... or local-md://...) to base64 inline data URIs
                    // to ensure images like GIFs are preserved in the offline HTML.
                    do {
                        // Match any src attribute starting with file:// or local-md://
                        let pattern = "src=\"(?:file|local-md)://([^\"]+)\""
                        let regex = try NSRegularExpression(pattern: pattern, options: [])
                        let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count))
                        
                        for match in matches.reversed() {
                            let range = match.range(at: 1)
                            if let swiftRange = Range(range, in: html), let fullRange = Range(match.range, in: html) {
                                let path = String(html[swiftRange])
                                if let decodedPath = path.removingPercentEncoding {
                                    let fileURL = URL(fileURLWithPath: decodedPath)
                                    if let data = try? Data(contentsOf: fileURL) {
                                        let base64 = data.base64EncodedString()
                                        
                                        var mimeType = "image/png"
                                        let ext = fileURL.pathExtension.lowercased()
                                        if ext == "gif" { mimeType = "image/gif" }
                                        else if ext == "jpg" || ext == "jpeg" { mimeType = "image/jpeg" }
                                        else if ext == "svg" { mimeType = "image/svg+xml" }
                                        else if ext == "webp" { mimeType = "image/webp" }
                                        
                                        html.replaceSubrange(fullRange, with: "src=\"data:\(mimeType);base64,\(base64)\"")
                                    }
                                }
                            }
                        }
                    } catch {
                        os_log("exportHTML regex error: %{public}@", log: self?.logger ?? .default, type: .error, error.localizedDescription)
                    }
                    
                    completion(html)
                } else {
                    completion(nil)
                }
            }
        }
        
        func exportPDF(webView: WKWebView, to destinationURL: URL, fontSize: Double? = nil) {
            guard webView.window != nil else {
                os_log("exportPDF: webView has no window", log: logger, type: .error)
                return
            }

            let resolvedSize = fontSize ?? (AppearancePreference.shared.baseFontSize * webView.pageZoom)
            let injectJS = "document.documentElement.style.setProperty('--print-font-size', '\(resolvedSize)px');"
            webView.evaluateJavaScript(injectJS) { [weak self] _, error in
                if let error = error {
                    os_log("exportPDF: failed to inject font-size variable: %{public}@",
                           log: self?.logger ?? .default, type: .error, error.localizedDescription)
                }
                self?.runPrintOperation(webView: webView, to: destinationURL)
            }
        }

        private func runPrintOperation(webView: WKWebView, to destinationURL: URL) {
            // Build a fresh NSPrintInfo — do NOT use NSPrintInfo.shared to avoid the
            // no-printer imageable-area scaling bug.
            let a4PaperSize = NSSize(width: 595.0, height: 842.0)
            let printInfo = NSPrintInfo()
            printInfo.paperSize = a4PaperSize
            printInfo.horizontalPagination = .fit
            printInfo.verticalPagination = .automatic
            printInfo.topMargin    = 0
            printInfo.bottomMargin = 0
            printInfo.leftMargin   = 0
            printInfo.rightMargin  = 0
            printInfo.isHorizontallyCentered = false
            printInfo.isVerticallyCentered   = false
            printInfo.jobDisposition = .save
            printInfo.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = destinationURL

            let printOperation = webView.printOperation(with: printInfo)
            printOperation.showsPrintPanel    = false
            printOperation.showsProgressPanel = false
            printOperation.view?.frame = NSRect(origin: .zero, size: a4PaperSize)

            let log = self.logger
            DispatchQueue.global(qos: .userInitiated).async {
                let success = printOperation.run()
                DispatchQueue.main.async {
                    if success {
                        os_log("Exported PDF to: %{public}@", log: log, type: .default, destinationURL.path)
                    } else {
                        os_log("exportPDF: NSPrintOperation.run() failed", log: log, type: .error)
                    }
                }
            }
        }

        private func startFileMonitoring() {
            stopFileMonitoring()

            guard let url = currentFileURL else { return }

            let fd = open(url.path, O_EVTONLY)
            guard fd >= 0 else {
                os_log("🔴 Cannot open file for monitoring, using polling only: %{public}@", log: logger, type: .error, url.path)
                startPollingTimer()
                return
            }
            monitoredFileDescriptor = fd

            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fd,
                eventMask: [.write, .delete, .rename],
                queue: .main
            )

            source.setEventHandler { [weak self] in
                guard let self else { return }
                let flags = source.data
                if flags.contains(.delete) || flags.contains(.rename) {
                    os_log("🟡 File replaced/renamed — restarting monitor: %{public}@",
                           log: self.logger, type: .debug, url.path)
                    self.stopDispatchMonitor()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                        guard let self else { return }
                        self.startFileMonitoring()
                        self.reloadFromDisk(url: url)
                    }
                    return
                }
                self.handleFileChange()
            }

            source.setCancelHandler { [weak self] in
                guard let self, self.monitoredFileDescriptor >= 0 else { return }
                close(self.monitoredFileDescriptor)
                self.monitoredFileDescriptor = -1
            }

            source.resume()
            fileMonitor = source
            os_log("🟢 File monitoring started: %{public}@", log: logger, type: .default, url.path)

            startPollingTimer()
        }

        private func stopDispatchMonitor() {
            fileMonitor?.cancel()
            fileMonitor = nil
        }

        private func stopFileMonitoring() {
            stopDispatchMonitor()
            stopPollingTimer()
        }

        private func startPollingTimer() {
            stopPollingTimer()
            pollingTimer = Timer.scheduledTimer(
                withTimeInterval: pollingInterval,
                repeats: true
            ) { [weak self] _ in
                self?.pollFileForChanges()
            }
        }

        private func stopPollingTimer() {
            pollingTimer?.invalidate()
            pollingTimer = nil
        }

        private func pollFileForChanges() {
            guard let url = currentFileURL else { return }
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path) else { return }
            let newSize = attrs[.size] as? UInt64 ?? 0
            let newMtime = attrs[.modificationDate] as? Date
            guard FileMonitorHelpers.shouldReload(
                newSize: newSize, newMtime: newMtime,
                knownSize: lastKnownFileSize, knownMtime: lastKnownFileModificationDate
            ) else { return }
            os_log("🟢 [poll] File changed, re-rendering: %{public}@", log: logger, type: .default, url.path)
            reloadFromDisk(url: url)
        }

        private func reloadFromDisk(url: URL) {
            do {
                let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
                let newSize = attrs[.size] as? UInt64 ?? 0
                let newMtime = attrs[.modificationDate] as? Date
                guard FileMonitorHelpers.shouldReload(
                    newSize: newSize, newMtime: newMtime,
                    knownSize: lastKnownFileSize, knownMtime: lastKnownFileModificationDate
                ) else { return }
                let newContent = try String(contentsOf: url, encoding: .utf8)
                lastKnownFileSize = newSize
                lastKnownFileModificationDate = newMtime
                guard let webView = currentWebView else { return }
                executeRender(
                    webView: webView,
                    content: newContent,
                    fileURL: url,
                    viewMode: lastViewMode,
                    appearanceMode: lastAppearanceMode,
                    baseFontSize: lastBaseFontSize,
                    enableMermaid: lastEnableMermaid,
                    enableKatex: lastEnableKatex,
                    enableEmoji: lastEnableEmoji,
                    codeHighlightTheme: lastCodeHighlightTheme,
                    collapseBlockquotesByDefault: lastCollapseBlockquotesByDefault
                )
                os_log("🟢 Reloaded from disk: %{public}@", log: logger, type: .default, url.lastPathComponent)
            } catch {
                os_log("🔴 reloadFromDisk failed: %{public}@", log: logger, type: .error, error.localizedDescription)
            }
        }

        private func handleFileChange() {
            guard let url = currentFileURL else { return }
            reloadFromDisk(url: url)
        }

        private func handleLinkClick(href: String) {
            if href.starts(with: "http://") || href.starts(with: "https://") {
                if let url = URL(string: href) {
                    os_log("🔵 Opening external URL: %{public}@", log: logger, type: .default, href)
                    NSWorkspace.shared.open(url)
                }
                return
            }
            
            guard let fileURL = currentFileURL else {
                os_log("🔴 Cannot resolve relative path: no current file URL", log: logger, type: .error)
                return
            }
            
            let (targetURL, fragment) = LinkNavigation.resolveLocalURLWithFragment(href: href, relativeTo: fileURL)
            
            guard let targetURL = targetURL else { return }
            
            os_log("🔵 Opening local file: %{public}@ anchor: %{public}@ (href: %{public}@)",
                   log: logger, type: .default, targetURL.path, fragment ?? "(none)", href)
            
            if let anchor = fragment, !anchor.isEmpty {
                PendingAnchorStore.shared.set(anchor: anchor, for: targetURL.path)
            }
            
            NSWorkspace.shared.open(targetURL)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard navigationAction.navigationType == .linkActivated,
                  let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            if url.scheme == "http" || url.scheme == "https" {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
            } else if url.isFileURL && url.pathExtension == "md" {
                 NSWorkspace.shared.open(url)
                 decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }

}

class ResizableWKWebView: WKWebView {
    private let webUndoManager = UndoManager()

    override var undoManager: UndoManager? {
        webUndoManager
    }

    private var hasSetInitialSize = false
    private let logger = OSLog(subsystem: "com.markdownquicklook.app", category: "ResizableWKWebView")
    
    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        super.willOpenMenu(menu, with: event)
        
        let findMenuItem = NSMenuItem(
            title: NSLocalizedString("Find...", comment: "Context menu search item"),
            action: #selector(triggerSearch),
            keyEquivalent: "f"
        )
        findMenuItem.keyEquivalentModifierMask = .command
        findMenuItem.target = self
        
        menu.insertItem(findMenuItem, at: 0)
        menu.insertItem(NSMenuItem.separator(), at: 1)
    }
    
    @objc func triggerSearch() {
        NotificationCenter.default.post(name: .toggleSearch, object: nil)
    }
    
    override func scrollWheel(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            // Bug 4 fix: ignore inertia-only phases and momentum scroll events
            let phase = event.phase
            if phase == .mayBegin || phase == .cancelled {
                super.scrollWheel(with: event)
                return
            }
            if event.momentumPhase != [] {
                super.scrollWheel(with: event)
                return
            }
            let delta = event.scrollingDeltaY
            guard abs(delta) > 0.1 else {
                super.scrollWheel(with: event)
                return
            }
            // Bug 6 fix: use pageZoom (text reflow) instead of magnification (visual-only scale)
            let newZoom = min(3.0, max(0.5, self.pageZoom + delta * 0.01))
            self.pageZoom = newZoom
            os_log("🔵 Cmd+scroll pageZoom: %.2f", log: logger, type: .debug, newZoom)
            return
        }
        super.scrollWheel(with: event)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        guard let window = self.window, !hasSetInitialSize else { return }
        
        if let screen = window.screen {
            let screenFrame = screen.visibleFrame
            
            let targetHeight = screenFrame.height * 0.85
            
            let idealWidth = min(screenFrame.width * 0.55, 1200)
            let targetWidth = max(idealWidth, 800)
            
            let finalWidth = min(targetWidth, screenFrame.width)
            let finalHeight = min(targetHeight, screenFrame.height)
            
            let x = screenFrame.origin.x + (screenFrame.width - finalWidth) / 2
            
            let y = screenFrame.origin.y + (screenFrame.height * 0.05)
            
            let currentFrame = window.frame
            
            if currentFrame.width < finalWidth * 0.9 || currentFrame.height < finalHeight * 0.9 {
                let newFrame = NSRect(x: x, y: y, width: finalWidth, height: finalHeight)
                window.setFrame(newFrame, display: true, animate: true)
                window.minSize = NSSize(width: 320, height: 200)
            } else {
                 window.minSize = NSSize(width: 320, height: 200)
            }
        }
        hasSetInitialSize = true
        
        self.allowsMagnification = true
        self.pageZoom = 1.0   // Bug 2 fix: zoom is session-only, always start at 1.0
    }
}


/// Thread-safe store for pending anchor fragments.
// MARK: - PDF Export Accessory View

final class PDFFontSizeAccessoryView {
    let view: NSView
    private let slider: NSSlider
    private let valueLabel: NSTextField

    var fontSize: Double { slider.doubleValue }

    init(initialFontSize: Double) {
        let clamped = max(8, min(72, initialFontSize))

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 380, height: 40))

        let title = NSTextField(labelWithString: NSLocalizedString("Font Size:", comment: ""))
        title.frame = NSRect(x: 16, y: 11, width: 76, height: 18)
        title.alignment = .right

        let sl = NSSlider(frame: NSRect(x: 100, y: 10, width: 200, height: 20))
        sl.minValue = 8
        sl.maxValue = 72
        sl.doubleValue = clamped
        sl.numberOfTickMarks = 0
        sl.allowsTickMarkValuesOnly = false
        sl.isContinuous = true

        let valLabel = NSTextField(labelWithString: "\(Int(clamped)) px")
        valLabel.frame = NSRect(x: 308, y: 11, width: 56, height: 18)
        valLabel.alignment = .left

        container.addSubview(title)
        container.addSubview(sl)
        container.addSubview(valLabel)

        self.slider     = sl
        self.valueLabel = valLabel
        self.view       = container

        sl.target = self
        sl.action = #selector(sliderChanged(_:))
    }

    @objc private func sliderChanged(_ sender: NSSlider) {
        valueLabel.stringValue = "\(Int(sender.doubleValue)) px"
    }
}

// MARK: - Pending Anchor Store

/// When the app opens a cross-file md link with an anchor (e.g. `notes.md#section`),
/// the anchor is stored here keyed by file path. The target window's renderer
/// consumes and clears it after the first successful render.
final class PendingAnchorStore {
    static let shared = PendingAnchorStore()
    private var store: [String: String] = [:]
    private let lock = NSLock()

    private init() {}

    func set(anchor: String, for path: String) {
        lock.lock(); defer { lock.unlock() }
        store[path] = anchor
    }

    /// Returns and removes the stored anchor for the given path, or nil if none.
    func consume(for path: String) -> String? {
        lock.lock(); defer { lock.unlock() }
        guard let anchor = store[path] else { return nil }
        store.removeValue(forKey: path)
        return anchor
    }
}