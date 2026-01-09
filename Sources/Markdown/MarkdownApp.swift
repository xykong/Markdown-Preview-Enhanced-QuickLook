import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check for silent registration flag used by installer
        if CommandLine.arguments.contains("--register-only") {
            NSApplication.shared.terminate(nil)
        }
    }
}

@main
struct MarkdownApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Use the shared preference
    @ObservedObject var preference = AppearancePreference.shared
    
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            MarkdownWebView(content: file.document.text, fileURL: file.fileURL, appearanceMode: preference.currentMode)
                .frame(minWidth: 800, idealWidth: 1000, maxWidth: .infinity,
                       minHeight: 600, idealHeight: 800, maxHeight: .infinity)
                .environmentObject(preference)
                .background(WindowAccessor())
        }
        .commands {
            CommandMenu("View") {
                Menu("Appearance") {
                    ForEach(AppearanceMode.allCases) { mode in
                        Button(action: {
                            preference.currentMode = mode
                        }) {
                            HStack {
                                Text(mode.displayName)
                                if preference.currentMode == mode {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
