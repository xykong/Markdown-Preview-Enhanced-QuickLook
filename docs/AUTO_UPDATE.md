# 自动更新系统使用指南

本项目使用 Sparkle 2.8.1 为所有用户（无论通过何种方式安装）提供统一的自动更新体验。

## 架构概览

```
┌─────────────────────────────────────────────────────────┐
│              启动时初始化 Sparkle                        │
│                                                         │
│   ✅ Homebrew 安装 → Sparkle 自动更新                    │
│   ✅ DMG 手动安装  → Sparkle 自动更新                    │
│                                                         │
│   统一体验：后台检查 → 自动下载 → 提示安装               │
└─────────────────────────────────────────────────────────┘
```

## 设计理念

遵循业界标准（iTerm2、Docker Desktop、VSCode 等主流应用）：
- **统一体验**: 所有用户都通过 Sparkle 获得自动更新
- **Homebrew 兼容**: Cask 中的 `auto_updates true` 告诉 Homebrew "让 app 自己管理更新"
- **及时安全**: 用户立即获得安全更新，无需等待 Homebrew Cask 维护者

## 功能特性

### 所有用户（Homebrew 和 DMG）

- **Sparkle 自动更新**: 使用业界标准的 Sparkle 2.8.1 框架
- **后台检查**: 每天自动检查更新（可配置）
- **安全验证**: EdDSA 签名验证，确保更新来源可信
- **手动检查**: 菜单栏 "检查更新..." (⌘U) 可随时主动检查
- **无感安装**: 下载完成后一键安装，自动重启应用

### Homebrew 注意事项

- `brew upgrade` 会跳过此 app（因为 Cask 中有 `auto_updates true`）
- 如需强制通过 Homebrew 更新，使用 `brew upgrade --greedy`
- Sparkle 更新后，`brew list --versions` 显示的版本可能过时（这是正常行为）

## 开发者指南

### 首次配置

#### 1. 生成 Sparkle 密钥对

```bash
./scripts/generate-sparkle-keys.sh
```

这将生成：
- `.sparkle-keys/sparkle_public_key.txt` - 公钥（安全分享）
- `.sparkle-keys/sparkle_private_key.pem` - 私钥（绝对保密！）

#### 2. 更新 Info.plist

将生成的公钥填入 `Sources/Markdown/Info.plist`：

```xml
<key>SUPublicEDKey</key>
<string>YOUR_GENERATED_PUBLIC_KEY_HERE</string>
```

替换 `SPARKLE_PUBLIC_KEY_PLACEHOLDER`。

#### 3. 重新生成 Xcode 项目

```bash
make generate
```

这会：
- 拉取 Sparkle 2.8.1 依赖
- 重新生成 `.xcodeproj` 文件
- 配置正确的链接设置

#### 4. 测试构建

```bash
make build
```

确保没有编译错误。

### 发布新版本

#### 完整发布流程

```bash
# 1. 发布 patch 版本（默认）
make release

# 或发布 minor 版本
make release minor

# 或发布 major 版本
make release major
```

这个命令会自动：
1. ✅ 更新 `.version` 文件
2. ✅ 更新 `CHANGELOG.md`
3. ✅ 创建 git tag
4. ✅ 构建 DMG
5. ✅ 创建 GitHub Release
6. ✅ 生成 Sparkle 签名
7. ✅ 更新 `appcast.xml`
8. ✅ 更新 Homebrew Cask

#### 手动步骤（如需要）

**1. 仅生成 appcast**

```bash
./scripts/generate-appcast.sh build/artifacts/MarkdownPreviewEnhanced.dmg
```

**2. 仅更新 Homebrew Cask**

```bash
./scripts/update-homebrew-cask.sh 1.4.85
```

### 部署 appcast.xml

Sparkle 需要访问 `appcast.xml` 来检查更新。推荐使用 GitHub Pages：

#### 方法 1: GitHub Pages（推荐）

1. 在 GitHub 仓库设置中启用 Pages
2. 选择 `main` 分支的 `/docs` 目录（或根目录）
3. 将 `appcast.xml` 提交到对应目录
4. 访问 `https://YOUR_USERNAME.github.io/YOUR_REPO/appcast.xml`

#### 方法 2: GitHub Releases（备选）

在 `Info.plist` 中使用：

```xml
<key>SUFeedURL</key>
<string>https://raw.githubusercontent.com/xykong/markdown-quicklook/master/appcast.xml</string>
```

### 安全最佳实践

#### 私钥管理

⚠️ **绝对不要提交私钥到 Git！**

```bash
# .gitignore 中已包含
.sparkle-keys/
```

**推荐存储方式：**
- 1Password / LastPass 等密码管理器
- 加密的 USB 驱动器
- 云端加密存储（如 1Password Vault）

**CI/CD 环境：**
- 使用 GitHub Secrets 存储私钥
- 在 workflow 中临时解密使用
- 构建完成后立即删除

#### 签名验证

每次发布时，Sparkle 会：
1. 使用私钥对 DMG 文件生成 EdDSA 签名
2. 签名存储在 `appcast.xml` 中
3. 用户端使用公钥验证签名
4. 签名不匹配 → 拒绝安装

## 用户体验

### DMG 用户更新流程

1. **后台检查**: 应用每天检查一次更新（启动后 + 定时）
2. **发现新版本**: 弹出通知对话框
   ```
   ┌─────────────────────────────────────┐
   │  发现新版本 1.4.85                   │
   │                                     │
   │  新增功能：                          │
   │  - 混合更新策略支持                  │
   │  - Sparkle 自动更新                 │
   │                                     │
   │  [稍后提醒]  [安装更新]               │
   └─────────────────────────────────────┘
   ```
3. **下载更新**: 显示下载进度条
4. **安装更新**: 自动安装，提示重启应用

### 手动检查更新

无论安装方式，用户都可以：
- 点击菜单栏 "检查更新..." 按钮
- 或使用快捷键 ⌘U

## 配置选项

### Info.plist 配置

```xml
<!-- 更新源 URL -->
<key>SUFeedURL</key>
<string>https://xykong.github.io/markdown-quicklook/appcast.xml</string>

<!-- 公钥 -->
<key>SUPublicEDKey</key>
<string>YOUR_PUBLIC_KEY</string>

<!-- 启用自动检查 -->
<key>SUEnableAutomaticChecks</key>
<true/>

<!-- 检查间隔（秒）：86400 = 24小时 -->
<key>SUScheduledCheckInterval</key>
<integer>86400</integer>

<!-- 允许自动安装（无需用户确认）-->
<key>SUAllowsAutomaticUpdates</key>
<true/>
```

### 自定义检查频率

Sparkle 的检查间隔在 `Info.plist` 中配置（见上方 `SUScheduledCheckInterval`）。
默认为 86400 秒（24 小时）。

## 故障排查

### Sparkle 未启动

**症状**: 应用启动但没有更新检查

**检查：**
1. Info.plist 中的公钥是否正确
2. appcast.xml 是否可访问
3. Console.app 中查看错误日志

```bash
log stream --predicate 'process == "Markdown Preview Enhanced"' --level debug
```

### 签名验证失败

**症状**: 提示"更新签名无效"

**原因：**
- 公钥与私钥不匹配
- appcast.xml 中的签名错误
- DMG 文件在签名后被修改

**解决：**
```bash
# 重新生成签名
./scripts/generate-appcast.sh build/artifacts/MarkdownPreviewEnhanced.dmg
```

### Homebrew 用户注意事项

**现象**: 通过 Sparkle 更新后，`brew list --versions` 显示旧版本

**说明**: 这是正常行为。Homebrew 的元数据不会自动更新，但应用本身是最新的。

**如果想通过 Homebrew 更新**: 使用 `brew upgrade --greedy markdown-preview-enhanced`

## 参考资源

- [Sparkle 官方文档](https://sparkle-project.org/documentation/)
- [Sparkle 沙盒支持](https://sparkle-project.org/documentation/sandboxing/)
- [EdDSA 签名指南](https://sparkle-project.org/documentation/package-updates/)
- [Homebrew Cask 文档](https://docs.brew.sh/Cask-Cookbook)

## 版本历史

- **1.5.88+**: 统一更新策略（所有用户使用 Sparkle）- 遵循业界标准
- **1.4.82-1.5.87**: 混合更新策略（Sparkle + Homebrew 检测）- 已废弃
- **1.4.0-1.4.81**: 仅手动更新（GitHub Releases + Homebrew）
