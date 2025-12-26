import SwiftUI

@main
struct MarkdownApp: App {
    var body: some Scene {
        WindowGroup {
            VStack {
                Text("Markdown Preview Enhanced for macOS Host App")
                    .font(.headline)
                    .padding()
                Text("This app hosts the Quick Look extension.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                   let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    Text("Version \(version) (\(build))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 5)
                }
            }
            .frame(width: 400, height: 300)
        }
    }
}
