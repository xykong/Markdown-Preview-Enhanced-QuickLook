import Cocoa
import QuickLookUI
import os.log
import WebKit

public class PreviewViewController: NSViewController, QLPreviewingController, WKNavigationDelegate, WKScriptMessageHandler {

    var statusLabel: NSTextField!
    var webView: WKWebView!
    var pendingMarkdown: String?
    var currentURL: URL?
    var isWebViewLoaded = false
    
    private var handshakeWorkItem: DispatchWorkItem?
    private let handshakeTimeoutInterval: TimeInterval = 10.0
    
    // Create a custom log object for easy filtering in Console.app
    // Subsystem: com.markdownquicklook.app
    // Category: MarkdownPreview
    private let logger = OSLog(subsystem: "com.markdownquicklook.app", category: "MarkdownPreview")
    
    private let maxPreviewSizeBytes: UInt64 = 500 * 1024 // 500KB limit
    
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
        
        let screen = NSScreen.main ?? NSScreen.screens.first
        let screenFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        
        let width = screenFrame.width * 0.5
        let height = screenFrame.height * 0.8
        
        os_log("🔵 Setting preferred size to: %.0f x %.0f", log: logger, type: .debug, width, height)

        self.view = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        self.view.autoresizingMask = [.width, .height]
        
        self.preferredContentSize = NSSize(width: width, height: height)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        os_log("🔵 viewDidLoad called", log: logger, type: .default)
        
        // Simple light background
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.white.cgColor
        
        AppearancePreference.shared.apply(to: self.view)
        
        os_log("🔵 configuring WebView...", log: logger, type: .default)
        
        // Initialize WebView
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.setURLSchemeHandler(LocalSchemeHandler(), forURLScheme: "local-resource")
        
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
            // When loading fileURL, we need to allow read access to the directory containing assets
            // bundleURL points to index.html
            // The assets are in ./assets/ relative to index.html
            // So we need read access to the parent directory of index.html
            let dir = url.deletingLastPathComponent()
            os_log("🔵 Loading HTML from bundle: %{public}@", log: logger, type: .default, url.path)
            
            // Critical: Ensure we allow read access to the directory so that relative paths like ./assets/script.js work
            webView.loadFileURL(url, allowingReadAccessTo: dir)
        } else {
            os_log("🔴 Failed to find index.html in bundle", log: logger, type: .error)
            
            // Debug info - list resource path
            let resourcePath = Bundle(for: type(of: self)).resourcePath ?? "nil"
            os_log("🔴 Resource path: %{public}@", log: logger, type: .error, resourcePath)
            
            webView.loadHTMLString("<html><body style='background: #ffeeee; font-family: system-ui;'><div style='text-align: center; margin-top: 20%;'><h1 style='color:red'>Error</h1><p>Could not load index.html from bundle.</p><p>Resource Path: \(resourcePath)</p></div></body></html>", baseURL: nil)
        }

        #if DEBUG
        // Debug Information Overlay
        let debugInfo = Bundle(for: type(of: self)).infoDictionary
        let version = debugInfo?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = debugInfo?["CFBundleVersion"] as? String ?? "Unknown"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let now = dateFormatter.string(from: Date())
        
        let debugLabel = NSTextField(labelWithString: "DEBUG v\(version) (\(build)) | Run: \(now)")
        debugLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        debugLabel.textColor = NSColor.white
        debugLabel.drawsBackground = true
        debugLabel.backgroundColor = NSColor.red.withAlphaComponent(0.6)
        debugLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(debugLabel)
        
        NSLayoutConstraint.activate([
            debugLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 5),
            debugLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -5)
        ])
        
        // Bring debug label to front
        self.view.addSubview(debugLabel, positioned: .above, relativeTo: webView)
        #endif
    }

    public func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        
        os_log("🔵 preparePreviewOfFile called for: %{public}@", log: logger, type: .default, url.path)
        self.currentURL = url
        
        // Update label to show we received the file
        DispatchQueue.main.async {
            // Read file content and render
            do {
                // Check file size
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = attributes[.size] as? UInt64 ?? 0
                
                var content: String
                
                if fileSize > self.maxPreviewSizeBytes {
                    os_log("🟠 File too large (%{public}llu bytes), truncating to %{public}llu bytes", log: self.logger, type: .default, fileSize, self.maxPreviewSizeBytes)
                    
                    let fileHandle = try FileHandle(forReadingFrom: url)
                    defer { try? fileHandle.close() }
                    
                    let data = fileHandle.readData(ofLength: Int(self.maxPreviewSizeBytes))
                    
                    if var stringContent = String(data: data, encoding: .utf8) {
                        // Find last newline to avoid breaking line
                        if let lastNewline = stringContent.lastIndex(of: "\n") {
                            stringContent = String(stringContent[...lastNewline])
                        }
                        
                        content = stringContent + "\n\n> **Preview truncated for performance. This file is too large to render fully in QuickLook.**"
                    } else {
                        // Fallback if encoding fails
                         content = "> **Error reading file content (Encoding issue).**"
                    }
                } else {
                     content = try String(contentsOf: url, encoding: .utf8)
                }

                self.pendingMarkdown = content
                
                if self.isWebViewLoaded {
                    self.renderPendingMarkdown()
                } else {
                    os_log("🔵 WebView not yet loaded, queueing markdown", log: self.logger, type: .debug)
                }
            } catch {
                os_log("🔴 Failed to read file: %{public}@", log: self.logger, type: .error, error.localizedDescription)
            }
        }
        
        handler(nil)
    }
    
    private func renderPendingMarkdown() {
        guard let content = pendingMarkdown else { return }
        
        // Only render if we have completed the handshake
        guard isWebViewLoaded else {
            os_log("🟡 renderPendingMarkdown called but WebView not ready (handshake pending), queuing...", log: logger, type: .debug)
            return
        }
        
        os_log("🔵 renderPendingMarkdown called with content length: %d", log: logger, type: .debug, content.count)
        
        guard let contentData = try? JSONSerialization.data(withJSONObject: [content], options: []),
              let contentJsonArray = String(data: contentData, encoding: .utf8) else {
            os_log("🔴 Failed to encode content to JSON", log: self.logger, type: .error)
            return
        }
        
        let safeContentArg = String(contentJsonArray.dropFirst().dropLast())
        
        var options: [String: String] = [:]
        
        if let url = self.currentURL {
            let dir = url.deletingLastPathComponent().path
            options["baseUrl"] = dir
        }
        
        let appearanceName = self.view.effectiveAppearance.name
        var theme = "system"
        if appearanceName == .darkAqua || appearanceName == .vibrantDark || appearanceName == .accessibilityHighContrastDarkAqua || appearanceName == .accessibilityHighContrastVibrantDark {
            theme = "dark"
        } else if appearanceName == .aqua || appearanceName == .vibrantLight || appearanceName == .accessibilityHighContrastAqua || appearanceName == .accessibilityHighContrastVibrantLight {
            theme = "light"
        }
        options["theme"] = theme
        
        guard let optionsData = try? JSONSerialization.data(withJSONObject: options, options: []),
              let optionsJson = String(data: optionsData, encoding: .utf8) else {
            os_log("🔴 Failed to encode options to JSON", log: self.logger, type: .error)
            return
        }
        
        // Directly call renderMarkdown since we know it exists (handshake complete)
        let callJs = """
        try {
            window.renderMarkdown(\(safeContentArg), \(optionsJson));
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
    }
    
    // MARK: - WKNavigationDelegate
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        os_log("🔵 WebView didFinish navigation (waiting for handshake)", log: logger, type: .debug)
        startHandshakeTimeout()
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        os_log("🔴 WebView didFail navigation: %{public}@", log: logger, type: .error, error.localizedDescription)
        cancelHandshakeTimeout()
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        os_log("🔴 WebView didFailProvisionalNavigation: %{public}@", log: logger, type: .error, error.localizedDescription)
        cancelHandshakeTimeout()
    }

    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        os_log("🔴 WebContent process terminated! Attempting reload...", log: logger, type: .error)
        cancelHandshakeTimeout()
        webView.reload()
    }
    
    // MARK: - WKScriptMessageHandler
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "logger", let body = message.body as? String {
            os_log("🟢 JS Log: %{public}@", log: logger, type: .debug, body)
            
            // Check for Handshake
            if body == "rendererReady" {
                os_log("🟢 Renderer Handshake Received!", log: logger, type: .default)
                cancelHandshakeTimeout()
                
                if !isWebViewLoaded {
                    isWebViewLoaded = true
                    renderPendingMarkdown()
                }
            }
        }
    }
    
    // MARK: - Handshake Timeout Management
    
    private func startHandshakeTimeout() {
        cancelHandshakeTimeout()
        
        if isWebViewLoaded { return }
        
        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if !self.isWebViewLoaded {
                os_log("🔴 Renderer Handshake Timeout (%{public}.1fs)! Showing non-destructive error.", log: self.logger, type: .error, self.handshakeTimeoutInterval)
                
                // Non-destructive error UI: Update #loading-status text or show overlay
                let js = """
                (function() {
                    var status = document.getElementById('loading-status');
                    if (status) {
                        status.textContent = 'Renderer timed out. Please retry.';
                        status.style.color = 'red';
                    } else {
                        // Create overlay if status is gone
                        var d = document.createElement('div');
                        d.style.position = 'fixed';
                        d.style.top = '10px';
                        d.style.right = '10px';
                        d.style.background = 'rgba(255,0,0,0.8)';
                        d.style.color = 'white';
                        d.style.padding = '5px 10px';
                        d.style.borderRadius = '4px';
                        d.style.zIndex = '9999';
                        d.innerText = 'Renderer Timeout';
                        document.body.appendChild(d);
                    }
                })();
                """
                self.webView.evaluateJavaScript(js, completionHandler: nil)
            }
        }
        
        self.handshakeWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + handshakeTimeoutInterval, execute: item)
        os_log("🔵 Started handshake timer (%.1fs)", log: logger, type: .debug, handshakeTimeoutInterval)
    }
    
    private func cancelHandshakeTimeout() {
        if let item = handshakeWorkItem {
            item.cancel()
            handshakeWorkItem = nil
            os_log("🔵 Cancelled handshake timer", log: logger, type: .debug)
        }
    }
    
    deinit {
        handshakeWorkItem?.cancel()
    }
}
