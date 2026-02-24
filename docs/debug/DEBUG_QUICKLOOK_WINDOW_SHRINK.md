# Debugging QuickLook Window Shrink Bug

## Overview

This guide helps reproduce and diagnose the intermittent QuickLook window shrink bug that occurs in multi-monitor setups, particularly when moving Finder focus between displays.

## Bug Description

QuickLook preview windows can shrink to a tiny size and persist that size, requiring manual resizing. This is most reproducible with:
- Multi-monitor setup (2+ displays)
- Moving Finder focus between displays
- Opening/closing QuickLook repeatedly
- Resizing via corner drag

## Reproduction Matrix

### Setup Requirements
1. **Multi-monitor setup**: Connect 2+ displays to your Mac
2. **Display configuration**: 
   - Different resolutions (e.g., 4K + 1080p) increases likelihood
   - Different scale factors (Retina vs non-Retina) increases likelihood
3. **QuickLook installed**: Debug build with logging enabled

### Test Cases

| Test Case | Steps | Expected Behavior | Bug Indicator |
|-----------|-------|-------------------|---------------|
| **Focus Move** | 1. Open QuickLook on Display A<br>2. Click Finder on Display B<br>3. Click back to QuickLook<br>4. Close and reopen | Window size remains consistent | Window shrinks after focus move |
| **Display Switch** | 1. Open QuickLook on Display A<br>2. Drag window to Display B<br>3. Close and reopen | Window adapts to Display B | Window shrinks during transition |
| **Corner Resize** | 1. Open QuickLook<br>2. Resize via corner drag<br>3. Close and reopen | Saved size persists | Window reverts to tiny size |
| **Rapid Open/Close** | 1. Open QuickLook<br>2. Immediately close<br>3. Repeat 5-10x | Size remains stable | Size progressively shrinks |
| **Mixed Operations** | 1. Open on Display A<br>2. Resize<br>3. Move to Display B<br>4. Close and reopen | Final size persists | Size corrupted by display switch |

### Reproduction Script

```bash
# 1. Build and install Debug version
cd /Users/happyelements/Documents/git/markdown-quicklook
./scripts/install.sh Debug true

# 2. Clear QuickLook cache
qlmanage -r
qlmanage -r cache

# 3. Start log collection
./scripts/collect-quicklook-window-logs.sh

# 4. Follow the on-screen instructions to reproduce the bug
#    The script will save logs to a timestamped file
```

## Log Collection

### Start Collecting Logs

```bash
# Start with default settings (writes to /tmp)
./scripts/collect-quicklook-window-logs.sh

# Or specify custom output directory
./scripts/collect-quicklook-window-logs.sh --output ./logs

# Show help
./scripts/collect-quicklook-window-logs.sh --help
```

### What to Look For in Logs

The DEBUG build logs these key events:

#### 1. Screen Environment Changes
```
📊 [didChangeScreen] Window changed screen
📊 [didChangeBackingProperties] Window backing properties changed
📊 [applicationDidChangeScreenParameters] App-wide screen parameters changed
```

**What it means**: Window moved between displays or display configuration changed.

#### 2. User Resize Events
```
📊 [windowWillStartLiveResize] Window starting live resize
📊 [windowDidEndLiveResize] Saving size: WxH
```

**What it means**: User actively resized the window.

#### 3. Size Persistence
```
📊 [windowDidEndLiveResize] Saving size: WxH
📊 [viewWillDisappear] Saving final size after user resize: WxH
📊 [viewWillDisappear] Skipping save - no user resize detected
```

**What it means**: Size being saved to UserDefaults.

#### 4. Layout Events
```
📊 [viewDidLayout] size=WxH trackingEnabled=true/false
📊 [viewDidLayout] SKIPPED - tracking disabled
📊 [viewDidLayout] SKIPPED - size too small
```

**What it means**: View layout passes (may be transient).

### Analyzing Logs

#### 5-Step Log Analysis

1. **Identify the sequence**: Look for the pattern of events leading up to the shrink
2. **Check screen changes**: Note when `didChangeScreen` or `applicationDidChangeScreenParameters` occurs
3. **Verify resize intent**: Confirm `windowDidEndLiveResize` only happens after user resize
4. **Check persistence**: Verify `quickLookSize` is only written at `windowDidEndLiveResize`
5. **Look for transient saves**: Search for any saves outside of user resize events

#### Log Analysis Commands

```bash
# Find all screen change events
grep "didChangeScreen\|applicationDidChangeScreenParameters" /tmp/quicklook-logs-*.log

# Find all resize events
grep "windowDidEndLiveResize\|windowWillStartLiveResize" /tmp/quicklook-logs-*.log

# Find all persistence writes
grep "Saving size\|Saving final size" /tmp/quicklook-logs-*.log

# Find viewDidLayout skips
grep "viewDidLayout.*SKIPPED" /tmp/quicklook-logs-*.log

# Extract screen environment dumps
grep -A 20 "SCREEN ENVIRONMENT" /tmp/quicklook-logs-*.log
```

## How to Tell If the Fix Works

### Expected Behavior (Fixed)

1. **Size only saved on user resize end**
   - `quickLookSize` should ONLY be written in `windowDidEndLiveResize`
   - No saves should occur from `viewDidLayout` or `viewWillDisappear` unless user resized

2. **Transient events don't persist**
   - Screen changes, backing property changes, focus moves should NOT trigger saves
   - Look for "Skipping save - no user resize detected" in logs

3. **No size corruption**
    - Saved size should always be ≥ 320x240
    - Size should not shrink below usable dimensions
    - Bad persisted sizes (e.g., from previous bugs) are auto-cleared on next preview

### Log Indicators of Working Fix

```bash
# Good: Only saves at resize end
grep "Saving size" logs | grep "windowDidEndLiveResize"

# Good: Skips saves on non-resize events
grep "Skipping save - no user resize detected" logs

# Bad: Any save from viewDidLayout (should not happen)
grep "viewDidLayout.*Saving" logs

# Bad: Saves from viewWillDisappear without user resize
grep "viewWillDisappear.*Saving" logs | grep -v "after user resize"
```

## Technical Details

### Root Cause

The bug occurs when:
1. QuickLook host temporarily resizes the view during display/focus transitions
2. This transient size gets persisted to UserDefaults
3. On next open, the corrupted small size is restored

### Fix Implementation

The fix ensures size is only saved when:
- User explicitly resizes the window (detected via `NSWindow.didEndLiveResizeNotification`)
- A durable flag `didUserResizeSinceOpen` tracks user resize intent
- Transient layout events are ignored

### Key Code Locations

- **Resize tracking**: `PreviewViewController.swift:800-816`
- **Size persistence**: `PreviewViewController.swift:815`
- **Screen environment logging**: `PreviewViewController.swift:84-148`

## Troubleshooting

### Logs Not Appearing

1. **Verify Debug build**: Ensure you built with `./scripts/install.sh Debug true`
2. **Check log predicate**: Ensure predicate matches `com.markdownquicklook.app`
3. **Restart log stream**: Stop and restart the log collection script
4. **Clear QL cache**: Run `qlmanage -r` and `qlmanage -r cache`

### Bug Not Reproducible

1. **Increase display diversity**: Use different resolutions/scale factors
2. **More aggressive testing**: Increase open/close frequency
3. **Check timing**: Bug may be timing-dependent; try at different system loads

### Logs Too Noisy

Filter by specific categories:
```bash
# Only screen events
log stream --predicate 'subsystem contains "com.markdownquicklook.app" AND message contains "SCREEN ENVIRONMENT"' --level debug

# Only resize events
log stream --predicate 'subsystem contains "com.markdownquicklook.app" AND (message contains "LiveResize" OR message contains "Saving size")' --level debug
```

## Additional Resources

- **Decisions log**: `.sisyphus/notepads/quicklook-window-shrink/decisions.md`
- **Issues log**: `.sisyphus/notepads/quicklook-window-shrink/issues.md`
- **Main code**: `Sources/MarkdownPreview/PreviewViewController.swift`
