# Change: 支持 YAML Front Matter 渲染

## Why

大量现实世界的 Markdown 文件（技术博客、静态网站生成器如 Hugo/Jekyll/Hexo、科研报告、Obsidian 笔记）在文件头部包含 YAML Front Matter。当前渲染器将其直接输出为原始 `---` 分隔的文本块，严重影响阅读体验。通过识别并结构化渲染 YAML 头信息，可以显著提升这类文件的预览质量。

## What Changes

- 在 `web-renderer/src/index.ts` 的渲染管线中，识别并提取文件头部的 YAML Front Matter（`---` 包裹）
- 当 `table` 扩展启用时，将 YAML 键值对渲染为格式化表格；否则渲染为带语法高亮的代码块
- 支持嵌套 YAML 对象的表格化展示（嵌套表格）
- 仅对 `.md` 文件默认启用；`.rmd` / `.qmd` 文件通过文件格式扩展提案单独处理
- 添加对应 Jest 测试用例覆盖各渲染路径

## Impact

- Affected specs: `yaml-frontmatter`（新建）
- Affected code:
  - `web-renderer/src/index.ts`（渲染管线主入口）
  - `web-renderer/test/`（新增测试文件）
  - 可能引入 `js-yaml` 或使用 `markdown-it-front-matter` 插件
