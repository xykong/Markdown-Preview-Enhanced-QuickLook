## 1. 调研与选型

- [x] 1.1 评估现有 npm 包：`markdown-it-github-alerts`、`markdown-it-obsidian-callouts` 等
- [x] 1.2 若无合适插件，评估自定义 markdown-it blockquote 规则的实现成本
- [x] 1.3 收集各平台 Callout 语法差异（GitHub、Obsidian、VitePress），确定需兼容的写法
- [x] 1.4 确定支持的类型集合（NOTE / TIP / IMPORTANT / WARNING / CAUTION）
- [x] 1.5 设计图标方案（Unicode emoji vs SVG inline）

## 2. 测试先行（TDD）

- [x] 2.1 编写测试：`> [!NOTE]` 渲染为 note 类型容器
- [x] 2.2 编写测试：`> [!WARNING]` 渲染为 warning 类型容器
- [x] 2.3 编写测试：`> [!TIP]` 渲染为 tip 类型容器
- [x] 2.4 编写测试：`> [!IMPORTANT]` 渲染为 important 类型容器
- [x] 2.5 编写测试：`> [!CAUTION]` 渲染为 caution 类型容器
- [x] 2.6 编写测试：未知类型（`> [!CUSTOM]`）降级为普通 blockquote
- [x] 2.7 编写测试：Callout 内支持多行内容和嵌套 Markdown
- [x] 2.8 编写测试：普通 blockquote（不含 `[!TYPE]`）渲染不受影响
- [x] 2.9 确认所有测试初始状态为红（失败）

## 3. 实现

- [x] 3.1 实现或引入 Callout 识别规则（markdown-it plugin 或自定义 blockquote_open rule）
- [x] 3.2 为每种类型生成带 `data-callout-type` 属性的 HTML 容器结构
- [x] 3.3 在 `web-renderer/styles/` 中添加 Callout CSS 样式
  - [x] 3.3.1 每种类型的左边框颜色和背景色
  - [x] 3.3.2 类型标签（如"📝 Note"）的样式
  - [x] 3.3.3 Dark mode 下的颜色适配（CSS media query）
- [x] 3.4 确保 Callout 内部的 Markdown 内容（加粗、链接、代码等）正常渲染

## 4. 验证

- [x] 4.1 运行 `npm test` 确认所有测试绿色通过
- [x] 4.2 手动测试：使用从 GitHub README / Obsidian 导出的真实 Callout 内容
- [x] 4.3 验证 Light 主题下各类型颜色正确
- [x] 4.4 验证 Dark 主题下各类型颜色正确
- [x] 4.5 验证 System 主题跟随系统切换时颜色自动更新
- [x] 4.6 验证普通 blockquote 渲染不受影响（回归）
- [x] 4.7 运行 `npm run build` 确认构建正常

## 5. 收尾

- [x] 5.1 更新 README 中的功能特性列表
