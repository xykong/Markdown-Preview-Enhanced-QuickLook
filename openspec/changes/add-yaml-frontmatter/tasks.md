## 1. 调研与技术选型

- [x] 1.1 评估现有 markdown-it 插件：`markdown-it-front-matter` vs 手动解析
- [x] 1.2 评估 YAML 解析库：`js-yaml`（轻量）vs 内置方案
- [x] 1.3 确定与 `markdown-it-anchor` / `markdown-it-task-lists` 的插件加载顺序兼容性
- [x] 1.4 记录技术选型决策到 `design.md`

## 2. 测试先行（TDD）

- [x] 2.1 编写测试：识别标准 `---` 包裹的 YAML 头部
- [x] 2.2 编写测试：YAML 键值对渲染为 HTML 表格（表格扩展启用时）
- [x] 2.3 编写测试：YAML 头部渲染为代码块（表格扩展未启用时）
- [x] 2.4 编写测试：嵌套 YAML 对象的嵌套表格渲染
- [x] 2.5 编写测试：无 YAML 头部的普通文件不受影响
- [x] 2.6 编写测试：YAML 头部后紧跟 `...` 结束符的场景
- [x] 2.7 编写测试：非文件首行出现 `---` 不被误识别为 Front Matter
- [x] 2.8 确认所有测试初始状态为红（失败）

## 3. 实现

- [x] 3.1 在 `web-renderer/src/index.ts` 渲染管线前置添加 Front Matter 提取逻辑
- [x] 3.2 实现 YAML 解析（引入选定的解析库或插件）
- [x] 3.3 实现表格渲染路径（键值对 → `<table>`）
- [x] 3.4 实现代码块回退路径（解析失败或未启用表格时）
- [x] 3.5 实现嵌套对象的递归表格生成
- [x] 3.6 确保提取后的正文 Markdown 内容正确传递给后续渲染管线

## 4. 样式与集成

- [x] 4.1 为 YAML 表格添加 CSS 样式（区分于正文普通表格，可用 `.yaml-frontmatter` 类名）
- [x] 4.2 验证 Light / Dark / System 三种主题下样式均正确
- [x] 4.3 验证与现有 TOC 生成逻辑的兼容性（Front Matter 标题不应出现在 TOC 中）

## 5. 验证与收尾

- [x] 5.1 运行 `npm test` 确认所有测试绿色通过
- [x] 5.2 手动测试：使用 Hugo / Jekyll 的真实 YAML Front Matter 文件验证渲染效果
- [x] 5.3 手动测试：不含 Front Matter 的普通 `.md` 文件渲染不受影响
- [x] 5.4 运行 `npm run build` 确认构建产物正常
- [x] 5.5 更新 `openspec/project.md` 中的功能列表（如适用）
