# Change: 导出为自包含 HTML 文件

## Why

用户在预览 Markdown 文件后，常常需要将渲染结果分享给他人或存档。当前只能截图或复制原始 Markdown，对方仍需要渲染环境才能查看。导出为自包含 HTML 文件可让任何人在任意浏览器中离线查看完整渲染结果，包括样式、代码高亮、数学公式和图表。

## What Changes

- 在 Host App 菜单栏 `File` 下添加 "Export as HTML…" 菜单项（`Cmd+Shift+E`）
- 触发后通过 JS bridge 从 WKWebView 获取当前渲染完成的 DOM HTML
- Swift 侧对 HTML 进行后处理：确保本地图片已 base64 内联（复用 `collectImageData()` 结果，已在渲染时注入）
- 弹出 `NSSavePanel` 让用户选择保存路径，默认文件名与源 `.md` 文件同名
- 导出的 HTML 须完全自包含（CSS、JS、图片、字体全部内联），离线可打开

## Impact

- Affected specs: `export-html`（新建）
- Affected code:
  - `Sources/Markdown/MarkdownApp.swift`（新增菜单命令）
  - `Sources/Markdown/MarkdownWebView.swift`（新增 JS bridge 消息处理 + export 方法）
  - `web-renderer/src/index.ts`（新增 `window.exportHTML()` JS 函数，返回序列化 DOM）
