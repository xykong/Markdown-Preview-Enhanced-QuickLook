import SwiftUI
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("✅ Sparkle updater controller initialized")
        
        if CommandLine.arguments.contains("--register-only") {
            NSApplication.shared.terminate(nil)
        }
        
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }
    
    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else {
            print("❌ Invalid URL event")
            return
        }
        
        print("🔵 Received URL: \(urlString)")
        
        if url.scheme == "markdownpreview",
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let path = components.queryItems?.first(where: { $0.name == "path" })?.value {
            let fileURL = URL(fileURLWithPath: path)
            print("🔵 Opening file: \(fileURL.path)")
            NSDocumentController.shared.openDocument(withContentsOf: fileURL, display: true) { _, _, error in
                if let error = error {
                    print("❌ Failed to open document: \(error.localizedDescription)")
                } else {
                    print("✅ Successfully opened document")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get the bundled QuickLook extension URL (for debugging)
    func getQuickLookExtensionURL() -> URL? {
        guard let plugInsURL = Bundle.main.builtInPlugInsURL else { return nil }
        let contents = try? FileManager.default.contentsOfDirectory(
            at: plugInsURL,
            includingPropertiesForKeys: nil
        )
        return contents?.first(where: { $0.pathExtension == "appex" })
    }
}

@main
struct MarkdownApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var preference = AppearancePreference.shared
    
    @State private var viewMode: ViewMode = .preview
    
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ZStack(alignment: .topTrailing) {
                MarkdownWebView(
                    content: file.document.text,
                    fileURL: file.fileURL,
                    appearanceMode: preference.currentMode,
                    viewMode: viewMode
                )
                
                HStack(spacing: 8) {
                    Button(action: {
                        viewMode = (viewMode == .preview) ? .source : .preview
                    }) {
                        Image(systemName: viewMode == .source ? "eye.fill" : "doc.text.fill")
                            .foregroundColor(viewMode == .source ? .blue : .secondary)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(Color.black.opacity(0.1))
                    .clipShape(Circle())
                    .help(viewMode == .source ? "Show Preview" : "Show Source")
                    
                    Button(action: {
                        let current = preference.currentMode
                        preference.currentMode = (current == .dark) ? .light : .dark
                    }) {
                        Image(systemName: preference.currentMode == .dark ? "sun.max.fill" : "moon.fill")
                            .foregroundColor(preference.currentMode == .dark ? .yellow : .secondary)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(Color.black.opacity(0.1))
                    .clipShape(Circle())
                    .help(preference.currentMode == .dark ? "Light Mode" : "Dark Mode")
                }
                .padding([.top, .trailing], 10)
            }
            .frame(minWidth: 800, idealWidth: 1000, maxWidth: .infinity,
                   minHeight: 600, idealHeight: 800, maxHeight: .infinity)
            .environmentObject(preference)
            .background(WindowAccessor())
        }
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updaterController: appDelegate.updaterController)
            }

            CommandGroup(after: .windowArrangement) {
                Button(action: {
                    viewMode = (viewMode == .preview) ? .source : .preview
                }) {
                    Text(viewMode == .source ? "Show Preview" : "Show Source")
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])

                Divider()

                Button(action: {
                    NotificationCenter.default.post(name: .toggleSearch, object: nil)
                }) {
                    Text(NSLocalizedString("Find...", comment: "Search menu item"))
                }
                .keyboardShortcut("f", modifiers: [.command])

                Divider()

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

struct CheckForUpdatesView: View {
    let updaterController: SPUStandardUpdaterController
    
    var body: some View {
        Button(NSLocalizedString("Check for Updates...", comment: "Check for updates menu item")) {
            print("🔍 [DEBUG] Triggering update check...")
            NSApp.sendAction(#selector(SPUStandardUpdaterController.checkForUpdates(_:)), to: updaterController, from: nil)
        }
        .keyboardShortcut("u", modifiers: .command)
        Divider()
    }
}
