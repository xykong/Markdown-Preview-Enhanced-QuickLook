## ADDED Requirements

### Requirement: PDF 导出入口
Host App SHALL 在菜单栏 File 分组下提供 "Export as PDF…" 菜单项，快捷键为 `Cmd+Shift+P`。该菜单项在无 Markdown 文档打开时 SHALL 处于禁用状态。

#### Scenario: 有文档时菜单项可用
- **WHEN** 用户打开了一个 Markdown 文档
- **THEN** "Export as PDF…" 菜单项处于可点击状态

#### Scenario: 无文档时菜单项禁用
- **WHEN** 未打开任何 Markdown 文档
- **THEN** "Export as PDF…" 菜单项处于禁用（grayed out）状态

---

### Requirement: PDF 生成质量
导出的 PDF SHALL 使用 `WKWebView.createPDF(configuration:)` 原生 API 生成，无需任何外部二进制依赖。导出内容 SHALL 与预览视图的正文渲染结果一致，代码高亮、数学公式、Mermaid 图表均正确呈现。

#### Scenario: 代码块、数学公式和图表正确渲染
- **WHEN** Markdown 文档包含代码块、KaTeX 数学公式和 Mermaid 图表
- **THEN** 导出的 PDF 中上述内容均正确显示，与屏幕预览效果一致

#### Scenario: 导出内容不含交互 UI 元素
- **WHEN** 用户导出 PDF
- **THEN** 导出文件中不包含 TOC 侧边栏、搜索框、主题切换按钮等交互控件，仅保留正文渲染内容

#### Scenario: 代码块不跨页断裂
- **WHEN** 文档中存在较长代码块且跨越页面边界
- **THEN** 代码块尽量保持完整不被截断，通过 CSS `break-inside: avoid` 实现

---

### Requirement: 保存文件交互
触发导出后 SHALL 弹出系统标准 `NSSavePanel`，默认文件名为源 Markdown 文件名（扩展名替换为 `.pdf`），允许用户修改保存路径和文件名。

#### Scenario: 默认文件名来自源文件
- **WHEN** 用户对 `design-doc.md` 触发 "Export as PDF…"
- **THEN** 保存面板默认文件名为 `design-doc.pdf`

#### Scenario: 用户取消时不写入文件
- **WHEN** 用户在保存面板点击取消
- **THEN** 不写入任何文件，当前文档状态不变
