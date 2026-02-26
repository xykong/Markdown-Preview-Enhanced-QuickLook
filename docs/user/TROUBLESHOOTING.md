# Troubleshooting Guide

> 普通用户建议先看：[`HELP.md`](HELP.md)（由浅入深、尽量不需要理解内部原理）。

## Extension Not Registered

### Issue
运行 `qlmanage -m | grep -i markdown` 或 `pluginkit -m -A -D -p com.apple.quicklook.preview | grep markdownquicklook` 没有找到扩展。

### Root Cause 1：未通过 Xcode 正确运行 Host App
Quick Look 扩展的注册机制要求：
1. 扩展必须通过 **Xcode Run** 运行，而不是简单的 `open` 命令
2. macOS 会缓存扩展列表，需要特殊的刷新流程

### Root Cause 2：扩展没有开启沙箱（Sandbox）
如果在日志中看到类似：

```bash
Ignoring mis-configured plugin ... plug-ins must be sandboxed
```

说明扩展本身没有启用 App Sandbox，`pkd` 会直接拒绝注册该插件，即使它已经被打包进 `.app` 中。

修复方式（已经在当前项目中完成）：

1. 为 Host App 和 Extension 分别添加 Entitlements 文件：
   - `Sources/Markdown/Markdown.entitlements`
   - `Sources/MarkdownPreview/MarkdownPreview.entitlements`

2. 在两个 target 的设置中都启用沙箱，并允许用户选择的文件只读访问：

   ```xml
   <!-- 必须：开启 App Sandbox -->
   <key>com.apple.security.app-sandbox</key>
   <true/>

   <!-- 推荐：允许读取用户在 Finder 中选择的 markdown 文件 -->
   <key>com.apple.security.files.user-selected.read-only</key>
   <true/>

   <!-- 仅限开发环境：允许调试器附加 -->
   <key>com.apple.security.get-task-allow</key>
   <true/>
   ```

3. 在 `project.yml` 中为两个 target 指定 `CODE_SIGN_ENTITLEMENTS`（当前仓库已配置好）：

   ```yaml
   Markdown:
     settings:
       CODE_SIGN_ENTITLEMENTS: Sources/Markdown/Markdown.entitlements

   MarkdownPreview:
     settings:
       CODE_SIGN_ENTITLEMENTS: Sources/MarkdownPreview/MarkdownPreview.entitlements
   ```

4. 重新生成并构建工程：

   ```bash
   make app
   ```

5. 再次查看插件是否被注册：

   ```bash
   pluginkit -m -A -D -p com.apple.quicklook.preview | grep -i markdownquicklook
   ```

   正常情况下应能看到：

   ```bash
   com.markdownquicklook.app.MarkdownPreview(1.0)
   ```

### Solution: Use Xcode Debugger

#### 方法 1: 通过 Xcode 运行 (推荐)
```bash
# 1. 生成工程
make generate

# 2. 在 Xcode 中打开
open FluxMarkdown.xcodeproj

# 3. 在 Xcode 中:
#    - 选择 Markdown scheme
#    - 按 Cmd+R 运行
#    - 保持 App 运行状态

# 4. 在新终端窗口:
qlmanage -r
qlmanage -r cache
killall Finder

# 5. 测试
#    在 Finder 中选中 Tests/fixtures/feature-validation.md，按空格
```

#### 方法 2: 使用 qlmanage 命令行测试
```bash
# 直接通过 qlmanage 调用扩展（绕过注册机制）
qlmanage -p Tests/fixtures/feature-validation.md
```

### Additional Checks

#### 查看系统日志
```bash
# Terminal 1: 启动日志监控
log stream --predicate 'subsystem contains "QuickLook" OR subsystem contains "MarkdownPreview"' --level debug

# Terminal 2: 打开文件触发 Quick Look
# 在 Finder 中按空格
```

#### 验证扩展文件完整性
```bash
APP_PATH=~/Library/Developer/Xcode/DerivedData/FluxMarkdown-*/Build/Products/Debug/FluxMarkdown.app

# 检查扩展是否存在
ls -la "$APP_PATH/Contents/PlugIns/MarkdownPreview.appex/Contents/MacOS"

# 检查 Web 资源是否正确复制
ls -la "$APP_PATH/Contents/PlugIns/MarkdownPreview.appex/Contents/Resources/dist"
```

## Known Limitations

### Debug vs Release Build
- **Debug 构建**: 使用的是开发签名，系统可能有额外限制
- **Workaround**: 在 Xcode 中通过 Product → Archive 创建 Release 版本

### Sandbox Restrictions  
macOS App Sandbox 会限制文件访问权限。如果 Markdown 文件引用了本地图片，可能需要额外的 Entitlements。

## Plain Text Preview Even Though Extension Is Registered

### Issue
`pluginkit -m -A -D -p com.apple.quicklook.preview | grep -i markdownquicklook` 能看到：

```bash
com.markdownquicklook.app.MarkdownPreview(1.0)
```

说明 Quick Look 扩展已经被系统识别并注册。但在 Finder 中选中 `.md` 文件按空格时，
Quick Look 仍然只显示**纯文本内容**，没有任何 Markdown 渲染效果（看起来就像普通的
文本预览一样）。

### Root Cause：Host App 不是 Markdown UTI 的默认 Owner

macOS 在选择 Quick Look Preview Extension 时，会优先考虑**默认处理该 UTI 的应用**。

如果我们的宿主应用 `FluxMarkdown.app` 仅仅把自己声明为 `Alternate` 处理程序
（即 `LSHandlerRank = Alternate`），系统会继续优先使用内置的 Markdown/Plain Text 预览
器，从而完全绕过 `com.markdownquicklook.app.MarkdownPreview` 扩展——这就导致 Quick Look
看起来“只有纯文本”，好像插件失效了一样。

**本仓库中已通过以下方式修复：**

在 `Sources/Markdown/Info.plist` 中，将 `CFBundleDocumentTypes` 的
`LSHandlerRank` 调整为：

```xml
<key>LSHandlerRank</key>
<string>Owner</string>
```

并在注释中明确说明：我们故意将宿主应用设置为 Markdown UTI 的默认 Owner，以便
Quick Look 在预览 `.md` 文件时能实际使用我们的 Preview Extension。

### Fix Steps（如何让你的本地环境生效）

1. **更新代码**（如果你是从旧版本升级上来）：
   - 确认本地 `Sources/Markdown/Info.plist` 中的 `LSHandlerRank` 已是 `Owner`。

2. **重新生成并构建工程**：

   ```bash
   make app
   ```

   这一步会：
   - 构建 `web-renderer`（生成 `dist/index.html` + `dist/bundle.js`）
   - 生成并构建 Xcode 工程与宿主 App + Extension

3. **运行宿主 App 以注册扩展**：

   ```bash
   open ~/Library/Developer/Xcode/DerivedData/FluxMarkdown-*/Build/Products/Debug/FluxMarkdown.app
   ```

   或者在 Xcode 中选择 **Markdown** scheme，按 `Cmd+R` 运行。

4. **刷新 Quick Look 缓存**：

   ```bash
   qlmanage -r
   qlmanage -r cache
   killall Finder
   ```

5. **再次测试 `.md` 预览**：
    - 在 Finder 中选中 `Tests/fixtures/feature-validation.md`（见 `docs/testing/TESTING.md` 中的示例）
   - 按空格触发 Quick Look
   - 预期行为：
     - 标题、副标题、代码块、数学公式、Mermaid 图表、任务列表都以富文本形式渲染
     - 不再是简单的纯文本显示

6. **可选：使用系统日志确认扩展已被调用**：

   ```bash
   log stream --style compact --predicate 'process == "MarkdownPreview"'
   ```

   然后在 Finder 中对 `.md` 文件按空格预览，日志中应该能看到类似：

   ```text
   MarkdownPreview: viewDidLoad called
   MarkdownPreview: preparePreviewOfFile called for: /path/to/file.md
   ```

   这说明：
   - Quick Look 已经不再使用系统内置的纯文本预览器
   - 我们的 `PreviewViewController` 和内置的 Web 渲染器已经实际参与渲染流程
