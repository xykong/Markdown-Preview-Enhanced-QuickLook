# Markdown 图片显示测试文档

本文档用于测试 Markdown QuickLook 扩展的图片显示功能。

## 1. 本地相对路径图片

### 1.1 相对路径（同目录）
![Test Image - Same Directory](./test-image.png)

### 1.2 相对路径（上级目录）
![Test Image - Parent Directory](../test-image.png)

### 1.3 相对路径（子目录）
![Test Image - Subdirectory](./images/test-image.png)

### 1.4 相对路径（显式当前目录）
![Test Image - Explicit Current](./images/logo.png)

## 2. 绝对路径图片

### 2.1 file:// 协议
![Test Image - File Protocol](file:///Users/Shared/test-image.png)

### 2.2 绝对文件系统路径
![Test Image - Absolute Path](/Users/Shared/test-image.png)

## 3. 网络图片

### 3.1 HTTPS 图片
![GitHub Logo](https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png)

### 3.2 HTTP 图片（如果支持）
![HTTP Image](http://example.com/image.png)

## 4. 图片带标题

![测试图片](./test-image.png "这是图片标题")

## 5. 链接包裹的图片

[![Clickable Image](./test-image.png)](https://github.com)

## 6. 特殊字符路径

### 6.1 中文路径
![中文路径](./图片/测试图片.png)

### 6.2 空格路径
![Space Path](./test images/test image.png)

### 6.3 特殊字符
![Special Chars](./test-images/image%20(1).png)

## 7. HTML img 标签（如果支持）

<img src="./test-image.png" alt="HTML Image" width="200">

## 8. 不存在的图片

![Missing Image](./does-not-exist.png)

## 9. 多个图片并排

![Image 1](./test1.png) ![Image 2](./test2.png) ![Image 3](./test3.png)

## 10. Base64 内嵌图片

![Base64 Image](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==)

---

## 预期行为

- ✅ 本地相对路径图片应该正确加载
- ✅ 网络图片应该正确加载
- ✅ 图片标题应该显示为悬停提示
- ✅ 链接包裹的图片应该可点击
- ⚠️  不存在的图片应显示占位符或错误提示
- ⚠️  绝对路径可能因沙箱限制无法访问
- ⚠️  Base64 图片应该直接显示

## 测试步骤

1. 在 Finder 中选中此文件
2. 按下空格键触发 QuickLook 预览
3. 检查各种图片是否正常显示
4. 检查控制台日志是否有错误信息
