<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

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
| **Release Process** | `docs/release/RELEASE_PROCESS.md` | Complete PR handling and release workflow. |
| **Homebrew Cask** | `../homebrew-tap/Casks/flux-markdown.rb` | Update version & SHA256 after each release. |

## ARCHITECTURE & PATTERNS
- **Hybrid Bridge**: Swift loads `index.html`, calls `window.renderMarkdown(content)`. JS logs back via `window.webkit.messageHandlers.logger`.
- **Ephemeral Project**: `.xcodeproj` is ignored. Always use `xcodegen` (`make generate`).
- **Versioning**: `.version` file stores full version (e.g., `1.13.149`). Build number (third part) aligns with git commit count.
- **Sandbox**: App Sandbox enabled. Read-only access to files.
- **Release Flow**: 
  1. **PR Merged**: Run `./scripts/analyze-pr.sh <PR_NUMBER>` to generate CHANGELOG entry, add to `[Unreleased]` section.
  2. **Release**: Run `make release [major|minor|patch]` → Updates `.version`, `CHANGELOG.md`, builds DMG, creates GitHub release.
  3. **Homebrew**: Run `./scripts/update-homebrew-cask.sh <VERSION>` to update Homebrew Cask automatically.
  4. See `docs/release/RELEASE_PROCESS.md` for complete workflow.
- **Homebrew Distribution**: After release, run `./scripts/update-homebrew-cask.sh <VERSION>` or manually update `../homebrew-tap/Casks/flux-markdown.rb`.

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
make generate                    # Generate Xcode project from project.yml
make build_renderer              # Build TypeScript engine (npm install && build)
make app                         # Build macOS app
make release [major|minor|patch] # Release new version
./install.sh                     # Build & install locally (clears QL cache)
log stream --predicate 'subsystem == "com.markdownquicklook.app"' --level debug
./scripts/analyze-pr.sh <PR_NUM> # Analyze PR and generate CHANGELOG entry
./scripts/update-homebrew-cask.sh <VERSION> # Update Homebrew Cask
```
