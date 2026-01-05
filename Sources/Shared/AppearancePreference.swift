import Foundation
import SwiftUI
import AppKit

public enum AppearanceMode: String, CaseIterable, Identifiable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    public var nsAppearance: NSAppearance? {
        switch self {
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        case .system: return nil // System handles it (nil implies inherited)
        }
    }
}

public class AppearancePreference: ObservableObject {
    public static let shared = AppearancePreference()
    
    // Key for UserDefaults
    // Note: To share between App and Extension, we technically need App Groups.
    // However, without App Groups, they will have separate storages.
    // For now, we will use standard UserDefaults, but if App Groups are enabled
    // in the future, we should switch to `UserDefaults(suiteName: "group.com.xykong.Markdown")`.
    private let key = "preferredAppearanceMode"
    
    // We use a property wrapper or direct access. simpler is direct access.
    @AppStorage("preferredAppearanceMode")
    public var currentMode: AppearanceMode = .light // Default to Light as requested
    
    public init() {}
    
    // Helper to apply appearance to a view
    public func apply(to view: NSView) {
        if let appearance = currentMode.nsAppearance {
            view.appearance = appearance
        } else {
            view.appearance = nil // Reset to system
        }
    }
}
