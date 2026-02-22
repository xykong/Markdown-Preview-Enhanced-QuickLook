## 1. 调研与设计

- [x] 1.1 验证 `WKWebView.createPDF(configuration:)` 在 macOS 11+ 沙箱环境下的行为
- [x] 1.2 调研 `WKPDFConfiguration` 可配置项（`rect`、`mediaType` 等）
- [x] 1.3 确定默认纸张尺寸策略（A4，通过 `WKPDFConfiguration.rect` 设置）
- [x] 1.4 列出需要在 `@media print` 下隐藏的 UI 元素：TOC 侧边栏、搜索框、主题切换按钮、缩放控件
- [x] 1.5 确定打印样式的字号、行高、页边距基准值

## 2. 测试先行（TDD）

- [x] 2.1 编写 Jest 测试：`@media print` 下 `#outline-panel`（TOC 侧边栏）`display` 为 `none`
- [x] 2.2 编写 Jest 测试：`@media print` 下 UI 控制按钮（主题切换、源码切换）`display` 为 `none`
- [x] 2.3 编写 XCTest 测试（或手动验收标准）：`exportPDF()` 方法返回非空 `Data`，且数据以 `%PDF-` magic bytes 开头
- [x] 2.4 确认 Jest 测试初始状态为红（失败）

## 3. 实现 — CSS 打印样式

- [x] 3.1 在 `web-renderer/src/index.ts` 或独立样式文件中添加 `@media print` CSS 规则块
  - [x] 3.1.1 隐藏 TOC 侧边栏、搜索框、UI 控制按钮
  - [x] 3.1.2 正文区域宽度设为 100%（移除侧边栏占用的空间）
  - [x] 3.1.3 代码块设置 `break-inside: avoid` 避免跨页断裂
  - [x] 3.1.4 标题设置 `break-after: avoid` 避免孤立标题
  - [x] 3.1.5 设置合理的正文字号（12pt）和页边距

## 4. 实现 — Swift 层

- [x] 4.1 在 `MarkdownWebView.swift` 的 Coordinator 中添加 `exportPDF(completion: @escaping (Data?) -> Void)` 方法
  - [x] 4.1.1 创建 `WKPDFConfiguration` 实例，设置 A4 纸张 rect
  - [x] 4.1.2 调用 `webView.createPDF(configuration:completionHandler:)` 获取 PDF `Data`
  - [x] 4.1.3 将结果回调给调用方
- [x] 4.2 在 `MarkdownApp.swift` 的 `CommandGroup` 中添加 "Export as PDF…" 菜单项
  - [x] 4.2.1 绑定快捷键 `Cmd+Shift+P`（注意与系统打印 `Cmd+P` 区分）
  - [x] 4.2.2 触发 `exportPDF`，在回调中弹出 `NSSavePanel`
  - [x] 4.2.3 `NSSavePanel` 配置：允许的文件类型 `.pdf`，默认文件名 = 源文件名（去掉 `.md` + 加 `.pdf`）
  - [x] 4.2.4 用户确认后将 PDF `Data` 写入用户选择的路径
- [x] 4.3 菜单项在无文档打开时为禁用状态

## 5. 验证

- [x] 5.1 运行 `npm test` 确认 `@media print` 相关 Jest 测试绿色通过
- [x] 5.2 手动测试：导出包含代码块、数学公式、Mermaid 图表的文档为 PDF，用预览 App 打开验证内容正确
- [x] 5.3 验证 PDF 中 TOC 侧边栏、控制按钮等 UI 元素不出现
- [x] 5.4 验证代码块不在页面中间断裂（`break-inside: avoid`）
- [x] 5.5 验证默认保存文件名正确（`README.md` → `README.pdf`）
- [x] 5.6 验证用户取消保存面板时不写入文件
- [x] 5.7 运行 `make app` 确认 Swift 构建无错误

## 6. 收尾

- [x] 6.1 更新 README 中的功能特性列表
