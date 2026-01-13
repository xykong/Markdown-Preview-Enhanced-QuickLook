# Changelog

## [Unreleased]

## [1.3.73] - 2026-01-13

### Fixed
- **QuickLook**: 修复双击 Markdown 文件时意外触发"使用默认应用打开"的问题。（感谢 [@sxmad](https://github.com/sxmad) 的贡献 [#2](https://github.com/xykong/markdown-quicklook/pull/2)）
  - 通过自定义 `InteractiveWebView` 子类拦截鼠标事件，防止事件冒泡到 QuickLook 宿主。
  - 添加 `NSClickGestureRecognizer` 拦截双击手势，确保 WebView 内的交互（如文本选择）不受影响。
  - 实现 `acceptsFirstMouse(for:)` 方法，允许 WebView 直接响应首次点击事件。

## [1.2.69] - 2026-01-12

### Added
- **预览 (Preview)**: 自动生成文档目录（Table of Contents）。
  - 自动从 Markdown 文档提取标题结构，无需手动添加 `[toc]` 标记。
  - 浮动式可折叠目录面板，支持 H1-H6 层级展示。
  - 智能导航：点击目录项平滑滚动到对应章节，自动高亮当前阅读位置。
  - 响应式设计：窗口宽度小于 1200px 时自动隐藏。
  - 完整的亮色/暗色主题支持，与系统主题同步。
- **预览 (Preview)**: 支持链接导航。
  - 支持锚点链接（`#id`）平滑滚动定位。
  - 外部链接（http/https）使用系统默认浏览器打开。
  - 本地 `.md` 文件链接通过 `NSWorkspace` 打开。
  - 引入 `markdown-it-anchor` 为标题生成稳定的 ID。

### Fixed
- **QuickLook**: 修复在预览界面右键点击 **Reload** 后卡在 "Loading renderer..." 且不会重新渲染的问题。

## [1.1.65] - 2026-01-09

### Added
- **App**: 支持 `--register-only` 启动参数。该参数允许应用在无界面模式下启动并立即退出，用于安装脚本触发 QuickLook 扩展注册。
- **预览 (Preview)**: 实现了大文件截断机制。为了防止渲染过大文件导致 QuickLook 卡死，超过 500KB 的文件将只渲染前 500KB，并在底部显示截断警告。
- **扩展 (Extension)**: 在 QuickLook 预览界面添加了悬浮的主题切换按钮，允许用户直接在预览中切换亮/暗模式。
- **架构 (Architecture)**: 引入 App Groups 支持。重构了 `AppearancePreference`，使用 App Group 同步主应用和扩展之间的配置（如主题设置）。
- **内部 (Internal)**: 实现了 `LocalSchemeHandler`，用于在 QuickLook 扩展的严格沙盒环境下安全加载本地图片资源。
- **宿主应用 (Host App)**: 实现了窗口大小和位置的持久化。应用现在能跨启动记住上次的窗口位置和大小。
- **外观设置**: 增加了“视图” > “外观”菜单，支持手动切换 **浅色**、**深色** 或 **跟随系统** 模式。
- **宿主浏览器**: 主应用现在作为一个独立的 Markdown 阅读器（只读模式）运行。
  - 支持通过 Finder 或“文件”>“打开”加载本地 `.md` 文件。
  - 实现了注入 `baseUrl` 的 `MarkdownWebView` 以正确解析本地资源。
  - 支持渲染相对路径的本地图片（如 `![alt](image.png)`）。
  - 实现了链接导航：外部链接在 Safari 打开，本地 `.md` 链接在应用新窗口打开。
- **文档**:
  - 新增 `docs/DESIGN_HOST_APP_BROWSER.md` 设计文档。
  - 新增 `docs/OPTIMIZATION_ROADMAP.md`，详细分析了性能和体验优化方向。

### Changed
- **性能 (Performance)**: 优化了 Mermaid.js 的加载策略。现在采用懒加载（Lazy Load）模式，仅在文档包含图表时才加载 Mermaid 库，显著提升了普通文档的打开速度。
- **渲染器 (Renderer)**: 改进了 Mermaid 图表渲染。
  - 改为按块（Per-block）渲染，防止单个图表错误导致整个页面渲染失败。
  - 增加了健壮的错误处理：无效的 Mermaid 语法现在会显示友好的错误信息及源码，而不是静默失败。
  - 增加了错误信息的暗色模式支持。
- **预览 (Preview)**: 增强了窗口调整逻辑。
  - 增加了智能屏幕边界约束，防止恢复的窗口超出当前屏幕可视范围。
  - 改进了调整大小的追踪生命周期，防止视图消失（Disappear）时发生布局抖动。
  - 增加了详细的环境日志，用于调试屏幕和窗口状态。
- **渲染器 (Renderer)**: 移除了最大宽度限制（原为 980px），允许预览内容充满整个窗口宽度，提供更沉浸的阅读体验。
- **外观 (Appearance)**: 将默认外观模式调整为 **浅色 (Light)**（此前默认跟随系统），以提供更一致的初始体验。
- **外观同步**: 实现了“完美暗色模式同步” (Perfect Dark Mode Sync)。
  - 引入自适应 CSS (`highlight-adaptive.css`)，消除切换主题时的白屏闪烁。
  - 解决了代码块主题与整体主题不匹配的问题。
  - 更新了 Swift 和 TypeScript 通信层，支持传递明确的主题参数以适配 Mermaid 图表。
- **构建系统**: 优化了 `make install`、`make app` 和 `make generate` 的日志输出，仅显示警告和错误，减少终端噪音。

### Fixed
- **QuickLook**: 修复了窗口调整大小的 Bug。增加了忽略初始系统强制约束的逻辑，解决了每次启动预览窗口都会自动变小的问题。
- **渲染器 (Renderer)**: 解决了 QuickLook "白屏" 问题。
  - 从 Webpack/Vite 分块构建切换为 **Vite SingleFile** 构建。
  - 将所有 JS/CSS/字体资源内联到单个 `index.html` 中，彻底规避了沙盒环境下的 CORS 和文件访问限制。
- **预览稳定性**: 增强了渲染器与原生代码的握手机制。
  - 将超时时间延长至 10 秒。
  - 超时后在 WebView 中显示可视化的错误提示。
  - 改进了 WebView 导航事件的竞态条件处理。
- **安装**: 更新了 `install.sh`，默认构建 Release 配置，并增强了在 DerivedData 中定位构建产物的稳健性。
- **稳定性**: 增加了 WebContent 进程意外终止时的自动重载恢复机制。
- **安全**: 补充了缺失的 Entitlements (Network Client, JIT, Printing, Downloads)，提升 WebView 功能支持和稳定性。
- **构建**: 增加了 Webpack 资源大小限制阈值，抑制因内联大文件（Mermaid/KaTeX/Highlight.js）产生的构建警告。

## [1.0.0] - 2025-12-27

### Added
- **构建系统**: 集成了 `xcodegen` 以实现 Xcode 项目的自动化生成。
- **构建工具**: 添加了 `Makefile` 用于编排项目生成和构建流程。
- **项目结构**: 创建了 `Sources/` 目录结构。
- **宿主应用**: 为 QuickLook 扩展创建了基础 Swift 宿主应用 (`MarkdownQuickLook`)。

### Fixed
- **Mermaid**: 升级 `mermaid` 依赖至 v10.0.0+ 以支持 `mermaid.run` API。
- **高亮配置**: 修复了 `markdown-it` 的高亮配置，保留代码块的 `language-*` 类名，确保 Mermaid 图表能被正确识别和渲染。
- **测试**: 为 `web-renderer` 添加了 Jest 测试套件，用于验证渲染逻辑和 API 调用。
