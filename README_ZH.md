# FluxMarkdown

[English README](README.md)

在 macOS Finder 里按空格（QuickLook）即可高质量预览 Markdown：支持 Mermaid / KaTeX / GFM / 目录（TOC）。

> 本项目受 [markdown-preview-enhanced](https://github.com/shd101wyy/markdown-preview-enhanced) 启发，并使用了其部分内容。

---

## 演示

> TODO：录制 `docs/assets/demo.gif`（10-15 秒）。参考 `docs/assets/README.md`。

![FluxMarkdown 演示](docs/assets/demo.gif)

---

## 30 秒安装

### Homebrew（推荐）

```bash
brew tap xykong/tap
brew install --cask flux-markdown
```

### 手动安装（DMG）

1. 从 [Releases](https://github.com/xykong/flux-markdown/releases) 下载最新的 `FluxMarkdown.dmg`
2. 打开 DMG
3. 将 **FluxMarkdown.app** 拖入 **Applications（应用程序）**

---

## 为什么选择 FluxMarkdown

- **GFM**：表格、任务列表、删除线
- **Mermaid**：流程图、时序图等
- **KaTeX**：数学公式
- **代码高亮**
- **目录（TOC）面板**：自动生成，跟随高亮
- **缩放**：Cmd +/-/0、Cmd+滚轮、触控板捏合
- **滚动位置记忆**：按文件记忆并恢复
- **链接**：主应用支持完整跳转；QuickLook 由于沙盒限制会弹 toast 提示

---

## 常见问题

### “应用已损坏” / “无法验证开发者”

```bash
xattr -cr "/Applications/FluxMarkdown.app"
```

### QuickLook 不刷新

```bash
qlmanage -r
```

更多：见 `docs/`（从 `docs/TROUBLESHOOTING.md`、`docs/AUTO_UPDATE.md` 开始）。

---

## 对比（QuickLook Markdown 插件）

| 功能 | FluxMarkdown | [QLMarkdown](https://github.com/sbarex/QLMarkdown) | [qlmarkdown](https://github.com/whomwah/qlmarkdown) | [PreviewMarkdown](https://github.com/smittytone/PreviewMarkdown) |
| --- | --- | --- | --- | --- |
| 安装方式 | brew cask / DMG | brew cask / DMG | 手动安装 | App Store / DMG |
| Mermaid | 支持 | 支持（[来源](https://github.com/sbarex/QLMarkdown/blob/main/README.md#mermaid-diagrams)） | 未提及 | 未提及 |
| KaTeX/数学公式 | 支持 | 支持（[来源](https://github.com/sbarex/QLMarkdown/blob/main/README.md#mathematical-expressions)） | 未提及 | 未提及 |
| GFM | 支持 | 支持（cmark-gfm；[来源](https://github.com/sbarex/QLMarkdown/releases/tag/1.0.18)） | 部分支持（Discount；[来源](https://github.com/whomwah/qlmarkdown#introduction)） | 未提及 |
| 目录（TOC） | 支持 | 未提及 | 不支持 | 未提及 |
| 主题 | 亮/暗/跟随系统 | CSS（[来源](https://github.com/sbarex/QLMarkdown/blob/main/README.md#extensions)） | 未提及 | 基础调节（[来源](https://github.com/smittytone/PreviewMarkdown#adjusting-the-preview)） |
| 缩放 | 支持 | 未提及 | 不支持 | 未提及 |
| 滚动位置记忆 | 支持 | 未提及 | 不支持 | 未提及 |

> 注：对比表基于上述项目公开 README/Release 内容；如果对方未公开说明，则标为“未提及”。

---

## 从源码构建

```bash
git clone https://github.com/xykong/flux-markdown.git
cd flux-markdown
make install
```

## License

见 `LICENSE`。
