## ADDED Requirements

### Requirement: 扩展代码高亮语言覆盖
渲染器 SHALL 支持不少于 40 种编程语言的语法高亮，覆盖常见的系统语言（Rust、Kotlin、Swift）、脚本语言（Ruby、PHP、R）、数据科学语言（Python、R、MATLAB）等类别。

#### Scenario: Kotlin 代码块正确高亮
- **WHEN** Markdown 包含标注为 `kotlin` 的代码块
- **THEN** 渲染输出中 Kotlin 关键词（`fun`、`val`、`data class` 等）被正确着色

#### Scenario: Rust 代码块正确高亮
- **WHEN** Markdown 包含标注为 `rust` 的代码块
- **THEN** 渲染输出中 Rust 关键词（`fn`、`let`、`impl`、`'lifetime` 等）被正确着色

#### Scenario: 未知语言代码块安全降级
- **WHEN** Markdown 包含标注为未注册语言的代码块
- **THEN** 代码块以纯文本等宽字体显示，不报错、不崩溃、不显示乱码

---

### Requirement: 语言别名支持
渲染器 SHALL 支持常见的语言别名，使得 `js`、`py`、`ts`、`rb` 等短别名与对应完整语言名称等效处理。

#### Scenario: js 别名等效于 javascript
- **WHEN** 代码块标注语言为 `js`
- **THEN** 渲染效果与标注为 `javascript` 完全一致

#### Scenario: py 别名等效于 python
- **WHEN** 代码块标注语言为 `py`
- **THEN** 渲染效果与标注为 `python` 完全一致
