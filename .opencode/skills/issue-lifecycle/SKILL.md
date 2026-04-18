---
name: issue-lifecycle
description: |
  FluxMarkdown 项目 GitHub Issue 全生命周期处理技能。涵盖从 issue 调查、定位、修复追踪、
  发布核查，到回复用户、标记 done 的完整闭环流程。

  当用户提到以下任何场景时，必须使用本 skill：
  - "回复 issue"、"处理 issue"、"关闭 issue"、"标记 done"
  - "检查 issue 是否已修复"、"哪些 issue 需要回复"
  - "review issue 情况"、"issue 进展"、"issue 跟进"
  - 发布新版本后需要通知用户
  - 审查 CHANGELOG / Release Note 是否完整
  - 检查 appcast.xml 描述是否与 CHANGELOG 一致
  - "有没有遗漏的 issue"、"contributor 有没有感谢"

  即使用户只说"帮我看看 issue"或"发布完了"，也应触发此 skill。
---

# Issue 生命周期处理技能

本 skill 将 FluxMarkdown 项目处理 GitHub Issue 的完整经验固化为可复用流程。
目标：**不遗漏任何 issue，不遗漏任何贡献者，保持所有渠道信息一致。**

---

## 核心原则（不可违反）

1. **语言对齐**：回复语言必须与 issue 语言一致。英文 issue → 英文回复，中文 issue → 中文回复。
2. **不关闭 issue**：只加 `done` label + 发评论。由 issue 作者决定是否关闭。
3. **信息一致性**：CHANGELOG、GitHub Release Note、appcast.xml 三处描述必须一致，且都要体现 issue 号和贡献者感谢。
4. **不遗漏**：每次发布后，系统性检查所有 open issue，不能只处理"明显相关"的。

---

## 阶段一：调查 —— 梳理当前 issue 状态

发布后或用户要求处理 issue 时，先做全局扫描。

```bash
# 1. 列出所有 open issue（含已标记 done 的）
gh issue list --state open --limit 50

# 2. 列出最近关闭的 issue（确认有无遗漏）
gh issue list --state closed --limit 20

# 3. 查看最近发布的版本
gh release list --limit 5
```

**关键判断**：对每个 issue，确认：
- 是否已在某个版本中修复/实现？（查 git log、CHANGELOG）
- 是否已回复？（查 issue comments）
- 是否已加 `done` label？

> ⚠️ 常见陷阱：CHANGELOG 更新后补充了条目，但 appcast.xml 的 `<description>` 是在更新前生成的，导致自动更新提示内容不全。**每次修改 CHANGELOG 后必须检查 appcast.xml。**

---

## 阶段二：定位 —— 确认修复归属

对每个疑似已修复的 issue，用 git log 精确确认：

```bash
# 查找包含 issue 关键词的 commit
git log --oneline --grep="#21" 
git log --oneline --grep="Mouseless"

# 查看 commit 详情，确认修复内容和所属版本
git show <commit-hash> --stat

# 确认该 commit 属于哪个 release tag
git tag --contains <commit-hash>
```

**不要凭印象判断**——必须以 git 记录为准。

---

## 阶段三：核查发布内容完整性

发布后（或发现信息不一致时），系统核查三个渠道：

### 3.1 检查 CHANGELOG.md

每个版本的 CHANGELOG 条目应包含：
- ✅ 功能描述清晰
- ✅ 关联 issue 号 `(#N)`
- ✅ 贡献者感谢 `(thanks @username)` —— 对于用户报告的 issue
- ✅ 所有该版本的 git commit 都有对应条目（用 `git log v旧..v新` 核对）

**补全格式**（中文条目）：
```markdown
- **功能描述**: 修复/新增内容简述 (#issue号, thanks @username)
  - 技术细节 1
  - 技术细节 2
```

**补全格式**（英文条目，用于英文 issue 相关修复）：
```markdown
- **Feature**: Fix/add description (#N, thanks @username)
  - Technical detail 1
```

### 3.2 检查 GitHub Release Note

```bash
gh release view v版本号 --json body -q '.body'
```

Release Note 内容应与 CHANGELOG 对应版本一致。如需更新：

```bash
gh release edit v版本号 --notes "$(cat <<'EOF'
### Added / Fixed / Changed
- **xxx**: ...

---
**Install / Update:**
```bash
brew update && brew upgrade --cask flux-markdown
```
Or download the DMG directly from the Assets below.
EOF
)"
```

### 3.3 检查 appcast.xml

appcast.xml 的 `<description>` 是 Sparkle 自动更新窗口中用户看到的内容，极易与 CHANGELOG 脱节。

```bash
# 查看当前最新版本的 description
python3 -c "
import re
with open('appcast.xml') as f:
    content = f.read()
m = re.search(r'(Version 最新版本.*?<description><!\[CDATA\[)(.*?)(\]\]></description>)', content, re.DOTALL)
if m:
    print(m.group(2).strip()[:500])
"
```

如不完整，直接编辑 `appcast.xml` 中对应 `<description><![CDATA[...]]></description>` 部分，
将 Markdown 转为 HTML 格式（`<h3>`/`<ul><li>`/`<strong>`/`<code>`），然后提交推送：

```bash
git add appcast.xml
git commit -m "docs(appcast): fix missing entries in v版本号 description"
git push origin master
```

---

## 阶段四：回复 issue

### 4.1 确定每个 issue 的处理状态

| 状态 | 行动 |
|------|------|
| 已修复并发布 | 回复 + 加 `done` label |
| 已实现（Feature Request）| 回复 + 加 `done` label |
| 尚未修复但已知晓 | 回复说明当前状态 + 临时方案（若有）|
| 待调查 | 回复请求更多信息 |

### 4.2 执行回复（中文 issue）

```bash
gh issue comment <NUMBER> --body "已在 [vX.Y.Z](https://github.com/xykong/flux-markdown/releases/tag/vX.Y.Z) 中修复。

**修复内容：**
- [与此 issue 相关的具体修复描述]

**更新方式：**
\`\`\`bash
brew update && brew upgrade --cask flux-markdown
\`\`\`
或从 [Releases 页面](https://github.com/xykong/flux-markdown/releases/tag/vX.Y.Z) 直接下载 DMG。

感谢你的反馈，这个问题的修复正是因为你的报告才得以推进！如有其他问题欢迎继续反馈 🙏"
```

### 4.3 执行回复（英文 issue）

```bash
gh issue comment <NUMBER> --body "Fixed in [vX.Y.Z](https://github.com/xykong/flux-markdown/releases/tag/vX.Y.Z)! 🎉

**What changed:**
- [Specific fix relevant to this issue]

**To update:**
\`\`\`bash
brew update && brew upgrade --cask flux-markdown
\`\`\`
Or download the DMG from the [Releases page](https://github.com/xykong/flux-markdown/releases/tag/vX.Y.Z).

Thanks for the report — your issue helped prioritize this fix! Please give it a try and let us know if everything looks good. 🙏"
```

### 4.4 加 done label

```bash
gh issue edit <NUMBER> --add-label "done"
```

**注意**：仅对已修复/已实现的 issue 加 `done`。尚未解决的 issue 不加。

---

## 阶段五：发布完整性自查清单

每次处理 issue 后，过一遍此清单：

```
[ ] git log 中每个 fix/feat commit 都有对应的 CHANGELOG 条目
[ ] 每个 CHANGELOG 条目都标注了 issue 号（如有）
[ ] 每个用户报告的修复都有 thanks @username
[ ] GitHub Release Note 内容与 CHANGELOG 一致
[ ] appcast.xml <description> 与 CHANGELOG 一致
[ ] 所有相关 open issue 都已回复
[ ] 已修复的 issue 都已加 done label
[ ] 未修复但已知的 issue 已回复说明状态
[ ] Feature Request 实现后已回复并感谢贡献者
```

---

## 常见遗漏模式（经验教训）

本 skill 从实际操作中总结出以下高频遗漏，每次处理前主动检查：

### 1. appcast.xml 与 CHANGELOG 脱节
**场景**：发布时先跑 `generate-appcast.sh`，之后才补充 CHANGELOG 条目，导致 appcast description 不完整。
**检测**：对比 appcast 最新 item 的 description 与 CHANGELOG 对应版本的内容。
**修复**：直接编辑 appcast.xml 的 CDATA 部分并推送。

### 2. 同一版本包含多个 commit，只记录了部分
**场景**：一次发布包含 5 个 commit（icon 修复、scroll 修复、RTL 新功能、window 修复、release bump），但 CHANGELOG 只写了最后一个。
**检测**：`git log v上一版本..v当前版本 --oneline` 列出所有 commit，逐一核对 CHANGELOG。
**修复**：补全所有遗漏条目。

### 3. Feature Request issue 没有回复
**场景**：bug fix 类 issue 都回复了，但 feature request 类（无 `done` label）被忽略。
**检测**：`gh issue list` 中过滤无 `done` label 的 issue，逐一确认是否已实现。
**修复**：实现后补发回复 + 加 `done` label。

### 4. 错误判断"未修复"而回复了误导信息
**场景**：没有仔细查 git log，凭印象以为未修复，给用户回复了"正在调查"。
**预防**：回复前必须执行 `git log --oneline --grep="#issue号"` 确认。

### 5. 回复语言错误
**场景**：用中文回复了英文 issue，或用英文回复了中文 issue。
**预防**：回复前看 issue 正文语言，严格对齐。

---

## 工具命令速查

```bash
# 查看所有 open issue（含 labels）
gh issue list --state open --limit 50

# 查看某 issue 的全部评论
gh api repos/xykong/flux-markdown/issues/<NUMBER>/comments --jq '.[].body'

# 查看某 issue 详情（作者、语言、内容）
gh issue view <NUMBER>

# 查找某 issue 相关 commit
git log --oneline --grep="#<NUMBER>"

# 确认 commit 属于哪个 tag
git tag --contains <commit-hash>

# 查看两个版本之间的所有 commit
git log v旧版本..v新版本 --oneline

# 加 done label
gh issue edit <NUMBER> --add-label "done"

# 发评论
gh issue comment <NUMBER> --body "..."

# 查看 release note
gh release view v版本号 --json body -q '.body'

# 更新 release note
gh release edit v版本号 --notes "..."
```

---

## 与发布流程的协作

本 skill 聚焦 issue 生命周期。完整的发布流程（版本号升级、DMG 构建、Homebrew 更新）
由 `/publish` 命令处理。两者协作关系：

```
/publish 发布新版本
    ↓
issue-lifecycle skill 处理 issue 回复
    ↓
检查 CHANGELOG / Release Note / appcast.xml 一致性
    ↓
回复所有相关 issue + 标记 done
```
