# FluxMarkdown

<p align="center">
  <em>Beautiful Markdown previews in macOS Finder QuickLook</em><br>
  Mermaid • KaTeX • GFM • TOC • Code Highlighting
</p>

<p align="center">
  <a href="https://github.com/xykong/flux-markdown/stargazers">
    <img src="https://img.shields.io/github/stars/xykong/flux-markdown?style=social" alt="GitHub stars">
  </a>
  <a href="https://github.com/xykong/flux-markdown/releases">
    <img src="https://img.shields.io/github/v/release/xykong/flux-markdown?style=flat-square" alt="Latest release">
  </a>
  <a href="https://github.com/xykong/flux-markdown/releases">
    <img src="https://img.shields.io/github/downloads/xykong/flux-markdown/total?style=flat-square" alt="Downloads">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/github/license/xykong/flux-markdown?style=flat-square" alt="License">
  </a>
</p>

<p align="center">
  <a href="README_ZH.md">中文文档</a> •
  <a href="#-quick-install-30-seconds">Install</a> •
  <a href="#-troubleshooting">Troubleshooting</a>
</p>

---

## ✨ Demo

![FluxMarkdown Demo](docs/assets/demo.gif)

<p align="center">
  <strong>Press <code>Space</code> in Finder → Instant preview with diagrams, math, and more.</strong>
</p>

<p align="center">
  <em>👋 If FluxMarkdown helps you, consider giving it a</em>
  <a href="https://github.com/xykong/flux-markdown/stargazers">⭐ star on GitHub</a>!
</p>

---

## 🚀 Quick Install (30 seconds)

### Homebrew (Recommended)

```bash
brew tap xykong/tap
brew install --cask flux-markdown
```

### Manual (DMG)

1. Download the latest `FluxMarkdown.dmg` from [Releases](https://github.com/xykong/flux-markdown/releases)
2. Open the DMG
3. Drag **FluxMarkdown.app** to **Applications**

---

## 💡 Why FluxMarkdown?

| Feature | Description |
|---------|-------------|
| 📊 **Mermaid Diagrams** | Architecture diagrams, flowcharts, sequence diagrams |
| 🧮 **KaTeX Math** | Inline and block mathematical expressions |
| 📝 **GFM Support** | Tables, task lists, strikethrough, and more |
| 🎨 **Code Highlighting** | Multi-language syntax highlighting |
| 📑 **TOC Panel** | Interactive table of contents with section tracking |
| 🔍 **Zoom & Pan** | Cmd +/-/0, Cmd+scroll, pinch gestures |
| 💾 **Position Memory** | Remembers scroll position per file |
| 🌓 **Themes** | Light, Dark, and System-synchronized modes |

---

## 🛠️ Troubleshooting

<details>
<summary><strong>"App is damaged" / "Unidentified developer"</strong></summary>

Run this in Terminal:
```bash
xattr -cr "/Applications/FluxMarkdown.app"
```
</details>

<details>
<summary><strong>QuickLook not showing updates</strong></summary>

Reset QuickLook cache:
```bash
qlmanage -r
```
</details>

<details>
<summary><strong>Preview not working at all</strong></summary>

1. Check if the app is in `/Applications/`
2. Try restarting Finder: `killall Finder`
3. Check `pluginkit -m -v` for active QuickLook extensions
</details>

**📚 More help:** See [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) and [`docs/AUTO_UPDATE.md`](docs/AUTO_UPDATE.md)

---

## Comparison (QuickLook Markdown plugins)

| Feature | FluxMarkdown | [QLMarkdown](https://github.com/sbarex/QLMarkdown) | [qlmarkdown](https://github.com/whomwah/qlmarkdown) | [PreviewMarkdown](https://github.com/smittytone/PreviewMarkdown) |
| --- | --- | --- | --- | --- |
| Install | brew cask / DMG | brew cask / DMG | manual | App Store / DMG |
| Mermaid | Yes | Yes ([ref](https://github.com/sbarex/QLMarkdown/blob/main/README.md#mermaid-diagrams)) | Not mentioned | Not mentioned |
| KaTeX / Math | Yes | Yes ([ref](https://github.com/sbarex/QLMarkdown/blob/main/README.md#mathematical-expressions)) | Not mentioned | Not mentioned |
| GFM | Yes | Yes (cmark-gfm; [ref](https://github.com/sbarex/QLMarkdown/releases/tag/1.0.18)) | Partial (Discount; [ref](https://github.com/whomwah/qlmarkdown#introduction)) | Not mentioned |
| TOC panel | Yes | Not mentioned | No | Not mentioned |
| Themes | Light/Dark/System | CSS-based ([ref](https://github.com/sbarex/QLMarkdown/blob/main/README.md#extensions)) | Not mentioned | Basic controls ([ref](https://github.com/smittytone/PreviewMarkdown#adjusting-the-preview)) |
| Zoom | Yes | Not mentioned | No | Not mentioned |
| Scroll restore | Yes | Not mentioned | No | Not mentioned |

> Notes:
> - Entries are based on public README/release notes at the cited links.
> - If a feature isn't mentioned in sources, we mark it as "Not mentioned".

---

## Build from source

```bash
git clone https://github.com/xykong/flux-markdown.git
cd flux-markdown
make install
```

## 📄 License

See [`LICENSE`](LICENSE).

---

<p align="center">
  <sub>Inspired by and partially based on <a href="https://github.com/shd101wyy/markdown-preview-enhanced">markdown-preview-enhanced</a></sub>
</p>
