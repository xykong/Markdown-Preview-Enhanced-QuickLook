## ADDED Requirements

### Requirement: DOT 语言代码块识别与图形渲染
渲染器 SHALL 识别语言标识符为 `dot` 或 `graphviz` 的围栏代码块，将其内容作为 DOT 语言规范渲染为 SVG 图形，替换原始代码块展示。所有渲染 SHALL 在本地完成，基于 WebAssembly 实现，不依赖任何外部网络服务或已安装的 Graphviz 二进制。

#### Scenario: dot 代码块有向图渲染为图形
- **WHEN** Markdown 包含语言标识符为 `dot` 且内容为合法 DOT 有向图（`digraph`）的代码块
- **THEN** 该代码块被替换为对应的 SVG 图形，原始 DOT 源码不显示

#### Scenario: graphviz 代码块无向图渲染为图形
- **WHEN** Markdown 包含语言标识符为 `graphviz` 且内容为合法 DOT 无向图（`graph`）的代码块
- **THEN** 该代码块被替换为对应的 SVG 图形，原始 DOT 源码不显示

#### Scenario: 非法 DOT 语法降级为代码块并显示错误提示
- **WHEN** `dot` 或 `graphviz` 代码块内容包含非法 DOT 语法
- **THEN** 保留原始代码块渲染，并在代码块下方显示错误提示文字，不抛出未捕获异常

#### Scenario: 空代码块降级为代码块并显示错误提示
- **WHEN** `dot` 或 `graphviz` 代码块内容为空或仅含空白字符
- **THEN** 保留原始代码块渲染，并在代码块下方显示错误提示文字

#### Scenario: 其他语言代码块不受影响
- **WHEN** Markdown 包含语言标识符为非 `dot` / `graphviz` 的代码块
- **THEN** 该代码块按原有代码高亮逻辑正常渲染，行为与引入 GraphViz 支持前完全一致

---

### Requirement: GraphViz 图形主题适配
GraphViz 图形的配色 SHALL 在 Light、Dark 和 System（随系统切换）三种主题下均保持可读性，节点边框色、背景色和文字色跟随当前主题。

#### Scenario: Dark 主题下图形配色自动适配
- **WHEN** 当前主题为 Dark 模式
- **THEN** GraphViz 图形使用适合暗色背景的配色方案，节点边框、连线和标签文字在暗色背景上对比度充足

#### Scenario: Light 主题下图形配色正常
- **WHEN** 当前主题为 Light 模式
- **THEN** GraphViz 图形使用适合亮色背景的默认配色方案，图形清晰可读
