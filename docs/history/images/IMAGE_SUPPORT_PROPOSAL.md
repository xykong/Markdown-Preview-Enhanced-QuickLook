# Markdown 图片显示支持方案

## 📋 现状分析

### 已有基础设施

1. **LocalSchemeHandler** (`Sources/MarkdownPreview/LocalSchemeHandler.swift`)
   - ✅ 已实现自定义 URL Scheme Handler (`local-resource://`)
   - ✅ 支持图片 MIME 类型识别 (png, jpg, gif, svg)
   - ✅ 可以加载本地文件系统资源
   - ✅ 已在 WebView 配置中注册

2. **Markdown 渲染器** (`web-renderer/src/index.ts`)
   - ✅ 已有图片渲染规则 (`md.renderer.rules.image`)
   - ✅ 相对路径会被转换为 `local-resource://` 协议
   - ✅ 支持 `baseUrl` 配置（从 Swift 传递过来）
   - ✅ 绝对路径和网络路径保持不变

3. **文件路径传递**
   - ✅ Swift 端在 `renderPendingMarkdown()` 中传递 `baseUrl` 选项
   - ✅ `baseUrl` 设置为 Markdown 文件所在目录

### 理论上应该可以工作的场景

根据代码分析，以下场景**理论上已经支持**：

| 图片路径类型 | 示例 | 转换后 | 预期结果 |
|------------|------|--------|---------|
| 相对路径（同目录） | `./image.png` | `local-resource:///path/to/dir/image.png` | ✅ 应该可以 |
| 相对路径（子目录） | `./images/logo.png` | `local-resource:///path/to/dir/images/logo.png` | ✅ 应该可以 |
| 相对路径（上级目录） | `../image.png` | `local-resource:///path/to/image.png` | ⚠️  取决于沙箱权限 |
| 网络图片 (HTTPS) | `https://example.com/img.png` | 保持不变 | ✅ 应该可以 |
| 网络图片 (HTTP) | `http://example.com/img.png` | 保持不变 | ⚠️  可能被 WKWebView 阻止 |
| 绝对路径 | `/Users/xxx/image.png` | 保持不变 | ❌ 沙箱限制 |
| Base64 内嵌 | `data:image/png;base64,...` | 保持不变 | ✅ 应该可以 |

---

## 🔍 问题诊断

如果图片显示有问题，可能的原因：

### 1. **路径解析问题**
- TypeScript 中的路径拼接可能有 bug
- `baseUrl` 可能没有正确传递
- 相对路径解析逻辑可能有边界情况未处理

### 2. **沙箱权限问题**
- App Sandbox 限制了文件访问范围
- QuickLook 扩展默认只能访问被预览的文件
- 同目录下的其他文件可能需要额外权限

### 3. **MIME 类型问题**
- 某些图片格式可能未识别
- WebP、AVIF 等现代格式可能不支持

### 4. **加载失败无提示**
- 图片加载失败时可能没有错误提示
- 用户无法知道是路径错误还是权限问题

---

## 📊 诊断方案

### 方案 A：使用现有测试文档诊断（推荐）

**步骤：**
1. 打开终端，运行调试脚本：
   ```bash
    log stream --predicate 'subsystem == "com.markdownquicklook.app"' --level debug
   ```

2. 在 Finder 中打开测试文件：
   ```bash
    open Tests/fixtures/images-test.md
   ```

3. 按空格键触发 QuickLook 预览

4. 观察终端日志输出：
   - 查找 `🔵 Start loading resource:` - 表示尝试加载资源
   - 查找 `🟢 Successfully loaded:` - 表示加载成功
   - 查找 `🔴 Failed to load resource:` - 表示加载失败
   - 查找 `JS Log:` - 前端日志信息

5. 根据日志分析问题：

| 日志特征 | 问题诊断 | 解决方案 |
|---------|---------|---------|
| 没有 "Start loading" 日志 | 路径转换失败，图片 URL 未使用 local-resource | 检查 TypeScript 路径转换逻辑 |
| 有 "Start loading" 但失败 | 文件不存在或权限问题 | 检查文件路径或调整沙箱权限 |
| 成功加载但不显示 | CSS 或 HTML 渲染问题 | 检查前端样式和图片标签 |
| 没有任何图片相关日志 | Markdown 未解析图片语法 | 检查 markdown-it 配置 |

### 方案 B：增强日志（如果方案 A 信息不足）

在 `web-renderer/src/index.ts` 的图片渲染规则中添加详细日志：

```typescript
md.renderer.rules.image = function (tokens, idx, options, env, self) {
    const token = tokens[idx];
    const srcIndex = token.attrIndex('src');
    if (srcIndex >= 0) {
        const originalSrc = token.attrs[srcIndex][1];
        logToSwift(`Image found: original src="${originalSrc}"`);
        
        const isAbsolute = /^(http:\/\/|https:\/\/|file:\/\/|\/)/.test(originalSrc);
        logToSwift(`Image: isAbsolute=${isAbsolute}, baseUrl=${env?.baseUrl}`);
        
        if (!isAbsolute && env && env.baseUrl) {
            const base = env.baseUrl.endsWith('/') ? env.baseUrl : env.baseUrl + '/';
            let cleanSrc = originalSrc;
            if (cleanSrc.startsWith('./')) {
                cleanSrc = cleanSrc.substring(2);
            }
            const finalUrl = "local-resource://" + base + cleanSrc;
            token.attrs[srcIndex][1] = finalUrl;
            logToSwift(`Image transformed: "${originalSrc}" -> "${finalUrl}"`);
        }
    }
    return defaultImageRender(tokens, idx, options, env, self);
};
```

---

## 🛠️ 解决方案

根据诊断结果，可能需要实施以下修复：

### 修复 1：路径解析增强（高优先级）

**问题：** 当前路径拼接可能不正确处理 `..` 等相对路径

**解决方案：** 使用规范化路径处理

```typescript
// 在 web-renderer/src/index.ts 中
md.renderer.rules.image = function (tokens, idx, options, env, self) {
    const token = tokens[idx];
    const srcIndex = token.attrIndex('src');
    if (srcIndex >= 0) {
        const src = token.attrs[srcIndex][1];
        const isAbsolute = /^(http:\/\/|https:\/\/|file:\/\/|data:|\/)/i.test(src);
        
        if (!isAbsolute && env && env.baseUrl) {
            // 清理路径前缀
            let cleanSrc = src;
            if (cleanSrc.startsWith('./')) {
                cleanSrc = cleanSrc.substring(2);
            }
            
            // 规范化路径（处理 ..）
            const base = env.baseUrl.endsWith('/') ? env.baseUrl : env.baseUrl + '/';
            const fullPath = base + cleanSrc;
            
            // 简单的路径规范化（处理 /.. 和 /.）
            const parts = fullPath.split('/').filter(p => p && p !== '.');
            const normalized: string[] = [];
            for (const part of parts) {
                if (part === '..') {
                    normalized.pop();
                } else {
                    normalized.push(part);
                }
            }
            
            token.attrs[srcIndex][1] = "local-resource://" + normalized.join('/');
        }
    }
    return defaultImageRender(tokens, idx, options, env, self);
};
```

### 修复 2：沙箱权限扩展（如果需要）

**问题：** 当前 App Sandbox 可能限制了同目录文件访问

**解决方案：** 在 `project.yml` 中调整沙箱权限

```yaml
# project.yml
targets:
  MarkdownPreview:
    settings:
      CODE_SIGN_ENTITLEMENTS: Sources/MarkdownPreview/MarkdownPreview.entitlements
```

在 `Sources/MarkdownPreview/MarkdownPreview.entitlements` 中：

```xml
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
<key>com.apple.security.files.bookmarks.document-scope</key>
<true/>
```

### 修复 3：错误提示优化

**问题：** 用户看不到图片加载失败的原因

**解决方案：** 在 CSS 中添加图片加载失败样式

```css
/* web-renderer/src/styles/main.css */
img {
  max-width: 100%;
  height: auto;
}

img[alt]::after {
  content: " (图片加载失败: " attr(alt) ")";
  display: block;
  padding: 10px;
  background-color: #fff3cd;
  border: 1px solid #ffc107;
  border-radius: 4px;
  color: #856404;
  font-size: 14px;
  font-family: -apple-system, BlinkMacSystemFont, sans-serif;
}
```

### 修复 4：支持更多图片格式

**问题：** LocalSchemeHandler 可能遗漏某些格式

**解决方案：** 扩展 MIME 类型支持

```swift
// Sources/MarkdownPreview/LocalSchemeHandler.swift
private func mimeType(for url: URL) -> String {
    let pathExtension = url.pathExtension.lowercased()
    switch pathExtension {
    case "png": return "image/png"
    case "jpg", "jpeg": return "image/jpeg"
    case "gif": return "image/gif"
    case "svg": return "image/svg+xml"
    case "webp": return "image/webp"
    case "ico": return "image/x-icon"
    case "bmp": return "image/bmp"
    case "tiff", "tif": return "image/tiff"
    case "heic", "heif": return "image/heic"
    case "css": return "text/css"
    case "js": return "application/javascript"
    default: return "application/octet-stream"
    }
}
```

---

## 📝 实施计划

### 阶段 1：诊断（立即执行）
1. ✅ 创建测试文档 `Tests/fixtures/images-test.md`
2. ✅ 创建测试图片资源
3. ⏳ 运行诊断脚本，收集日志
4. ⏳ 分析日志，确定具体问题

### 阶段 2：修复（待确认问题后）
根据诊断结果，按优先级实施：
- **P0 - 阻塞问题：** 如果完全无法加载图片，先修复路径解析和沙箱权限
- **P1 - 重要问题：** 如果部分场景有问题，针对性修复
- **P2 - 优化项：** 错误提示、更多格式支持

### 阶段 3：测试验证
1. 使用测试文档验证所有场景
2. 更新测试文档中的"预期行为"部分
3. 编写自动化测试（如果需要）

---

## 🎯 下一步行动

**请先执行诊断方案 A：**

```bash
# 终端 1：启动日志监控
log stream --predicate 'subsystem == "com.markdownquicklook.app"' --level debug

# 终端 2：打开测试文档
open Tests/fixtures/images-test.md
# 然后在 Finder 中按空格预览
```

**然后告诉我：**
1. 看到了哪些日志输出？
2. 哪些图片显示成功了？
3. 哪些图片显示失败了？

根据这些信息，我们可以精确定位问题并实施对应的修复方案。

---

## 📚 参考资料

- [WKWebView Custom URL Scheme](https://developer.apple.com/documentation/webkit/wkurlschemehandler)
- [App Sandbox in QuickLook Extensions](https://developer.apple.com/documentation/quicklook/qlpreviewingcontroller)
- [markdown-it Image Renderer](https://github.com/markdown-it/markdown-it/blob/master/docs/architecture.md#renderer)
