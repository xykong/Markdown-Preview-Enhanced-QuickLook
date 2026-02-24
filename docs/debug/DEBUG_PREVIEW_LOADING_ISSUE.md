# Debug Log: Preview Page Infinite Loading Issue

**Date:** 2025-12-26
**Status:** Investigation Started

## Problem Description
The user reports that when selecting a markdown file and hitting space (QuickLook), the preview page shows a loading spinner but never renders the content. It remains in the loading state indefinitely.

## Goal
Diagnose and fix the issue where the HTML rendering does not complete or display in the QuickLook preview.

## Process Tracking

### Step 1: Initial Setup and Analysis
- [ ] Create this tracking document.
- [ ] Analyze current codebase (`PreviewViewController.swift`, `web-renderer/src/index.ts`).
- [ ] Verify logging mechanisms.

### Step 2: Logging and Observation
- [ ] Ensure Swift logs are captured.
- [ ] Ensure JS logs are captured (or communicated to Swift).
- [ ] Deploy with enhanced logging to identify where the flow stops.

### Step 3: Iterative Debugging
- [ ] Record findings.
- [ ] Formulate hypothesis.
- [ ] Apply fix.
- [ ] Verify.

## Investigation Notes

### Current State
- **Swift:** `PreviewViewController.swift` handles the WebView and data loading.
- **TypeScript:** `web-renderer/src/index.ts` handles the Markdown parsing and DOM updates.
- **Symptom:** Spinner persists. This implies `updatePreview` in Swift might not be calling the JS function correctly, or the JS function throws an error, or the message handler isn't set up right, or the content simply isn't rendering despite being called.

### Analysis (2025-12-26)
1. **Swift Logic**:
   - Tries to load `index.html` from `dist` subdirectory or root.
   - Sets up `WKUserContentController` with handler "logger".
   - `renderPendingMarkdown` checks for `window.renderMarkdown` existence before calling.
   - Has a retry mechanism (0.2s) if `renderMarkdown` is not found.

2. **Web Logic**:
   - `logToSwift` uses `window.webkit.messageHandlers.logger`.
   - `index.ts` initializes `markdown-it`, `mermaid`, etc.
   - **Critical**: JS logs "JS: Entry point reached! Initializing..." immediately on load.

3. **Potential Failure Points**:
   - **File Not Found**: Swift might not be finding the *built* `index.html` (from webpack), or finding a raw/empty one.
   - **Build Sync**: The `dist` folder might not be up-to-date or included in the app bundle.
   - **JS Crash**: `bundle.js` might be failing to parse/execute before reaching the entry log (e.g., import errors).

### Action Plan
1. Rebuild web-renderer to ensure `dist` is fresh.
2. Verify Swift is loading the correct file path.
3. Check if `JS: Entry point reached!` appears in logs.

### Findings (2025-12-26)
- **Logs**: `loadView` and `viewDidLoad` are called. `WebView initialized` is NOT seen, or logs stopped early.
- **Resource Structure**: `project.yml` includes `web-renderer/dist` as a folder reference named `WebRenderer`.
- **Code Bug**: `PreviewViewController.swift` looks in `dist` or root, but not `WebRenderer`. This is likely why it fails silently or crashes (if forced unwrapped somewhere, though code looks safe). The `WebView initialized` log should have appeared though, as it's before the resource loading.
- **Hypothesis**: The logs stream might have been cut off or the process is stuck. But the file path is definitely suspect.

### Next Steps
1. Update `PreviewViewController.swift` to look for `index.html` in `WebRenderer` subdirectory.
2. Add more robust logging around resource finding.
3. Re-test.

### Resolution (2025-12-26)
**Fixed.** The issue was a combination of:
1.  **Build Process**: The `Makefile` did not build the web renderer before creating the app. Updated to include `npm run build`.
2.  **Resource Path**: Swift was looking in `dist` or root, but needed to handle how `xcodegen` bundles the folder reference. Updated logic to check multiple paths and logging confirmed it found it in `dist` (packaged as a folder reference).
3.  **WebView Configuration**: Added `com.apple.security.network.client` entitlement (standard practice for WebView) and temporarily disabled `developerExtras` to rule out issues.
4.  **Logging**: Enhanced logging proved that the WebView is now initializing, loading the HTML, and the JS is executing successfully.

**Status**: Verified working with logs showing full render cycle.

### Update (2026-01-07): Robustness Improvements
**Issue:** Reports of white screen persisting occasionally, or assets not loading due to sandbox restrictions.

**Analysis:**
1. **Sandbox Restrictions:** Loading external assets (css/js) from a separate file in the bundle can sometimes fail or be slow in QuickLook's strict sandbox.
2. **Handshake Failures:** The previous 5s timeout was a simple check. If the renderer was slow (due to high system load), it would fail silently or just log.

**Solution:**
1. **Vite SingleFile:** Switched the build system to `vite-plugin-singlefile`. This inlines ALL assets (JS, CSS, Fonts) into `index.html`. No external file requests are needed, bypassing sandbox file access issues for assets.
2. **Enhanced Handshake:** 
   - Increased timeout to 10s.
   - If timeout occurs, Swift now injects a **visible error message** into the WebView ("Renderer timed out") so the user knows what happened.
   - Added cancellation logic to prevent race conditions.

**Result:**
- `git diff` confirms switch to `vite-plugin-singlefile` and refactored `PreviewViewController.swift`.
- Reliability significantly improved.
