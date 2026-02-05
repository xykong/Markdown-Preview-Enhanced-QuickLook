import WebKit
import os.log

class LocalSchemeHandler: NSObject, WKURLSchemeHandler {
    private let logger = OSLog(subsystem: "com.markdownquicklook.app", category: "LocalSchemeHandler")
    var baseDirectory: URL?

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else { return }
        
        var filePath: String
        if let host = url.host, !host.isEmpty {
            filePath = "/" + host + url.path
        } else {
            filePath = url.path
        }
        
        os_log("🔵 Start loading resource: %{public}@", log: logger, type: .debug, filePath)

        let fileUrl = URL(fileURLWithPath: filePath)
        
        guard let baseDir = baseDirectory else {
            os_log("🔴 Base directory not set", log: logger, type: .error)
            urlSchemeTask.didFailWithError(NSError(domain: "LocalSchemeHandler", code: -1, userInfo: [NSLocalizedDescriptionKey: "Base directory not set"]))
            return
        }
        
        var coordinatorError: NSError?
        var resultData: Data?
        var accessError: Error?
        
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(readingItemAt: fileUrl, options: [], error: &coordinatorError) { url in
            let _ = baseDir.startAccessingSecurityScopedResource()
            defer {
                baseDir.stopAccessingSecurityScopedResource()
            }
            
            do {
                resultData = try Data(contentsOf: url)
            } catch {
                accessError = error
            }
        }
        
        if let error = coordinatorError ?? accessError {
            os_log("🔴 Failed to load resource: %{public}@. Error: %{public}@", log: logger, type: .error, filePath, error.localizedDescription)
            urlSchemeTask.didFailWithError(error)
            return
        }
        
        if let data = resultData {
            let response = URLResponse(url: url, mimeType: self.mimeType(for: url), expectedContentLength: data.count, textEncodingName: nil)
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
            os_log("🟢 Successfully loaded: %{public}@", log: logger, type: .debug, filePath)
        } else {
            let error = NSError(domain: "LocalSchemeHandler", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data"])
            os_log("🔴 Failed to load resource: %{public}@. No data", log: logger, type: .error, filePath)
            urlSchemeTask.didFailWithError(error)
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        os_log("Stopped loading: %{public}@", log: logger, type: .debug, urlSchemeTask.request.url?.path ?? "unknown")
    }
    
    private func mimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()
        switch pathExtension {
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "svg": return "image/svg+xml"
        case "css": return "text/css"
        case "js": return "application/javascript"
        default: return "application/octet-stream"
        }
    }
}
