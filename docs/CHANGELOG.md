# Changelog

## [Unreleased]

### Changed
- **Build System**: Optimized build logs for `make install`, `make app`, and `make generate`. Now uses minimal output mode (warnings & errors only) to reduce terminal noise.
- **Appearance**: Changed default appearance mode to **Light** (previously followed system settings).
- **Appearance Sync**: Implemented "Perfect Dark Mode Sync" to eliminate white flashes and code block theme mismatches.
  - Added adaptive CSS (`highlight-adaptive.css`) for instant code block theme switching.
  - Updated `MarkdownWebView` (Swift) and `web-renderer` (TS) to pass explicit theme parameters for Mermaid.js support.
- **Appearance Sync**: Implemented "Perfect Dark Mode Sync" to eliminate white flashes and code block theme mismatches.
  - Added adaptive CSS (`highlight-adaptive.css`) for instant code block theme switching.
  - Updated `MarkdownWebView` (Swift) and `web-renderer` (TS) to pass explicit theme parameters for Mermaid.js support.
- **Installation**: Updated `install.sh` to build `Release` configuration by default and robustly locate the built application in DerivedData.
- **Host App**: Improved `index.html` resource discovery logic to fallback to multiple directories.

### Fixed
- **Renderer**: Switched from Webpack/Vite chunked build to **Vite SingleFile** build. This fixes the "White Screen" issue in QuickLook by inlining all JS/CSS/Font assets into a single `index.html`, avoiding CORS/file-access restrictions in the Sandbox.
- **Preview Stability**: Enhanced the renderer handshake mechanism.
  - Increased timeout to 10 seconds.
  - Added visible error feedback in the WebView on timeout.
  - Improved race condition handling for WebView navigation events.
- **Build**: Increased Webpack asset size limits to suppress warnings for large bundles (Mermaid/KaTeX/Highlight.js).
- **Stability**: Added auto-reload recovery when WebView WebContent process terminates.
- **Security**: Added missing entitlements (Network Client, JIT, Printing, Downloads) to support WebView features and stability.

### Added
- **Appearance Settings**: Added "View" > "Appearance" menu to switch between Light, Dark, and System modes.
- **Host App Browser**: The main app now functions as a standalone Markdown viewer/editor (Read-Only mode).
  - Supports opening local `.md` files via Finder or File > Open.
  - Implemented `MarkdownWebView` with `baseUrl` injection for resolving local resources.
  - Added support for rendering local images (e.g., `![alt](image.png)`).
  - Implemented navigation handling: External links open in Safari, local `.md` links open in new App windows.
- **Architecture**:
  - Adopted SwiftUI `DocumentGroup` for file management.
  - Updated `web-renderer` to accept `baseUrl` option in `renderMarkdown`.
  - Updated `project.yml` to bundle renderer assets into the Host App.
- **Documentation**:
  - Added `docs/DESIGN_HOST_APP_BROWSER.md`.
  - Added `docs/OPTIMIZATION_ROADMAP.md`: Detailed analysis of performance and UX improvement opportunities.

## [1.0.0] - 2025-12-27

### Added
- Integrated `xcodegen` for automated Xcode project generation.
- Added `Makefile` to orchestrate build and project generation.
- Created `Sources/` directory structure.
- Created Swift Host App (`MarkdownQuickLook`) for the extension.

### Fixed
- Upgraded `mermaid` dependency to v10.0.0+ to support `mermaid.run` API.
- Fixed `markdown-it` highlight configuration to preserve `language-*` classes for code blocks, ensuring Mermaid diagrams are correctly detected and rendered.
- Added Jest test suite for `web-renderer` to verify rendering logic and API calls.
