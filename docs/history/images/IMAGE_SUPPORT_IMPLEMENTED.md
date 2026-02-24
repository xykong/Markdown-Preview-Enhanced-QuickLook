# Markdown 图片显示支持 - 实现总结

## ✅ 已完成

Markdown 图片显示功能已成功实现并测试通过！

## 📊 实现方案

### 方案概述

由于 macOS QuickLook 扩展的严格沙箱限制，我们采用了 **Base64 内嵌方案**：

1. **Swift 端**：解析 Markdown 内容，提取所有图片引用
2. **Swift 端**：读取这些图片文件并转换为 Base64 编码
3. **Swift 端**：将 Base64 数据作为 JSON 传递给 JavaScript
4. **JavaScript 端**：渲染时直接使用 Base64 data URLs

###实现细节

#### 1. Swift 端 - 图片收集 (`PreviewViewController.swift`)

```swift
private func collectImageData(from markdownURL: URL, content: String) -> [String: String] {
    // 1. 使用正则表达式解析 Markdown 中的图片引用: ![...](path)
    // 2. 对每个相对路径图片：
    //    - 解析路径（处理 ./ 和 ..）
    //    - 读取文件数据
    //    - 转换为 Base64
    //    - 生成 data URL: data:image/png;base64,<base64>
    // 3. 返回 [相对路径 -> data URL] 的字典
}
```

#### 2. JavaScript 端 - 图片渲染 (`web-renderer/src/index.ts`)

```typescript
md.renderer.rules.image = function (tokens, idx, options, env, self) {
    // 1. 获取图片的原始路径
    // 2. 如果是相对路径且有 imageData：
    //    - 规范化路径
    //    - 查找对应的 Base64 data URL
    //    - 替换 src 属性
    // 3. 渲染图片标签
}
```

#### 3. 沙箱权限配置 (`MarkdownPreview.entitlements`)

添加了临时例外权限，允许读取文件系统中的文件：

```xml
<key>com.apple.security.temporary-exception.files.absolute-path.read-only</key>
<array>
    <string>/</string>
</array>
```

**注意**：这是必需的，因为 QuickLook 扩展默认只能访问被预览的文件本身。

---

## 🎯 支持的图片场景

### ✅ 完全支持

| 场景 | 示例 | 说明 |
|------|------|------|
| 同目录相对路径 | `![](./image.png)` | ✅ 完美支持 |
| 子目录相对路径 | `![](./images/logo.png)` | ✅ 完美支持 |
| 上级目录相对路径 | `![](../image.png)` | ✅ 完美支持 |
| 网络图片 (HTTPS) | `![](https://example.com/img.png)` | ✅ 完美支持 |
| Base64 内嵌 | `![](data:image/png;base64,...)` | ✅ 完美支持 |

### ⚠️ 部分支持

| 场景 | 示例 | 说明 |
|------|------|------|
| 网络图片 (HTTP) | `![](http://example.com/img.png)` | ⚠️  可能被 WKWebView 安全策略阻止 |

### ❌ 不支持

| 场景 | 示例 | 说明 |
|------|------|------|
| 绝对路径 | `![](/Users/xxx/image.png)` | ❌ 不在 Markdown 文件目录范围内 |
| file:// 协议 | `![](file:///path/to/image.png)` | ❌ 安全限制 |

---

## 🧪 测试

### 测试文档

已创建完整的测试文档：`Tests/fixtures/images-test.md`

包含 10 种不同的图片引用场景和 6 张测试图片。

### 测试步骤

```bash
# 方法 1：Finder 预览
open Tests/fixtures/images-test.md
# 然后按空格键

# 方法 2：命令行
qlmanage -p Tests/fixtures/images-test.md

# 方法 3：查看日志
log stream --predicate 'subsystem == "com.markdownquicklook.app"' --level debug
```

### 测试结果

```
✅ 成功收集了 6 张图片
✅ JavaScript 端正确使用 Base64 数据
✅ 图片在 QuickLook 预览中正常显示
```

---

## 📝 技术要点

### 1. 为什么不能使用 `local-resource://` 自定义 URL Scheme？

**问题**：QuickLook 扩展的沙箱只允许访问被预览的文件本身，不允许访问同目录的其他文件。

即使实现了 `WKURLSchemeHandler`，尝试读取其他文件时也会遇到权限错误：
```
The file "test-image.png" couldn't be opened because you don't have permission to view it.
```

### 2. 为什么需要 temporary-exception 权限？

**答案**：macOS 的 App Sandbox 对 QuickLook 扩展特别严格。标准权限（如 `user-selected.read-only`、`bookmarks.document-scope`）都不够。

只有添加 `temporary-exception.files.absolute-path.read-only` 权限后，扩展才能读取 Markdown 文件同目录下的图片。

### 3. Base64 方案的优缺点

**优点**：
- ✅ 完全绕过沙箱文件访问限制
- ✅ 图片与 HTML 一起传递，加载更可靠
- ✅ 不需要复杂的 URL Scheme Handler

**缺点**：
- ⚠️  Base64 编码会增加约 33% 的数据大小
- ⚠️  首次加载时需要读取和编码所有图片
- ⚠️  不适合大量或超大图片的场景

**性能优化方案**：
- 只解析 Markdown 中实际引用的图片（已实现）
- 可以考虑添加图片大小限制（如单张图片 > 5MB 则跳过）
- 可以考虑添加总大小限制（如所有图片总和 > 20MB 则警告）

### 4. 正则表达式解析图片引用

使用的正则表达式：`!\[.*?\]\((.*?)\)`

**匹配示例**：
- `![Alt Text](./image.png)` → `./image.png`
- `![](images/logo.png)` → `images/logo.png`  
- `![Description](../test.jpg "Title")` → `../test.jpg "Title"`

**已知问题**：
- 当前正则会匹配到标题部分（如 `"Title"`），需要在路径处理时清理
- 不支持引用式图片：`![Alt][ref]`（较少使用）

---

## 🔧 相关文件

### 修改的文件

| 文件 | 修改内容 |
|------|---------|
| `Sources/MarkdownPreview/PreviewViewController.swift` | 添加 `collectImageData()` 方法 |
| `Sources/MarkdownPreview/LocalSchemeHandler.swift` | 修复 URL 路径解析（host + path） |
| `Sources/MarkdownPreview/MarkdownPreview.entitlements` | 添加文件读取权限 |
| `web-renderer/src/index.ts` | 更新图片渲染规则使用 Base64 数据 |

### 新增的文件

| 文件 | 说明 |
|------|------|
| `Tests/fixtures/images-test.md` | 图片显示测试文档 |
| `Tests/fixtures/test-image.png` | 测试图片（蓝色） |
| `Tests/fixtures/images/test-image.png` | 测试图片（绿色） |
| `Tests/fixtures/images/logo.png` | 测试图片（紫色） |
| `Tests/fixtures/test1.png`, `test2.png`, `test3.png` | 并排显示测试图片 |
| `Tests/fixtures/README.md` | 测试说明 |
| `docs/IMAGE_SUPPORT_PROPOSAL.md` | 初始方案文档 |
| `docs/IMAGE_SUPPORT_IMPLEMENTED.md` | 本文档 |

---

## 🚀 后续优化建议

### 1. 性能优化

```swift
// 添加图片大小限制
let maxImageSize: Int64 = 5 * 1024 * 1024  // 5MB
let totalMaxSize: Int64 = 20 * 1024 * 1024  // 20MB

// 在 collectImageData 中添加检查
if fileSize > maxImageSize {
    os_log("⚠️  Image too large, skipping: %{public}@", relativePath)
    continue
}
```

### 2. 错误提示优化

在 CSS 中添加加载失败的视觉提示：

```css
/* web-renderer/src/styles/main.css */
img[src^="data:"] {
    /* Base64 图片正常显示 */
}

img:not([src^="data:"]):not([src^="http"]) {
    /* 本地图片加载失败的提示样式 */
    background: #fff3cd;
    border: 2px dashed #ffc107;
}
```

### 3. 支持更多格式

```swift
// 在 mimeTypeForExtension 中添加
case "heic", "heif": return "image/heic"
case "tiff", "tif": return "image/tiff"
```

### 4. 缓存优化

考虑在文件内容未变化时缓存 Base64 数据（基于文件修改时间）。

---

## 📚 参考资料

- [WKWebView Custom URL Scheme](https://developer.apple.com/documentation/webkit/wkurlschemehandler)
- [App Sandbox in QuickLook Extensions](https://developer.apple.com/documentation/quicklook/qlpreviewingcontroller)
- [QuickLook Framework Documentation](https://developer.apple.com/documentation/quicklook)
- [NSFileCoordinator for Coordinated File Access](https://developer.apple.com/documentation/foundation/nsfilecoordinator)
