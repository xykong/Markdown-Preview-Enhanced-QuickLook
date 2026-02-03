import SwiftUI
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
    var updater: SPUUpdater?
    private var userDriver: SPUStandardUserDriver?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupUpdateMechanism()
        
        if CommandLine.arguments.contains("--register-only") {
            NSApplication.shared.terminate(nil)
        }
    }
    
    // MARK: - Update Mechanism
    
    private func setupUpdateMechanism() {
        let hostBundle = Bundle.main
        userDriver = SPUStandardUserDriver(hostBundle: hostBundle, delegate: nil)
        updater = SPUUpdater(
            hostBundle: hostBundle,
            applicationBundle: hostBundle,
            userDriver: userDriver!,
            delegate: nil
        )
        
        do {
            try updater?.start()
            print("✅ Sparkle auto-updater initialized successfully")
        } catch {
            print("❌ Failed to start Sparkle: \(error.localizedDescription)")
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
                CheckForUpdatesView(updater: appDelegate.updater)
            }
            
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

struct CheckForUpdatesView: View {
    let updater: SPUUpdater?
    
    var body: some View {
        Button("检查更新...") {
            updater?.checkForUpdates()
        }
        .keyboardShortcut("u", modifiers: .command)
        Divider()
    }
}
