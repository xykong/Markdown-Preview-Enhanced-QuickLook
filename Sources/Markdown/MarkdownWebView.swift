import SwiftUI
import WebKit
import os.log

struct MarkdownWebView: NSViewRepresentable {
    var content: String
    var fileURL: URL?
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let coordinator = context.coordinator
        
        let webConfiguration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(coordinator, name: "logger")
        webConfiguration.userContentController = userContentController
        
        webConfiguration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        #if DEBUG
        webConfiguration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        #endif

        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = coordinator
        
        var bundleURL: URL?
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "WebRenderer") {
            bundleURL = url
        } else if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "dist") {
            bundleURL = url
        } else if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            bundleURL = url
        }
        
        if let url = bundleURL {
            let dir = url.deletingLastPathComponent()
            webView.loadFileURL(url, allowingReadAccessTo: dir)
        }
        
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.render(webView: webView, content: content, fileURL: fileURL)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        private let logger = OSLog(subsystem: "com.markdownquicklook.app", category: "MarkdownWebView")
        
        func render(webView: WKWebView, content: String, fileURL: URL?) {
            let checkJs = "typeof window.renderMarkdown"
            webView.evaluateJavaScript(checkJs) { [weak self] result, error in
                guard let self = self else { return }
                
                if let type = result as? String, type == "function" {
                    self.executeRender(webView: webView, content: content, fileURL: fileURL)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.render(webView: webView, content: content, fileURL: fileURL)
                    }
                }
            }
        }
        
        private func executeRender(webView: WKWebView, content: String, fileURL: URL?) {
            let escapedContent = content
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
                .replacingOccurrences(of: "\r", with: "\\r")
            
            var options = "{}"
            if let url = fileURL {
                let baseUrlString = url.deletingLastPathComponent().path
                options = "{ \"baseUrl\": \"\(baseUrlString)\" }"
            }
            
            let js = "window.renderMarkdown(\"\(escapedContent)\", \(options));"
            
            webView.evaluateJavaScript(js) { [weak self] _, error in
                if let error = error {
                    os_log("JS Error: %{public}@", log: self?.logger ?? .default, type: .error, error.localizedDescription)
                }
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "logger", let body = message.body as? String {
                os_log("JS Log: %{public}@", log: logger, type: .debug, body)
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
