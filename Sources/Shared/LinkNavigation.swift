import Foundation

enum LinkNavigation {

    static func resolveLocalURLWithFragment(href: String, relativeTo fileURL: URL) -> (URL?, String?) {
        let hrefPath: String
        let fragment: String?
        if let hashRange = href.range(of: "#") {
            hrefPath = String(href[href.startIndex..<hashRange.lowerBound])
            fragment = String(href[hashRange.upperBound...])
        } else {
            hrefPath = href
            fragment = nil
        }
        return (resolveLocalURL(href: hrefPath, relativeTo: fileURL), fragment)
    }

    static func resolveLocalURL(href: String, relativeTo fileURL: URL) -> URL? {
        let decoded = href.removingPercentEncoding ?? href

        if decoded.isEmpty { return nil }

        if decoded.hasPrefix("#") { return nil }

        if decoded.hasPrefix("file://") {
            return URL(string: decoded)
        }

        if decoded.hasPrefix("/") {
            return URL(fileURLWithPath: decoded)
        }

        let baseDir = fileURL.deletingLastPathComponent()
        var targetURL = baseDir
        for component in decoded.split(separator: "/") {
            let componentStr = String(component)
            if componentStr == ".." {
                targetURL.deleteLastPathComponent()
            } else if componentStr != "." {
                targetURL.appendPathComponent(componentStr)
            }
        }
        return targetURL
    }
}
