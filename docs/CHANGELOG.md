# Changelog

## [Unreleased]

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
