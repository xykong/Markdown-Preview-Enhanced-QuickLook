# Auto Reload Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make FluxMarkdown automatically re-render when the underlying `.md` file is modified externally, and expose a manual "Reload" button + keyboard shortcut for both the main app and QuickLook extension.

**Architecture:** Fix atomic-save edge cases in `DispatchSourceFileSystemObject` monitoring (rename/delete restarts), add a polling-timer fallback to catch any missed events, wire up a `reloadFile` notification through the existing `NotificationCenter` pattern, add a toolbar button in both surfaces, and register `Cmd+R` as the keyboard shortcut.

**Tech Stack:** Swift, AppKit/SwiftUI, `DispatchSource`, `Timer`, `NotificationCenter`, XCTest

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `Sources/Shared/NotificationNames.swift` | Modify | Add `.reloadFile` notification name |
| `Sources/Markdown/MarkdownWebView.swift` | Modify | Fix file monitor in `Coordinator`; add reload handler; add polling timer |
| `Sources/Markdown/MarkdownApp.swift` | Modify | Add Reload toolbar button; register `Cmd+R` menu command |
| `Sources/MarkdownPreview/PreviewViewController.swift` | Modify | Fix file monitor restart logic; add polling timer; add reload button + `Cmd+R` key handler |
| `Tests/MarkdownTests/FileMonitorTests.swift` | Create | Unit tests for atomic-save and polling fallback logic |

---

## Task 1: Add `reloadFile` notification name

**Files:**
- Modify: `Sources/Shared/NotificationNames.swift`

- [ ] **Step 1: Add the notification name**

Replace the entire file content with:

```swift
import Foundation

extension Notification.Name {
    static let toggleSearch = Notification.Name("toggleSearch")
    static let exportHTML   = Notification.Name("exportHTML")
    static let exportPDF    = Notification.Name("exportPDF")
    static let toggleHelp   = Notification.Name("toggleHelp")
    static let zoomIn       = Notification.Name("zoomIn")
    static let zoomOut      = Notification.Name("zoomOut")
    static let reloadFile   = Notification.Name("reloadFile")
}
```

- [ ] **Step 2: Commit**

```bash
git add Sources/Shared/NotificationNames.swift
git commit -m "feat(shared): add reloadFile notification name"
```

---

## Task 2: Write failing tests for file monitor logic

**Files:**
- Create: `Tests/MarkdownTests/FileMonitorTests.swift`

These tests validate the helper logic that decides whether a file change is real (size or mtime changed) and that polling fires correctly. We test the pure logic — no UI.

- [ ] **Step 1: Create the test file**

```swift
import XCTest
@testable import MarkdownTests   // tests run in the MarkdownTests bundle

// MARK: - FileChangeDecision tests
// These test the static helper we will add to Coordinator (Task 3).

final class FileMonitorTests: XCTestCase {

    // MARK: shouldReload helper

    func testShouldReloadWhenSizeChanges() {
        // size changed → should reload
        XCTAssertTrue(FileMonitorHelpers.shouldReload(
            newSize: 100, newMtime: date(0),
            knownSize: 50, knownMtime: date(0)
        ))
    }

    func testShouldReloadWhenMtimeChanges() {
        // mtime changed → should reload
        XCTAssertTrue(FileMonitorHelpers.shouldReload(
            newSize: 100, newMtime: date(1),
            knownSize: 100, knownMtime: date(0)
        ))
    }

    func testShouldNotReloadWhenUnchanged() {
        // nothing changed → should NOT reload
        XCTAssertFalse(FileMonitorHelpers.shouldReload(
            newSize: 100, newMtime: date(0),
            knownSize: 100, knownMtime: date(0)
        ))
    }

    func testShouldReloadWhenBothChange() {
        XCTAssertTrue(FileMonitorHelpers.shouldReload(
            newSize: 200, newMtime: date(5),
            knownSize: 100, knownMtime: date(0)
        ))
    }

    // MARK: Helpers

    private func date(_ offset: TimeInterval) -> Date {
        Date(timeIntervalSince1970: 1_000_000 + offset)
    }
}
```

- [ ] **Step 2: Run tests to confirm compile failure (helper not yet defined)**

```bash
cd /Users/xykong/workspace/xykong/flux-markdown
make generate
xcodebuild test -scheme Markdown -destination 'platform=macOS' \
  -only-testing:MarkdownTests/FileMonitorTests 2>&1 | tail -20
```

Expected: Build error — `FileMonitorHelpers` not found.

- [ ] **Step 3: Commit the failing test**

```bash
git add Tests/MarkdownTests/FileMonitorTests.swift
git commit -m "test(monitor): add failing tests for FileMonitorHelpers"
```

---

## Task 3: Implement `FileMonitorHelpers` in Shared

**Files:**
- Create: `Sources/Shared/FileMonitorHelpers.swift`

- [ ] **Step 1: Create the helpers file**

```swift
import Foundation

/// Pure-logic helpers for file change detection.
/// Extracted here so they are testable without UI dependencies.
enum FileMonitorHelpers {

    /// Returns `true` if the file metadata indicates the content has changed.
    static func shouldReload(
        newSize: UInt64, newMtime: Date?,
        knownSize: UInt64, knownMtime: Date?
    ) -> Bool {
        newSize != knownSize || newMtime != knownMtime
    }
}
```

- [ ] **Step 2: Run tests to confirm they pass**

```bash
xcodebuild test -scheme Markdown -destination 'platform=macOS' \
  -only-testing:MarkdownTests/FileMonitorTests 2>&1 | tail -20
```

Expected: All 4 tests PASS.

- [ ] **Step 3: Commit**

```bash
git add Sources/Shared/FileMonitorHelpers.swift
git commit -m "feat(shared): add FileMonitorHelpers for testable change detection"
```

---

## Task 4: Fix file monitor in `MarkdownWebView.Coordinator` (main app)

**Files:**
- Modify: `Sources/Markdown/MarkdownWebView.swift` — `Coordinator` class (lines 107–652)

The existing `handleFileChange` method has two issues:
1. On `.rename`, it calls `handleFileChange()` again immediately after `startFileMonitoring()` — but `startFileMonitoring` is async and the file descriptor may not be open yet.
2. The `shouldReload` check duplicates logic we now have in `FileMonitorHelpers`.

We also add:
- A polling `Timer` (every 2 s) as fallback
- A `handleReloadFile` method wired to `.reloadFile` notification

- [ ] **Step 1: Add instance vars for polling timer and reload flag**

Inside `Coordinator`, after the existing `private var lastCodeHighlightTheme` line (≈ line 127), add:

```swift
        private var pollingTimer: Timer?
        private let pollingInterval: TimeInterval = 2.0
```

- [ ] **Step 2: Subscribe to `reloadFile` notification in `init()`**

Inside `Coordinator.init()`, after the last `addObserver` call (≈ line 166), add:

```swift
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleReloadFile),
                name: .reloadFile,
                object: nil
            )
```

- [ ] **Step 3: Add `handleReloadFile` method**

After the existing `handleZoomOut()` method (≈ line 199), add:

```swift
        @objc func handleReloadFile() {
            guard let url = currentFileURL else { return }
            os_log("🔄 Manual reload triggered: %{public}@", log: logger, type: .default, url.lastPathComponent)
            reloadFromDisk(url: url)
        }
```

- [ ] **Step 4: Replace `startFileMonitoring` with the fixed version**

Find the existing `startFileMonitoring()` method (≈ line 569) and replace it entirely with:

```swift
        private func startFileMonitoring() {
            stopFileMonitoring()

            guard let url = currentFileURL else { return }

            let fd = open(url.path, O_EVTONLY)
            guard fd >= 0 else {
                os_log("🔴 Cannot open file for monitoring: %{public}@", log: logger, type: .error, url.path)
                startPollingTimer()   // fall back to polling only
                return
            }
            monitoredFileDescriptor = fd

            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fd,
                eventMask: [.write, .delete, .rename],
                queue: .main
            )

            source.setEventHandler { [weak self] in
                guard let self else { return }
                let flags = source.data
                if flags.contains(.delete) || flags.contains(.rename) {
                    // Atomic-save: file was replaced. Stop old monitor,
                    // wait briefly for the new inode to appear, then restart.
                    os_log("🟡 File replaced/renamed — restarting monitor: %{public}@",
                           log: self.logger, type: .debug, url.path)
                    self.stopDispatchMonitor()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                        guard let self else { return }
                        self.startFileMonitoring()
                        // Read from disk after restarting (new inode is now open)
                        self.reloadFromDisk(url: url)
                    }
                    return
                }
                self.handleFileChange()
            }

            source.setCancelHandler { [weak self] in
                guard let self, self.monitoredFileDescriptor >= 0 else { return }
                close(self.monitoredFileDescriptor)
                self.monitoredFileDescriptor = -1
            }

            source.resume()
            fileMonitor = source
            os_log("🟢 File monitoring started: %{public}@", log: logger, type: .default, url.path)

            startPollingTimer()
        }
```

- [ ] **Step 5: Add `stopDispatchMonitor`, `startPollingTimer`, `stopPollingTimer`, and `reloadFromDisk`**

After `stopFileMonitoring()` (≈ line 602), add:

```swift
        private func stopDispatchMonitor() {
            fileMonitor?.cancel()
            fileMonitor = nil
        }

        private func stopFileMonitoring() {
            stopDispatchMonitor()
            stopPollingTimer()
        }

        private func startPollingTimer() {
            stopPollingTimer()
            pollingTimer = Timer.scheduledTimer(
                withTimeInterval: pollingInterval,
                repeats: true
            ) { [weak self] _ in
                self?.pollFileForChanges()
            }
        }

        private func stopPollingTimer() {
            pollingTimer?.invalidate()
            pollingTimer = nil
        }

        private func pollFileForChanges() {
            guard let url = currentFileURL else { return }
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path) else { return }
            let newSize = attrs[.size] as? UInt64 ?? 0
            let newMtime = attrs[.modificationDate] as? Date
            guard FileMonitorHelpers.shouldReload(
                newSize: newSize, newMtime: newMtime,
                knownSize: lastKnownFileSize, knownMtime: lastKnownFileModificationDate
            ) else { return }
            os_log("🟢 [poll] File changed, re-rendering: %{public}@", log: logger, type: .default, url.path)
            reloadFromDisk(url: url)
        }

        private func reloadFromDisk(url: URL) {
            do {
                let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
                let newSize = attrs[.size] as? UInt64 ?? 0
                let newMtime = attrs[.modificationDate] as? Date
                guard FileMonitorHelpers.shouldReload(
                    newSize: newSize, newMtime: newMtime,
                    knownSize: lastKnownFileSize, knownMtime: lastKnownFileModificationDate
                ) else { return }
                let newContent = try String(contentsOf: url, encoding: .utf8)
                lastKnownFileSize = newSize
                lastKnownFileModificationDate = newMtime
                guard let webView = currentWebView else { return }
                executeRender(
                    webView: webView,
                    content: newContent,
                    fileURL: url,
                    viewMode: lastViewMode,
                    appearanceMode: lastAppearanceMode,
                    baseFontSize: lastBaseFontSize,
                    enableMermaid: lastEnableMermaid,
                    enableKatex: lastEnableKatex,
                    enableEmoji: lastEnableEmoji,
                    codeHighlightTheme: lastCodeHighlightTheme
                )
                os_log("🟢 Reloaded from disk: %{public}@", log: logger, type: .default, url.lastPathComponent)
            } catch {
                os_log("🔴 reloadFromDisk failed: %{public}@", log: logger, type: .error, error.localizedDescription)
            }
        }
```

- [ ] **Step 6: Replace the old `handleFileChange` with a thin wrapper**

Find the existing `handleFileChange()` (≈ line 607) and replace it with:

```swift
        private func handleFileChange() {
            guard let url = currentFileURL else { return }
            reloadFromDisk(url: url)
        }
```

- [ ] **Step 7: Stop polling timer in `deinit`**

The existing `deinit` calls `stopFileMonitoring()` which now also calls `stopPollingTimer()` — no change needed. Verify `deinit` still reads:

```swift
        deinit {
            NotificationCenter.default.removeObserver(self)
            stopFileMonitoring()
        }
```

- [ ] **Step 8: Build to confirm no compile errors**

```bash
make generate && xcodebuild build -scheme Markdown -destination 'platform=macOS' 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 9: Commit**

```bash
git add Sources/Markdown/MarkdownWebView.swift Sources/Shared/FileMonitorHelpers.swift
git commit -m "fix(app): robust file monitor with atomic-save support and polling fallback"
```

---

## Task 5: Add Reload button + `Cmd+R` to main app toolbar

**Files:**
- Modify: `Sources/Markdown/MarkdownApp.swift`

Pattern: all existing action buttons post a `NotificationCenter` notification. Follow the same pattern.

- [ ] **Step 1: Add the Reload button to the toolbar HStack**

In `MarkdownApp.swift`, find the `HStack(spacing: 8)` that holds the toolbar buttons (≈ line 99). Add the reload button **before** the zoom-out button (i.e., as the first item in the HStack, or between zoom controls and help — choosing before zoom-out to keep logical grouping):

```swift
                    Button(action: {
                        NotificationCenter.default.post(name: .reloadFile, object: nil)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.secondary)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(Color.black.opacity(0.1))
                    .clipShape(Circle())
                    .help("Reload File (⌘R)")
```

Insert this block immediately before the existing zoom-out `Button` block.

- [ ] **Step 2: Add `Cmd+R` menu command**

In the `.commands { }` block (≈ line 173), inside `CommandGroup(after: .saveItem)` **before** the Divider, add:

```swift
                Button(action: {
                    NotificationCenter.default.post(name: .reloadFile, object: nil)
                }) {
                    Text(NSLocalizedString("Reload File", comment: "Reload file menu item"))
                }
                .keyboardShortcut("r", modifiers: [.command])
                Divider()
```

So the full `CommandGroup(after: .saveItem)` becomes:

```swift
            CommandGroup(after: .saveItem) {
                Button(action: {
                    NotificationCenter.default.post(name: .reloadFile, object: nil)
                }) {
                    Text(NSLocalizedString("Reload File", comment: "Reload file menu item"))
                }
                .keyboardShortcut("r", modifiers: [.command])
                Divider()
                Button(action: {
                    NotificationCenter.default.post(name: .exportHTML, object: nil)
                }) {
                    Text(NSLocalizedString("Export as HTML…", comment: "Export HTML menu item"))
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                
                Button(action: {
                    NotificationCenter.default.post(name: .exportPDF, object: nil)
                }) {
                    Text(NSLocalizedString("Export as PDF…", comment: "Export PDF menu item"))
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
            }
```

- [ ] **Step 3: Build to confirm no compile errors**

```bash
xcodebuild build -scheme Markdown -destination 'platform=macOS' 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add Sources/Markdown/MarkdownApp.swift
git commit -m "feat(app): add Reload button and Cmd+R shortcut to main app toolbar"
```

---

## Task 6: Fix file monitor in `PreviewViewController` (QuickLook extension)

**Files:**
- Modify: `Sources/MarkdownPreview/PreviewViewController.swift`

Same fixes as Task 4, applied to the QuickLook `PreviewViewController`. The existing `startFileMonitoring` / `handleFileChange` / `stopFileMonitoring` methods live at lines 1456–1505.

- [ ] **Step 1: Add polling timer instance vars**

After line 150 (`private var lastKnownFileModificationDate: Date?`), add:

```swift
    private var pollingTimer: Timer?
    private let pollingInterval: TimeInterval = 2.0
```

- [ ] **Step 2: Replace `startFileMonitoring` with the fixed version**

Find and replace the entire `startFileMonitoring()` method with:

```swift
    private func startFileMonitoring() {
        guard let url = currentURL else {
            os_log("🟡 Cannot start file monitoring: currentURL is nil", log: logger, type: .debug)
            return
        }

        stopFileMonitoring()

        let path = url.path
        let fd = open(path, O_EVTONLY)

        if fd < 0 {
            os_log("🔴 Failed to open file for monitoring, using polling only: %{public}@", log: logger, type: .error, path)
            startPollingTimer()
            return
        }

        monitoredFileDescriptor = fd

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            guard let self else { return }
            let flags = source.data
            if flags.contains(.delete) || flags.contains(.rename) {
                os_log("🟡 File replaced/renamed — restarting monitor: %{public}@",
                       log: self.logger, type: .debug, path)
                self.stopDispatchMonitor()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                    guard let self else { return }
                    self.startFileMonitoring()
                    self.reloadFromDisk()
                }
                return
            }
            self.handleFileChange()
        }

        source.setCancelHandler { [weak self] in
            guard let self, self.monitoredFileDescriptor >= 0 else { return }
            close(self.monitoredFileDescriptor)
            self.monitoredFileDescriptor = -1
        }

        source.resume()
        self.fileMonitor = source
        os_log("🟢 File monitoring started for: %{public}@", log: logger, type: .default, path)

        startPollingTimer()
    }
```

- [ ] **Step 3: Replace `stopFileMonitoring` and add helpers**

Find and replace the existing `stopFileMonitoring()` method, then add the new helpers immediately after it:

```swift
    private func stopDispatchMonitor() {
        fileMonitor?.cancel()
        fileMonitor = nil
    }

    private func stopFileMonitoring() {
        stopDispatchMonitor()
        stopPollingTimer()
    }

    private func startPollingTimer() {
        stopPollingTimer()
        pollingTimer = Timer.scheduledTimer(
            withTimeInterval: pollingInterval,
            repeats: true
        ) { [weak self] _ in
            self?.pollFileForChanges()
        }
    }

    private func stopPollingTimer() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    private func pollFileForChanges() {
        guard let url = currentURL else { return }
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path) else { return }
        let newSize = attrs[.size] as? UInt64 ?? 0
        let newMtime = attrs[.modificationDate] as? Date
        guard FileMonitorHelpers.shouldReload(
            newSize: newSize, newMtime: newMtime,
            knownSize: lastKnownFileSize ?? 0,
            knownMtime: lastKnownFileModificationDate
        ) else { return }
        os_log("🟢 [poll] File changed, reloading: %{public}@", log: logger, type: .default, url.lastPathComponent)
        reloadFromDisk()
    }

    private func reloadFromDisk() {
        guard let url = currentURL else { return }
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
            let newSize = attrs[.size] as? UInt64 ?? 0
            let newMtime = attrs[.modificationDate] as? Date
            guard FileMonitorHelpers.shouldReload(
                newSize: newSize, newMtime: newMtime,
                knownSize: lastKnownFileSize ?? 0,
                knownMtime: lastKnownFileModificationDate
            ) else { return }

            var content: String
            if newSize > maxPreviewSizeBytes {
                let fh = try FileHandle(forReadingFrom: url)
                defer { try? fh.close() }
                let data = fh.readData(ofLength: Int(maxPreviewSizeBytes))
                if var s = String(data: data, encoding: .utf8) {
                    if let last = s.lastIndex(of: "\n") { s = String(s[...last]) }
                    content = s + "\n\n> **Preview truncated.**"
                } else {
                    content = "> **Encoding Error**"
                }
            } else {
                content = try String(contentsOf: url, encoding: .utf8)
            }

            if url.pathExtension.lowercased() == "mmd" {
                content = "```mermaid\n\(content)\n```"
            }

            pendingMarkdown = content
            lastKnownFileSize = newSize
            lastKnownFileModificationDate = newMtime
            if isWebViewLoaded { renderCurrentMode() }
            os_log("🟢 Reloaded from disk: %{public}@", log: logger, type: .default, url.lastPathComponent)
        } catch {
            os_log("🔴 reloadFromDisk failed: %{public}@", log: logger, type: .error, error.localizedDescription)
        }
    }
```

- [ ] **Step 4: Replace `handleFileChange` with thin wrapper**

Find and replace the existing `handleFileChange()`:

```swift
    private func handleFileChange() {
        reloadFromDisk()
    }
```

- [ ] **Step 5: Stop polling timer in `viewWillDisappear` and `deinit`**

`stopFileMonitoring()` already calls `stopPollingTimer()`, and both `viewWillDisappear` and `deinit` already call `stopFileMonitoring()`. No additional changes needed — verify by searching for `stopFileMonitoring` calls (should be at lines ≈421, 488).

- [ ] **Step 6: Build to confirm no compile errors**

```bash
xcodebuild build -scheme Markdown -destination 'platform=macOS' 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 7: Commit**

```bash
git add Sources/MarkdownPreview/PreviewViewController.swift
git commit -m "fix(quicklook): robust file monitor with atomic-save support and polling fallback"
```

---

## Task 7: Add Reload button + `Cmd+R` to QuickLook extension toolbar

**Files:**
- Modify: `Sources/MarkdownPreview/PreviewViewController.swift`

Pattern: all existing toolbar buttons are `NSButton` instances set up in `setup*Button()` methods, positioned using Auto Layout relative to the previous button. The rightmost button is `themeButton` (top-right corner). New buttons attach to the left of existing ones.

- [ ] **Step 1: Add `reloadButton` property**

After the existing `private var zoomOutButton: NSButton!` declaration (≈ line 234), add:

```swift
    private var reloadButton: NSButton!
```

- [ ] **Step 2: Add `setupReloadButton()` method**

After the `setupZoomOutButton()` method (≈ line 702), add:

```swift
    private func setupReloadButton() {
        let button = NSButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .circular
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.1).cgColor
        button.layer?.cornerRadius = 15
        button.target = self
        button.action = #selector(reloadFileManually)
        button.toolTip = "Reload File (⌘R)"

        if let image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "Reload File") {
            button.image = image
            button.contentTintColor = NSColor.darkGray
        }

        self.view.addSubview(button)
        self.reloadButton = button

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 10),
            button.trailingAnchor.constraint(equalTo: zoomOutButton.leadingAnchor, constant: -8),
            button.widthAnchor.constraint(equalToConstant: 30),
            button.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
```

- [ ] **Step 3: Add `reloadFileManually` action**

After `resetZoom()` (≈ line 795), add:

```swift
    @objc private func reloadFileManually() {
        os_log("🔄 Manual reload triggered by button/shortcut", log: logger, type: .default)
        // Force reload by clearing cached metadata so reloadFromDisk proceeds
        lastKnownFileSize = nil
        lastKnownFileModificationDate = nil
        reloadFromDisk()
    }
```

- [ ] **Step 4: Call `setupReloadButton()` in `viewDidLoad`**

In `viewDidLoad`, find the block that calls the other setup methods (≈ line 328–333):

```swift
        setupThemeButton()
        setupSourceButton()
        setupHelpButton()
        setupZoomInButton()
        setupZoomOutButton()
        setupVersionLabel()
```

Add `setupReloadButton()` between `setupZoomOutButton()` and `setupVersionLabel()`:

```swift
        setupThemeButton()
        setupSourceButton()
        setupHelpButton()
        setupZoomInButton()
        setupZoomOutButton()
        setupReloadButton()
        setupVersionLabel()
```

- [ ] **Step 5: Fix `setupVersionLabel` anchor — it currently anchors to `zoomOutButton`**

In `setupVersionLabel()`, find:

```swift
            label.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -72)
```

The `-72` offset was chosen to leave room for buttons to its right. Now there's one more button (reloadButton) so we need to anchor the label to `reloadButton.leadingAnchor` instead:

```swift
            label.trailingAnchor.constraint(equalTo: reloadButton.leadingAnchor, constant: -8)
```

- [ ] **Step 6: Register `Cmd+R` in `handleKeyDownEvent`**

Find `handleKeyDownEvent` (≈ line 797). Inside the `if flags == .command { switch ... }` block, add a case for `"r"`:

```swift
            case "r", "R":
                os_log("🔵 Reload File triggered", log: logger, type: .default)
                reloadFileManually()
                return nil
```

The full switch should then look like:

```swift
        if flags == .command {
            switch event.charactersIgnoringModifiers {
            case "+", "=":
                zoomIn()
                return nil
            case "-", "_":
                zoomOut()
                return nil
            case "0":
                resetZoom()
                return nil
            case "r", "R":
                reloadFileManually()
                return nil
            default:
                break
            }
        }
```

- [ ] **Step 7: Build to confirm no compile errors**

```bash
xcodebuild build -scheme Markdown -destination 'platform=macOS' 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 8: Commit**

```bash
git add Sources/MarkdownPreview/PreviewViewController.swift
git commit -m "feat(quicklook): add Reload button and Cmd+R shortcut to QuickLook toolbar"
```

---

## Task 8: Run all tests

- [ ] **Step 1: Run full test suite**

```bash
xcodebuild test -scheme Markdown -destination 'platform=macOS' 2>&1 | grep -E "Test (Suite|Case|Passed|Failed)|error:|BUILD"
```

Expected: All tests pass including `FileMonitorTests`.

- [ ] **Step 2: Manual smoke test — main app**

1. Open a `.md` file in FluxMarkdown.app
2. Modify the file in an external editor (e.g., `echo "\n\n## Auto-reload test" >> <file>`)
3. Observe that the preview updates within 2 seconds without any user action
4. Press `Cmd+R` — confirm preview refreshes
5. Click the `↺` (arrow.clockwise) toolbar button — confirm preview refreshes

- [ ] **Step 3: Manual smoke test — QuickLook**

1. Select a `.md` file in Finder and press Space
2. Modify the file externally
3. Observe that the QuickLook preview updates within 2 seconds
4. Press `Cmd+R` in the QuickLook window — confirm refresh
5. Click the `↺` button in the QuickLook toolbar — confirm refresh

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: verify auto-reload and manual reload work end-to-end (issue #17)"
```
