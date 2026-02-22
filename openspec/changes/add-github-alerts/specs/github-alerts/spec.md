## ADDED Requirements

### Requirement: GitHub Alerts / Callout 识别与渲染
渲染器 SHALL 识别 blockquote 首行为 `[!TYPE]` 格式的 Callout 语法，并将其渲染为带有视觉区分的结构化容器，而非普通 blockquote。支持的类型：`NOTE`、`TIP`、`IMPORTANT`、`WARNING`、`CAUTION`（类型名称大小写不敏感）。

#### Scenario: NOTE 类型 Callout 正确渲染
- **WHEN** Markdown 包含 `> [!NOTE]` 开头的 blockquote
- **THEN** 渲染输出为带蓝色语义配色和"Note"标签的结构化容器，不显示原始 `[!NOTE]` 文本

#### Scenario: WARNING 类型 Callout 正确渲染
- **WHEN** Markdown 包含 `> [!WARNING]` 开头的 blockquote
- **THEN** 渲染输出为带橙色/黄色语义配色和"Warning"标签的结构化容器

#### Scenario: CAUTION 类型 Callout 正确渲染
- **WHEN** Markdown 包含 `> [!CAUTION]` 开头的 blockquote
- **THEN** 渲染输出为带红色语义配色和"Caution"标签的结构化容器

#### Scenario: TIP 类型 Callout 正确渲染
- **WHEN** Markdown 包含 `> [!TIP]` 开头的 blockquote
- **THEN** 渲染输出为带绿色语义配色和"Tip"标签的结构化容器

#### Scenario: IMPORTANT 类型 Callout 正确渲染
- **WHEN** Markdown 包含 `> [!IMPORTANT]` 开头的 blockquote
- **THEN** 渲染输出为带紫色语义配色和"Important"标签的结构化容器

#### Scenario: 未知类型降级为普通 blockquote
- **WHEN** Markdown 包含 `> [!CUSTOM]` 等未注册类型的 blockquote
- **THEN** 整个 blockquote 作为普通引用块渲染，不应用 Callout 样式

#### Scenario: Callout 内支持完整 Markdown 内容
- **WHEN** Callout 容器内包含多行文本、加粗、链接、行内代码等 Markdown 语法
- **THEN** 容器内的所有 Markdown 语法均正常渲染

---

### Requirement: Callout 主题适配
Callout 容器的配色 SHALL 在 Light、Dark 和 System（随系统切换）三种主题下均保持可读性和语义一致性。

#### Scenario: Dark 模式下颜色自动适配
- **WHEN** 系统外观切换为 Dark 模式
- **THEN** 各类型 Callout 的背景色和边框色自动切换为适合暗色背景的配色，不出现对比度不足的情况

#### Scenario: 普通 blockquote 渲染不受影响
- **WHEN** Markdown 包含不带 `[!TYPE]` 标记的普通 blockquote
- **THEN** 该 blockquote 按原有普通引用样式渲染，与引入 Callout 功能前行为完全一致
