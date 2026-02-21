## ADDED Requirements

### Requirement: mermaid 模块空闲预热
渲染引擎 SHALL 在每次 `renderMarkdown()` 成功完成后，调度一个空闲时刻任务（`setTimeout(..., 0)`），若 mermaid 模块尚未加载（`mermaidInstance === null`），则静默执行动态 import 以预热 WebKit 文件缓存。预热 SHALL 只触发一次，不得阻塞当前渲染，不得调用 `mermaid.initialize()` 或操作 DOM。

#### Scenario: 预热不影响当前渲染
- **WHEN** `renderMarkdown()` 被调用并完成渲染
- **THEN** 预热任务在当前调用栈清空后异步执行
- **AND** 当前渲染的完成时间不受预热影响

#### Scenario: 预热后 mermaid chunk 已缓存
- **WHEN** 同一 WKWebView 会话中首次 `renderMarkdown()` 完成后，预热任务已执行
- **AND** 后续调用 `renderMarkdown()` 时文档含 mermaid 块
- **THEN** mermaid 模块直接从缓存加载，`mermaidInstance` 已为非 null，跳过 import
- **AND** mermaid 渲染耗时 SHALL 显著低于首次冷加载（目标：warm p50 ≤ 20ms）

#### Scenario: 预热仅触发一次
- **WHEN** `renderMarkdown()` 被多次调用
- **AND** `mermaidInstance` 已在预热或正式渲染中被赋值
- **THEN** 后续预热任务检测到 `mermaidInstance !== null`，立即退出，不重复 import
