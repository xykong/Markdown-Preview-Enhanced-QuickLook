## 1. 调研与选型

- [x] 1.1 评估 `@hpcc-js/wasm-graphviz` 在 WKWebView / Vite 构建环境下的兼容性
- [x] 1.2 确认 WebAssembly `.wasm` 文件的打包策略（是否可与 vite-plugin-singlefile 一起内联）
- [x] 1.3 评估 bundle 体积影响（wasm 文件大小，与现有 5.5 MB 单文件策略的兼容性）
- [x] 1.4 确定支持的代码块语言标识符：`dot` 和 `graphviz`
- [x] 1.5 确定布局引擎选择策略（默认使用 `dot`，可通过注释或属性扩展）

## 2. 测试先行（TDD）

- [x] 2.1 编写测试：`dot` 代码块包含合法有向图（`digraph`）→ 渲染为 `<svg>` 元素
- [x] 2.2 编写测试：`graphviz` 代码块包含合法无向图（`graph`）→ 渲染为 `<svg>` 元素
- [x] 2.3 编写测试：代码块包含非法 DOT 语法 → 降级显示带错误提示的原始代码块
- [x] 2.4 编写测试：空代码块 → 降级显示带错误提示的原始代码块
- [x] 2.5 编写测试：普通代码块（非 dot/graphviz 语言）渲染不受影响
- [x] 2.6 确认所有测试初始状态为红（失败）

## 3. 实现

- [x] 3.1 在 `web-renderer/package.json` 中添加 `@hpcc-js/wasm-graphviz` 依赖
- [x] 3.2 在 `web-renderer/src/index.ts` 中添加代码块后处理钩子，识别 `dot` / `graphviz` 语言标识符
- [x] 3.3 实现异步 WASM 模块初始化（在渲染前确保 `graphviz` 实例已就绪）
- [x] 3.4 调用 `graphviz.dot(src)` 将 DOT 源码转换为 SVG 字符串
- [x] 3.5 将渲染结果 SVG 替换原 `<code>` 块，包裹在 `<div class="graphviz-diagram">` 容器中
- [x] 3.6 渲染失败时降级：保留原始 `<pre><code>` 并附加 `.graphviz-error` 提示文字
- [x] 3.7 添加主题色适配：根据 `data-theme` 属性为 SVG 注入前景色 / 背景色样式

## 4. 验证

- [x] 4.1 运行 `npm test` 确认所有测试绿色通过
- [x] 4.2 手动测试：使用典型 DOT 图（依赖关系图、状态机、树形结构）验证渲染正确
- [x] 4.3 验证 Light 主题下图表可读性
- [x] 4.4 验证 Dark 主题下图表可读性（节点边框、标签色适配）
- [x] 4.5 验证非法 DOT 语法降级行为
- [x] 4.6 验证普通代码块渲染不受影响（回归）
- [x] 4.7 运行 `npm run build` 确认构建正常，WASM 文件正确打包

## 5. 收尾

- [x] 5.1 更新 README 中的功能特性列表
