import Cocoa
import QuickLookUI
import os.log
import WebKit

public class PreviewViewController: NSViewController, QLPreviewingController, WKNavigationDelegate, WKScriptMessageHandler {

    var statusLabel: NSTextField!
    var webView: WKWebView!
    var pendingMarkdown: String?
    var isWebViewLoaded = false
    
    // Create a custom log object for easy filtering in Console.app
    // Subsystem: com.markdownquicklook.app
    // Category: MarkdownPreview
    private let logger = OSLog(subsystem: "com.markdownquicklook.app", category: "MarkdownPreview")
    
    public override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        os_log("🔵 init(nibName:bundle:) called", log: logger, type: .debug)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        os_log("🔵 init(coder:) called", log: logger, type: .debug)
    }
    
    public override func loadView() {
        os_log("🔵 loadView called", log: logger, type: .debug)
        // Create the main view programmatically with a default size
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
        self.view.autoresizingMask = [.width, .height]
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        os_log("🔵 viewDidLoad called", log: logger, type: .default)
        
        // Simple light background
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.white.cgColor
        
        os_log("🔵 configuring WebView...", log: logger, type: .default)
        
        // Initialize WebView
        let webConfiguration = WKWebViewConfiguration()
        
        // Enable developer extras for inspection
        // webConfiguration.preferences.setValue(true, forKey: "developerExtras")
        
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "logger")
        webConfiguration.userContentController = userContentController
        
        os_log("🔵 initializing WKWebView instance...", log: logger, type: .default)
        webView = WKWebView(frame: self.view.bounds, configuration: webConfiguration)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        self.view.addSubview(webView)
        
        os_log("🔵 WebView initialized and added to view", log: logger, type: .default)
        
        
        // Load the HTML template from the bundle
        // Since we added WebRenderer as a folder reference, it should be in Contents/Resources/WebRenderer
        var bundleURL: URL?
        
        // Try finding in WebRenderer folder (most likely for folder reference)
        if let url = Bundle(for: type(of: self)).url(forResource: "index", withExtension: "html", subdirectory: "WebRenderer") {
            bundleURL = url
            os_log("🔵 Found index.html in WebRenderer subdirectory: %{public}@", log: logger, type: .default, url.path)
        } else if let url = Bundle(for: type(of: self)).url(forResource: "index", withExtension: "html", subdirectory: "dist") {
            bundleURL = url
            os_log("🔵 Found index.html in dist subdirectory: %{public}@", log: logger, type: .default, url.path)
        } else if let url = Bundle(for: type(of: self)).url(forResource: "index", withExtension: "html") {
            bundleURL = url
            os_log("🔵 Found index.html in root: %{public}@", log: logger, type: .default, url.path)
        }
        
        if let url = bundleURL {
            let dir = url.deletingLastPathComponent()
            os_log("🔵 Loading HTML from bundle: %{public}@", log: logger, type: .default, url.path)
            
            do {
                let htmlContent = try String(contentsOf: url, encoding: .utf8)
                os_log("🔵 Read HTML content, length: %d", log: logger, type: .default, htmlContent.count)
                // Use loadHTMLString as a fallback for loadFileURL issues
                webView.loadHTMLString(htmlContent, baseURL: dir)
            } catch {
                os_log("🔴 Failed to read index.html content: %{public}@", log: logger, type: .error, error.localizedDescription)
                webView.loadFileURL(url, allowingReadAccessTo: dir)
            }
        } else {
            os_log("🔴 Failed to find index.html in bundle", log: logger, type: .error)
            
            // Debug info - list resource path
            let resourcePath = Bundle(for: type(of: self)).resourcePath ?? "nil"
            os_log("🔴 Resource path: %{public}@", log: logger, type: .error, resourcePath)
            
            webView.loadHTMLString("<html><body style='background: #ffeeee; font-family: system-ui;'><div style='text-align: center; margin-top: 20%;'><h1 style='color:red'>Error</h1><p>Could not load index.html from bundle.</p><p>Resource Path: \(resourcePath)</p></div></body></html>", baseURL: nil)
        }
        
        // Debug timeout check
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            os_log("🔵 2s Check - isLoading: %{public}@", log: self.logger, type: .debug, self.webView.isLoading ? "true" : "false")
            if !self.isWebViewLoaded && !self.webView.isLoading {
                os_log("🔴 WebView stuck: not loaded and not loading. Attempting to force load state.", log: self.logger, type: .error)
                // Assume loaded if it's not loading anymore (maybe delegate missed?)
                self.isWebViewLoaded = true
                self.renderPendingMarkdown()
            }
        }

        // Debug Information Overlay
        // let debugInfo = Bundle(for: type(of: self)).infoDictionary
        // let version = debugInfo?["CFBundleShortVersionString"] as? String ?? "Unknown"
        // let build = debugInfo?["CFBundleVersion"] as? String ?? "Unknown"
        //
        // let dateFormatter = DateFormatter()
        // dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        // let now = dateFormatter.string(from: Date())
        //
        // let debugLabel = NSTextField(labelWithString: "v\(version) (\(build)) | Run: \(now)")
        // debugLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        // debugLabel.textColor = NSColor.white
        // debugLabel.drawsBackground = true
        // debugLabel.backgroundColor = NSColor.black.withAlphaComponent(0.6)
        // debugLabel.translatesAutoresizingMaskIntoConstraints = false
        //
        // self.view.addSubview(debugLabel)
        //
        // NSLayoutConstraint.activate([
        //     debugLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 5),
        //     debugLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -5)
        // ])
        //
        // // Bring debug label to front
        // self.view.addSubview(debugLabel, positioned: .above, relativeTo: webView)
    }

    public func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        
        os_log("🔵 preparePreviewOfFile called for: %{public}@", log: logger, type: .default, url.path)
        
        // Update label to show we received the file
        DispatchQueue.main.async {
            // self.statusLabel.stringValue = "Markdown Preview\nFile: \(url.lastPathComponent)"
            // Read file content and render
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                self.pendingMarkdown = content
                
                if self.isWebViewLoaded {
                    self.renderPendingMarkdown()
                } else {
                    os_log("🔵 WebView not yet loaded, queueing markdown", log: self.logger, type: .debug)
                }
            } catch {
                os_log("🔴 Failed to read file: %{public}@", log: self.logger, type: .error, error.localizedDescription)
                // self.statusLabel.stringValue = "Error reading file: \(error.localizedDescription)"
            }
        }
        
        handler(nil)
    }
    
    private func renderPendingMarkdown() {
        guard let content = pendingMarkdown else { return }
        
        os_log("🔵 renderPendingMarkdown called with content length: %d", log: logger, type: .debug, content.count)
        
        // Escape special characters for JavaScript string
        let escapedContent = content
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
        
        // Check existence of renderMarkdown
        let checkJs = "typeof window.renderMarkdown"
        
        webView.evaluateJavaScript(checkJs) { (result, error) in
            if let type = result as? String, type == "function" {
                os_log("🟢 renderMarkdown is ready", log: self.logger, type: .debug)
                
                // Call it
                // We use a try-catch block in JS to ensure we catch any internal errors and log them
                let callJs = """
                try {
                    window.renderMarkdown("\(escapedContent)");
                    "success"
                } catch(e) {
                    "error: " + e.toString()
                }
                """
                
                self.webView.evaluateJavaScript(callJs) { (innerResult, innerError) in
                    if let innerError = innerError {
                        os_log("🔴 JS Execution Error: %{public}@", log: self.logger, type: .error, innerError.localizedDescription)
                    } else if let res = innerResult as? String {
                        os_log("🔵 JS Execution Result: %{public}@", log: self.logger, type: .debug, res)
                    }
                }
                
            } else {
                // Not ready yet
                os_log("🟡 renderMarkdown not ready (type: %{public}@), retrying in 0.2s...", log: self.logger, type: .debug, String(describing: result))
                
                // Retry limit?
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.renderPendingMarkdown()
                }
            }
        }
        
        // Do not clear pendingMarkdown yet as we might retry
    }
    
    // MARK: - WKNavigationDelegate
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        os_log("🔵 WebView didFinish navigation", log: logger, type: .debug)
        isWebViewLoaded = true
        renderPendingMarkdown()
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        os_log("🔴 WebView didFail navigation: %{public}@", log: logger, type: .error, error.localizedDescription)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        os_log("🔴 WebView didFailProvisionalNavigation: %{public}@", log: logger, type: .error, error.localizedDescription)
    }
    
    // MARK: - WKScriptMessageHandler
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "logger", let body = message.body as? String {
            os_log("🟢 JS Log: %{public}@", log: logger, type: .debug, body)
        }
    }
}
