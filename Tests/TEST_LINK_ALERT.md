# 链接跳转功能测试指南

## 功能说明

### QuickLook 预览模式
- **不支持**链接跳转（macOS 沙盒限制）
- 点击链接时会弹出提示对话框
- 提供"在应用中打开"按钮，可直接跳转到主 APP

### 主应用模式
- **完全支持**所有链接类型跳转
- 外部 URL、文档内锚点、相对路径、特殊文件类型等

---

## 测试步骤

### 测试 1: QuickLook 预览模式

1. **打开 QuickLook 预览**
   ```bash
    qlmanage -p Tests/test-link-navigation.md
   ```

2. **点击任意链接**（如 `test-title.md`）

3. **期望行为**：
   - ✅ 弹出对话框
   - 标题：**链接跳转功能不可用**
   - 内容：说明 QuickLook 限制，建议使用主应用
   - 两个按钮：
     - **"在应用中打开"** - 点击后应该启动主 APP 并打开当前文件
     - **"取消"** - 关闭对话框

4. **点击"在应用中打开"**

5. **期望结果**：
   - ✅ 主 APP 启动
   - ✅ 当前 Markdown 文件在主 APP 中打开
   - ✅ 可以正常点击链接跳转

---

### 测试 2: 主应用模式

1. **直接用主 APP 打开**
   ```bash
open -a "FluxMarkdown" Tests/test-link-navigation.md
   ```

2. **点击各种链接**：
   - [Google](https://www.google.com) - 应在浏览器中打开
   - [同目录文件](test-title.md) - 应在 APP 中打开
   - [子目录文件](fixtures/README.md) - 应在 APP 中打开
   - [父目录文件](../README.md) - 应在 APP 中打开

3. **期望行为**：
   - ✅ **不显示**对话框
   - ✅ 直接打开链接目标

---

## URL Scheme 测试

可以手动测试 URL Scheme：

```bash
open "markdownpreview://open?path=/absolute/path/to/your/repo/flux-markdown/Tests/test-link-navigation.md"
```

**期望结果**：
- ✅ 主 APP 启动
- ✅ 指定的文件被打开

---

## 技术说明

### 实现方案

1. **QuickLook Extension**：
   - 拦截所有链接点击
   - 显示友好的提示对话框
   - 尝试两种方式启动主 APP：
     - 方式 1：URL Scheme (`markdownpreview://open?path=...`)
     - 方式 2：直接启动 (`NSWorkspace.open(withApplicationAt:)`)

2. **主应用**：
   - 注册 URL Scheme: `markdownpreview://`
   - 处理 `open?path=` 命令
   - 正常打开指定文件

### 为什么 QuickLook 不支持链接跳转？

这是 **macOS 系统级限制**：
- QuickLook Extension 是 App Extension
- App Extension 运行在严格的沙盒中
- 禁止启动其他进程或应用
- `NSWorkspace.shared.open()` 会静默失败

所有 QuickLook Extension 都有此限制，无法通过任何配置解决。

---

## 故障排查

### 对话框没有弹出

**可能原因**：
1. 缓存问题 - 清除 QuickLook 缓存：
   ```bash
   qlmanage -r
   qlmanage -r cache
   ```

2. Extension 未加载 - 重新安装：
   ```bash
   ./scripts/install.sh
   ```

### "在应用中打开"按钮无反应

**检查日志**：
```bash
log stream --predicate 'subsystem == "com.markdownquicklook.app"' --level debug
```

**查找**：
- `Attempting to open main app with URL scheme`
- `URL Scheme open result: SUCCESS/FAILED`

**如果 URL Scheme 失败**：
- 代码会自动尝试方式 2（直接启动）
- 查看日志：`Failed to open via URL scheme, trying direct app launch`

---

## 用户体验总结

| 使用场景 | 链接跳转 | 用户体验 |
|---------|---------|---------|
| **Finder 空格预览** | ❌ 不支持 | 显示提示，可跳转到 APP |
| **主应用打开** | ✅ 完全支持 | 无缝跳转，体验流畅 |
| **双击 .md 文件** | ✅ 完全支持 | 默认用主 APP 打开 |

**建议用户**：
- 快速浏览 → 用 QuickLook（空格键）
- 完整功能 → 双击文件或用主 APP 打开
