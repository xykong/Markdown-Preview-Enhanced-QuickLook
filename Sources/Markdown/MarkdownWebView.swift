import SwiftUI
import AppKit
import WebKit
import os.log

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
    
    private static let sharedProcessPool = WKProcessPool()
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let coordinator = context.coordinator
        
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.processPool = MarkdownWebView.sharedProcessPool
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

        context.coordinator.render(webView: webView, content: content, fileURL: fileURL, viewMode: viewMode, appearanceMode: appearanceMode, baseFontSize: baseFontSize, enableMermaid: enableMermaid, enableKatex: enableKatex, enableEmoji: enableEmoji, codeHighlightTheme: codeHighlightTheme)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let logger = OSLog(subsystem: "com.markdownquicklook.app", category: "MarkdownWebView")
        var isWebViewLoaded = false
        var pendingRender: (() -> Void)?
        weak var currentWebView: WKWebView?
        var currentFileURL: URL?
        
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
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        @objc func handleToggleSearch() {
            guard let webView = currentWebView else { return }
            let js = "window.toggleSearch();"
            webView.evaluateJavaScript(js) { [weak self] _, error in
                if let error = error {
                    os_log("Failed to toggle search: %{public}@", log: self?.logger ?? .default, type: .error, error.localizedDescription)
                }
            }
        }
        
        @objc func handleExportHTML() {
            guard let webView = currentWebView else { return }
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
            guard let webView = currentWebView else { return }
            exportPDF(webView: webView) { [weak self] pdfData in
                DispatchQueue.main.async {
                    guard let pdfData = pdfData else {
                        os_log("exportPDF: received nil data", log: self?.logger ?? .default, type: .error)
                        return
                    }
                    let panel = NSSavePanel()
                    panel.allowedContentTypes = [.pdf]
                    panel.nameFieldStringValue = self?.defaultExportFilename(extension: "pdf") ?? "export.pdf"
                    panel.begin { response in
                        guard response == .OK, let url = panel.url else { return }
                        do {
                            try pdfData.write(to: url, options: .atomic)
                            os_log("Exported PDF to: %{public}@", log: self?.logger ?? .default, type: .default, url.path)
                        } catch {
                            os_log("Failed to write PDF: %{public}@", log: self?.logger ?? .default, type: .error, error.localizedDescription)
                        }
                    }
                }
            }
        }
        
        private func defaultExportFilename(extension ext: String) -> String {
            guard let fileURL = currentFileURL else { return "export.\(ext)" }
            return fileURL.deletingPathExtension().lastPathComponent + ".\(ext)"
        }
        
        private func mimeTypeForExtension(_ ext: String) -> String {
            switch ext.lowercased() {
            case "png": return "image/png"
            case "jpg", "jpeg": return "image/jpeg"
            case "gif": return "image/gif"
            case "svg": return "image/svg+xml"
            case "webp": return "image/webp"
            case "ico": return "image/x-icon"
            case "bmp": return "image/bmp"
            default: return "image/\(ext)"
            }
        }
        
        private func collectImageData(from markdownURL: URL, content: String) -> [String: String] {
            var imageData: [String: String] = [:]
            let baseDir = markdownURL.deletingLastPathComponent()
            
            let fileAccessGranted = markdownURL.startAccessingSecurityScopedResource()
            let dirAccessGranted = baseDir.startAccessingSecurityScopedResource()
            
            defer {
                if fileAccessGranted {
                    markdownURL.stopAccessingSecurityScopedResource()
                }
                if dirAccessGranted {
                    baseDir.stopAccessingSecurityScopedResource()
                }
            }
            
            let pattern = #"!\[[^\]]*\]\(([^)"]+(?:\s+"[^"]*")?)\)"#
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                return imageData
            }
            
            let nsContent = content as NSString
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsContent.length))
            
            for match in matches {
                guard match.numberOfRanges >= 2 else { continue }
                var imagePath = nsContent.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
                
                if let spaceIndex = imagePath.firstIndex(of: " "), imagePath[spaceIndex...].contains("\"") {
                    imagePath = String(imagePath[..<spaceIndex])
                }
                
                // Skip network URLs and data URLs
                if imagePath.starts(with: "http://") || imagePath.starts(with: "https://") || 
                   imagePath.starts(with: "data:") {
                    continue
                }
                
                // Store the original path as key (before any transformations)
                let originalPath = imagePath
                var cleanPath = imagePath
                var imageURL: URL
                
                // Handle file:// protocol
                if imagePath.starts(with: "file://") {
                    cleanPath = String(imagePath.dropFirst("file://".count))
                    imageURL = URL(fileURLWithPath: cleanPath)
                }
                // Handle absolute filesystem paths
                else if imagePath.starts(with: "/") {
                    imageURL = URL(fileURLWithPath: imagePath)
                    cleanPath = imagePath
                }
                // Handle relative paths
                else {
                    if cleanPath.starts(with: "./") {
                        cleanPath = String(cleanPath.dropFirst(2))
                    }
                    
                    imageURL = baseDir
                    for component in cleanPath.split(separator: "/") {
                        let componentStr = String(component)
                        
                        if componentStr == ".." {
                            imageURL.deleteLastPathComponent()
                        } else {
                            if let decoded = componentStr.removingPercentEncoding {
                                imageURL.appendPathComponent(decoded)
                            } else {
                                imageURL.appendPathComponent(componentStr)
                            }
                        }
                    }
                }
                
                do {
                    let data = try Data(contentsOf: imageURL)
                    let base64 = data.base64EncodedString()
                    let mimeType = mimeTypeForExtension(imageURL.pathExtension)
                    let dataURL = "data:\(mimeType);base64,\(base64)"
                    
                    imageData[originalPath] = dataURL
                } catch {
                    os_log("🔴 Failed to load image: %{public}@ (original: %{public}@) - Error: %{public}@", log: logger, type: .error, imageURL.path, originalPath, error.localizedDescription)
                }
            }
            
            return imageData
        }
        
        func render(webView: WKWebView, content: String, fileURL: URL?, viewMode: ViewMode, appearanceMode: AppearanceMode, baseFontSize: Double, enableMermaid: Bool, enableKatex: Bool, enableEmoji: Bool, codeHighlightTheme: String) {
            currentFileURL = fileURL

            pendingRender = { [weak self] in
                self?.executeRender(webView: webView, content: content, fileURL: fileURL, viewMode: viewMode, appearanceMode: appearanceMode, baseFontSize: baseFontSize, enableMermaid: enableMermaid, enableKatex: enableKatex, enableEmoji: enableEmoji, codeHighlightTheme: codeHighlightTheme)
            }

            if isWebViewLoaded {
                pendingRender?()
                pendingRender = nil
            } else {
                os_log("Coordinator: WebView not ready, queuing render", log: logger, type: .debug)
            }
        }

        private func executeRender(webView: WKWebView, content: String, fileURL: URL?, viewMode: ViewMode, appearanceMode: AppearanceMode, baseFontSize: Double, enableMermaid: Bool, enableKatex: Bool, enableEmoji: Bool, codeHighlightTheme: String) {
            guard let contentData = try? JSONSerialization.data(withJSONObject: [content], options: []),
                  let contentJsonArray = String(data: contentData, encoding: .utf8) else {
                os_log("Failed to encode content", log: logger, type: .error)
                return
            }

            let safeContentArg = String(contentJsonArray.dropFirst().dropLast())

            var options: [String: Any] = [:]

            if let url = fileURL {
                let baseUrlString = url.deletingLastPathComponent().path
                options["baseUrl"] = baseUrlString

                options["imageData"] = self.collectImageData(from: url, content: content)
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
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            os_log("WebView didFinish navigation", log: logger, type: .debug)
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
            webView.evaluateJavaScript("window.exportHTML()") { result, error in
                if let error = error {
                    os_log("exportHTML JS error: %{public}@", log: self.logger, type: .error, error.localizedDescription)
                    completion(nil)
                } else {
                    completion(result as? String)
                }
            }
        }
        
        func exportPDF(webView: WKWebView, completion: @escaping (Data?) -> Void) {
            let config = WKPDFConfiguration()
            config.rect = CGRect(x: 0, y: 0, width: webView.bounds.width, height: webView.bounds.height)
            webView.createPDF(configuration: config) { result in
                switch result {
                case .success(let data):
                    completion(data)
                case .failure(let error):
                    os_log("exportPDF error: %{public}@", log: self.logger, type: .error, error.localizedDescription)
                    completion(nil)
                }
            }
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
            
            let baseDir = fileURL.deletingLastPathComponent()
            var targetURL: URL
            
            if href.starts(with: "file://") {
                guard let url = URL(string: href) else {
                    os_log("🔴 Invalid file URL: %{public}@", log: logger, type: .error, href)
                    return
                }
                targetURL = url
            } else if href.starts(with: "/") {
                targetURL = URL(fileURLWithPath: href)
            } else {
                targetURL = baseDir
                for component in href.split(separator: "/") {
                    let componentStr = String(component)
                    if componentStr == ".." {
                        targetURL.deleteLastPathComponent()
                    } else if componentStr != "." {
                        targetURL.appendPathComponent(componentStr)
                    }
                }
            }
            
            os_log("🔵 Opening local file: %{public}@ (base: %{public}@, href: %{public}@)", 
                   log: logger, type: .default, targetURL.path, baseDir.path, href)
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
    private var currentZoomLevel: Double = 1.0
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
                window.minSize = NSSize(width: 800, height: 600)
            } else {
                 window.minSize = NSSize(width: 800, height: 600)
            }
        }
        hasSetInitialSize = true
        
        currentZoomLevel = AppearancePreference.shared.zoomLevel
        
        self.allowsMagnification = true
        self.magnification = currentZoomLevel
        os_log("🔵 Enabled WKWebView magnification, initial level: %.2f", log: logger, type: .default, currentZoomLevel)
    }
}
