import SwiftUI

@main
struct MarkdownApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            MarkdownWebView(content: file.document.text, fileURL: file.fileURL)
                .frame(minWidth: 800, idealWidth: 1000, maxWidth: .infinity,
                       minHeight: 600, idealHeight: 800, maxHeight: .infinity)
        }
    }
}
