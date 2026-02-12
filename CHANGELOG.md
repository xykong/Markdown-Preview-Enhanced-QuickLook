# Changelog

## [Unreleased]

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
