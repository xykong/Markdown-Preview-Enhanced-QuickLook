## 1. 调研与选型

- [x] 1.1 评估 `vega` 与 `vega-lite` npm 包在浏览器（WKWebView）环境下的兼容性
- [x] 1.2 确认 `vega-lite` 可以将规范编译为完整 Vega 规范（`vega-lite` → `vega` 管线）
- [x] 1.3 评估 bundle 体积影响（与 vite-plugin-singlefile 内联策略的兼容性）
- [x] 1.4 确定支持的代码块语言标识符：`vega` 和 `vega-lite`
- [x] 1.5 确定图表容器尺寸策略（spec 中的 width/height 优先，缺省时自适应容器宽度）

## 2. 测试先行（TDD）

- [x] 2.1 编写测试：`vega-lite` 代码块包含合法 bar chart spec → 渲染为 `<svg>` 元素
- [x] 2.2 编写测试：`vega` 代码块包含合法 Vega spec → 渲染为 `<svg>` 元素
- [x] 2.3 编写测试：代码块包含无效 JSON → 降级显示带错误提示的原始代码块
- [x] 2.4 编写测试：代码块包含合法 JSON 但不符合 Vega 规范 → 降级显示带错误提示的原始代码块
- [x] 2.5 编写测试：普通代码块（非 vega/vega-lite 语言）渲染不受影响
- [x] 2.6 确认所有测试初始状态为红（失败）

## 3. 实现

- [x] 3.1 在 `web-renderer/package.json` 中添加 `vega` 和 `vega-lite` 依赖
- [x] 3.2 在 `web-renderer/src/index.ts` 中添加代码块后处理钩子，识别 `vega` / `vega-lite` 语言标识符
- [x] 3.3 实现 Vega-Lite 规范到 Vega 规范的编译（`vegaLite.compile(spec).spec`）
- [x] 3.4 实现 Vega 规范到 SVG 的渲染（`new vega.View(runtime).toSVG()`）
- [x] 3.5 将渲染结果 SVG 替换原 `<code>` 块，包裹在 `<div class="vega-diagram">` 容器中
- [x] 3.6 渲染失败时降级：保留原始 `<pre><code>` 并附加 `.vega-error` 提示文字
- [x] 3.7 添加主题色适配：根据 `data-theme` 属性为 SVG 注入前景色 / 背景色配置

## 4. 验证

- [x] 4.1 运行 `npm test` 确认所有测试绿色通过
- [x] 4.2 手动测试：使用 Vega-Lite 官方示例（bar、line、scatter chart）验证渲染正确
- [x] 4.3 验证 Light 主题下图表可读性
- [x] 4.4 验证 Dark 主题下图表可读性（背景/文字色适配）
- [x] 4.5 验证无效 JSON 降级行为
- [x] 4.6 验证普通代码块渲染不受影响（回归）
- [x] 4.7 运行 `npm run build` 确认构建正常，bundle 体积增量在可接受范围

## 5. 收尾

- [x] 5.1 更新 README 中的功能特性列表
