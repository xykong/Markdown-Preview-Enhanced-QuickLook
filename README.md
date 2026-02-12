# Markdown Preview Enhanced for macOS QuickLook

[中文 README](README_ZH.md)

A macOS QuickLook extension to beautifully preview Markdown files with full rendering, syntax highlighting, math formulas, and diagram support.

**Inspired by and partially based on [markdown-preview-enhanced](https://github.com/shd101wyy/markdown-preview-enhanced).**

## Features
- **Update Restoration**: Automatically reopens the last viewed Markdown file after an app update, providing a seamless user experience

- **Markdown**: CommonMark + GFM (Tables, Task Lists, Strikethrough)
- **Math**: KaTeX support for mathematical expressions (`$E=mc^2$`)
- **Diagrams**: Mermaid support for flowcharts, sequence diagrams, etc.
- **Syntax Highlighting**: Code blocks with language-specific highlighting
- **Emoji**: Full emoji support with `:emoji_name:` syntax
- **Table of Contents**: Auto-generated, collapsible navigation panel with smart highlighting
- **Link Navigation**: Full link support in the main app. Click links to open external URLs, navigate to local files, or scroll to anchors. QuickLook shows a non-intrusive toast due to sandbox limitations.
- **Theme**: Configurable appearance (Light, Dark, or System). Defaults to Light mode for better readability.
- **Zoom**: Keyboard shortcuts (`Cmd +/-/0`), scroll wheel zoom (hold `Cmd` and scroll), and pinch gesture (two-finger pinch) with persistence
- **Scroll Position Memory**: Automatically remembers scroll position for eachMarkdown file and restores it on next preview
- **Update Restoration**: Automatically reopens the last viewed Markdown file after an app update, providing a seamless user experience

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

### 🔐 First-Time Permission Request

**When you first preview a Markdown file with images**, macOS will show a permission dialog:

```
"Markdown Preview Enhanced.app" would like to 
access files in your home folder.

Keeping app data separate makes it easier to 
manage your privacy and security.

[Don't Allow]  [Allow]
```

**Why is this needed?**
- Markdown files often reference images using relative paths (e.g., `../images/pic.png`)
- These images may be outside the current directory
- macOS sandbox requires explicit permission to access them

**What to do:**
1. ✅ Click **"Allow"** - Recommended for full functionality
   - All image types will display correctly (relative paths, absolute paths)
   - You only need to grant permission once
   
2. ❌ Click **"Don't Allow"** - Limited functionality
   - Images in the same directory and subdirectories will still work
   - Parent directory images (`../`) and absolute paths may not display

**Security note:** This permission only grants access to **your home folder** (`/Users/username/`), not system files or other users' data.

### Testing

After completing the activation and permission steps above, test the extension:

```bash
qlmanage -p tests/fixtures/test-sample.md
```

Or simply select any `.md` file in Finder and press Space (QuickLook shortcut).

## 🛠️ Troubleshooting

### Permission Dialog Keeps Appearing

**Problem:** The permission dialog shows up every time you preview a Markdown file.

**Solution:**
1. Make sure you clicked **"Allow"** (not "Don't Allow") in the permission dialog
2. If you accidentally clicked "Don't Allow", you need to reset the permission:
   - Open **System Settings** > **Privacy & Security** > **Files and Folders**
   - Look for "Markdown Preview Enhanced"
   - Enable access to your home folder
3. Alternatively, completely reset permissions:
   ```bash
   tccutil reset All com.xykong.Markdown
   ```
   Then preview a Markdown file again and click "Allow" this time.

### Images Not Displaying

**Problem:** Some or all images in Markdown files don't show up.

**Checklist:**

1. **Check file permissions** - Make sure you clicked "Allow" in the permission dialog

2. **Verify image paths:**
   - ✅ Same directory: `![](./image.png)` → Should work
   - ✅ Subdirectory: `![](./images/pic.png)` → Should work
   - ✅ Parent directory: `![](../images/pic.png)` → Requires "Allow" permission
   - ✅ Absolute path (home folder): `![](/Users/username/Pictures/pic.png)` → Requires "Allow" permission
   - ❌ System paths: `![](/System/...)` → Not supported
   - ❌ Other users: `![](/Users/other-user/...)` → Not supported

3. **Check image file exists:**
   ```bash
   # From terminal, check if file exists
   ls -la /path/to/your/image.png
   ```

4. **Supported formats:**
   - ✅ PNG, JPEG, GIF, WebP, SVG
   - ✅ Network images (HTTPS)
   - ⚠️ HTTP images (may be blocked by security policy)

### QuickLook Not Working

**Problem:** Pressing Space on a `.md` file doesn't trigger preview.

**Solution:**
1. Reset QuickLook cache:
   ```bash
   qlmanage -r
   qlmanage -r cache
   ```

2. Set as default handler manually:
   - Right-click on a `.md` file → **Get Info**
   - Under "Open with:", select **Markdown Preview Enhanced**
   - Click **Change All...**

3. Log out and log back in (or restart your Mac)

### Managing Permissions Manually

**To view current permissions:**
- **System Settings** > **Privacy & Security** > **Files and Folders**
- Look for "Markdown Preview Enhanced"

**To revoke permissions:**
- Toggle off the permission switch
- Next time you preview a file, you'll be asked again

**To grant permissions without dialog:**
- You can pre-authorize in System Settings before using the app

### Link Navigation in QuickLook

**Problem:** Clicking links in QuickLook preview shows a toast notification instead of navigating.

**Why this happens:**
- macOS App Sandbox restricts QuickLook extensions from opening files or external URLs
- This is a system-level security feature that cannot be bypassed
- The toast is a non-intrusive way to inform users about this limitation

**Solution:**
- Double-click the `.md` file to open it in the main app instead
- The main app has full link navigation support without sandbox restrictions

**Supported link types (Main App only):**
- External URLs: `https://example.com` → Opens in default browser
- Relative paths: `./other.md` or `../dir/file.md` → Opens the target file
- Anchors: `#section` → Smooth scroll to the section
- All file types: `.md`, `.sql`, `.py`, `.json`, etc. → Opens with default app

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
