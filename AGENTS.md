# PROJECT KNOWLEDGE BASE

**Generated:** 2026-01-05
**Context:** Hybrid macOS QuickLook Extension (Swift + TypeScript)

## OVERVIEW
macOS QuickLook extension for Markdown files. Hybrid architecture: Native Swift app hosts a `WKWebView` which runs a bundled TypeScript rendering engine.

## STRUCTURE
```
.
├── Makefile            # Main build orchestrator (npm + xcodegen + xcodebuild)
├── project.yml         # XcodeGen config (Generates .xcodeproj - DO NOT EDIT PROJECT DIRECTLY)
├── Sources/
│   ├── Markdown/       # Host App (SwiftUI) - Container for extension
│   └── MarkdownPreview/# Extension (AppKit) - WKWebView, QLPreviewingController
├── web-renderer/       # Rendering Engine (TypeScript/Vite) -> See web-renderer/AGENTS.md
└── scripts/            # Versioning and packaging scripts
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Project Config** | `project.yml` | Add files/targets here. Run `make generate` to apply. |
| **Build Logic** | `Makefile` | `make all` builds everything. |
| **Extension Logic** | `Sources/MarkdownPreview/PreviewViewController.swift` | Lifecycle, File I/O, JS Bridge. |
| **Host UI** | `Sources/Markdown/MarkdownApp.swift` | Minimal SwiftUI container. |
| **Rendering** | `web-renderer/src/index.ts` | Markdown parsing (see subdir AGENTS.md). |
| **Rules** | `.clinerules` | TDD & Doc-first requirements. |
| **Homebrew Cask** | `../homebrew-tap/Casks/markdown-preview-enhanced.rb` | Update version & SHA256 after each release. |

## ARCHITECTURE & PATTERNS
- **Hybrid Bridge**: Swift loads `index.html`, calls `window.renderMarkdown(content)`. JS logs back via `window.webkit.messageHandlers.logger`.
- **Ephemeral Project**: `.xcodeproj` is ignored. Always use `xcodegen` (`make generate`).
- **Versioning**: `.version` file stores base version (e.g., `1.2`). Full version = `{base}.{git_commit_count}`.
- **Sandbox**: App Sandbox enabled. Read-only access to files.
- **Release Flow**: `make release [major|minor|patch]` → Updates `.version`, `CHANGELOG.md`, builds DMG, creates GitHub release.
- **Homebrew Distribution**: After release, manually update `../homebrew-tap/Casks/markdown-preview-enhanced.rb` with new version & SHA256.

## CONVENTIONS
- **TDD**: Write tests/metrics *before* implementation (see `.clinerules`).
- **Docs**: Create `docs/DEBUG_*.md` for hard problems.
- **Logs**: Use `os_log` via the JS bridge. Do not rely on `console.log` alone.

## ANTI-PATTERNS
- **Never commit .xcodeproj**: It is generated.
- **No manual build numbers**: Use `make` or scripts.
- **Do not edit `dist/`**: It is a build artifact of `web-renderer`.

## COMMANDS
```bash
make generate       # Generate Xcode project from project.yml
make build_renderer # Build TypeScript engine (npm install && build)
make app            # Build macOS app
./install.sh        # Build & install locally (clears QL cache)
./debug-extension.sh# Stream logs
```
