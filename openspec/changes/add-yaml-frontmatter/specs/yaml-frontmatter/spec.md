## ADDED Requirements

### Requirement: YAML Front Matter 识别
渲染器 SHALL 识别 Markdown 文件开头以 `---` 为第一行、以 `---` 或 `...` 为结束行的 YAML Front Matter 块，并将其从正文 Markdown 内容中分离，不参与后续 Markdown 渲染管线。

#### Scenario: 标准 Front Matter 被正确提取
- **WHEN** Markdown 文件第一行为 `---`，且后续某行为 `---` 或 `...`
- **THEN** 两个分隔符之间的内容被识别为 YAML Front Matter，不在正文中显示原始 `---` 和 YAML 文本

#### Scenario: 非首行分隔符不被误识别
- **WHEN** Markdown 正文中（非第一行）出现独立的 `---` 分隔线
- **THEN** 该分隔线按普通 Markdown 水平线处理，不触发 Front Matter 解析

#### Scenario: 无 Front Matter 的文件不受影响
- **WHEN** Markdown 文件第一行不是 `---`
- **THEN** 整个文件内容作为正常 Markdown 渲染，行为与添加此功能前完全一致

---

### Requirement: YAML Front Matter 表格渲染
当 YAML Front Matter 被成功解析时，渲染器 SHALL 将键值对渲染为 HTML 表格，置于正文内容之前，使用 `.yaml-frontmatter` CSS 类名包裹。

#### Scenario: 简单键值对渲染为表格
- **WHEN** YAML Front Matter 包含简单键值对（如 `title: "My Post"`, `date: 2024-01-15`）
- **THEN** 渲染输出中包含一个两列表格（键 / 值），每个 YAML 条目对应一行

#### Scenario: 嵌套对象渲染为嵌套表格
- **WHEN** YAML 值为嵌套对象（如 `author: { name: Alice, email: alice@example.com }`）
- **THEN** 嵌套对象在对应单元格中以嵌套表格形式展示

#### Scenario: 数组值渲染为行内文本
- **WHEN** YAML 值为数组（如 `tags: [swift, macos, quicklook]`）
- **THEN** 数组元素以逗号分隔的行内文本显示在同一单元格中

#### Scenario: Front Matter 不出现在目录（TOC）中
- **WHEN** 文件含有 YAML Front Matter 且正文含有标题
- **THEN** TOC 面板仅显示正文标题，不包含 YAML 键名

---

### Requirement: YAML 解析失败回退
当 YAML Front Matter 内容无法被解析为合法 YAML 时，渲染器 SHALL 将其作为带语法高亮的代码块渲染，而非静默失败或崩溃。

#### Scenario: 非法 YAML 内容降级为代码块
- **WHEN** Front Matter 块内容解析失败（格式错误的 YAML）
- **THEN** 该内容以 `yaml` 语言标识的语法高亮代码块形式展示，并附加视觉提示标识解析失败

#### Scenario: 渲染器不因 YAML 解析失败而崩溃
- **WHEN** YAML Front Matter 内容存在语法错误
- **THEN** 正文 Markdown 内容仍然正常渲染，不受影响
