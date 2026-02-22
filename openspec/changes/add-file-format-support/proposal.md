# Change: 扩展文件格式支持

## Why

当前 FluxMarkdown 仅注册了 `.md` 文件的 UTI（通用类型标识符），无法预览技术社区中广泛使用的其他 Markdown 变体格式。`.mdx`（React 文档生态）、`.rmd`（数据科学 / R Markdown）、`.qmd`（Quarto 学术写作）、`.mdoc`（Markdoc 文档平台）等格式在各自领域有大量用户，这些用户目前无法使用 FluxMarkdown 进行 QuickLook 预览。扩展文件格式支持是零技术成本、高用户覆盖率的改进。

## What Changes

- 在 `project.yml` 的 `UTImportedTypeDeclarations` 和 `NSExtension` 中注册新 UTI
- 新增支持的文件格式：
  - `.mdx` — MDX（Markdown + JSX，React 文档生态）
  - `.rmd` — R Markdown（数据科学，不执行 R 代码，仅预览文本）
  - `.qmd` — Quarto（科学写作，不执行代码）
  - `.mdoc` — Markdoc（Stripe 文档平台格式）
  - `.mdown` — Markdown 早期扩展名别名
  - `.mkd` / `.mkdn` / `.mkdown` — Markdown 常见别名
- 对以上格式，渲染行为与 `.md` 完全一致（纯文本 Markdown 渲染）
- 运行 `make generate` 重新生成 `.xcodeproj`

## Impact

- Affected specs: `file-format-support`（新建）
- Affected code:
  - `project.yml`（UTI 注册，Info.plist 等效项）
  - `make generate` 重新生成 `.xcodeproj`（无需手动编辑）
- **无需修改任何渲染逻辑**，纯配置变更
