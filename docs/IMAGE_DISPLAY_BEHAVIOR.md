# 图片显示行为说明

## 📊 不同图片类型的显示行为

### ✅ 正常显示（有内容）

| 类型 | 示例 | 行为 | 原因 |
|------|------|------|------|
| 相对路径（存在） | `./image.png` | ✅ 显示图片 | Swift 读取并转换为 Base64 |
| 子目录（存在） | `./images/logo.png` | ✅ 显示图片 | Swift 读取并转换为 Base64 |
| 网络图片 (HTTPS) | `https://example.com/img.png` | ✅ 显示图片 | 浏览器直接加载 |
| Base64 内嵌 | `data:image/...` | ✅ 显示图片 | 直接内嵌在 HTML 中 |

### ⚠️  占位符显示（黄色方框）

| 类型 | 示例 | 行为 | 原因 |
|------|------|------|------|
| 相对路径（不存在） | `./missing.png` | ⚠️  显示占位符 | Swift 无法读取，CSS 显示友好提示 |
| 子目录（不存在） | `./images/missing.png` | ⚠️  显示占位符 | Swift 无法读取，CSS 显示友好提示 |

**占位符样式**：
- 黄色虚线边框
- 显示 "⚠️ 图片未找到"
- 显示图片的 alt 文本
- 暗色模式下自动调整颜色

### 🚫 不显示（浏览器默认破损图标）

| 类型 | 示例 | 行为 | 原因 |
|------|------|------|------|
| 绝对路径 | `/Users/xxx/image.png` | 🚫 破损图标 | 不在处理范围，浏览器无法访问 |
| file:// 协议 | `file:///path/to/image.png` | 🚫 破损图标 | 安全限制，被过滤 |
| HTTP 图片 | `http://example.com/img.png` | 🚫 可能破损 | WKWebView 安全策略可能阻止 |

---

## 🎯 设计理念

### 为什么相对路径不存在时显示占位符？

**用户友好**：
- 相对路径图片是用户期望能加载的图片
- 如果不存在，很可能是：
  - 文件路径写错了
  - 文件被移动或删除了
  - 文件名大小写不匹配

显示友好的占位符可以帮助用户快速发现问题。

### 为什么绝对路径不显示占位符？

**明确预期**：
- 绝对路径本身就超出了相对路径的设计范围
- 用户应该知道绝对路径在 QuickLook 环境中无法工作
- 显示浏览器默认的破损图标更诚实

**技术原因**：
- 绝对路径在 Swift 端被过滤，不会尝试加载
- 在 HTML 中保持原始 URL
- CSS 选择器 `img[src^="./"]` 和 `img[src^="../"]` 不会匹配绝对路径

---

## 🔍 如何识别图片显示问题

### 1. 看到占位符（黄色方框）

**含义**：相对路径图片未找到

**解决方法**：
1. 检查文件是否存在：
   ```bash
   ls -la path/to/image.png
   ```
2. 检查文件路径是否正确（相对于 Markdown 文件）
3. 检查文件名大小写是否匹配（macOS 默认不区分，但某些场景会区分）

### 2. 看到破损图标

**含义**：图片加载失败或路径不支持

**可能原因**：
- 绝对路径（设计限制）
- file:// 协议（安全限制）
- HTTP 图片被阻止（安全策略）
- 网络连接问题（对于网络图片）

**解决方法**：
- 对于本地图片：改用相对路径
- 对于网络图片：确保使用 HTTPS
- 检查网络连接

### 3. 什么都不显示

**含义**：图片语法可能有问题

**检查**：
1. Markdown 语法是否正确：`![Alt Text](path)`
2. 是否有多余的空格或特殊字符
3. 查看日志确认是否被解析：
   ```bash
   log stream --predicate 'subsystem == "com.markdownquicklook.app"' --level debug
   ```

---

## 📝 最佳实践

### ✅ 推荐的做法

```markdown
<!-- 相对路径：最可靠 -->
![Logo](./images/logo.png)

<!-- 子目录相对路径 -->
![Screenshot](./screenshots/app.png)

<!-- 网络图片：使用 HTTPS -->
![GitHub](https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png)

<!-- Base64 内嵌：适合小图标 -->
![Icon](data:image/png;base64,iVBORw0KG...)
```

### ❌ 不推荐的做法

```markdown
<!-- 绝对路径：不会工作 -->
![Logo](/Users/username/Pictures/logo.png)

<!-- file:// 协议：被过滤 -->
![Logo](file:///Users/username/Pictures/logo.png)

<!-- HTTP 图片：可能被阻止 -->
![Logo](http://example.com/logo.png)
```

---

## 🧪 测试清单

使用 `Tests/fixtures/images-test.md` 测试时，预期结果：

- [ ] 同目录图片 (`./test-image.png`) - ✅ 显示
- [ ] 子目录图片 (`./images/test-image.png`) - ✅ 显示
- [ ] 上级目录图片 (`../test-image.png`) - ⚠️  占位符（文件不存在）
- [ ] 网络图片 (GitHub HTTPS) - ✅ 显示
- [ ] 不存在的图片 (`./does-not-exist.png`) - ⚠️  占位符
- [ ] 绝对路径 (`/Users/Shared/...`) - 🚫 破损图标（不是占位符）
- [ ] file:// 协议 - 🚫 破损图标（不是占位符）

---

## 💡 开发者注意事项

### CSS 选择器说明

```css
/* 只对相对路径的图片显示占位符 */
img[alt][src^="./"],
img[alt][src^="../"] {
  /* 占位符样式 */
}
```

**为什么使用 `^=` 而不是 `:not()`？**
- `^=` (starts with) 精确匹配相对路径
- 不会误捕获绝对路径、网络 URL 等
- 更明确的意图表达

### Swift 端过滤逻辑

```swift
// 这些路径会被跳过，不会尝试加载
if imagePath.starts(with: "http://") || 
   imagePath.starts(with: "https://") || 
   imagePath.starts(with: "data:") || 
   imagePath.starts(with: "/") ||
   imagePath.starts(with: "file://") {
    continue
}
```

这确保了：
1. 网络图片由浏览器加载
2. Base64 图片保持不变
3. 绝对路径不会浪费资源尝试加载
