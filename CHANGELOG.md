## [Unreleased]

### Added
- **PDF 导出分页功能**: 导出 PDF 时自动将长文档分页为标准 A4 页面
  - 使用 CoreGraphics 将单页 PDF 切片为多个 A4 页面
  - 添加 `@media print` CSS 规则优化打印样式（防止代码块、图片跨页截断）
  - 最后一页内容自动对齐到页面顶部
- **欢迎窗口 (Welcome Window)**: 直接启动 App 时显示友好的欢迎界面，引导用户快速上手
  - 大号 "+" 按钮支持点击打开文件或拖拽文件到窗口
  - 简洁的使用提示：QuickLook 空格预览、双击打开、拖拽文件
  - 快捷入口：Open Settings (Cmd+,)、Troubleshooting 帮助文档
  - 显示应用图标，提升品牌识别度
- **用户友好帮助文档**: 新增 `docs/user/HELP.md`，由浅入深引导用户
  - 先体验成功（Space 预览）
  - 常见问题由简到难排查
  - 文末引导到高级排障文档

### Fixed
- **HTML 导出功能重构**: 参考 MPE (Markdown Preview Enhanced) 方案，彻底重构 HTML 导出逻辑
  - 生成纯净的独立 HTML 文件，不再包含臃肿的 JS Bundle（文件体积大幅缩小）
  - 内联所有 CSS 样式，确保离线打开时格式、字体、代码高亮正确显示
  - 自动将本地图片（GIF、PNG、JPG、SVG、WebP）转换为 base64 Data URI，确保图片在任意环境下正常显示
  - 导出的 HTML 可直接分享给他人，无需依赖原始文件路径
- **构建过程警告修复**: 清理 `make install` 过程中的冗余警告信息
  - 抑制 xcodebuild 的 DVTDeviceOperation 内部警告（Xcode 15/16 已知问题）
  - 抑制 Vite 打包的 chunk size 警告（本地应用无需严格限制块大小）
  - 静默 Vite 详细构建日志，提升输出可读性
- **安装脚本兼容性修复**: 修复 macOS 新版本上默认应用设置失败的问题
  - 将废弃的 Python LaunchServices 脚本替换为 Swift 原生实现
  - 修复 macOS 12+ 不再自带 LaunchServices Python 模块的问题

### Changed
- **Troubleshooting 文档优化**: 在 `docs/user/TROUBLESHOOTING.md` 顶部添加提示，引导普通用户先看 HELP.md

## [1.16.195] - 2026-02-26

### Changed
- **文档结构重组**: 按主题分层重构 `docs/` 目录结构，提升文档可维护性和可发现性
  - 新增 `docs/README.md` 作为文档总索引
  - 按主题分层：`docs/{user,dev,release,design,debug,testing,performance,research,licenses,history}/`
  - 合并图片相关文档到 `docs/features/IMAGES.md`，原始详细文档归档至 `docs/history/images/`
  - 合并性能相关文档到 `docs/performance/PERFORMANCE.md`，原始详细文档归档至 `docs/history/performance/`
  - 统一测试路径引用：`tests/` → `Tests/`
  - 删除根目录竞品 README 副本，仅保留 `docs/research/COMPETITIVE_ANALYSIS.md` 中的分析
  - 清理所有 `.DS_Store` 文件

### Fixed
- **搜索功能导致文件被标记为已编辑**: 修复在 Host App 中使用搜索功能时，Markdown 文件被错误标记为「已编辑」且修改时间戳更新的问题 (#8)
  - Host App: 为 `ResizableWKWebView` 隔离独立的 `UndoManager`，避免搜索输入触发 `DocumentGroup` 的 autosave
  - QuickLook Extension: 修复 security-scoped 资源访问泄漏，添加文件监控的 size/mtime 门禁
  - Web Renderer: 移除搜索框的 100ms 延迟 focus，添加 `stopPropagation()` 防止按键冒泡

### Added
- **脚注支持（Footnotes）**: 使用 `[^1]` 语法添加脚注，脚注内容自动渲染在文档底部
- **上标 / 下标**: 支持 `H~2~O`（下标）和 `x^2^`（上标）语法，适用于化学式和数学表达式
- **`==高亮==` 语法**: 使用 `==文本==` 语法高亮标注重要内容，渲染为 `<mark>` 标签
- **Smart 排版（Typographer）**: 自动转换直引号为弯引号（`"` → `""`），`--` 为连接号（–），`---` 为破折号（—）
- **Raw 源码切换**: 点击预览窗口右上角 `</>` 按钮，可在渲染视图与原始 Markdown 源码（带语法高亮）之间切换

### Added
- **YAML Frontmatter 支持**: 自动解析文档头部的 YAML 元数据，以表格形式美观展示
- **GitHub Alerts 支持**: 渲染 `> [!NOTE]`、`> [!WARNING]` 等 GitHub 风格提示框
- **扩展代码高亮**: 新增 20+ 种语言支持（Scala、Perl、R、Dart、Lua、Haskell、Elixir、Groovy、Verilog、VHDL、Makefile、TOML、Protobuf、GraphQL、PowerShell、Objective-C 等）
- **Vega/Vega-Lite 图表**: 支持 `vega` 和 `vega-lite` 代码块渲染为交互式 SVG 图表
- **Graphviz 图表**: 支持 `dot`/`graphviz` 代码块渲染为 SVG 图
- **导出功能**: 新增「导出为 HTML」和「导出为 PDF」菜单项（Cmd+Shift+E / Cmd+Shift+P）
- **Settings 界面**: 全新设计的偏好设置窗口（Cmd+,），支持：
  - Appearance: Light / Dark / System 主题切换
  - Rendering: Mermaid / KaTeX / Emoji 开关
  - Editor: 字体大小调整、代码高亮主题选择（Default / GitHub / Monokai / Atom One Dark）
- **文件格式支持**: 新增 `.mdx`、`.rmd`、`.qmd`、`.mdoc`、`.mkd`、`.mkdn`、`.mkdown` 扩展名

### Fixed
- **Host App Loading 卡死**: 修复 Host App 打开文档后一直显示 "Loading renderer..." 的问题（添加 `allowUniversalAccessFromFileURLs` 配置）
- **Settings 主题按钮点击失效**: 修复 Appearance 界面 Light/Dark/System 按钮随机无法点击的问题（ZStack 重构 hit-test 层级）
- **字体大小设置不生效**: 修复 Editor 中调整字体大小后文档无变化的问题
- **代码高亮主题不生效**: 修复 Editor 中切换代码主题后文档无变化的问题
- **KaTeX 开关不生效**: 修复 Rendering 中关闭 KaTeX 后公式仍然渲染的问题（动态重建 MarkdownIt 实例）
- **Emoji 开关不生效**: 修复 Rendering 中关闭 Emoji 后 `:name:` 格式仍然转换为图标的问题

## [1.15.165] - 2026-02-22

### Added
- **性能基线测试基础设施**:
  - 新增三层性能测试框架 (JS 引擎层 / Swift-WKWebView 层 / QuickLook 系统层)
  - 新增 7 个标准 Markdown fixture 文件用于可重复性测试
  - 新增 `benchmark/js-bench/` - Playwright 驱动的 JS 渲染基准测试
  - 新增 `benchmark/swift-bench/` - XCTest 驱动的 WKWebView 桥接层测试
  - 新增 `benchmark/ql-bench/` - qlmanage 端到端系统层测试
  - 新增 `benchmark/compare.py` - 优化前后对比脚本
  - 新增 `benchmark/run-all.sh` - 一键运行全部测试
- 新增 `docs/history/performance/BENCHMARK_BASELINE.md` - 完整基线测试报告文档
  - 记录了优化前的性能基线数据，为后续优化提供量化对比基准

### Changed
- **重大性能优化 (7项)**:
  - **P0 Bundle 拆分**: 移除 `vite-plugin-singlefile`，改用标准多文件输出 + `loadFileURL`
    - `index.html` 从 5.5 MB 降至 1.84 KB (-99.97%)
    - Swift 侧从 `loadHTMLString()` 改为 `loadFileURL(_:allowingReadAccessTo:)`
  - **P1-A highlight.js Tree-shaking**: 全量导入改为 `highlight.js/core` + 按需注册 24 种语言
    - hljs 贡献从 ~400 KB 降至 ~80 KB (-80%)
  - **P1-B Mermaid 单例化**: `mermaid.initialize()` 改为仅主题变化时调用
    - mermaid 热渲染从 ~186ms 降至 ~46ms (-75%)
  - **P2-A 图片 I/O 异步化**: `collectImageData()` 移至后台 `Task.detached`
    - 消除主线程图片 I/O 阻塞
  - **P2-B LocalSchemeHandler 启用**: 注册已实现未启用的 `local-md://` scheme handler
    - 删除 ~50 行 base64→Blob 转换代码，图片改为按需加载
  - **KaTeX 懒加载**: 改为按需动态 import，仅含公式文档加载
    - `index.js` 从 554 KB 降至 317 KB (-43%)
  - **Mermaid 预热**: 渲染后空闲时刻预热 mermaid chunk
    - 同会话二次打开 mermaid 文档从 ~380ms 降至 ~20ms

## [1.14.164] - 2026-02-18

### Changed
- **⚠️ LICENSE 变更为双许可证模式（重大变更）**:
  - **开源许可证**: 从 Non-Commercial 改为 **GPL-3.0**
    - ✅ 个人、教育、开源项目可免费使用
    - ✅ 任何修改必须以 GPL-3.0 开源
    - ✅ 满足 Homebrew 官方 cask 提交要求
  - **商业许可证**: 为闭源商业使用提供选项
    - 📧 联系 xy.kong@gmail.com 咨询商业授权
    - 📜 详情见 `LICENSE.COMMERCIAL`
  - **影响**: 
    - ✅ 移除了商业使用的硬性限制
    - ✅ 允许提交到 Homebrew 官方仓库
    - ✅ 允许企业和开源项目自由采用
    - ⚠️ 如需闭源商业化，需购买商业许可证

### Added
- **README 首屏优化**: 改进项目首页的视觉呈现和用户体验
  - 添加演示 GIF (`docs/assets/demo.gif`)，展示 Mermaid、KaTeX、代码高亮、TOC 等核心功能
  - 添加 GitHub badges（Stars、Release、Downloads、License）以增强信任度
  - 添加快速导航链接（中文文档、安装、常见问题）
  - 添加显式 Star CTA（Call-to-Action）以提升 Star 转化率
  - 改进 Troubleshooting 部分使用折叠式 `<details>`，降低视觉噪音
  - 同步更新中英文 README（README.md 和 README_ZH.md）

## [1.13.158] - 2026-02-16
_无待发布的变更_

## [1.13.156] - 2026-02-16
_无待发布的变更_

## [1.13.150] - 2026-02-13

### Added
- **更新后自动恢复文件**: 更新后自动打开上次查看的 Markdown 文件
  - 在主应用打开文件时自动保存文件路径
  - 通过 Sparkle 更新器检测更新安装事件
  - 更新完成后应用重启时自动恢复上次打开的文件
  - 使用 App Groups (group.com.xykong.Markdown) 实现跨进程持久化存储
  - 如果用户之前查看的文件已被删除，会优雅地处理失败情况
  - 只在更新后触发恢复，正常启动不会影响用户体验

## [1.13.149] - 2026-02-13

### Fixed
- **菜单重复问题**: 修复主应用菜单栏中出现两个 "View" 菜单的问题
  - 将 `CommandMenu("View")` 改为 `CommandGroup(after: .windowArrangement)`
  - 菜单项现在正确添加到系统默认的 View 菜单中，而不是创建新的独立菜单
- **国际化支持 (i18n)**: 修复"检查更新"菜单项和 QuickLook 预览中的 Toast 消息在英文系统中显示中文的问题
  - 将硬编码的中文文本替换为 `NSLocalizedString` 调用
  - 在 `en.lproj/Localizable.strings` 和 `zh-Hans.lproj/Localizable.strings` 中添加对应的翻译
  - 修复的字符串包括：
    - "Check for Updates..." (检查更新...)
    - "QuickLook preview does not support link navigation" (QuickLook 预览模式不支持链接跳转)
    - "Double-click .md file to open in main app for full functionality" (请双击 .md 文件用主应用打开以使用完整功能)


### Changed
- **菜单布局优化**: 优化菜单栏结构以符合 Apple Human Interface Guidelines (HIG)
  - **Find 菜单曲目**: 从 Window 菜单移至 Edit 菜单（位置：.textEditing 组）
    - 符合 macOS 标准惯例，快捷键 ⌘+F
  - **Show Source 菜单项**: 从 Window 菜单移至 View 菜单（位置：.toolbar 组）
    - 快捷键 ⌘+⇧+M，更适合视图切换操作
  - **Appearance 子菜单**: 从 Window 菜单移至 View 菜单（位置：.toolbar 组）
    - 主题选择属于视图配置，不符合窗口管理范畴
  - **Window 菜单**: 现在仅保留窗口管理相关功能
## [1.13.141] - 2026-02-13

### Fixed
- **锚点跳转宽容匹配（Anchor Link Tolerant Matching）**: 修复手写目录链接与自动生成的 anchor ID 不匹配的问题。
  - **问题场景**: 用户手写目录时，链接可能使用多个连字符（`---`）或混淆下划线（`_`）与连字符（`-`），导致跳转失败
  - **解决方案**: 实现三层渐进式匹配策略
    - **Level 1（最高优先级）**: 精确匹配，保证准确性
    - **Level 2**: 压缩多个连续连字符（`---` → `-`），解决手写目录多连字符问题
    - **Level 3**: 统一下划线和连字符（`_` ≈ `-`），解决视觉相似字符混淆问题
  - **优先级保证**: 当文档中同时存在相似标题时，优先跳转到精确匹配的标题
  - **技术实现**:
    - 新增 `compressMultipleHyphens()` 函数压缩连字符
    - 新增 `unifyUnderscoreAndHyphen()` 函数统一下划线和连字符
    - 新增 `findElementByAnchor()` 函数实现三层渐进式查找
    - 更新主内容区和目录面板的链接点击处理器
  - **测试覆盖**: 新增 `test/anchor-matching.test.ts`，包含 10 个测试用例，覆盖所有匹配层级和优先级场景
  - **兼容性**: 与主流 Markdown 编辑器（Typora、VSCode）的宽容行为一致，提升用户体验
  - **用户体验**:
    - 手写目录小错误不再影响跳转
    - 不需要精确记住下划线还是连字符
    - 容错设计，减少用户认知负担
