# Change: 轻量设置 GUI 面板

## Why

当前 FluxMarkdown 的配置完全依赖代码层面的默认值，普通用户无法调整主题偏好、字体大小基准等个性化选项，降低了产品的易用性。引入一个轻量的 SwiftUI 设置面板，让用户通过图形界面完成常用配置，无需接触代码或配置文件。

## What Changes

- 在 Host App 中添加 SwiftUI `Settings` 视图（通过 `Settings {}` 场景或 `Preferences` 菜单）
- 初始版本提供以下可配置项：
  - **主题**：Light / Dark / System（下拉或分段选择器）
  - **默认字体大小**：字号基准调节（滑块或步进器，范围 12–24pt）
  - **代码高亮主题**：从预置主题列表中选择
  - **渲染开关**：Mermaid、KaTeX、Emoji 等可独立开关
- 配置项写入 `AppearancePreference.swift` 管理的 `UserDefaults`，与现有偏好存储体系一致
- 设置变更实时生效（下次 QuickLook 打开时应用，无需重启）

## Impact

- Affected specs: `settings-ui`（新建）
- Affected code:
  - `Sources/Markdown/`（新增 Settings SwiftUI 视图）
  - `Sources/Shared/AppearancePreference.swift`（扩展偏好项）
  - `web-renderer/src/index.ts`（接收并应用来自 Swift 的配置参数）
  - `project.yml`（新增 Settings 视图文件）
