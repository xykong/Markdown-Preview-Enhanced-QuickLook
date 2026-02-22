# Change: 支持 Vega / Vega-Lite 数据可视化图表

## Why

Markdown 文档中的数据可视化需求越来越普遍——从统计图表到交互式数据展示，用户通常只能截图或外链图片，无法在只读预览中保持数据的语义结构。Vega 和 Vega-Lite 是业界成熟的声明式可视化语法标准，纯 JSON/YAML 输入、纯 JS 渲染，与沙箱环境完全兼容，无需任何外部服务或运行时依赖。

## What Changes

- 在渲染管线中识别 ` ```vega ` 和 ` ```vega-lite ` 代码块，将其内容作为 Vega/Vega-Lite 规范渲染为 SVG 图表
- 引入 `vega` 和 `vega-lite` npm 包（纯 JS，离线可用）
- 图表渲染失败时降级显示原始代码块并附带错误提示
- 自动适配 Light / Dark 主题（背景色、文字色跟随主题）
- 添加对应 Jest 测试

## Impact

- Affected specs: `vega-diagrams`（新建）
- Affected code:
  - `web-renderer/src/index.ts`（代码块渲染钩子）
  - `web-renderer/package.json`（新增 `vega`、`vega-lite` 依赖）
  - `web-renderer/test/`（新增测试）
