# Troubleshooting Guide

## Extension Not Registered

### Issue
运行 `qlmanage -m | grep -i markdown` 没有找到扩展。

### Root Cause
Quick Look 扩展的注册机制要求：
1. 扩展必须通过 **Xcode Run** 运行，而不是简单的 `open` 命令
2. macOS 会缓存扩展列表，需要特殊的刷新流程

### Solution: Use Xcode Debugger

#### 方法 1: 通过 Xcode 运行 (推荐)
```bash
# 1. 生成工程
make generate

# 2. 在 Xcode 中打开
open MarkdownQuickLook.xcodeproj

# 3. 在 Xcode 中:
#    - 选择 MarkdownQuickLook scheme
#    - 按 Cmd+R 运行
#    - 保持 App 运行状态

# 4. 在新终端窗口:
qlmanage -r
qlmanage -r cache
killall Finder

# 5. 测试
#    在 Finder 中选中 test-sample.md，按空格
```

#### 方法 2: 使用 qlmanage 命令行测试
```bash
# 直接通过 qlmanage 调用扩展（绕过注册机制）
qlmanage -p test-sample.md
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
APP_PATH=~/Library/Developer/Xcode/DerivedData/MarkdownQuickLook-*/Build/Products/Debug/MarkdownQuickLook.app

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
