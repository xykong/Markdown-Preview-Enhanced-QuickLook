# Change: 支持 GitHub Alerts / Callouts 渲染

## Why

GitHub、Obsidian、Docusaurus、VitePress 等现代文档平台广泛支持 Callout（提示块）语法。用户在这些平台上撰写的文档大量使用 `> [!NOTE]`、`> [!WARNING]` 等标记来突出重要信息。当前渲染器将其作为普通 blockquote 处理，丢失了语义信息和视觉区分，导致技术文档的预览体验明显降级。

## What Changes

- 在 markdown-it 渲染管线中添加 Callout 自定义规则，识别 blockquote 首行为 `[!TYPE]` 的结构
- 支持的类型：`NOTE`、`TIP`、`IMPORTANT`、`WARNING`、`CAUTION`
- 将识别到的 Callout 渲染为带图标和语义颜色的结构化容器（区别于普通 blockquote）
- 自动适配 Light / Dark 主题
- 添加对应 Jest 测试

## Impact

- Affected specs: `github-alerts`（新建）
- Affected code:
  - `web-renderer/src/index.ts`（markdown-it 自定义规则）
  - `web-renderer/styles/`（Callout 样式）
  - `web-renderer/test/`（新增测试）
