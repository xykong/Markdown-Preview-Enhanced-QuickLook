# Change: 导出为 PDF 文件

## Why

Markdown 文档在技术写作、会议纪要、项目文档等场景中被广泛使用，用户通常需要将其转化为 PDF 进行正式分发或打印。当前 FluxMarkdown 不提供任何导出能力，用户只能依赖截图或手动打印，流程繁琐且格式不可控。`WKWebView.createPDF(configuration:)` 是 macOS 11+ 提供的原生 API，在 App Sandbox 中完全可用，无需任何外部依赖。

## What Changes

- 在 Host App 菜单栏 `File` 下添加 "Export as PDF…" 菜单项（`Cmd+Shift+P`）
- Swift 侧调用 `WKWebView.createPDF(configuration:)` 将当前渲染内容生成为 PDF `Data`
- 弹出 `NSSavePanel` 让用户选择保存路径，默认文件名与源 `.md` 文件同名
- 新增 `@media print` CSS 样式：隐藏交互 UI（TOC 侧边栏、控制按钮）、优化分页、设置合理字号和页边距

## Impact

- Affected specs: `export-pdf`（新建）
- Affected code:
  - `Sources/Markdown/MarkdownApp.swift`（新增菜单命令）
  - `Sources/Markdown/MarkdownWebView.swift`（新增 `exportPDF(completion:)` 方法）
  - `web-renderer/src/index.ts` 或 `web-renderer/styles/`（新增 `@media print` CSS）
