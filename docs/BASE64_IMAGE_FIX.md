# Base64 图片显示修复文档

## 问题描述

Markdown 文档中的 Base64 内嵌图片（`data:image/...`）无法在 QuickLook 预览中显示。

## 根本原因

发现了两个层面的问题：

### 问题 1: WKWebView 安全限制
WKWebView 在 macOS 沙盒环境中对 `data:` URLs 有安全限制：
1. **`loadFileURL` 限制**: 使用 `loadFileURL` 加载本地 HTML 时，WKWebView 会阻止页面中的 `data:` URLs
2. **安全策略**: 沙盒环境中的 WKWebView 默认不信任 data: scheme

### 问题 2: markdown-it URL 验证（关键问题）
markdown-it 的内置 URL 验证器拒绝渲染某些 Base64 图片：
- ✅ `data:image/png;base64,...` - 可以渲染
- ❌ `data:image/svg+xml;base64,...` - **被拒绝**（因为 `svg+xml` 中的 `+` 被认为是无效字符）
- ✅ `data:image/jpeg;base64,...` - 可以渲染

导致 Markdown 语法 `![](data:image/svg+xml;base64,...)` 不被转换为 `<img>` 标签，而是直接输出为文本。

## 解决方案

### 1. 改用 `loadHTMLString` 加载方式

**文件**: `Sources/MarkdownPreview/PreviewViewController.swift`

```swift
// 之前（有限制）
webView.loadFileURL(url, allowingReadAccessTo: dir)

// 修复后（更灵活）
let htmlContent = try String(contentsOf: url, encoding: .utf8)
let baseURL = url.deletingLastPathComponent()
webView.loadHTMLString(htmlContent, baseURL: baseURL)
```

### 2. 添加 WKWebView 配置

```swift
webConfiguration.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
```

### 3. 覆盖 markdown-it URL 验证（关键修复）

**文件**: `web-renderer/src/index.ts`

```typescript
// 保存原始的 validateLink 方法
const originalValidateLink = md.validateLink.bind(md);

// 覆盖以允许所有 data: URLs
md.validateLink = function(url: string): boolean {
    if (url.startsWith('data:')) {
        return true;  // 允许所有 data: URLs，包括 data:image/svg+xml
    }
    return originalValidateLink(url);  // 其他 URLs 使用默认验证
};
```

**为什么这很重要**:
- 没有这个修复，`![SVG](data:image/svg+xml;base64,...)` 不会被渲染为 `<img>` 标签
- markdown-it 会直接输出原始文本：`![SVG](data:image/svg+xml;base64,...)`
- 后续的 Blob 转换也无法执行（因为 HTML 中没有 `<img>` 标签）

### 4. Base64 → Blob URL 转换

**文件**: `web-renderer/src/index.ts`

由于 WKWebView 仍然可能阻止 data: URLs，实现了自动转换：

```typescript
// 检测 HTML 中的 Base64 图片
if (html.includes('data:image')) {
    const imgMatches = html.match(/<img[^>]+src="(data:image\/[^"]+)"/g);
    if (imgMatches) {
        imgMatches.forEach((match) => {
            // 提取 Base64 数据
            const dataUrlMatch = match.match(/src="(data:image\/([^;]+);base64,([^"]+))"/);
            if (dataUrlMatch) {
                const [, dataUrl, mimeType, base64Data] = dataUrlMatch;
                
                // 转换为 Blob
                const binaryString = atob(base64Data);
                const bytes = new Uint8Array(binaryString.length);
                for (let i = 0; i < binaryString.length; i++) {
                    bytes[i] = binaryString.charCodeAt(i);
                }
                const blob = new Blob([bytes], { type: `image/${mimeType}` });
                const blobUrl = URL.createObjectURL(blob);
                
                // 替换 data: URL 为 blob: URL
                html = html.replace(dataUrl, blobUrl);
            }
        });
    }
}
```

## 工作原理

1. **Markdown 渲染**: markdown-it 将 `![](data:image/...)` 转换为 `<img src="data:image/...">`
2. **HTML 生成**: 完整的 HTML 字符串包含 Base64 图片
3. **Base64 检测**: JavaScript 检测 HTML 中的所有 `data:image` URLs
4. **Blob 转换**: 将 Base64 解码为二进制数据，创建 Blob 对象
5. **URL 替换**: 将 `data:image/...` 替换为 `blob:...` URL
6. **DOM 渲染**: 浏览器加载 blob: URLs（不受沙盒限制）

## 支持的格式

- ✅ PNG: `data:image/png;base64,...`
- ✅ JPEG: `data:image/jpeg;base64,...`
- ✅ SVG: `data:image/svg+xml;base64,...`
- ✅ GIF: `data:image/gif;base64,...`
- ✅ WebP: `data:image/webp;base64,...`

## 测试验证

### 单元测试

```bash
cd web-renderer && npm test
```

所有 26 个测试通过，包括：
- Base64 图片保持不变
- 本地文件替换为 Base64
- 网络 URL 保持不变
- 混合场景测试

### 手动测试

创建测试文件：

```markdown
# Base64 Test

![PNG Image](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==)

![SVG Image](data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgZmlsbD0icmVkIi8+Cjwvc3ZnPg==)
```

预期结果：应该看到红色图形。

## 性能考虑

- **内存使用**: Blob URLs 会保留在内存中，但对于典型的 Markdown 文档（少量图片）影响可忽略
- **转换开销**: Base64 解码和 Blob 创建是同步操作，对小图片（< 1MB）性能影响很小
- **清理**: Blob URLs 在页面卸载时自动清理

## 兼容性

- ✅ macOS 11.0+ (WKWebView with Blob support)
- ✅ 所有图片格式
- ✅ Markdown 语法和 HTML 标签
- ✅ 混合使用 Base64、本地文件、网络图片

## 调试

如果 Base64 图片仍然不显示，检查日志：

```bash
log stream --predicate 'subsystem == "com.markdownquicklook.app"' --level debug
```

关键日志：
- `[Image] Type: embedded-base64` - 图片被识别为 Base64
- `[Render] Found X Base64 img tags` - 检测到 Base64 图片
- `[Render] ✅ Converted to blob: blob:...` - 转换成功

## 相关文件

- `Sources/MarkdownPreview/PreviewViewController.swift` - WKWebView 配置和加载
- `web-renderer/src/index.ts` - Base64 检测和转换逻辑
- `web-renderer/test/renderer.test.ts` - 单元测试

## 未来改进

- [ ] 考虑使用 Worker 进行异步 Base64 解码（大文件）
- [ ] 添加 Base64 图片大小限制（避免内存问题）
- [ ] 支持更多图片格式（AVIF、HEIF）
