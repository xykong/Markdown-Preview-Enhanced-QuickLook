## 1. 设计与范围确认

- [x] 1.1 梳理现有 `AppearancePreference.swift` 中已有的偏好项，避免重复
- [x] 1.2 确定设置面板的菜单入口位置（macOS Settings 场景 vs 自定义 Preferences 窗口）
- [x] 1.3 确定第一个版本的最小可配置项集合（主题、字号基准、代码主题）
- [x] 1.4 设计 Swift → JS 的配置传递协议（`renderMarkdown(content, options)` 中的 options 对象扩展）

## 2. 测试先行（TDD）

- [x] 2.1 编写 XCTest：主题偏好存入 UserDefaults 后可正确读取
- [x] 2.2 编写 XCTest：字号基准偏好存入 UserDefaults 后可正确读取
- [x] 2.3 编写 Jest 测试：`renderMarkdown` 接受 `fontSize` 参数并应用到 CSS 变量
- [x] 2.4 确认测试初始状态为红（失败）

## 3. Swift 实现

- [x] 3.1 在 `Sources/Shared/AppearancePreference.swift` 中添加新偏好项（字号基准、代码主题等）
- [x] 3.2 创建 `Sources/Markdown/SettingsView.swift`（SwiftUI Settings 视图）
  - [x] 3.2.1 主题选择器（Picker: Light/Dark/System）
  - [x] 3.2.2 字体大小调节器（Slider 12-24pt，步进 1pt）
  - [x] 3.2.3 代码高亮主题选择器（Picker，列举预置主题）
  - [x] 3.2.4 渲染功能开关（Toggle: Mermaid / KaTeX / Emoji）
- [x] 3.3 在 `Sources/Markdown/MarkdownApp.swift` 中注册 Settings 场景
- [x] 3.4 更新 `project.yml` 添加新 Swift 文件

## 4. JS 侧适配

- [x] 4.1 扩展 `window.renderMarkdown(content, options)` 的 `options` 类型定义
- [x] 4.2 在渲染函数中读取 `options.fontSize` 并应用到根元素 CSS 变量
- [x] 4.3 在渲染函数中读取 `options.enableMermaid` / `options.enableKatex` 等开关

## 5. 集成与验证

- [x] 5.1 运行 XCTest 和 Jest 测试，确认全绿
- [x] 5.2 手动验证：打开设置面板，修改主题，重新打开 QuickLook 预览，确认生效
- [x] 5.3 手动验证：修改字号，重新预览，确认字体大小变化
- [x] 5.4 手动验证：关闭 Mermaid 开关，含图表的文件不再渲染图表（图表代码块正常显示）
- [x] 5.5 运行 `make app` 确认构建成功

## 6. 收尾

- [x] 6.1 更新 README 说明设置面板入口位置
- [x] 6.2 更新 `openspec/project.md` 中的配置管理说明
