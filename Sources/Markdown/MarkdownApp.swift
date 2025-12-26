import SwiftUI

@main
struct MarkdownApp: App {
    var body: some Scene {
        WindowGroup {
            VStack {
                Text("Markdown Host App")
                    .font(.headline)
                    .padding()
                Text("This app hosts the Quick Look extension.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(width: 400, height: 300)
        }
    }
}
