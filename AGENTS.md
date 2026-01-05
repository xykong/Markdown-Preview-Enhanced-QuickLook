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
├── web-renderer/       # Rendering Engine (TypeScript/Webpack) -> See web-renderer/AGENTS.md
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

## ARCHITECTURE & PATTERNS
- **Hybrid Bridge**: Swift loads `index.html`, calls `window.renderMarkdown(content)`. JS logs back via `window.webkit.messageHandlers.logger`.
- **Ephemeral Project**: `.xcodeproj` is ignored. Always use `xcodegen` (`make generate`).
- **Manual Versioning**: `.build_number` file tracked by `scripts/`.
- **Sandbox**: App Sandbox enabled. Read-only access to files.

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
