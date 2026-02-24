# FluxMarkdown 竞品分析与差距报告

**版本** ：基于 v1.16.182  
**日期** ：2026-02-23  
**范围** ：macOS Markdown QuickLook 插件 + 主流 Markdown 预览器

---

## 一、我们的现状（v1.16.182）

| 能力 | 状态 |
|------|------|
| Mermaid 图表 | ✅ 本地 bundle，离线可用 |
| KaTeX 数学公式 | ✅ 本地 bundle，渲染快 |
| GFM（表格、任务列表、删除线） | ✅ |
| GitHub Alerts（NOTE/WARNING/TIP...） | ✅ |
| Vega / Vega-Lite 交互图表 | ✅ 独家 |
| Graphviz / DOT 图 | ✅ 独家 |
| TOC 侧边栏（可交互） | ✅ 独家 |
| 导出 PDF / HTML | ✅ 独家 |
| YAML Frontmatter 表格展示 | ✅ |
| 缩放 / 滚动位置记忆 | ✅ |
| 代码高亮 40+ 语言 | ✅ |
| 多代码高亮主题（GitHub / Monokai / Atom One Dark） | ✅ |
| Settings 窗口（Cmd+,） | ✅ |
| 文件格式 .mdx / .rmd / .qmd / .mdoc 等 | ✅ |
| Sparkle 自动更新 | ✅ |
| i18n 中英文 | ✅ |

---

## 二、竞品概览

### 2.1 直接竞品：QuickLook 插件

| 特性 | FluxMarkdown | QLMarkdown (sbarex) | PreviewMarkdown | qlmarkdown (toland) |
|------|:---:|:---:|:---:|:---:|
| 渲染引擎 | TS/Vite 自研 | cmark-gfm | Markdown-It | Discount (C) |
| Mermaid | ✅ | ✅ | ❌ | ❌ |
| 数学公式 | ✅ KaTeX | ✅ MathJax | ❌ | ❌ |
| Vega / Graphviz 图表 | ✅ | ❌ | ❌ | ❌ |
| TOC 侧边栏 | ✅ | ❌ | ❌ | ❌ |
| 导出 PDF/HTML | ✅ | ❌ | ❌ | ❌ |
| GitHub Alerts | ✅ | ❌ | ❌ | ❌ |
| YAML Frontmatter | ✅ | ✅ | ✅ | ❌ |
| 多代码高亮主题 | ✅ | ❌ | ❌ | ❌ |
| 自定义 CSS | ❌ | ✅ | ❌ | ❌ |
| 本地图片沙盒方案 | ⚠️ | ✅ base64 内嵌 | ❌ | ❌ |
| 脚注（Footnotes） | ❌ | ✅ | ❌ | ❌ |
| 上标 / 下标 | ❌ | ✅ | ❌ | ❌ |
| `==高亮==` 语法 | ❌ | ✅ | ❌ | ❌ |
| 代码语言自动猜测 | ❌ | ✅ Linguist/Enry | ❌ | ❌ |
| CLI 批量转换工具 | ❌ | ✅ | ❌ | ❌ |
| .textbundle / .apib 格式 | ❌ | ✅ | ❌ | ❌ |
| 预览内搜索（Cmd+F） | ❌ | ❌ | ❌ | ❌ |
| Raw 源码切换 | ❌ | ✅ | ❌ | ❌ |
| Smart 引号 / 破折号 | ❌ | ✅ | ❌ | ❌ |
| 缩放 | ✅ | ❌ | ❌ | ❌ |
| 滚动位置记忆 | ✅ | ❌ | ❌ | ❌ |
| 字体大小设置 | ✅ | ❌ | ⚠️ 有限 | ❌ |
| Homebrew 安装 | ✅ | ✅ | ❌ | ❌ |
| 已签名/公证 | ✅ | ❌ | ✅ App Store | ❌ |

### 2.2 间接竞品：专用 Markdown 预览器

| 特性 | FluxMarkdown | Marked 2 | Typora | iA Writer |
|------|:---:|:---:|:---:|:---:|
| 使用方式 | QuickLook（Space 键） | 独立应用 | 编辑器 | 编辑器 |
| Mermaid | ✅ | ✅ | ✅ | ❌ |
| 数学公式 | ✅ KaTeX | ✅ MathJax | ✅ MathJax | ❌ |
| 自定义 CSS | ❌ | ✅ 深度支持 | ✅ 主题系统 | ✅ 模板系统 |
| 自定义处理器 | ❌ | ✅ 任意脚本 | ❌ | ❌ |
| 导出格式 | PDF / HTML | PDF/HTML/DOCX/RTF/ODT | PDF/HTML/DOCX/LaTeX/Epub | PDF/HTML/DOCX |
| 多文件合并 | ❌ | ✅ transclusion | ❌ | ✅ Content Blocks |
| CriticMarkup 审阅 | ❌ | ✅ | ❌ | ❌ |
| 文档统计 / 可读性 | ❌ | ✅ 词频、可读性评分 | ❌ | ✅ 词性高亮 |
| 链接校验 | ❌ | ✅ | ❌ | ❌ |
| Vega / Graphviz | ✅ | ❌ | ❌ | ❌ |
| QuickLook 即时预览 | ✅ | ❌ | ❌ | ❌ |
| 无需打开应用 | ✅ | ❌ 需要打开 Marked 2 | ❌ | ❌ |
| 价格 | 免费/GPL | 付费（$13.99） | 付费（$14.99） | 付费（$49.99/年） |

---

## 三、差距分析

### 3.1 高优先级差距

#### ① 预览内搜索（Cmd+F）
- **现状** ：❌ 缺失
- **用户需求** ：🔥🔥🔥 高频，是付费产品 Peek 的核心差异点
- **实现路径** ：在 JS 层实现自定义搜索 overlay，WKWebView 支持 `findString:` API
- **工作量估计** ：中等（纯 JS + Swift bridge）

#### ② 本地图片渲染健壮性
- **现状** ：⚠️ 沙盒限制下相对路径图片是否正确渲染未充分验证
- **用户需求** ：🔥🔥🔥 最高频投诉之一
- **实现路径** ：参考 QLMarkdown 的 base64 内嵌方案，或使用 `local-md://` scheme 处理
- **工作量估计** ：小（已有 LocalSchemeHandler 基础）

#### ③ Raw 源码切换（Toggle）
- **现状** ：❌ 缺失
- **用户需求** ：🔥🔥 开发者场景频繁使用，一键切换渲染 ↔ 原始 Markdown
- **实现路径** ：JS 层切换显示内容，Swift 端加一个工具栏按钮
- **工作量估计** ：小

### 3.2 中优先级差距

#### ④ 自定义 CSS
- **现状** ：❌ 缺失，Settings 只有内置主题
- **用户需求** ：🔥🔥 Power user 必备
- **实现路径** ：Settings 中添加 CSS 文件路径输入，通过 Swift 读取文件后注入 WebView
- **工作量估计** ：中等

#### ⑤ 脚注（Footnotes）
- **现状** ：❌ 缺失
- **用户需求** ：🔥🔥 学术写作用户常用
- **实现路径** ：`markdown-it-footnote` 插件，一行引入
- **工作量估计** ：极小

#### ⑥ 上标 / 下标（`H~2~O`、`x^2^`）
- **现状** ：❌ 缺失
- **用户需求** ：🔥 化学、数学用户
- **实现路径** ：`markdown-it-sub` + `markdown-it-sup` 插件
- **工作量估计** ：极小

#### ⑦ `==高亮==` 语法
- **现状** ：❌ 缺失
- **用户需求** ：🔥🔥 Obsidian / 笔记用户高频
- **实现路径** ：`markdown-it-mark` 插件
- **工作量估计** ：极小

#### ⑧ Smart 引号 / 破折号（`---` → em dash）
- **现状** ：❌ 缺失
- **用户需求** ：🔥 写作类用户
- **实现路径** ：`markdown-it-smartarrows` 或 markdown-it `typographer` 选项
- **工作量估计** ：极小（一个配置项）

#### ⑨ 自动刷新（外部编辑器保存后更新）
- **现状** ：❌ QuickLook 重新触发才更新
- **用户需求** ：🔥 配合外部编辑器工作流
- **实现路径** ：QuickLook 生命周期内通过 `DispatchSourceFileSystemObject` 监听文件变化
- **工作量估计** ：中等，需处理 QuickLook 沙盒限制

### 3.3 低优先级差距

| 功能 | 备注 |
|------|------|
| CLI 批量转换工具 | 工程量大，受众偏小 |
| 文档统计（字数、阅读时间） | QuickLook 场景需求弱 |
| .textbundle / .apib 格式 | 小众需求 |
| 代码语言自动猜测（Linguist） | 需集成 Go 库，成本高 |
| 多文件合并（transclusion） | Marked 2 特色，超出 QuickLook 定位 |
| CriticMarkup | 审阅场景与 QuickLook 定位不符 |

---

## 四、我们的核心护城河

| 护城河 | 说明 |
|--------|------|
| **Vega / Vega-Lite 交互图表** | 所有 QuickLook 插件中唯一支持，数据科学 / 工程师用户的杀手锏 |
| **Graphviz / DOT** | 同上，系统设计文档的标准图表格式 |
| **TOC 侧边栏** | QuickLook 插件独有，长文档导航无竞争 |
| **QuickLook 内直接导出 PDF/HTML** | 通常需要打开 Marked 2 才能完成，我们在 Space 键预览时即可完成 |
| **多代码高亮主题** | 其他 QuickLook 插件均无此功能 |
| **渲染性能** | 经过 7 项性能优化（v1.15），bundle 分包 + 懒加载，冷启动和热渲染均领先竞品 |
| **已公证 + Homebrew 分发** | QLMarkdown 未公证，安装体验差；我们支持 `brew install --cask` |

---

## 五、战略建议

### 短期（1-2 个版本）

快速收割低工程量、高用户感知的功能：

```
markdown-it-footnote  →  脚注支持
markdown-it-sub/sup   →  上标 / 下标
markdown-it-mark      →  ==高亮== 语法
typographer: true     →  Smart 引号 / 破折号
Raw Toggle 按钮        →  源码 / 渲染视图切换
```

这 5 项合计工程量不超过 1 天，但可以直接填补与 QLMarkdown 最显眼的语法差距。

### 中期（3-4 个版本）

投入"差异化杀手级功能"：

1. **预览内 Cmd+F 搜索** — 实现后可作为核心宣传点，直接对标付费产品 Peek
2. **本地图片沙盒修复** — 消除最高频用户投诉
3. **自定义 CSS** — 吸引从 QLMarkdown 迁移的 power user

### 长期（持续方向）

- 持续优化渲染性能（我们的技术护城河）
- 探索 Finder 侧边栏 Preview Pane 兼容性
- 关注 macOS 新版本兼容性（Sequoia / Tahoe）

---

## 六、参考来源

- [sbarex/QLMarkdown README](https://github.com/sbarex/QLMarkdown/blob/main/README.md)
- [sbarex/QLMarkdown Issues](https://github.com/sbarex/QLMarkdown/issues)
- [Marked 2 Help](https://marked2app.com/help/)
- [Typora 官网](https://typora.io)
- [iA Writer 官网](https://ia.net/writer)
- 用户反馈来源：GitHub Issues、Reddit r/MacOS、r/Markdown
