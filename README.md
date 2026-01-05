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
- **Theme**: Configurable appearance (Light, Dark, or System). Defaults to Light mode for better readability.

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

# Run installation script
./install.sh
```

This script will:
1. Build the application with all dependencies
2. Install it to `/Applications/Markdown Preview Enhanced.app`
3. Register it with the system
4. Reset QuickLook cache

### ⚠️ Critical Activation Step

**The QuickLook extension will NOT work until you complete this step:**

1. **Right-click** (or Control+click) on any `.md` file in Finder
2. Select **"Get Info"** (or press `⌘+I`)
3. In the **"Open with:"** section, select **Markdown Preview Enhanced.app**
4. Click the **"Change All..."** button
5. Confirm by clicking **"Continue"**

This sets Markdown Preview Enhanced as the default application for all `.md` files, which is **required** for macOS to use our QuickLook extension.

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
