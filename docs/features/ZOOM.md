# Zoom Feature

## Quick Start

### How to Use

#### In QuickLook Preview (Select .md file → Press Space)

**Method 1: Mouse Wheel Zoom (RECOMMENDED)**
```
Hold CMD + Scroll Up/Down
```
- Most reliable method
- Works like other Mac apps (Safari, Preview, etc.)

**Method 2: Pinch Gesture**
```
Two-finger pinch on trackpad
```
- Natural gesture for macOS users
- Zoom in (pinch out) / Zoom out (pinch in)

**Method 3: Keyboard Shortcuts**
```
CMD + '+'  or  CMD + '='    → Zoom In
CMD + '-'                    → Zoom Out
CMD + '0'                    → Reset to 100%
```
- May work depending on system configuration
- Click inside preview window first

#### In Host App (Double-click .md file to open)

All methods work:
- ✅ CMD + '+'/'-'/'0'
- ✅ CMD + Scroll Wheel
- ✅ Pinch Gesture

## Features

- **Zoom Range**: 0.5x to 3.0x with 0.1 increments
- **Persistent**: Zoom level is saved and restored across sessions
- **Smooth Scaling**: CSS transform for high-quality rendering
- **Multiple Input Methods**: Keyboard, mouse wheel, and trackpad gestures

## Implementation Overview

### Architecture

The zoom functionality is implemented using a hybrid approach:

1. **Web Renderer (TypeScript)**: Primary zoom handling for responsiveness
2. **Swift Integration**: Event capture and preferences storage
3. **CSS Transform**: Smooth visual scaling

### Key Components

#### 1. Web Renderer (`web-renderer/src/index.ts`)

The zoom functionality is primarily handled in the web renderer:

```typescript
// Keyboard event listener in the web page
document.addEventListener('keydown', (e: KeyboardEvent) => {
    if (e.metaKey || e.ctrlKey) {
        if (e.key === '+' || e.key === '=') {
            // Zoom in
        } else if (e.key === '-' || e.key === '_') {
            // Zoom out
        } else if (e.key === '0') {
            // Reset zoom
        }
    }
});
```

CSS transform is used for smooth zooming:
```typescript
outputDiv.style.transform = `scale(${level})`;
outputDiv.style.transformOrigin = 'top left';
outputDiv.style.width = `${100 / level}%`;
```

#### 2. Swift Integration (`Sources/MarkdownPreview/PreviewViewController.swift`)

Enhanced `InteractiveWebView` to accept keyboard focus and handle events:

```swift
class InteractiveWebView: WKWebView {
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func scrollWheel(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            // CMD + scroll wheel = zoom
        }
    }
}
```

#### 3. Preferences Storage (`Sources/Shared/AppearancePreference.swift`)

Persistent storage for zoom level:

```swift
public var zoomLevel: Double {
    get {
        let level = store.double(forKey: zoomLevelKey)
        return level == 0 ? 1.0 : level
    }
    set {
        store.set(newValue, forKey: zoomLevelKey)
        store.synchronize()
    }
}
```

### Event Handling Layers

Multiple event capture mechanisms ensure reliability:

1. **NSEvent Local Monitor**: Captures keyboard events at application level (works in Host App)
2. **performKeyEquivalent**: Intercepts CMD combinations before system processing
3. **keyDown Override**: Standard keyboard event handling
4. **JavaScript Keyboard Events**: Direct event handling in web page
5. **scrollWheel Override**: CMD + scroll wheel zoom handling
6. **Pinch Gesture**: Trackpad pinch-to-zoom support

### Event Flow

1. User performs zoom action (keyboard/scroll/gesture)
2. Event is captured by appropriate handler
3. Zoom level is calculated and validated (0.5x - 3.0x range)
4. CSS transform is applied to content
5. Zoom level is logged back to Swift via message handler
6. Swift saves the zoom level to UserDefaults for persistence

## Testing

### Quick Test

```bash
open -a Finder Tests/fixtures/zoom-test.md
# Select file and press Space
# Try: Hold CMD + Scroll, Pinch, or CMD + '+'
```

### Debug Mode

Stream logs to see real-time output:

```bash
log stream --predicate 'subsystem == "com.markdownquicklook.app"' --level debug
```

This will:
1. Open the test file in QuickLook
2. Start monitoring logs for keyboard and zoom events
3. Show real-time log output

Look for these log messages:
- `performKeyEquivalent called` - Event intercepted before system
- `handleKeyDownEvent` - Event being processed
- `Zoom In/Out/Reset triggered` - Zoom function executed
- `WebView scrollWheel with CMD` - Scroll zoom triggered
- `Zoom level set to X` - JavaScript applied the zoom

### Expected Behavior

**In Host App** (works perfectly):
- All keyboard shortcuts work
- Mouse wheel zoom works
- Pinch gesture works
- Zoom persists across sessions

**In QuickLook Preview** (partial):
- Keyboard shortcuts may be intercepted by system
- Mouse wheel zoom works reliably
- Pinch gesture works
- Zoom persists across sessions

## Troubleshooting

### Keyboard shortcuts not working in QuickLook?

→ **Use CMD + Scroll Wheel or Pinch Gesture** instead (this is normal for QuickLook)

**Why?** QuickLook extensions run in a restricted environment where macOS intercepts many CMD+key combinations for system use.

### Nothing happens?

1. Click inside the preview window first
2. Make sure file is opened with correct app
3. Check: Right-click .md → Get Info → Open with: "FluxMarkdown"

### Still not working?

Stream logs to see details:

```bash
log stream --predicate 'subsystem == "com.markdownquicklook.app"' --level debug
```

## Technical Notes

### Why Multiple Input Methods?

**QuickLook Limitation**: macOS intercepts many keyboard shortcuts for system use, especially in QuickLook windows. This is why we provide multiple input methods:

1. **Keyboard shortcuts**: Work great in Host App
2. **Mouse wheel zoom**: More reliable in QuickLook (same as Preview.app, Safari)
3. **Pinch gesture**: Most natural for macOS users

### System Limitations

1. **QuickLook owns the window**: The system controls window focus and event routing
2. **Security sandboxing**: QuickLook extensions run in restricted environment
3. **System shortcuts priority**: macOS intercepts many CMD+key combinations for system use
4. **Non-standard window lifecycle**: Preview windows have different event handling than normal app windows

### Why JavaScript Event Handling?

QuickLook preview controllers have limited keyboard event handling because:
- The QuickLook window manages its own event routing
- The system controls window focus and first responder status
- JavaScript keyboard events in WKWebView are more reliable for this use case

## Status

### ✅ Fully Working

- Host App: All input methods (keyboard, scroll, gesture)
- QuickLook: Mouse wheel zoom and pinch gesture
- Zoom persistence across sessions
- Smooth CSS-based scaling
- Range validation (0.5x - 3.0x)

### ⚠️ Partial Support

- QuickLook: Keyboard shortcuts (system may intercept)

### 🔮 Future Enhancements

- Visual zoom indicator (e.g., percentage display in UI)
- Menu items for zoom controls (Host App only)
- Custom zoom levels (preset buttons)
- Animation during zoom transitions
