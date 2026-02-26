import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct WelcomeView: View {
    @State private var isTargeted = false
    @State private var window: NSWindow?
    @State private var openErrorMessage: String?
    @State private var isOpening = false

    @Environment(\.openURL) private var openURL

    private let settingsWindowManager = SettingsWindowManager.shared

    private let allowedContentTypes: [UTType] = {
        var types: [UTType] = []
        if let md = UTType(filenameExtension: "md") {
            types.append(md)
        }
        types.append(.plainText)
        return types
    }()

    var body: some View {
        ZStack {
            background

            VStack(spacing: 22) {
                header
                dropZone
                tips

                if let message = openErrorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 520)
                }
            }
            .padding(36)
        }
        .background(WelcomeWindowAccessor { window in
            self.window = window
        })
        .onReceive(Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()) { _ in
            closeIfAnyDocumentIsOpen()
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(NSColor.windowBackgroundColor),
                Color(NSColor.controlBackgroundColor)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(spacing: 10) {
            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(NSColor.separatorColor).opacity(0.8), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
                    .accessibilityLabel(Text("FluxMarkdown App Icon"))
            }

            Text("FluxMarkdown")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.primary)

            Text("Open a Markdown file or drop it here to start.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }

    private var dropZone: some View {
        Button(action: openFilePicker) {
            VStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(borderColor, style: StrokeStyle(lineWidth: 2, dash: [8, 6]))

                    VStack(spacing: 10) {
                        Image(systemName: "plus")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundColor(isTargeted ? Color.accentColor : Color.secondary)

                        Text("Open Markdown File…")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)

                        Text("Drag & drop .md/.mdx/.txt here")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        if isOpening {
                            ProgressView()
                        }
                    }
                    .padding(.horizontal, 26)
                }
                .frame(width: 520, height: 240)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .disabled(isOpening)
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
    }

    private var tips: some View {
        VStack(alignment: .leading, spacing: 10) {
            if #available(macOS 12.0, *) {
                TipRow(icon: "space", title: "QuickLook", subtitle: "In Finder, select a file and press Space.")
            } else {
                TipRow(icon: "keyboard", title: "QuickLook", subtitle: "In Finder, select a file and press Space.")
            }
            TipRow(icon: "doc.text", title: "Open with App", subtitle: "Double-click a .md file to open it here.")
            TipRow(icon: "arrow.down.doc", title: "Drag & Drop", subtitle: "Drop files onto the + area to open.")

            Divider()
                .padding(.top, 2)

            HStack(spacing: 10) {
                Button("Open Settings") {
                    settingsWindowManager.show()
                }
                .buttonStyle(BorderlessButtonStyle())
                .foregroundColor(.accentColor)

                Text("•")
                    .foregroundColor(Color.secondary.opacity(0.6))

                Button("Troubleshooting") {
                    if let url = URL(string: "https://github.com/xykong/flux-markdown/blob/main/docs/user/HELP.md") {
                        openURL(url)
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
                .foregroundColor(.accentColor)

                Spacer()
            }
            .font(.system(size: 12, weight: .semibold))
        }
        .frame(maxWidth: 520, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(NSColor.separatorColor).opacity(0.8), lineWidth: 1)
        )
    }

    private var borderColor: Color {
        if isTargeted {
            return Color.accentColor.opacity(0.9)
        }
        return Color(NSColor.separatorColor).opacity(0.9)
    }

    private func openFilePicker() {
        openErrorMessage = nil
        isOpening = true

        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = allowedContentTypes
        panel.prompt = "Open"

        if panel.runModal() == .OK {
            open(urls: panel.urls)
        } else {
            isOpening = false
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        openErrorMessage = nil
        isOpening = true

        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let error {
                    DispatchQueue.main.async {
                        openErrorMessage = error.localizedDescription
                        isOpening = false
                    }
                    return
                }

                let url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else if let raw = item as? URL {
                    url = raw
                } else if let raw = item as? String {
                    url = URL(string: raw)
                } else {
                    url = nil
                }

                if let url {
                    DispatchQueue.main.async {
                        open(urls: [url])
                    }
                }
            }
        }

        return true
    }

    private func open(urls: [URL]) {
        guard !urls.isEmpty else {
            isOpening = false
            return
        }

        var remaining = urls.count
        for url in urls {
            NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, error in
                if let error {
                    DispatchQueue.main.async {
                        openErrorMessage = error.localizedDescription
                    }
                }

                DispatchQueue.main.async {
                    remaining -= 1
                    if remaining <= 0 {
                        isOpening = false
                    }
                }
            }
        }
    }

    private func closeIfAnyDocumentIsOpen() {
        guard window != nil else { return }
        if !NSDocumentController.shared.documents.isEmpty {
            window?.close()
            window = nil
        }
    }
}

private struct TipRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.accentColor)
                .frame(width: 20, height: 20, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct WelcomeWindowAccessor: NSViewRepresentable {
    let onWindow: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onWindow(window)
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.isMovableByWindowBackground = true
                window.setContentSize(NSSize(width: 720, height: 620))
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private final class SettingsWindowManager: NSObject {
    static let shared = SettingsWindowManager()

    private var settingsWindow: NSWindow?

    @objc func show() {
        NSApp.activate(ignoringOtherApps: true)

        let keyWindowBefore = NSApp.keyWindow

        _ = tryPerformCmdCommaKeyEquivalent()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if self.didOpenSettingsWindow(keyWindowBefore: keyWindowBefore) {
                return
            }

            if self.trySendAction(Selector(("showSettingsWindow:"))) {
                return
            }

            if self.trySendAction(Selector(("showPreferencesWindow:"))) {
                return
            }

            if self.tryPerformSettingsMenuItem() {
                return
            }

            self.showFallbackSettingsWindow()
        }
    }

    private func trySendAction(_ selector: Selector) -> Bool {
        NSApp.sendAction(selector, to: nil, from: nil)
    }

    private func tryPerformSettingsMenuItem() -> Bool {
        guard let mainMenu = NSApp.mainMenu else { return false }
        let items = allMenuItems(in: mainMenu)

        if let item = items.first(where: { isSettingsMenuItem($0) }) {
            if let action = item.action {
                return NSApp.sendAction(action, to: nil, from: item)
            }
        }

        return false
    }

    private func tryPerformCmdCommaKeyEquivalent() -> Bool {
        guard let menu = NSApp.mainMenu else { return false }
        guard let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [.command],
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: 0,
            context: nil,
            characters: ",",
            charactersIgnoringModifiers: ",",
            isARepeat: false,
            keyCode: 43
        ) else {
            return false
        }

        return menu.performKeyEquivalent(with: event)
    }

    private func didOpenSettingsWindow(keyWindowBefore: NSWindow?) -> Bool {
        if let settingsWindow {
            return settingsWindow.isVisible
        }

        guard let keyAfter = NSApp.keyWindow else { return false }
        if let before = keyWindowBefore, keyAfter === before {
            return false
        }

        let title = keyAfter.title.lowercased()
        if title.contains("settings") || title.contains("preferences") {
            return true
        }

        return keyAfter.identifier?.rawValue.lowercased().contains("settings") == true
    }

    private func isSettingsMenuItem(_ item: NSMenuItem) -> Bool {
        let hasCmdComma = item.keyEquivalent == "," && item.keyEquivalentModifierMask.contains(.command)
        if hasCmdComma {
            return true
        }

        let title = item.title.lowercased()
        if title.contains("settings") || title.contains("preferences") {
            return true
        }

        if item.title.contains("设置") || item.title.contains("偏好") {
            return true
        }

        if let actionName = item.action.map({ NSStringFromSelector($0).lowercased() }) {
            if actionName.contains("showsettings") || actionName.contains("showpreferences") {
                return true
            }
        }

        return false
    }

    private func allMenuItems(in menu: NSMenu) -> [NSMenuItem] {
        var result: [NSMenuItem] = []
        for item in menu.items {
            result.append(item)
            if let submenu = item.submenu {
                result.append(contentsOf: allMenuItems(in: submenu))
            }
        }
        return result
    }

    private func showFallbackSettingsWindow() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = SettingsView()
        let hostingView = NSHostingView(rootView: view)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 440),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.center()
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }
}
