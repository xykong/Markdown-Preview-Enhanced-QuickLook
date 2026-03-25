# Bug: Percent-Encoded Filenames Break Link Navigation

## Symptom

In the main app, clicking a markdown link to a file whose name contains spaces fails silently — the target file does not open.

Example markdown:

```markdown
[Open notes](my%20notes.md)
[Open notes](my notes.md)
```

Both produce `href="my%20notes.md"` in rendered HTML (markdown-it percent-encodes spaces in link targets). Clicking either link results in no file opening.

## Root Cause

`MarkdownWebView.Coordinator.handleLinkClick(href:)` built the target path by splitting `hrefPath` on `/` and calling `appendPathComponent(_:)` for each segment:

```swift
for component in hrefPath.split(separator: "/") {
    let componentStr = String(component)
    if componentStr == ".." {
        targetURL.deleteLastPathComponent()
    } else if componentStr != "." {
        targetURL.appendPathComponent(componentStr)   // BUG: componentStr still contains %20
    }
}
```

`appendPathComponent` treats the string as a literal filesystem segment. It does **not** percent-decode. So `appendPathComponent("my%20notes.md")` creates the path `/…/my%20notes.md` (with literal `%20`), which does not exist on the filesystem.

`NSWorkspace.shared.open(targetURL)` then fails silently — no error, no opened window.

## Fix

Extract the URL resolution logic into `LinkNavigation` (a new `enum` in `Sources/Shared/LinkNavigation.swift`) with a `resolveLocalURL(href:relativeTo:)` static method.

The fix is a single call before path processing:

```swift
let decoded = href.removingPercentEncoding ?? href
```

`String.removingPercentEncoding` decodes all percent-encoded sequences (`%20` → ` `, `%E8%AE%BE` → `设`, etc.) before the path is split and resolved. All subsequent `appendPathComponent` calls operate on clean filesystem names.

## Files Changed

| File | Change |
|------|--------|
| `Sources/Shared/LinkNavigation.swift` | New file: `enum LinkNavigation` with `resolveLocalURL` and `resolveLocalURLWithFragment` static methods |
| `Sources/Markdown/MarkdownWebView.swift` | `handleLinkClick` now delegates to `LinkNavigation.resolveLocalURLWithFragment` |
| `Tests/MarkdownTests/LinkNavigationTests.swift` | New: 14 test cases covering the regression and all href variants |

## Test Cases Added

- `testResolvesPercentEncodedSpacesInRelativeHref` — core regression: `file%20with%20spaces.md` → `/…/file with spaces.md`
- `testResolvesPercentEncodedSpacesInDirectoryComponent` — `my%20folder/notes.md` → `/…/my folder/notes.md`
- `testResolvesMultiplePercentEncodedCharacters` — `file%20name%20%28version%201%29.md` → `/…/file name (version 1).md`
- `testResolvesChineseChracterInPercentEncodedHref` — `%E8%AE%BE…` → `/…/设计文档.md`
- `testExtractsFragmentFromPercentEncodedHref` — `my%20notes.md#introduction` splits correctly
- Plus path resolution cases: plain, `./`, `../`, absolute, `file://`, empty, pure anchor

## TDD Cycle

**Red**: Tests written against `LinkNavigation.resolveLocalURL` before the implementation existed. All 14 failed with "type has no member" until the fix was added.

**Green**: `LinkNavigation.swift` implemented with `removingPercentEncoding`. All 14 tests passed.

**Refactor**: The original inline path-building logic in `handleLinkClick` replaced with a single call to `LinkNavigation.resolveLocalURLWithFragment`, making `handleLinkClick` 12 lines instead of 32.
