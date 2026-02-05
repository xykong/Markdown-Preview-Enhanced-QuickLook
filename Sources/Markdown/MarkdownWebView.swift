import SwiftUI
import AppKit
import WebKit
import os.log

struct MarkdownWebView: NSViewRepresentable {
    var content: String
    var fileURL: URL?
    var appearanceMode: AppearanceMode = .light
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let coordinator = context.coordinator
        
        let webConfiguration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(coordinator, name: "logger")
        
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
        
        context.coordinator.render(webView: webView, content: content, fileURL: fileURL)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let logger = OSLog(subsystem: "com.markdownquicklook.app", category: "MarkdownWebView")
        var isWebViewLoaded = false
        var pendingRender: (() -> Void)?
        weak var currentWebView: WKWebView?
        
        override init() {
            super.init()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleToggleSearch),
                name: .toggleSearch,
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
        
        func render(webView: WKWebView, content: String, fileURL: URL?) {
            // Save the render action
            pendingRender = { [weak self] in
                self?.executeRender(webView: webView, content: content, fileURL: fileURL)
            }
            
            // If already loaded, render immediately
            if isWebViewLoaded {
                pendingRender?()
                pendingRender = nil
            } else {
                os_log("Coordinator: WebView not ready, queuing render", log: logger, type: .debug)
            }
        }
        
        private func executeRender(webView: WKWebView, content: String, fileURL: URL?) {
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
            
            guard let optionsData = try? JSONSerialization.data(withJSONObject: options, options: []),
                  let optionsJson = String(data: optionsData, encoding: .utf8) else {
                os_log("Failed to encode options", log: logger, type: .error)
                return
            }
            
            let js = "window.renderMarkdown(\(safeContentArg), \(optionsJson));"
            
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
            }
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

