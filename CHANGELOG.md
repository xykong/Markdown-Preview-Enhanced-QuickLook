# Changelog

## [Unreleased]
_无待发布的变更_

## [1.12.136] - 2026-02-11

### Added
- **双模式显示 (Preview/Source Toggle)**: 实现预览模式与源码模式的快速切换功能。
  - **QuickLook 预览**:
    - 右上角新增源码/预览切换按钮 (文档图标 ↔ 眼睛图标)
    - 源码模式使用 `highlight.js` 实现 Markdown 语法高亮
    - 显示原始 Markdown 源码,支持选择和复制
    - 快捷键 `Cmd+Shift+M` 快速切换模式
    - 切换模式时保持当前滚动位置
  - **主应用**:
    - 添加与 QuickLook 一致的浮动按钮组 (源码 + 主题切换)
    - View 菜单中新增 "Show Source/Show Preview" 选项
    - 支持键盘快捷键 `Cmd+Shift+M` 切换
  - **用户体验优化**:
    - 源码视图留白最小化 (外层 padding: 0px, 代码块 padding: 6px)
    - 表格内容 TOC 按钮下移 40px (top: 20px → 60px),避免与功能按钮重叠
    - 等宽字体显示源码,适配浅色/深色主题
  - **技术实现**:
    - 新增 `ViewMode` 枚举管理当前显示模式
    - 新增 `window.renderSource()` 函数渲染带语法高亮的源码
    - 新增 `source-view.css` 样式文件

## [1.11.130] - 2026-02-11

### Added
- **链接导航 (Link Navigation)**: 为 Markdown 文档添加完整的链接跳转支持。
  - **主应用 (Main App)**:
    - 外部 URL 链接 (http/https) 在默认浏览器中打开
    - 相对路径链接 (`../file.md`, `./dir/file.md`) 正确解析并打开目标文件
    - 页内锚点链接 (`#section`) 平滑滚动定位
    - 支持所有文件类型 (`.md`, `.sql`, `.py`, `.json` 等)
  - **QuickLook 预览 (Preview)**:
    - 由于 macOS 沙盒限制,所有链接点击时显示优雅的 toast 提示而非打扰用户的对话框
    - Toast 位置: 顶部居中
    - 自动关闭: 3 秒后淡出消失
    - 非阻塞: 用户可继续浏览文档
    - 防重复: 同时只显示一个 toast
    - 提示文案: "QuickLook 预览模式不支持链接跳转 / 请双击 .md 文件用主应用打开以使用完整功能"
  - **技术实现**:
    - 端到端桥接: JavaScript 通过 `window.webkit.messageHandlers.linkClicked` 将链接信息传递给 Swift
    - 页内锚点: JavaScript 直接处理平滑滚动
    - 文件路径解析: 支持相对路径、绝对路径、`file://` 协议等多种格式
    - 日志增强: 所有链接点击操作记录到系统日志,便于调试

## [1.10.127] - 2026-02-10

### Added
- **滚动位置记忆**: 自动记录每个 Markdown 文件的滚动位置，下次打开时自动恢复到上次查看的位置。
  - 支持记录最近 100 个文件的位置
  - 使用 LRU（最近最少使用）策略自动管理存储
  - 存储位置通过 App Group 在主 App 和 QuickLook 扩展间共享

## [1.10.124] - 2026-02-09
_无待发布的变更_

## [1.10.119] - 2026-02-09

### Security
- **沙盒权限优化**: 将 QuickLook 扩展的文件访问权限从整个文件系统 (`/`) 缩小到仅用户主目录 (`$HOME/`),大幅提升安全性。
  - **改进内容**:
    - 修改 entitlements 配置: `com.apple.security.temporary-exception.files.absolute-path.read-only` 从 `/` 改为 `$HOME/`
    - 权限对话框文案从"访问所有数据"改为更友好的"访问您的主文件夹"
    - 添加完整的中英文用户指引和故障排查文档
  - **安全性提升**:
    - ✅ 无法访问系统目录 (`/System/`, `/Library/`)
    - ✅ 无法访问其他用户数据 (`/Users/other-user/`)
    - ✅ 无法访问应用程序数据
    - ✅ 仅限访问当前用户的主目录
  - **功能影响**:
    - ✅ 覆盖 99% 的真实使用场景(用户 Markdown 文件几乎都在 `$HOME` 下)
    - ✅ 相对路径图片(同目录、子目录、上层目录)仍可正常工作
    - ✅ 用户主目录内的绝对路径图片仍可正常工作
    - ❌ 不再支持系统目录和其他用户目录的绝对路径
  - **用户体验**:
    - 权限对话框更清晰易懂
    - 仅需授权一次,之后不再弹窗
    - 提供完整的故障排查指南

### Fixed
- **WKWebView 进程泄漏**: 修复 QuickLook 扩展中 WKWebView 进程累积导致严重内存占用问题。
  - **问题表现**: 预览多个 Markdown 文件时，会累积创建 30+ 个 "Web Content" 进程，每个进程占用 60-80MB，总内存占用达 2GB+。
  - **根本原因**:
    1. 缺少 `WKProcessPool` 共享机制
    2. 自定义 URL scheme handler (`local-resource://`) 阻止了进程共享（WebKit 安全设计）
    3. WKWebView 没有被正确清理，导致 retain cycle 无法打破
  - **解决方案**:
    1. 添加共享的 `WKProcessPool` 用于所有 WKWebView 实例
    2. 移除不必要的 `local-resource://` 自定义 scheme handler（图片已通过 data URL 传递）
    3. 在 `viewWillDisappear` 和 `deinit` 中添加完整的 WKWebView 清理逻辑：
       - `stopLoading()` 停止所有加载
       - 移除 `navigationDelegate` 和 `messageHandler` 引用，打破 retain cycle
       - 清理手势识别器
       - 从视图层级移除并释放引用
  - **修复效果**:
    - Web Content 进程数量从 30+ 降低到 1-2 个
    - 总内存占用从 2GB+ 降低到 100-200MB
    - 进程和内存占用保持稳定，不再累积
  - **影响范围**:
    - QuickLook 扩展 (`PreviewViewController.swift`)
    - 主应用 (`MarkdownWebView.swift`) - 为一致性也添加了共享 process pool

### Docs
- 添加首次使用权限请求说明,解释为什么需要权限以及如何处理
- 添加完整的 Troubleshooting 章节,涵盖权限管理、图片显示、QuickLook 预览等常见问题
- 更新技术文档 `docs/ABSOLUTE_PATH_SUPPORT.md`,说明新的安全限制和权限范围

## [1.9.118] - 2026-02-09

### Fixed
- **WKWebView 进程泄漏**: 修复 QuickLook 扩展中 WKWebView 进程累积导致严重内存占用问题。
  - **问题表现**: 预览多个 Markdown 文件时，会累积创建 30+ 个 "Web Content" 进程，每个进程占用 60-80MB，总内存占用达 2GB+。
  - **根本原因**:
    1. 缺少 `WKProcessPool` 共享机制
    2. 自定义 URL scheme handler (`local-resource://`) 阻止了进程共享（WebKit 安全设计）
    3. WKWebView 没有被正确清理，导致 retain cycle 无法打破
  - **解决方案**:
    1. 添加共享的 `WKProcessPool` 用于所有 WKWebView 实例
    2. 移除不必要的 `local-resource://` 自定义 scheme handler（图片已通过 data URL 传递）
    3. 在 `viewWillDisappear` 和 `deinit` 中添加完整的 WKWebView 清理逻辑：
       - `stopLoading()` 停止所有加载
       - 移除 `navigationDelegate` 和 `messageHandler` 引用，打破 retain cycle
       - 清理手势识别器
       - 从视图层级移除并释放引用
  - **修复效果**:
    - Web Content 进程数量从 30+ 降低到 1-2 个
    - 总内存占用从 2GB+ 降低到 100-200MB
    - 进程和内存占用保持稳定，不再累积
  - **影响范围**:
    - QuickLook 扩展 (`PreviewViewController.swift`)
    - 主应用 (`MarkdownWebView.swift`) - 为一致性也添加了共享 process pool

## [1.8.114] - 2026-02-05

### Added
- **页内搜索功能**: 为主应用添加完整的页内搜索功能。
  - **功能特性**:
    - ✅ 浏览器风格的搜索工具栏 (Cmd+F 触发)
    - ✅ 实时高亮所有匹配项 (黄色背景)
    - ✅ 当前匹配项特殊高亮 (橙色背景)
    - ✅ 匹配计数显示 (如 "3/15")
    - ✅ 上一个/下一个匹配导航
    - ✅ 三种搜索模式:
      - 普通搜索 (默认)
      - 大小写敏感匹配 (Aa 选项)
      - 全字匹配 (ab 选项)
      - 正则表达式搜索 (.* 选项)
    - ✅ 正则表达式错误提示
  - **触发方式**:
    - Cmd+F 键盘快捷键
    - View 菜单 → "查找..." / "Find..."
    - 右键菜单 → "查找..." / "Find..."
  - **国际化支持**:
    - 英文: "Find..."
    - 简体中文: "查找..."
  - **主题支持**: 自动适配亮色/深色模式
  - **注意**: QuickLook 预览模式暂不支持搜索功能

### Fixed
- **Swift 编译警告**: 修复 `startAccessingSecurityScopedResource()` 返回值未使用的警告

## [1.7.112] - 2026-02-04
_无待发布的变更_

## [1.7.110] - 2026-02-04

### Fixed
- **APP 模式图片显示**: 修复双击打开 APP 时本地图片无法显示的问题。
  - **根本原因**: 主 APP 缺少图片收集逻辑,且 macOS App Sandbox 限制了文件访问权限
  - **解决方案**:
    1. 在 `MarkdownWebView.swift` 中添加 `collectImageData()` 方法(与 QuickLook Extension 保持一致)
    2. 在 `executeRender()` 中调用图片收集并转换为 base64 data URLs
    3. 临时禁用 App Sandbox 以允许读取 Markdown 文件同目录下的图片
  - **支持特性**:
    - ✅ 相对路径图片 (`./image.png`, `../image.png`)
    - ✅ 绝对路径图片 (`/path/to/image.png`)
    - ✅ `file://` 协议图片
    - ✅ 多种图片格式 (PNG, JPEG, GIF, SVG, WebP, ICO, BMP)
    - ✅ 图片带标题 (`![alt](url "title")`)
    - ✅ 特殊字符路径 (URL 编码自动处理)

## [1.7.109] - 2026-02-04

### Fixed
- **Base64 图片显示**: ✅ 完全修复 Base64 内嵌图片（`data:image/...`）无法显示的问题。
  - **根本原因分析**:
    1. WKWebView 在沙盒环境中阻止 data: URLs
    2. markdown-it 的 URL 验证拒绝 `data:image/svg+xml` 等复杂 MIME 类型（核心问题）
  - **解决方案**:
    1. 将 `loadFileURL` 改为 `loadHTMLString`（允许更灵活的内容加载）
    2. 添加 `allowUniversalAccessFromFileURLs` 配置到 WKWebViewConfiguration
    3. **关键修复 A**: 覆盖 `md.validateLink` 方法，允许所有 `data:` URLs 通过 markdown-it 验证
    4. **关键修复 B**: 将 Base64 data URLs 转换为 Blob URLs（绕过 WKWebView 的 data: scheme 限制）
  - **验证结果**: 
    - ✅ Markdown 语法 `![](data:image/png;base64,...)` - 完全正常
    - ✅ Markdown 语法 `![](data:image/svg+xml;base64,...)` - 完全正常
    - ✅ HTML 标签 `<img src="data:image/...">` - 完全正常
    - ✅ 支持所有格式：PNG、JPEG、SVG、GIF、WebP
  - 改进 TypeScript 图片渲染逻辑，明确区分三种图片类型：Base64 内嵌、本地文件、网络 URL
  - 添加全面的单元测试覆盖所有图片类型（26 个测试全部通过）
  - 增强日志输出，显示每个图片的处理过程，便于调试

- **图片显示**: 修复多种图片路径无法显示的问题。
  - 修复绝对文件系统路径（`/path/to/image`）不显示的问题
  - 修复上级目录相对路径（`../image.png`）不显示的问题
  - 修复图片带标题（`![alt](url "title")`）不显示的问题
  - 修复特殊字符路径（`image%20(1).png`）不显示的问题
  - 修复空格路径（`test images/test image.png`）不显示的问题
  - 实现方式：Swift 端收集所有图片并转换为 base64 data URL，TypeScript 端使用 base64 替换原始路径

### Fixed
- **自动更新**: 修复安装新版本时报错 "An error occurred while running the updater" 的问题。
  - 使用正确的 Sparkle XPC 服务名称：`$(PRODUCT_BUNDLE_IDENTIFIER)-spks` 和 `$(PRODUCT_BUNDLE_IDENTIFIER)-spki`。
  - 之前使用的服务名 `com.xykong.Markdown.Installer` 不符合 Sparkle 规范，导致更新器无法正常运行。

## [1.6.96] - 2026-02-04

### Fixed
- **自动更新**: 修复安装新版本时报错 "An error occurred while launching the installer" 的问题。
  - 添加 `com.apple.security.temporary-exception.mach-lookup.global-name` 权限，允许 Sparkle 安装器与主应用通信。
  - 添加 `com.apple.security.temporary-exception.files.absolute-path.read-write` 权限，允许 Sparkle 写入 `/Applications` 目录。
  - 在 Info.plist 中启用 `SUEnableInstallerLauncherService`，支持沙盒应用的安装器启动服务。

### Added
- **测试工具**: 新增本地更新测试脚本 `scripts/test-update-simple.sh` 和 `scripts/test-update-locally.sh`。

## [1.6.93] - 2026-02-04

### Fixed
- **自动更新**: 修复手动检查更新无响应的问题。
  - 使用 `SPUStandardUpdaterController` 替代手动组装 `SPUUpdater` + `SPUStandardUserDriver`，这是 Sparkle 2.x 推荐的 SwiftUI 集成方式。
  - 使用 `NSApp.sendAction()` 正确触发更新检查的 AppKit action。

## [1.6.90] - 2026-02-03

## [1.5.87] - 2026-02-03

### Added
- **自动更新 (Auto Update)**: 实现混合更新策略，同时支持 Homebrew 和 DMG 安装用户。
  - **Homebrew 用户**: 每周自动检查 GitHub API，发现新版本时提示运行 `brew upgrade`，一键复制更新命令。
  - **DMG 用户**: 集成 Sparkle 2.8.1 框架，每天自动检查更新，支持 EdDSA 签名验证，自动下载安装。
  - **智能检测**: 自动识别安装方式（Homebrew Caskroom vs 手动 DMG），应用对应的更新策略。
  - **安全验证**: 使用 EdDSA 签名确保更新来源可信，私钥存储在 `.sparkle-keys/`（已加入 `.gitignore`）。
  - **自动化发布**: `make release` 命令现在自动生成 Sparkle 签名、更新 `appcast.xml`、更新 Homebrew Cask。
  - **新增脚本**: `generate-sparkle-keys.sh`（密钥生成）、`generate-appcast.sh`（appcast 生成）。
  - **新增文档**: `docs/AUTO_UPDATE.md` 完整使用指南。

### Changed
- **项目结构 (Project Structure)**: 重组项目目录结构，提升可维护性。
  - 将所有文档整理到 `docs/` 目录：`docs/features/`（功能文档）、`docs/testing/`（测试文档）。
  - 将所有测试文件整理到 `tests/` 目录：`tests/fixtures/`（测试样本）、`tests/scripts/`（测试脚本）。
  - 合并相关文档：将 `ZOOM_FEATURE.md`、`ZOOM_STATUS.md`、`QUICK_START_ZOOM.md` 合并为 `docs/features/ZOOM.md`。
  - 更新所有文件引用路径，确保文档和脚本中的路径正确。
  - 根目录现在只保留核心项目文件（README、Makefile、配置文件等）。

### Added
- **预览 (Preview)**: 实现实时文件监控和自动刷新功能。
  - 使用 `DispatchSource` 监控文件系统事件（写入、删除、重命名）。
  - 当文件被外部编辑器修改时，预览自动更新内容，无需手动关闭并重新打开。
  - 保留滚动位置和缩放级别，提供流畅的用户体验。
  - 正确的生命周期管理，确保资源清理和内存安全。

## [1.4.81] - 2026-01-14

### Added
- **预览 (Preview)**: 添加缩放功能。
  - 支持键盘快捷键：`Cmd +` (放大), `Cmd -` (缩小), `Cmd 0` (重置)。
  - 支持触控板/鼠标滚轮缩放：按住 `Cmd` 键并滚动。
  - 支持双指拉伸缩放：使用触控板双指拉伸手势进行缩放。
  - 缩放范围：0.5x - 3.0x。
  - 自动保存缩放级别，下次打开时恢复。
- **安装 (Installation)**: 实现完全自动化的安装过程。
  - `install.sh` 脚本现在自动设置应用为 `.md` 文件的默认处理程序。
  - 自动移除隔离属性 (`xattr -cr`)。
  - 自动启动应用完成 QuickLook 扩展注册。
  - 支持 `make install debug` 命令安装调试版本。
  - 使用 `duti`（如果可用）或 LaunchServices API 设置文件关联。
- **构建 (Build)**: 改进 `Makefile` 构建流程。
  - 添加 `install`, `dmg`, `release`, `delete-release` 伪目标。
  - 增强 `app` 目标，添加构建日志和指定 arm64 架构。
  - 支持自动检测和构建调试/发布配置。

### Changed
- **文档 (Documentation)**: 更新安装说明，移除需要用户手动设置默认应用的步骤。
  - 强调安装过程已完全自动化。
  - 添加 `make install debug` 命令说明。

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
