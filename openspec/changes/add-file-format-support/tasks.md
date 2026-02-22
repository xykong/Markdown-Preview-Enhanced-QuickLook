## 1. 调研

- [x] 1.1 查阅 Apple UTI 文档，确认各格式对应的 UTI 字符串（如 `io.typora.markdown` 的处理方式）
- [x] 1.2 用 `mdls -name kMDItemContentType` 检查各格式在当前 macOS 上的实际 UTI 注册情况
- [x] 1.3 确认 `.rmd` 和 `.qmd` 的动态 UTI（`dyn.ah62d4rv4ge81e5pe` 等）
- [x] 1.4 明确哪些格式需要声明为 `UTImportedTypeDeclarations`，哪些可直接用系统 UTI

## 2. 配置（TDD：先写验收标准）

- [x] 2.1 准备测试 fixture：各格式的简单 Markdown 文件（`tests/fixtures/test-*.mdx` 等）
- [x] 2.2 用 `qlmanage -p <file>` 验证扩展前各格式无法预览（记录基线）

## 3. 实现

- [x] 3.1 在 `project.yml` 中添加各格式的 `UTImportedTypeDeclarations`
- [x] 3.2 在 `project.yml` 的 QuickLook Extension `LSItemContentTypes` 中添加对应 UTI
- [x] 3.3 运行 `make generate` 重新生成 Xcode 项目
- [x] 3.4 运行 `make app` 构建 Host App 和 Extension

## 4. 验证

- [x] 4.1 用 `qlmanage -p test.mdx` 确认 MDX 文件可预览
- [x] 4.2 用 `qlmanage -p test.rmd` 确认 RMarkdown 文件可预览
- [x] 4.3 用 `qlmanage -p test.qmd` 确认 Quarto 文件可预览
- [x] 4.4 用 `qlmanage -p test.mdoc` 确认 Markdoc 文件可预览
- [x] 4.5 用 `qlmanage -p test.mdown` 确认 mdown 别名可预览
- [x] 4.6 确认已有 `.md` 文件预览不受影响（回归测试）
- [x] 4.7 在 Finder 中 Space 预览各格式文件，确认 QuickLook 扩展正确触发

## 5. 收尾

- [x] 5.1 更新 `README.md` 和 `README_ZH.md` 中的支持格式列表
- [x] 5.2 更新 `openspec/project.md` 中的支持格式说明
