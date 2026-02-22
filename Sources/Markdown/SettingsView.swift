import SwiftUI

// MARK: - Models

enum SettingsTab: String, CaseIterable, Identifiable {
    case appearance
    case rendering
    case editor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appearance: return "Appearance"
        case .rendering: return "Rendering"
        case .editor: return "Editor"
        }
    }

    var icon: String {
        switch self {
        case .appearance: return "paintbrush.fill"
        case .rendering: return "cpu"
        case .editor: return "textformat"
        }
    }
}

// MARK: - Main View

struct SettingsView: View {
    @ObservedObject private var preference = AppearancePreference.shared
    @State private var selectedTab: SettingsTab? = .appearance

    var body: some View {
        NavigationView {
            // Sidebar
            List {
                ForEach(SettingsTab.allCases) { tab in
                    SidebarRow(
                        title: tab.title,
                        icon: tab.icon,
                        isSelected: selectedTab == tab,
                        action: { selectedTab = tab }
                    )
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 180)

            // Content
            Group {
                if let tab = selectedTab {
                    ScrollView {
                        VStack(spacing: 20) {
                            switch tab {
                            case .appearance:
                                AppearanceSettingsView(preference: preference)
                            case .rendering:
                                RenderingSettingsView(preference: preference)
                            case .editor:
                                EditorSettingsView(preference: preference)
                            }
                        }
                        .padding(24)
                    }
                } else {
                    Color.clear
                }
            }
        }
        .frame(width: 600, height: 440)
    }

    private func SidebarRow(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 18)
                Text(title)
                    .font(.system(size: 13))
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .foregroundColor(isSelected ? .accentColor : .primary)
    }
}

// MARK: - Appearance Tab

struct AppearanceSettingsView: View {
    @ObservedObject var preference: AppearancePreference

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSectionHeader(title: "Theme", description: "Choose your preferred interface style")

            HStack(spacing: 0) {
                ThemeOptionButton(mode: .light, icon: "sun.max", label: "Light", current: preference.currentMode) {
                    preference.currentMode = .light
                }
                Divider()
                ThemeOptionButton(mode: .dark, icon: "moon.fill", label: "Dark", current: preference.currentMode) {
                    preference.currentMode = .dark
                }
                Divider()
                ThemeOptionButton(mode: .system, icon: "circle.lefthalf.filled", label: "System", current: preference.currentMode) {
                    preference.currentMode = .system
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func ThemeOptionButton(mode: AppearanceMode, icon: String, label: String, current: AppearanceMode, action: @escaping () -> Void) -> some View {
        let isSelected = current == mode
        return ZStack {
            if isSelected {
                Color.accentColor.opacity(0.12)
            } else {
                Color(NSColor.controlBackgroundColor)
            }
            Button(action: action) {
                VStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                    Text(label)
                        .font(.system(size: 12))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Rendering Tab

struct RenderingSettingsView: View {
    @ObservedObject var preference: AppearancePreference

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSectionHeader(title: "Features", description: "Enable or disable rendering capabilities")

            VStack(spacing: 0) {
                FeatureToggleRow(
                    title: "Mermaid Diagrams",
                    subtitle: "Flowcharts, sequence diagrams, and more",
                    icon: "diagram",
                    isOn: Binding(get: { preference.enableMermaid }, set: { preference.enableMermaid = $0 })
                )
                Divider().padding(.leading, 52)
                FeatureToggleRow(
                    title: "KaTeX Math",
                    subtitle: "Mathematical expressions and equations",
                    icon: "function",
                    isOn: Binding(get: { preference.enableKatex }, set: { preference.enableKatex = $0 })
                )
                Divider().padding(.leading, 52)
                FeatureToggleRow(
                    title: "Emoji Support",
                    subtitle: "GitHub flavored emoji codes like :smile:",
                    icon: "face.smiling",
                    isOn: Binding(get: { preference.enableEmoji }, set: { preference.enableEmoji = $0 })
                )
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func FeatureToggleRow(title: String, subtitle: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Editor Tab

struct EditorSettingsView: View {
    @ObservedObject var preference: AppearancePreference

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Font Size
            VStack(alignment: .leading, spacing: 12) {
                SettingsSectionHeader(title: "Typography", description: "Adjust the reading experience")

                VStack(spacing: 0) {
                    HStack {
                        Text("Font Size")
                            .font(.system(size: 13))
                        Spacer()
                        Text("\(Int(preference.baseFontSize))px")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.accentColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)

                    Divider()

                    HStack(spacing: 8) {
                        Text("A").font(.system(size: 11)).foregroundColor(.secondary)
                        Slider(
                            value: Binding(
                                get: { preference.baseFontSize },
                                set: { preference.baseFontSize = $0 }
                            ),
                            in: 12...24,
                            step: 1
                        )
                        .accentColor(.accentColor)
                        Text("A").font(.system(size: 20)).foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
            }

            // Code Theme
            VStack(alignment: .leading, spacing: 12) {
                SettingsSectionHeader(title: "Code Highlighting", description: "Syntax highlighting theme for code blocks")

                VStack(spacing: 0) {
                    CodeThemeRow(name: "Default", id: "default", color: Color(NSColor.textColor))
                    Divider().padding(.leading, 36)
                    CodeThemeRow(name: "GitHub", id: "github", color: Color(red: 0.141, green: 0.161, blue: 0.243))
                    Divider().padding(.leading, 36)
                    CodeThemeRow(name: "Monokai", id: "monokai", color: Color(red: 0.153, green: 0.157, blue: 0.133))
                    Divider().padding(.leading, 36)
                    CodeThemeRow(name: "Atom One Dark", id: "atom-one-dark", color: Color(red: 0.157, green: 0.173, blue: 0.204))
                }
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func CodeThemeRow(name: String, id: String, color: Color) -> some View {
        Button(action: { preference.codeHighlightTheme = id }) {
            HStack(spacing: 10) {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color(NSColor.separatorColor), lineWidth: 0.5))

                Text(name)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)

                Spacer()

                if preference.codeHighlightTheme == id {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 11, weight: .semibold))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Shared Components

struct SettingsSectionHeader: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
