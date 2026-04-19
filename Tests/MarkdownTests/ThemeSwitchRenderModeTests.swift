import XCTest

@MainActor
final class ThemeSwitchRenderModeTests: XCTestCase {

    private func resolveThemeJS(
        currentContent: String,
        previousContent: String,
        appearanceMode: AppearanceMode,
        viewMode: ViewMode = .preview
    ) -> String {
        let onlyThemeChanged = (currentContent == previousContent) && (viewMode == .preview)
        if onlyThemeChanged {
            let theme: String
            switch appearanceMode {
            case .dark:   theme = "dark"
            case .light:  theme = "light"
            case .system: theme = "system"
            }
            return "window.updateTheme('\(theme)');"
        } else {
            return "window.renderMarkdown(...);"
        }
    }

    func testThemeOnlyChange_callsUpdateTheme_lightToDark() {
        let js = resolveThemeJS(currentContent: "# Hello", previousContent: "# Hello", appearanceMode: .dark)
        XCTAssertTrue(js.contains("updateTheme"))
        XCTAssertFalse(js.contains("renderMarkdown"))
    }

    func testThemeOnlyChange_callsUpdateTheme_darkToLight() {
        let js = resolveThemeJS(currentContent: "# Hello", previousContent: "# Hello", appearanceMode: .light)
        XCTAssertTrue(js.contains("updateTheme"))
        XCTAssertFalse(js.contains("renderMarkdown"))
    }

    func testThemeOnlyChange_callsUpdateTheme_system() {
        let js = resolveThemeJS(currentContent: "# Hello", previousContent: "# Hello", appearanceMode: .system)
        XCTAssertTrue(js.contains("updateTheme"))
        XCTAssertFalse(js.contains("renderMarkdown"))
    }

    func testContentChange_callsFullRenderMarkdown() {
        let js = resolveThemeJS(currentContent: "# New", previousContent: "# Old", appearanceMode: .dark)
        XCTAssertTrue(js.contains("renderMarkdown"))
        XCTAssertFalse(js.contains("updateTheme"))
    }

    func testSourceViewMode_alwaysFullRender() {
        let js = resolveThemeJS(currentContent: "# Hello", previousContent: "# Hello", appearanceMode: .dark, viewMode: .source)
        XCTAssertFalse(js.contains("updateTheme"))
    }

    func testUpdateTheme_passesDarkTheme() {
        let js = resolveThemeJS(currentContent: "# Hello", previousContent: "# Hello", appearanceMode: .dark)
        XCTAssertTrue(js.contains("'dark'"))
    }

    func testUpdateTheme_passesLightTheme() {
        let js = resolveThemeJS(currentContent: "# Hello", previousContent: "# Hello", appearanceMode: .light)
        XCTAssertTrue(js.contains("'light'"))
    }

    func testUpdateTheme_passesSystemTheme() {
        let js = resolveThemeJS(currentContent: "# Hello", previousContent: "# Hello", appearanceMode: .system)
        XCTAssertTrue(js.contains("'system'"))
    }

    func testFirstLoad_noHistory_callsFullRender() {
        let js = resolveThemeJS(currentContent: "# Hello", previousContent: "", appearanceMode: .dark)
        XCTAssertTrue(js.contains("renderMarkdown"))
    }
}
