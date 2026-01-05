# Changelog

## [Unreleased]

### Added
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
