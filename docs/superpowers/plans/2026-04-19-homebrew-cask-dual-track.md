# Homebrew Cask Dual-Track Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 维护两个版本的 Homebrew Cask：官方合规版（提交到 homebrew/homebrew-cask）和功能完整版（xykong/homebrew-tap）。

**Architecture:** 
- `../homebrew-tap/Casks/flux-markdown.rb` 是 **功能版**，修复格式问题但保留全部功能（duti、auto_updates 等）
- 新建 `../homebrew-tap/Casks/flux-markdown-official.rb` 作为 **官方版草稿**，符合 homebrew/homebrew-cask 所有规范
- `scripts/update-homebrew-cask.sh` 同时更新两个文件，并新增 `scripts/submit-to-homebrew.sh` 帮助提交官方 PR

**Tech Stack:** Ruby (Cask DSL), Bash, GitHub CLI (`gh`)

---

## 文件清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `../homebrew-tap/Casks/flux-markdown.rb` | **修改** | 功能版：修复 style 问题，保留 duti/auto_updates |
| `../homebrew-tap/Casks/flux-markdown-official.rb` | **新建** | 官方版草稿：符合 homebrew-cask 规范 |
| `scripts/update-homebrew-cask.sh` | **修改** | 同时更新两个 Cask 文件 |
| `scripts/submit-to-homebrew.sh` | **新建** | 自动化提交官方 PR 的帮助脚本 |
| `docs/release/HOMEBREW_SUBMISSION.md` | **新建** | 官方库提交和维护文档 |

---

## Task 1: 修复功能版 Cask 格式（tap 版）

修复 `../homebrew-tap/Casks/flux-markdown.rb` 中所有 `brew style` 报告的格式问题，同时保留所有功能。

**Files:**
- Modify: `../homebrew-tap/Casks/flux-markdown.rb`

- [ ] **Step 1: 更新 flux-markdown.rb（功能版）**

将文件内容替换为以下（所有 single quotes → double quotes，修复 stanza 顺序，修复 desc，修复 zap 排序）：

```ruby
cask "flux-markdown" do
  version "1.25.310"
  sha256 "27b1c1c60085274ecd1107be0f6c4645d8a9864073f5f3bf4b2b4014fccb1882"

  url "https://github.com/xykong/flux-markdown/releases/download/v#{version}/FluxMarkdown.dmg"
  name "FluxMarkdown"
  desc "Markdown previews in Finder QuickLook with diagrams and math"
  homepage "https://github.com/xykong/flux-markdown"

  livecheck do
    url "https://raw.githubusercontent.com/xykong/flux-markdown/master/appcast.xml"
    strategy :sparkle, &:short_version
  end

  auto_updates true

  app "FluxMarkdown.app"

  depends_on formula: "duti"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/FluxMarkdown.app"],
                   sudo: false

    lsregister = "/System/Library/Frameworks/CoreServices.framework" \
                 "/Frameworks/LaunchServices.framework/Support/lsregister"
    system_command lsregister,
                   args: ["-f", "#{appdir}/FluxMarkdown.app"],
                   sudo: false

    system_command "/usr/bin/qlmanage",
                   args: ["-r"],
                   sudo: false

    # Register the QuickLook extension directly via pluginkit.
    # This works in headless/non-GUI sessions (e.g. a different admin user running brew).
    # Replaces the previous `open --register-only` approach which required a GUI login
    # session and caused the entire installation to be rolled back on failure (issue #20).
    system_command "/usr/bin/pluginkit",
                   args: ["-a", "#{appdir}/FluxMarkdown.app/Contents/PlugIns/MarkdownPreview.appex"],
                   sudo: false

    # Set FluxMarkdown as the default handler for Markdown file types.
    # Use file extensions (.md, .markdown) rather than UTIs to avoid
    # "does not conform to any UTI hierarchy" errors on clean systems.
    duti_bin = ["/opt/homebrew/bin/duti", "/usr/local/bin/duti"].find { |p| File.exist?(p) }
    if duti_bin
      %w[.md .markdown].each do |ext|
        system_command duti_bin,
                       args:         ["-s", "com.xykong.Markdown", ext, "all"],
                       sudo:         false,
                       print_stderr: false
      end
    end
  end

  caveats <<~EOS
    FluxMarkdown has been set as the default app for .md and .markdown files.

    If the QuickLook extension does not work immediately:
      1. Run 'qlmanage -r' in Terminal.
      2. Restart Finder (Force Quit > Finder > Relaunch).
  EOS

  zap trash: [
    "~/Library/Application Scripts/com.xykong.Markdown",
    "~/Library/Application Scripts/com.xykong.Markdown.QuickLook",
    "~/Library/Containers/com.xykong.Markdown",
    "~/Library/Containers/com.xykong.Markdown.QuickLook",
  ]
end
```

- [ ] **Step 2: 验证 style 通过**

```bash
brew style /Users/xykong/workspace/xykong/homebrew-tap/Casks/flux-markdown.rb
```

期望输出：`1 file inspected, no offenses detected`（或仅剩不可自动修复的 line length）

- [ ] **Step 3: Commit**

```bash
cd /Users/xykong/workspace/xykong/homebrew-tap
git add Casks/flux-markdown.rb
git commit -m "fix(cask): fix brew style offenses in tap cask"
git push origin master
```

---

## Task 2: 创建官方版 Cask（官方合规版）

新建 `../homebrew-tap/Casks/flux-markdown-official.rb` 作为提交到官方的草稿文件（本地预览/测试用）。

**Files:**
- Create: `../homebrew-tap/Casks/flux-markdown-official.rb`

- [ ] **Step 1: 创建官方版 Cask 文件**

创建 `/Users/xykong/workspace/xykong/homebrew-tap/Casks/flux-markdown-official.rb`，内容如下：

```ruby
cask "flux-markdown" do
  version "1.25.310"
  sha256 "27b1c1c60085274ecd1107be0f6c4645d8a9864073f5f3bf4b2b4014fccb1882"

  url "https://github.com/xykong/flux-markdown/releases/download/v#{version}/FluxMarkdown.dmg"
  name "FluxMarkdown"
  desc "Markdown previews in Finder QuickLook with diagrams and math"
  homepage "https://github.com/xykong/flux-markdown"

  livecheck do
    url :stable
    strategy :github_latest
  end

  app "FluxMarkdown.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/FluxMarkdown.app"],
                   sudo: false

    lsregister = "/System/Library/Frameworks/CoreServices.framework" \
                 "/Frameworks/LaunchServices.framework/Support/lsregister"
    system_command lsregister,
                   args: ["-f", "#{appdir}/FluxMarkdown.app"],
                   sudo: false

    system_command "/usr/bin/qlmanage",
                   args: ["-r"],
                   sudo: false

    system_command "/usr/bin/pluginkit",
                   args: ["-a", "#{appdir}/FluxMarkdown.app/Contents/PlugIns/MarkdownPreview.appex"],
                   sudo: false
  end

  caveats <<~EOS
    If the QuickLook extension does not work immediately:
      1. Run 'qlmanage -r' in Terminal.
      2. Restart Finder (Force Quit > Finder > Relaunch).
  EOS

  zap trash: [
    "~/Library/Application Scripts/com.xykong.Markdown",
    "~/Library/Application Scripts/com.xykong.Markdown.QuickLook",
    "~/Library/Containers/com.xykong.Markdown",
    "~/Library/Containers/com.xykong.Markdown.QuickLook",
  ]
end
```

**官方版与功能版的关键差异：**
- ❌ 去掉 `auto_updates true`（官方禁止）
- ❌ 去掉 `depends_on formula: "duti"`（官方禁止 cask 依赖 formula）
- ❌ 去掉 duti 相关的 postflight（依赖被移除）
- ❌ 去掉 caveats 中关于默认 app 的说明
- ✅ livecheck 改为 `:github_latest` strategy
- ✅ 其余 postflight（xattr、lsregister、qlmanage、pluginkit）保留

- [ ] **Step 2: 验证 style 通过**

```bash
brew style /Users/xykong/workspace/xykong/homebrew-tap/Casks/flux-markdown-official.rb
```

期望输出：`1 file inspected, no offenses detected`

- [ ] **Step 3: Commit**

```bash
cd /Users/xykong/workspace/xykong/homebrew-tap
git add Casks/flux-markdown-official.rb
git commit -m "feat(cask): add official homebrew-cask compliant version"
git push origin master
```

---

## Task 3: 更新 update-homebrew-cask.sh 同时维护两个文件

**Files:**
- Modify: `scripts/update-homebrew-cask.sh`

- [ ] **Step 1: 更新脚本同时更新两个 Cask 文件**

在脚本中，在更新 `CASK_FILE`（功能版）之后，添加对 `OFFICIAL_CASK_FILE` 的同步更新：

在 `/Users/xykong/workspace/xykong/flux-markdown/scripts/update-homebrew-cask.sh` 中，在 `CASK_FILE` 定义后添加：

```bash
OFFICIAL_CASK_FILE="../homebrew-tap/Casks/flux-markdown-official.rb"
```

在更新功能版 cask 的 `sed` 命令之后添加以下块：

```bash
# Update official cask if it exists
if [ -f "$OFFICIAL_CASK_FILE" ]; then
    echo "🔧 Updating official cask file..."
    sed -i '' "s/version \".*\"/version \"$VERSION\"/" "$OFFICIAL_CASK_FILE"
    sed -i '' "s/sha256 \".*\"/sha256 \"$SHA256\"/" "$OFFICIAL_CASK_FILE"
    echo "✅ Official cask file updated: $OFFICIAL_CASK_FILE"
fi
```

- [ ] **Step 2: 验证脚本语法正确**

```bash
bash -n /Users/xykong/workspace/xykong/flux-markdown/scripts/update-homebrew-cask.sh
```

期望输出：无报错（exit 0）

- [ ] **Step 3: Commit**

```bash
cd /Users/xykong/workspace/xykong/flux-markdown
git add scripts/update-homebrew-cask.sh
git commit -m "feat(scripts): update cask script to sync both tap and official cask"
```

---

## Task 4: 创建 submit-to-homebrew.sh 提交帮助脚本

**Files:**
- Create: `scripts/submit-to-homebrew.sh`

- [ ] **Step 1: 创建提交脚本**

创建 `/Users/xykong/workspace/xykong/flux-markdown/scripts/submit-to-homebrew.sh`：

```bash
#!/bin/bash
# submit-to-homebrew.sh
# Helper script to submit flux-markdown to homebrew/homebrew-cask
#
# Usage: ./scripts/submit-to-homebrew.sh
#
# Prerequisites:
#   - gh CLI installed and authenticated
#   - Official cask already updated (run update-homebrew-cask.sh first)
#   - Homebrew/homebrew-cask fork exists (gh repo fork will create it)

set -e

OFFICIAL_CASK_FILE="../homebrew-tap/Casks/flux-markdown-official.rb"
VERSION_FILE=".version"

if [ ! -f "$VERSION_FILE" ]; then
    echo "❌ Error: Version file not found. Run from project root."
    exit 1
fi

if [ ! -f "$OFFICIAL_CASK_FILE" ]; then
    echo "❌ Error: Official cask not found at $OFFICIAL_CASK_FILE"
    echo "Run ./scripts/update-homebrew-cask.sh first."
    exit 1
fi

VERSION=$(cat "$VERSION_FILE")
WORK_DIR=$(mktemp -d)

echo "🍺 Preparing to submit flux-markdown v$VERSION to homebrew/homebrew-cask"
echo ""

# Check if fork exists, create if not
echo "📋 Checking for Homebrew/homebrew-cask fork..."
if ! gh repo view "$USER/homebrew-cask" &>/dev/null 2>&1; then
    echo "🔀 Forking Homebrew/homebrew-cask..."
    gh repo fork Homebrew/homebrew-cask --clone=false
fi

echo "📥 Cloning your fork..."
gh repo clone "$USER/homebrew-cask" "$WORK_DIR/homebrew-cask"
cd "$WORK_DIR/homebrew-cask"

# Ensure upstream is set
git remote add upstream https://github.com/Homebrew/homebrew-cask.git 2>/dev/null || true
git fetch upstream
git checkout master
git merge upstream/master

# Create branch
BRANCH="add-flux-markdown-${VERSION}"
git checkout -b "$BRANCH"

# Copy official cask to correct location (f/ subdirectory)
mkdir -p Casks/f
cp "$OLDPWD/$OFFICIAL_CASK_FILE" "Casks/f/flux-markdown.rb"

echo ""
echo "📄 Cask content to be submitted:"
echo "─────────────────────────────────"
cat Casks/f/flux-markdown.rb
echo "─────────────────────────────────"
echo ""

# Run style check
echo "🔍 Running brew style..."
brew style Casks/f/flux-markdown.rb

echo ""
echo "✅ Style check passed!"
echo ""

# Commit
git add Casks/f/flux-markdown.rb
git commit -m "Add flux-markdown"

# Push
git push origin "$BRANCH"

echo ""
echo "🚀 Creating PR to Homebrew/homebrew-cask..."

PR_URL=$(gh pr create \
    --repo Homebrew/homebrew-cask \
    --title "Add flux-markdown" \
    --body "$(cat <<'EOF'
## flux-markdown

- **Name:** FluxMarkdown
- **Homepage:** https://github.com/xykong/flux-markdown
- **Desc:** Markdown previews in Finder QuickLook with diagrams and math

**Checklist:**
- [x] I have read the [contribution guidelines](https://github.com/Homebrew/homebrew-cask/blob/master/CONTRIBUTING.md)
- [x] I have verified the cask works locally: `brew install --cask ./Casks/f/flux-markdown.rb`
- [x] `brew audit --cask flux-markdown` passes
- [x] `brew style flux-markdown` passes

**About this cask:**
FluxMarkdown is a macOS QuickLook extension for Markdown files with 600+ GitHub stars.
It supports Mermaid diagrams, KaTeX math, GFM, syntax highlighting, TOC, and export.
EOF
)" \
    --head "$USER:$BRANCH")

echo ""
echo "🎉 PR created: $PR_URL"
echo ""
echo "📝 Work directory: $WORK_DIR/homebrew-cask"
echo "   (cleanup with: rm -rf $WORK_DIR)"

# Cleanup temp dir (optional)
cd "$OLDPWD"
```

- [ ] **Step 2: 设置可执行权限**

```bash
chmod +x /Users/xykong/workspace/xykong/flux-markdown/scripts/submit-to-homebrew.sh
```

- [ ] **Step 3: 验证脚本语法**

```bash
bash -n /Users/xykong/workspace/xykong/flux-markdown/scripts/submit-to-homebrew.sh
```

- [ ] **Step 4: Commit**

```bash
cd /Users/xykong/workspace/xykong/flux-markdown
git add scripts/submit-to-homebrew.sh
git commit -m "feat(scripts): add submit-to-homebrew.sh for official cask submission"
```

---

## Task 5: 创建官方库提交文档

**Files:**
- Create: `docs/release/HOMEBREW_SUBMISSION.md`

- [ ] **Step 1: 创建文档**

创建 `/Users/xykong/workspace/xykong/flux-markdown/docs/release/HOMEBREW_SUBMISSION.md`：

```markdown
# Homebrew 官方库提交与维护指南

## 双轨策略

| 版本 | 位置 | 安装方式 | 功能 |
|------|------|----------|------|
| **功能版（tap）** | `../homebrew-tap/Casks/flux-markdown.rb` | `brew install --cask xykong/tap/flux-markdown` | 完整：duti 默认关联、auto_updates、appcast livecheck |
| **官方版** | `../homebrew-tap/Casks/flux-markdown-official.rb`（草稿）→ 提交到 homebrew/homebrew-cask | `brew install --cask flux-markdown` | 精简：符合官方规范，无 formula 依赖 |

---

## 首次提交到官方库

### 前提条件

- [ ] `gh` CLI 已安装且已登录（`gh auth status`）
- [ ] 官方版 cask 已更新（运行 `update-homebrew-cask.sh`）
- [ ] `brew style ./Casks/flux-markdown-official.rb` 无报错

### 提交步骤

```bash
# 1. 确认当前版本和 cask 是最新的
cat .version
brew style ../homebrew-tap/Casks/flux-markdown-official.rb

# 2. 运行提交脚本
./scripts/submit-to-homebrew.sh
```

脚本会自动：
1. Fork homebrew/homebrew-cask（如果尚未 fork）
2. Clone 你的 fork
3. 创建新分支 `add-flux-markdown-<version>`
4. 复制 official cask 到 `Casks/f/flux-markdown.rb`
5. 运行 style 检查
6. 提交并推送
7. 创建 PR

---

## 后续版本更新

### 功能版（tap）更新（每次 release 自动）

由 `update-homebrew-cask.sh` 自动处理：

```bash
./scripts/update-homebrew-cask.sh
# 同时更新 flux-markdown.rb 和 flux-markdown-official.rb
```

### 官方库版本更新

**方案一：依赖 Homebrew Bot（推荐）**

一旦官方 PR 合并，Homebrew 的 `BrewTestBot` 会自动检测新版本（通过 livecheck）并提 PR。
你只需：
1. 检查自动 PR 是否正确
2. 批准（Comment `@BrewTestBot approved` 或直接 approve）

**方案二：手动提 PR**

```bash
# 克隆已有 fork
git clone https://github.com/$USER/homebrew-cask
cd homebrew-cask
git fetch upstream && git merge upstream/master

# 创建分支
git checkout -b "bump-flux-markdown-<NEW_VERSION>"

# 更新版本
VERSION="<NEW_VERSION>"
SHA256="<NEW_SHA256>"
sed -i '' "s/version \".*\"/version \"$VERSION\"/" Casks/f/flux-markdown.rb
sed -i '' "s/sha256 \".*\"/sha256 \"$SHA256\"/" Casks/f/flux-markdown.rb

# 验证
brew style Casks/f/flux-markdown.rb

# 提交 PR
git add Casks/f/flux-markdown.rb
git commit -m "flux-markdown $VERSION"
gh pr create --repo Homebrew/homebrew-cask --title "flux-markdown $VERSION" --body "Version bump."
```

---

## 两个版本的差异说明

| 字段 | 功能版（tap） | 官方版 |
|------|-----------|--------|
| `auto_updates` | ✅ `true` | ❌ 不允许（官方管理更新） |
| `depends_on formula: "duti"` | ✅ 有 | ❌ 官方禁止 cask 依赖 formula |
| duti postflight | ✅ 设置默认文件关联 | ❌ 去掉 |
| livecheck strategy | `sparkle` + appcast.xml | `github_latest` |
| caveats | 含默认 app 说明 | 仅 QuickLook 说明 |

---

## 常见问题

**Q: 官方 PR 被拒绝怎么办？**
官方审核者常见反馈：
- `postflight` 命令需要解释原因 → 在 PR 描述中说明每个 `system_command` 的必要性
- 需要提供 `brew test` 用例 → 查看官方 CONTRIBUTING.md 了解测试要求

**Q: 官方库合并后我的 tap 版本如何共存？**
完全没问题。用户可以：
- `brew install --cask flux-markdown`（官方版，功能精简）
- `brew install --cask xykong/tap/flux-markdown`（tap 版，功能完整）

如果用户先安装了官方版，再想切换到 tap 版：
```bash
brew uninstall --cask flux-markdown
brew install --cask xykong/tap/flux-markdown
```
```

- [ ] **Step 2: Commit**

```bash
cd /Users/xykong/workspace/xykong/flux-markdown
git add docs/release/HOMEBREW_SUBMISSION.md
git commit -m "docs: add homebrew official submission guide"
```

---

## Task 6: 更新 AGENTS.md 记录双轨维护信息

**Files:**
- Modify: `AGENTS.md`

- [ ] **Step 1: 在 WHERE TO LOOK 表格中添加官方版条目**

在 `AGENTS.md` 的 `WHERE TO LOOK` 表格中，在 `Homebrew Cask` 行下方添加：

```markdown
| **Homebrew Official Cask** | `../homebrew-tap/Casks/flux-markdown-official.rb` | Official-compliant version for homebrew/homebrew-cask submission. |
```

并在 COMMANDS 部分添加：

```markdown
./scripts/submit-to-homebrew.sh   # Submit official cask to homebrew/homebrew-cask
```

- [ ] **Step 2: Commit**

```bash
cd /Users/xykong/workspace/xykong/flux-markdown
git add AGENTS.md
git commit -m "docs: update AGENTS.md with homebrew dual-track info"
```

---

## 自检清单

- [ ] `brew style flux-markdown.rb` — 0 offenses（功能版）
- [ ] `brew style flux-markdown-official.rb` — 0 offenses（官方版）
- [ ] `update-homebrew-cask.sh` 同时更新两个文件
- [ ] `submit-to-homebrew.sh` 语法正确，逻辑完整
- [ ] `HOMEBREW_SUBMISSION.md` 文档涵盖首次提交和后续维护
- [ ] `AGENTS.md` 更新反映新文件结构
