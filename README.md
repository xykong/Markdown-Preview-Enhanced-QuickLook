# Markdown QuickLook Extension

A macOS QuickLook extension to beautifully preview Markdown files with full rendering, syntax highlighting, math formulas, and diagram support.

## Features

- **Markdown**: CommonMark + GFM (Tables, Task Lists, Strikethrough)
- **Math**: KaTeX support for mathematical expressions (`$E=mc^2$`)
- **Diagrams**: Mermaid support for flowcharts, sequence diagrams, etc.
- **Syntax Highlighting**: Code blocks with language-specific highlighting
- **Emoji**: Full emoji support with `:emoji_name:` syntax
- **Theme**: Automatic light/dark mode based on system settings

## Quick Start

### Installation

Run the installation script:

```bash
./install.sh
```

This will:
1. Build the application with all dependencies
2. Install it to `/Applications/MarkdownQuickLook.app`
3. Register it with the system
4. Reset QuickLook cache

### ⚠️ Critical Activation Step

**The QuickLook extension will NOT work until you complete this step:**

1. **Right-click** (or Control+click) on any `.md` file in Finder
2. Select **"Get Info"** (or press `⌘+I`)
3. In the **"Open with:"** section, select **MarkdownQuickLook.app**
4. Click the **"Change All..."** button
5. Confirm by clicking **"Continue"**

This sets MarkdownQuickLook as the default application for all `.md` files, which is **required** for macOS to use our QuickLook extension.

### Testing

After completing the activation step above, test the extension:

```bash
qlmanage -p test-sample.md
```

Or simply select any `.md` file in Finder and press Space (QuickLook shortcut).

## Why Do I Need to Set a Default App?

macOS QuickLook extensions (the modern App Extension type) only work when:
1. The extension is embedded in an application
2. That application is set as the default handler for the file type

This is different from old-style `.qlgenerator` plugins that worked system-wide. The modern approach provides better security and isolation.

## Manual Build

If you prefer to build manually:

```bash
# 1. Build web renderer
cd web-renderer
npm install
npm run build

# 2. Generate Xcode project and build
cd ..
make app

# 3. Install to Applications
cp -R ~/Library/Developer/Xcode/DerivedData/MarkdownQuickLook-*/Build/Products/Debug/MarkdownQuickLook.app /Applications/

# 4. Register with system
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/MarkdownQuickLook.app

# 5. Reset QuickLook
qlmanage -r && qlmanage -r cache
```

Then follow the **Critical Activation Step** above.

## Troubleshooting

### QuickLook shows white screen or plain text

**Cause**: MarkdownQuickLook is not set as the default application for `.md` files.

**Solution**: Follow the **Critical Activation Step** above.

### "Open with Xcode" appears in QuickLook preview

**Cause**: Xcode (or another app) is set as the default handler for `.md` files.

**Solution**: 
1. Right-click a `.md` file → Get Info
2. Change "Open with:" to MarkdownQuickLook.app
3. Click "Change All..."

### Extension not appearing in qlmanage output

**Cause**: The app hasn't been registered with LaunchServices.

**Solution**:
```bash
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/MarkdownQuickLook.app
qlmanage -r && qlmanage -r cache
```

### After building, still shows old preview

**Cause**: QuickLook cache needs to be cleared.

**Solution**:
```bash
qlmanage -r && qlmanage -r cache
```

## Development

### Project Structure

- `Sources/MarkdownQuickLook/` - Main application wrapper
- `Sources/MarkdownPreview/` - QuickLook Preview Extension
- `web-renderer/` - Web-based Markdown rendering engine
- `docs/` - Documentation
- `project.yml` - XcodeGen project configuration

### Building for Development

```bash
make app
```

### Testing

```bash
# Test with a specific file
qlmanage -p test-sample.md

# Debug extension loading
qlmanage -m plugins | grep -i markdown

# View system handler for .md files
mdls -name kMDItemContentType test-sample.md
```

## Technical Details

This is a modern macOS QuickLook Preview Extension (not the legacy `.qlgenerator` format). Key differences:

- **App Extension**: Lives inside a host application
- **Security**: Runs in a sandboxed environment
- **Activation**: Requires being set as default handler
- **Distribution**: Distributed as part of an app bundle

The extension uses:
- **Swift/WebKit**: For the macOS extension layer
- **Node.js/Webpack**: For bundling the web renderer
- **markdown-it**: Markdown parser
- **Mermaid**: Diagram rendering
- **KaTeX**: Math rendering
- **highlight.js**: Syntax highlighting

## License

MIT License - See LICENSE file for details.

## Contributing

Contributions are welcome! Please see our contributing guidelines in the docs folder.
