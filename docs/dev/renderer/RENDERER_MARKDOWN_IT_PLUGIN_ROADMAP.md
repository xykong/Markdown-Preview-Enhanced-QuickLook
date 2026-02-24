# Markdown-it 插件路线图（面向预览/浏览）

**状态：** Draft
**日期：** 2026-01-12
**背景：** 本项目是 *Markdown 预览器*（QuickLook + Host Browser），不提供编辑功能。Markdown 内容来自外部应用（GitHub / Obsidian / Typora / VSCode 等），我们无法要求作者遵循“仅对本应用有效”的写作约定。

因此，本路线图的目标是：
- **提高兼容性**：更好地支持现实世界中常见的 Markdown 方言/扩展语法。
- **提高可读性**：不要求作者额外标注，也能让渲染结果更“像文档”。
- **控制风险**：避免引入明显的 XSS 攻击面扩大（尤其在 WKWebView 场景下）。

---

## 当前状态

渲染器入口：`web-renderer/src/index.ts`

### markdown-it 配置
- `html: true`
- `breaks: true`
- `linkify: true`
- `typographer: true`

### 已启用插件
- `@iktakahiro/markdown-it-katex`
- `markdown-it-emoji`
- `markdown-it-footnote`
- `markdown-it-task-lists`
- `markdown-it-mark`
- `markdown-it-sub`
- `markdown-it-sup`
- `markdown-it-anchor`（permalink 关闭；自定义 `slugify`）

---

## 选型原则：该加什么、避免加什么

### 优先添加
满足以下条件的插件/能力：
1. **兼容性提升明显**：能覆盖外部文档常见语法（Markdown Extra / GitHub / Pandoc/导出工具等）。
2. **默认体验更好**：作者不需要“专门为我们写”。
3. **低冲突**：不容易与已有语法/插件产生解析冲突。

### 谨慎/避免
1. **需要作者显式采用的新语法**（只对我们有效），因为我们无法与作者“达成协议”。
2. **重 UI 依赖** 且收益不明确的特性（除非能显著提升大量文档的兼容性）。
3. **显著扩大注入/XSS 面** 的能力（除非同时落地安全策略）。

---

## P0 — 最高优先级（兼容性收益最大）

### 1) 定义列表（Definition List / Markdown Extra）
**建议插件：** `markdown-it-deflist`

**动机：** 许多外部文档会使用定义列表语法来写参数说明/术语表；如果不支持，会退化成普通段落，可读性明显下降。

**常见输入：**
```md
Term
: Definition

Parameter A
: Explains A
```

**期望输出：**
- 生成 `<dl><dt>...<dd>...`，呈现为“词条解释 / API 参数说明”的结构。

**集成备注：**
- 一般低风险、低冲突；优先落地。

---

### 2) GitHub 风格 Callouts / Alerts（提示块）
**目标：** 将常见“提示/警告”写法渲染成更清晰的结构与样式。

**为什么 P0：**
- 可读性提升非常直观。
- 内容作者通常来自 GitHub/现代工具链，这种写法出现频率越来越高。
- 不依赖作者为“我们的应用”特意写语法（更像兼容 GitHub）。

**常见输入（GitHub alerts）：**
```md
> [!NOTE]
> This is a note.

> [!WARNING]
> Danger ahead.
```

**实现路径：**
- 优先：寻找明确支持 GitHub alerts 的现成 markdown-it 插件。
- 备选：在 markdown-it 层实现一个小规则：检测 blockquote token 序列的第一行是否为 `[!TYPE]`，然后改写为结构化 block。

**集成备注：**
- 先用“轻样式”也能显著增益（复用 GitHub 风格即可），后续再细化 UI。

---

### 3) 图片尺寸语法兼容（Image Size）
**建议插件：** `markdown-it-imsize`（或同类替代）

**动机：** 外部工具经常使用非标准但流行的图片尺寸标注方式。如果不支持，会导致图片过大/排版混乱。

**常见输入：**
```md
![](img.png =200x)
![](img.png =200x100)
```

**期望行为：**
- 将尺寸信息转换为 `<img width="200" ...>` 或样式属性，改善阅读排版。

**集成备注（非常重要）：**
- 当前我们有自定义 `image` rule，会把相对路径改写成 `local-resource://...`。
- 引入 imsize 后必须验证：尺寸解析不会破坏/覆盖 URL 改写；必要时调整插件顺序或改写逻辑。

---

## P1 — 强候选（建议在采样/反馈后落地）

### 4) 属性语法兼容（Attributes / Pandoc / Markdown Extra）
**建议插件：** `markdown-it-attrs`

**收益：** 兼容一些常见的 `{#id .class key=value}` 写法，能让排版/定位更“对”。

**风险：**
- 在当前 `html: true` 的情况下，attrs 类能力会进一步扩大可注入面。

**建议：**
- 等“安全策略”确定后再启用（见下文 Security）。

---

### 5) 缩写 / 插入（Markdown Extra）
**建议插件：** `markdown-it-abbr`, `markdown-it-ins`

**收益：**
- 成本低；在规范/学术/说明书类文档中有价值。
- “静默兼容”：文档没用到就无影响，用到了就更正确。

---

### 6) 更宽松/更强的表格支持（谨慎评估）
**目标：** 支持“看起来像表格但 GFM 解析失败”的输入。

**备注：**
- 表格增强类插件更容易产生解析冲突或误判。
- 建议先收集一批“真实渲染失败样本”，再评估是否引入更宽松的表格插件。

---

## 非插件增强（通常 ROI 更高）

### A) 自动目录 / 大纲（UI 功能）
**目标：** 不要求作者写 `[toc]` 或 `[[toc]]`，仍然提供导航能力。

**实现思路：**
- 使用 markdown-it 的 token（`md.parse`）提取 headings，构建 outline。
- 在 Web UI 中渲染为浮层面板/侧边栏。

**为什么值得：**
- 任何有标题结构的文档都能受益。
- 不依赖作者约定，符合“外部文档预览”的产品约束。

### B) 表格横向滚动容器
对 `<table>` 外包一层可横向滚动容器，避免 QuickLook 窄窗口里布局崩坏。

### C) 代码块增强（复制按钮/语言标签/折叠）
这更偏 Web 渲染/UI 层（未必是 markdown-it 插件），但对技术文档阅读非常增益。

---

## Security（预览外部文档的现实约束）

当前我们设置 `html: true`，并且通过 `outputDiv.innerHTML = ...` 注入渲染结果。

**风险：** 对不受信任的 Markdown，原始 HTML 可能带来脚本注入、事件处理器注入等风险（WKWebView 环境尤其需要谨慎）。

### 推荐方向（二选一）
1. **更安全的默认值：** 将 `html` 设为 `false`，尽可能依赖 markdown-it + 插件能力。
2. **保留 HTML，但做净化：** 在写入 DOM 前对 HTML 做 sanitize，并使用严格的 allowlist（标签/属性）。

**经验法则：**
- 当我们引入更“丰富 DOM” 的能力（例如 attrs、callout 自定义结构等）时，**sanitize 的必要性只会更高**。

---

## 建议落地顺序（可迭代执行）

1. 引入 `markdown-it-deflist`（低风险）+ 测试。
2. 支持 GitHub alerts/callouts（插件或自定义规则）+ 测试。
3. 引入 `markdown-it-imsize` + 测试（重点验证与 `local-resource://` 改写的兼容性）。
4. 确定安全策略（`html: false` 或 sanitize）后，再考虑启用 `markdown-it-attrs`。
5. 可选：`abbr` / `ins`。
6. 表格增强：基于真实失败样本评估后再引入。

---

## 最小测试清单（每新增一个能力都要补）

在 `web-renderer/test/`（Jest）中增加/扩展测试，至少覆盖：
- Definition list 能渲染为 `<dl>`。
- Callout 能渲染为稳定结构（避免退化成普通 blockquote）。
- Image size 语法生效，并且相对图片仍能正确改写为 `local-resource://...`。
- Anchor ID 规则稳定，且链接导航行为不回归。
- Security（取决于策略）：不允许的标签/属性不会出现在最终 DOM 中。

---

## “兼容性语料库”（长期收益）

建议逐步收集外部来源的 Markdown 样本（或用测试夹具内联）：
- GitHub README
- Obsidian 笔记
- Typora 导出
- VSCode Markdown Preview

每次遇到渲染问题：
1) 将样本加入语料库；2) 用测试锁定问题；3) 再引入插件/规则修复。
