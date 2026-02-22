# Change: 支持 GraphViz / DOT 语言依赖关系图渲染

## Why

软件架构文档、系统设计文档中大量使用 DOT 语言描述模块依赖、调用关系、状态机等图结构。当前渲染器将 ` ```dot ` 和 ` ```graphviz ` 代码块作为普通代码块展示，用户无法在预览时看到可视化的图形，必须借助外部工具转换。`@hpcc-js/wasm-graphviz` 提供了基于 WebAssembly 的纯 JS GraphViz 实现，无需安装 Graphviz 二进制，离线可用，与沙箱环境完全兼容。

## What Changes

- 在渲染管线中识别 ` ```dot ` 和 ` ```graphviz ` 代码块，将其内容作为 DOT 语言规范渲染为 SVG 图形
- 引入 `@hpcc-js/wasm-graphviz` npm 包（WebAssembly 实现，纯 JS，离线可用）
- 渲染失败时降级显示原始代码块并附带错误提示
- 自动适配 Light / Dark 主题（背景色、文字色跟随主题）
- 添加对应 Jest 测试

## Impact

- Affected specs: `graphviz-diagrams`（新建）
- Affected code:
  - `web-renderer/src/index.ts`（代码块渲染钩子）
  - `web-renderer/package.json`（新增 `@hpcc-js/wasm-graphviz` 依赖）
  - `web-renderer/test/`（新增测试）
