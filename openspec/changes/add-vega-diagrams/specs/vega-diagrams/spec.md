## ADDED Requirements

### Requirement: Vega / Vega-Lite 代码块识别与图表渲染
渲染器 SHALL 识别语言标识符为 `vega` 或 `vega-lite` 的围栏代码块，将其内容解析为 Vega 规范并渲染为 SVG 图表，替换原始代码块展示。所有渲染 SHALL 在本地完成，不依赖任何外部网络服务。

#### Scenario: vega-lite 代码块渲染为图表
- **WHEN** Markdown 包含语言标识符为 `vega-lite` 且内容为合法 Vega-Lite JSON 规范的代码块
- **THEN** 该代码块被替换为对应的 SVG 图表，原始 JSON 文本不显示

#### Scenario: vega 代码块渲染为图表
- **WHEN** Markdown 包含语言标识符为 `vega` 且内容为合法 Vega JSON 规范的代码块
- **THEN** 该代码块被替换为对应的 SVG 图表，原始 JSON 文本不显示

#### Scenario: 无效 JSON 降级为代码块并显示错误提示
- **WHEN** `vega` 或 `vega-lite` 代码块内容不是合法 JSON
- **THEN** 保留原始代码块渲染，并在代码块下方显示错误提示文字，不抛出未捕获异常

#### Scenario: 合法 JSON 但不符合 Vega 规范时降级
- **WHEN** `vega` 或 `vega-lite` 代码块包含合法 JSON 但内容不符合 Vega 规范（如缺少 `$schema` 或 `mark` 字段）
- **THEN** 保留原始代码块渲染，并在代码块下方显示错误提示文字

#### Scenario: 其他语言代码块不受影响
- **WHEN** Markdown 包含语言标识符为非 `vega` / `vega-lite` 的代码块
- **THEN** 该代码块按原有代码高亮逻辑正常渲染，行为与引入 Vega 支持前完全一致

---

### Requirement: Vega 图表主题适配
Vega 图表的配色 SHALL 在 Light、Dark 和 System（随系统切换）三种主题下均保持可读性，背景色和文字色跟随当前主题。

#### Scenario: Dark 主题下图表配色自动适配
- **WHEN** 当前主题为 Dark 模式
- **THEN** Vega 图表使用适合暗色背景的配色方案，轴线、标签和图形元素在暗色背景上对比度充足

#### Scenario: Light 主题下图表配色正常
- **WHEN** 当前主题为 Light 模式
- **THEN** Vega 图表使用适合亮色背景的默认配色方案，图表清晰可读
