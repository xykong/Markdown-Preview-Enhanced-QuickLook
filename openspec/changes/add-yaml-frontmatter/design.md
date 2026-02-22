## Context

YAML Front Matter 是静态网站生成器和技术写作工具的通用约定。文件形如：

```markdown
---
title: "My Post"
date: 2024-01-15
tags: [swift, macos]
author:
  name: Alice
  email: alice@example.com
---

# 正文内容
```

QuickLook 插件是**只读预览器**，无法影响文件内容，只需正确渲染。当前渲染器将 `---` 包裹的内容作为普通 Markdown 处理，导致分隔符和 YAML 文本以原始文本形式显示。

## Goals / Non-Goals

- Goals:
  - 识别文件首行为 `---` 的 YAML Front Matter
  - 将其渲染为结构化视图（优先表格，回退代码块）
  - 支持嵌套对象
  - 不影响不含 Front Matter 的文件

- Non-Goals:
  - 不对 YAML 内容进行校验或错误提示
  - 不支持 TOML / JSON Front Matter（范围外）
  - 不根据 Front Matter 改变渲染主题或布局（范围外）

## Decisions

- **技术选型**: 优先使用 `markdown-it-front-matter` 插件 + `js-yaml` 解析，而非手动字符串切割
  - 理由：插件与 markdown-it 管线集成更干净，避免破坏 token 流；`js-yaml` 是业界标准，轻量可靠
  - 替代方案考虑过：手动 `split('---')`，但对多行字符串值和边界条件处理脆弱

- **渲染策略**: 提取后的 YAML 作为独立 HTML 块注入到渲染结果最前端，与正文 Markdown 渲染完全分离
  - 理由：避免 YAML 内容干扰 markdown-it 的标题锚点、TOC 生成等逻辑

- **CSS 类名**: 使用 `.yaml-frontmatter` 包裹容器，便于样式隔离和未来定制

## Risks / Trade-offs

- **性能**: `js-yaml` 增加约 40KB bundle 体积 → 可通过动态 import 仅在检测到 Front Matter 时加载（与 KaTeX 延迟加载策略一致）
- **误识别风险**: 若 Markdown 正文中有独立的 `---` 分隔线，可能被误识别 → 通过严格要求 Front Matter 必须从**文件第 1 行**开始来规避

## Open Questions

- 是否需要支持 `+++` (TOML) 格式？（当前倾向：不支持，等用户反馈）
- 数组类型的 YAML 值（如 `tags: [a, b, c]`）如何在表格中展示？（建议：以逗号分隔的行内文本）
