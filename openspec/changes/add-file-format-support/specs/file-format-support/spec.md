## ADDED Requirements

### Requirement: 扩展 Markdown 变体格式支持
FluxMarkdown QuickLook 扩展 SHALL 能够预览以下文件格式，渲染行为与 `.md` 文件完全一致：`.mdx`、`.rmd`、`.qmd`、`.mdoc`、`.mdown`、`.mkd`、`.mkdn`、`.mkdown`。

#### Scenario: MDX 文件可通过 QuickLook 预览
- **WHEN** 用户在 Finder 中选中 `.mdx` 文件并按下 Space 键
- **THEN** FluxMarkdown QuickLook 扩展被触发，文件内容作为 Markdown 渲染并显示（JSX 标签作为原始文本处理，不执行）

#### Scenario: R Markdown 文件可通过 QuickLook 预览
- **WHEN** 用户在 Finder 中选中 `.rmd` 文件并按下 Space 键
- **THEN** FluxMarkdown QuickLook 扩展被触发，文件内容作为 Markdown 渲染（R 代码块作为普通代码块显示，不执行）

#### Scenario: Quarto 文件可通过 QuickLook 预览
- **WHEN** 用户在 Finder 中选中 `.qmd` 文件并按下 Space 键
- **THEN** FluxMarkdown QuickLook 扩展被触发，文件内容作为 Markdown 渲染（代码块不执行）

#### Scenario: Markdoc 文件可通过 QuickLook 预览
- **WHEN** 用户在 Finder 中选中 `.mdoc` 文件并按下 Space 键
- **THEN** FluxMarkdown QuickLook 扩展被触发，文件内容作为 Markdown 渲染

#### Scenario: Markdown 别名格式可通过 QuickLook 预览
- **WHEN** 用户在 Finder 中选中 `.mdown`、`.mkd`、`.mkdn` 或 `.mkdown` 格式的文件并按下 Space 键
- **THEN** FluxMarkdown QuickLook 扩展被触发，文件内容作为 Markdown 渲染

#### Scenario: 原有 .md 格式预览不受影响
- **WHEN** 用户在 Finder 中选中 `.md` 文件并按下 Space 键
- **THEN** 行为与新格式支持添加之前完全一致，无功能回归
