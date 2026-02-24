# Sparkle 自动更新实现经验总结

**日期**: 2026-02-04  
**版本**: v1.6.102  
**问题**: 实现 macOS 沙盒应用的 Sparkle 自动更新功能

---

## 问题背景

为开源项目（非 Apple Developer 认证）添加 Sparkle 2.x 自动更新功能时，遇到了一系列级联问题，经过 **5 轮调试**才最终解决。

**初始目标**：让用户能够通过应用内的"检查更新"功能，自动下载并安装新版本。

**环境限制**：
- 开源项目，无 Apple Developer 账号
- 未进行代码签名和公证（Ad-hoc signing）
- 应用启用了沙盒（App Sandbox）
- 使用 Sparkle 2.8.1 框架

---

## 问题演化过程

### 第 1 轮：启动安装器失败

**错误信息**：
```
An error occurred while launching the installer. Please try again later.
```

**根本原因**：
沙盒应用缺少必要的权限，Sparkle 安装器进程无法启动。

**解决方案**：
在 `Markdown.entitlements` 中添加沙盒权限例外：

```xml
<!-- 允许 Sparkle 安装器与主应用通信 -->
<key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
<array>
    <string>com.xykong.Markdown.Installer</string>
</array>

<!-- 允许写入 /Applications 目录 -->
<key>com.apple.security.temporary-exception.files.absolute-path.read-write</key>
<array>
    <string>/Applications</string>
</array>
```

在 `Info.plist` 中启用安装器服务：
```xml
<key>SUEnableInstallerLauncherService</key>
<true/>
```

**失败原因**：服务名称错误。

---

### 第 2 轮：运行更新器失败

**错误信息**：
```
An error occurred while running the updater. Please try again later.
```

**根本原因**：
Mach lookup 服务名称不符合 Sparkle 规范。我们使用了自定义名称 `com.xykong.Markdown.Installer`，但 Sparkle 2.x 要求使用标准格式。

**解决方案**：
修正服务名称为 Sparkle 标准格式：

```xml
<key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
<array>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)-spks</string>  <!-- Status Service -->
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)-spki</string>  <!-- Installer Service -->
</array>
```

编译后自动展开为：
- `com.xykong.Markdown-spks`
- `com.xykong.Markdown-spki`

**失败原因**：密钥不匹配。

---

### 第 3 轮：签名验证失败

**错误信息**：
```
The update is improperly signed and could not be validated. Please try again later.
```

**根本原因**：
在调试过程中重新生成了 Sparkle 密钥对，导致：
- 已安装的应用（v1.6.97）包含**旧公钥**
- 新发布的更新（v1.6.99）用**新私钥**签名
- 签名验证失败（公钥与签名不匹配）

**技术细节**：
Sparkle 使用 EdDSA 非对称加密：
1. 发布者用**私钥**签名 DMG
2. 应用内嵌**公钥**验证签名
3. 如果密钥对不匹配，验证失败

**初步尝试**（失败）：
更新 `Info.plist` 中的公钥后重新发布 v1.6.100。但旧版本（v1.6.96-v1.6.99）仍然包含旧公钥，无法验证新签名。

**失败原因**：没有考虑向后兼容性。

---

### 第 4 轮：实现密钥迁移

**最终方案**：
使用 Sparkle 的密钥链（Key Chain）功能，在新版本中同时支持新旧两个公钥：

```xml
<key>SUPublicEDKey</key>
<string>BDhsLBTgtRax5K78RrmvkB2wCcLeKM7FxsuHu47soaU=</string>

<key>SUPublicEDKeyChain</key>
<array>
    <string>6SVanhzrlDTTBpWI4kYycYh05QUI0lbkZg/LyOQCO8A=</string>  <!-- 旧钥 -->
    <string>BDhsLBTgtRax5K78RrmvkB2wCcLeKM7FxsuHu47soaU=</string>  <!-- 新钥 -->
</array>
```

**工作原理**：
- v1.6.96（旧版本）用旧公钥验证 → 在 `SUPublicEDKeyChain` 中找到旧公钥 → 验证通过
- v1.6.102（新版本）用新公钥验证 → 在 `SUPublicEDKeyChain` 中找到新公钥 → 验证通过

**结果**：成功！

---

## 核心教训

### 1. **分层调试：逐层解决问题**

每个错误都只是**表面症状**，背后隐藏着**多层依赖关系**：

```
启动失败 → 权限不足 → Mach lookup 失败 → 服务名错误
           ↓
        签名验证 → 密钥不匹配 → 密钥迁移
```

**教训**：
- 不要一次性修改多个配置
- 每次只解决一个错误
- 验证修复后再继续
- 记录每一步的假设和结果

### 2. **文档与实践的差距**

**Sparkle 官方文档**存在的问题：
- 沙盒配置示例不完整
- 服务名称格式未明确说明（`-spks`/`-spki` 后缀）
- 密钥迁移场景未突出强调

**教训**：
- 官方文档是起点，不是终点
- 阅读 GitHub Issues 和源代码
- 搜索真实项目的实现案例
- 咨询专业 AI（如 Oracle）补充知识盲区

### 3. **向后兼容性的重要性**

**错误做法**：
直接更换密钥，导致所有旧版本用户无法更新。

**正确做法**：
使用 `SUPublicEDKeyChain` 实现渐进式迁移：
1. 新版本同时支持新旧两个公钥
2. 等待大部分用户升级后
3. 未来版本可移除旧公钥

**教训**：
- 任何涉及加密/验证的变更都要考虑向后兼容
- 设计迁移路径，而非断崖式升级
- 在测试环境模拟旧版本更新场景

### 4. **测试策略的重要性**

**我们的错误**：
- 初期只测试"最新版本 → 最新版本"
- 未测试"旧版本 → 新版本"的真实场景
- 导致密钥问题在生产环境才暴露

**正确测试流程**：
```bash
# 1. 下载旧版本
curl -L -o old.dmg https://github.com/.../v1.6.96/...

# 2. 安装旧版本
hdiutil attach old.dmg
cp -R "FluxMarkdown.app" /Applications/
hdiutil detach

# 3. 测试更新到新版本
open "/Applications/FluxMarkdown.app"
# 点击 "Check for Updates"
```

**教训**：
- 自动化测试脚本（如 `test-update-from-old-version.sh`）
- 模拟真实用户场景
- 测试多个版本的升级路径

### 5. **密钥管理的教训**

**我们犯的错误**：
- 密钥只存储在 macOS Keychain，未备份
- `.sparkle-keys/` 目录被清空后密钥丢失
- 无法用旧密钥签名新版本

**正确做法**：
```bash
# 1. 生成密钥后立即备份
security find-generic-password -l "Sparkle EdDSA Private Key" -g 2>&1 | grep "password:"

# 2. 安全存储
# - 密码管理器（1Password, Bitwarden）
# - 加密的私有仓库
# - 团队共享的安全存储

# 3. 文档记录
echo "Public Key: $(cat .sparkle-keys/sparkle_public_key.txt)" >> .sparkle-keys/README.md
```

**教训**：
- 密钥是单点故障（SPOF）
- 丢失私钥 = 所有旧用户无法更新
- 加密密钥的管理优先级 = 代码仓库

---

## 通用开发指导

### 原则 1：增量开发与验证

**反模式**：
```
1. 一次性添加所有配置
2. 构建 → 发布
3. 用户报错 → 不知道哪里出问题
```

**正确模式**：
```
1. 添加权限配置 → 本地测试 → 验证通过
2. 修正服务名称 → 本地测试 → 验证通过
3. 配置密钥 → 本地测试 → 验证通过
4. 发布到生产环境
```

### 原则 2：文档驱动调试

**每次遇到难题时**：
1. 创建 `docs/DEBUG_XXX.md`
2. 记录问题现象、假设、尝试、结果
3. 最终方案落地到文档

**本次产出**：
- `docs/LESSONS_SPARKLE_AUTO_UPDATE.md`（本文档）
- `scripts/test-update-from-old-version.sh`（测试脚本）
- `.sparkle-keys/README.md`（密钥管理说明）

### 原则 3：咨询专家而非盲目尝试

**我们的做法**：
- 遇到权限问题 → 咨询 Oracle（AI 专家）
- Oracle 提供了完整的解决方案和最佳实践
- 节省了大量试错时间

**教训**：
- 复杂技术问题不要独自摸索
- 利用 AI 助手（Oracle, Librarian）
- 搜索真实项目的实现（GitHub Code Search）

### 原则 4：自动化测试优先

**教训**：
手动测试容易遗漏边界情况。自动化测试脚本确保：
- 可重复性
- 覆盖多种场景
- 节省时间

**示例**：
```bash
# 测试从旧版本更新
./scripts/test-update-from-old-version.sh

# 测试签名验证
./scripts/verify-sparkle-signature.sh
```

---

## 技术细节备忘

### Sparkle 2.x 沙盒配置（完整版）

```xml
<!-- Markdown.entitlements -->
<key>com.apple.security.app-sandbox</key>
<true/>

<!-- Sparkle XPC 服务 -->
<key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
<array>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)-spks</string>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)-spki</string>
</array>

<!-- 安装权限 -->
<key>com.apple.security.temporary-exception.files.absolute-path.read-write</key>
<array>
    <string>/Applications</string>
</array>

<!-- 下载权限 -->
<key>com.apple.security.files.downloads.read-write</key>
<true/>

<!-- 网络权限 -->
<key>com.apple.security.network.client</key>
<true/>
```

```xml
<!-- Info.plist -->
<key>SUFeedURL</key>
<string>https://your-domain.com/appcast.xml</string>

<key>SUPublicEDKey</key>
<string>YOUR_NEW_PUBLIC_KEY</string>

<key>SUPublicEDKeyChain</key>
<array>
    <string>YOUR_OLD_PUBLIC_KEY</string>
    <string>YOUR_NEW_PUBLIC_KEY</string>
</array>

<key>SUEnableInstallerLauncherService</key>
<true/>

<key>SUEnableAutomaticChecks</key>
<true/>

<key>SUScheduledCheckInterval</key>
<integer>86400</integer>
```

### 密钥生成与签名

```bash
# 1. 生成密钥（存储在 Keychain）
/path/to/Sparkle/bin/generate_keys

# 2. 备份公钥
security find-generic-password -l "Sparkle EdDSA Private Key" -g 2>&1 | \
    grep "password:" | cut -d '"' -f 2 > .sparkle-keys/public_key_backup.txt

# 3. 签名 DMG
/path/to/Sparkle/bin/sign_update YourApp.dmg

# 输出示例：
# sparkle:edSignature="..." length="123456"
```

### appcast.xml 格式

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>Your App</title>
        <item>
            <title>Version 1.6.102</title>
            <sparkle:version>102</sparkle:version>
            <sparkle:shortVersionString>1.6.102</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>11.0</sparkle:minimumSystemVersion>
            <pubDate>Wed, 04 Feb 2026 02:02:00 +0800</pubDate>
            <enclosure 
                url="https://github.com/.../YourApp.dmg"
                sparkle:edSignature="SIGNATURE_FROM_SIGN_UPDATE"
                length="FILE_SIZE_IN_BYTES"
                type="application/octet-stream" />
        </item>
    </channel>
</rss>
```

---

## 检查清单（Checklist）

实现 Sparkle 自动更新前，确保完成以下检查：

### 配置检查
- [ ] `Markdown.entitlements` 包含所有必要的沙盒权限
- [ ] Mach lookup 服务名称使用 `$(PRODUCT_BUNDLE_IDENTIFIER)-spks/spki` 格式
- [ ] `Info.plist` 包含 `SUEnableInstallerLauncherService`
- [ ] 公钥已正确添加到 `Info.plist`
- [ ] 如果更换过密钥，已配置 `SUPublicEDKeyChain`

### 密钥管理
- [ ] 密钥已生成并存储在 Keychain
- [ ] 私钥已备份到安全位置
- [ ] 公钥已记录在代码仓库（`.sparkle-keys/README.md`）
- [ ] 团队成员知道如何访问私钥

### 测试验证
- [ ] 本地测试：构建并安装到 `/Applications`
- [ ] 更新测试：从旧版本更新到新版本
- [ ] 签名验证：确保 DMG 签名正确
- [ ] 降级测试：旧版本能否验证新签名（密钥迁移）

### 发布流程
- [ ] DMG 已用私钥签名
- [ ] appcast.xml 已更新（版本、URL、签名、文件大小）
- [ ] appcast.xml 已推送到公开 URL
- [ ] GitHub Release 已创建并附带 DMG

---

## 参考资源

### 官方文档
- [Sparkle 2.x Documentation](https://sparkle-project.org/documentation/)
- [Sandboxing Guide](https://sparkle-project.org/documentation/sandboxing/)
- [EdDSA Signatures](https://sparkle-project.org/documentation/security/)

### 实战案例
- [iTerm2 Sparkle Configuration](https://github.com/gnachman/iTerm2)
- [Transmission Sparkle Setup](https://github.com/transmission/transmission)

### 调试工具
- `security find-generic-password` - 查看 Keychain 中的密钥
- `codesign -d --entitlements` - 验证应用的权限配置
- `log show --predicate` - 查看系统日志中的 Sparkle 错误

---

## 结论

这次调试经历的核心教训是：**复杂系统的集成需要系统性思考**。

看似简单的"自动更新"功能，实际涉及：
1. macOS 沙盒安全模型
2. Sparkle 框架的 XPC 服务架构
3. 非对称加密的密钥管理
4. 向后兼容的迁移策略
5. 真实用户场景的测试覆盖

**如果重来一次，我会这样做**：
1. 第一步：阅读 Sparkle 沙盒配置的完整文档（而非快速入门）
2. 第二步：搜索开源项目的完整配置（iTerm2, Transmission）
3. 第三步：创建自动化测试脚本（模拟旧版本更新）
4. 第四步：增量开发，每一步都验证
5. 第五步：文档记录每个决策和配置

**时间对比**：
- 实际耗时：5 轮调试 × 30 分钟 = 2.5 小时（多次发布、回滚）
- 理想耗时：系统性调研 30 分钟 + 一次性正确实现 30 分钟 = 1 小时

**节省的不仅是时间**，更重要的是：
- 用户体验（避免多次失败的更新尝试）
- 代码质量（一次性正确的配置）
- 团队知识沉淀（完整的文档）

---

**最后的建议**：当你遇到类似的复杂问题时，问自己三个问题：

1. **我是否理解了整个系统的工作原理？**（而非仅仅表面症状）
2. **我是否有完整的测试策略？**（覆盖真实用户场景）
3. **我是否记录了足够的信息供未来参考？**（文档 > 记忆）

记住：**慢即是快，快即是慢**。
