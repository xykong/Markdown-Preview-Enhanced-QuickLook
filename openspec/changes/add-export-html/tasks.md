## 1. 调研与设计

- [x] 1.1 确认 `document.documentElement.outerHTML` 在当前单文件 HTML bundle 下是否已包含所有内联 CSS/JS
- [x] 1.2 确认渲染时注入的 base64 图片数据是否已替换 DOM 中的 `src` 属性（验证 `collectImageData()` 注入路径）
- [x] 1.3 确定导出 HTML 中是否需要隐藏 TOC 侧边栏和 UI 控制按钮（仅保留正文内容）
- [x] 1.4 确定默认保存文件名策略：与源 `.md` 文件同名，扩展名改为 `.html`

## 2. 测试先行（TDD）

- [x] 2.1 编写 Jest 测试：`window.exportHTML()` 返回字符串，包含 `<html>` 根元素
- [x] 2.2 编写 Jest 测试：返回的 HTML 中不包含外部 `http://` / `https://` 资源引用（完全离线）
- [x] 2.3 编写 Jest 测试：返回的 HTML 中不含 TOC 侧边栏元素（`#outline-panel` 不存在或 `display:none`）
- [x] 2.4 确认所有测试初始状态为红（失败）

## 3. 实现 — JS 层

- [x] 3.1 在 `web-renderer/src/index.ts` 中实现 `window.exportHTML(): string` 函数
  - [x] 3.1.1 克隆 `document.documentElement`
  - [x] 3.1.2 在克隆中移除或隐藏 TOC 侧边栏、搜索框、UI 控制按钮等交互元素
  - [x] 3.1.3 返回完整 HTML 字符串（`<!DOCTYPE html>` + outerHTML）

## 4. 实现 — Swift 层

- [x] 4.1 在 `MarkdownWebView.swift` 的 Coordinator 中添加 `exportHTML(completion:)` 方法
  - [x] 4.1.1 调用 `webView.evaluateJavaScript("window.exportHTML()")` 获取 HTML 字符串
  - [x] 4.1.2 将结果回调给调用方
- [x] 4.2 在 `MarkdownApp.swift` 的 `CommandGroup` 中添加 "Export as HTML…" 菜单项
  - [x] 4.2.1 绑定快捷键 `Cmd+Shift+E`
  - [x] 4.2.2 触发 `exportHTML`，在回调中弹出 `NSSavePanel`
  - [x] 4.2.3 `NSSavePanel` 配置：允许的文件类型 `.html`，默认文件名 = 源文件名（去掉 `.md` + 加 `.html`）
  - [x] 4.2.4 用户确认后将 HTML 字符串写入用户选择的路径（`String.write(to:atomically:encoding:)`）
- [x] 4.3 菜单项在无文档打开时为禁用状态

## 5. 验证

- [x] 5.1 运行 `npm test` 确认所有 Jest 测试绿色通过
- [x] 5.2 手动测试：导出包含代码块、数学公式、Mermaid 图表的文档，在 Safari / Chrome 中离线打开验证渲染正确
- [x] 5.3 验证导出 HTML 中无外部资源引用（用浏览器开发者工具 Network 面板确认全部 200 本地）
- [x] 5.4 验证本地图片（相对路径）在导出 HTML 中以 base64 内联显示
- [x] 5.5 验证 TOC 侧边栏、搜索框等 UI 元素不出现在导出内容中
- [x] 5.6 验证默认保存文件名正确（`README.md` → `README.html`）
- [x] 5.7 运行 `make app` 确认 Swift 构建无错误

## 6. 收尾

- [x] 6.1 更新 README 中的功能特性列表
