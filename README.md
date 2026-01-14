# Markdown Preview Enhanced for macOS QuickLook

[中文 README](README_ZH.md)

A macOS QuickLook extension to beautifully preview Markdown files with full rendering, syntax highlighting, math formulas, and diagram support.

**Inspired by and partially based on [markdown-preview-enhanced](https://github.com/shd101wyy/markdown-preview-enhanced).**

## Features

- **Markdown**: CommonMark + GFM (Tables, Task Lists, Strikethrough)
- **Math**: KaTeX support for mathematical expressions (`$E=mc^2$`)
- **Diagrams**: Mermaid support for flowcharts, sequence diagrams, etc.
- **Syntax Highlighting**: Code blocks with language-specific highlighting
- **Emoji**: Full emoji support with `:emoji_name:` syntax
- **Table of Contents**: Auto-generated, collapsible navigation panel with smart highlighting
- **Theme**: Configurable appearance (Light, Dark, or System). Defaults to Light mode for better readability.
- **Zoom**: Keyboard shortcuts (`Cmd +/-/0`), scroll wheel zoom (hold `Cmd` and scroll), and pinch gesture (two-finger pinch) with persistence

## Quick Start

### Installation

#### Method 1: Homebrew (Recommended)

```bash
brew tap xykong/tap
brew install --cask markdown-preview-enhanced
```

#### Method 2: Manual Installation (DMG)

1. Download the latest `.dmg` from the [Releases](https://github.com/xykong/markdown-quicklook/releases) page.
2. Open the `.dmg` file.
3. Drag **Markdown Preview Enhanced.app** to your **Applications** folder.

#### Method 3: Build from Source (For Developers)

```bash
# Clone the repository
git clone https://github.com/xykong/markdown-quicklook.git
cd markdown-quicklook

# Build and Install (Release version)
make install

# Or install Debug version for development
make install debug
```

This command will automatically:
1. Build the application with all dependencies
2. Install it to `/Applications/Markdown Preview Enhanced.app`
3. Register it with the system
4. Launch the app to complete registration
5. Set as default handler for `.md` files
6. Reset QuickLook cache

**The installation is now fully automated!** The extension should work immediately after installation.

### 🛑 Troubleshooting: "App is damaged" or "Unidentified Developer"

Since this app is open-source and not notarized by Apple, you might see an error saying **"Markdown Preview Enhanced.app is damaged and can't be opened"** or **"cannot be opened because the developer cannot be verified"**.

**Option 1: Command Line (Recommended)**

Run the following command in Terminal to remove the quarantine attribute:

```bash
xattr -cr "/Applications/Markdown Preview Enhanced.app"
```

**Option 2: Manual Authorization**

1. Go to **System Settings** > **Privacy & Security**.
2. Scroll down to the **Security** section.
3. You should see a message saying "Markdown Preview Enhanced.app was blocked...".
4. Click **Open Anyway**.
5. Enter your password to confirm.

Then try opening the app again.

### Testing

After completing the activation step above, test the extension:

```bash
qlmanage -p test-sample.md
```

Or simply select any `.md` file in Finder and press Space (QuickLook shortcut).

## Acknowledgements

This project is significantly inspired by and utilizes portions of [markdown-preview-enhanced](https://github.com/shd101wyy/markdown-preview-enhanced), created by Yiyi Wang (shd101wyy). We sincerely thank the author for their excellent work.

This project complies with the University of Illinois/NCSA Open Source License under which `markdown-preview-enhanced` is distributed.

## License

**Non-Commercial License**

This software is free for personal, educational, and non-commercial use only. Commercial use is strictly prohibited without prior written permission from the author. See the [LICENSE](LICENSE) file for details.

This project also respects the licenses of third-party libraries used, including:
- `markdown-preview-enhanced` (NCSA License)
- `markdown-it` (MIT License)
- `highlight.js` (BSD-3-Clause License)
- `katex` (MIT License)
- `mermaid` (MIT License)
