import SwiftUI
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
    // Use SPUStandardUpdaterController for SwiftUI integration
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
    
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            MarkdownWebView(content: file.document.text, fileURL: file.fileURL, appearanceMode: preference.currentMode)
                .frame(minWidth: 800, idealWidth: 1000, maxWidth: .infinity,
                       minHeight: 600, idealHeight: 800, maxHeight: .infinity)
                .environmentObject(preference)
                .background(WindowAccessor())
        }
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updaterController: appDelegate.updaterController)
            }
            
            CommandMenu("View") {
                Button(action: {
                    NotificationCenter.default.post(name: .toggleSearch, object: nil)
                }) {
                    Text(NSLocalizedString("Find...", comment: "Search menu item"))
                }
                .keyboardShortcut("f", modifiers: .command)
                
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
        Button("检查更新...") {
            print("🔍 [DEBUG] Triggering update check...")
            NSApp.sendAction(#selector(SPUStandardUpdaterController.checkForUpdates(_:)), to: updaterController, from: nil)
        }
        .keyboardShortcut("u", modifiers: .command)
        Divider()
    }
}
