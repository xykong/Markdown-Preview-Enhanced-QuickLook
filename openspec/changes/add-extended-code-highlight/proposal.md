# Change: 代码高亮语言扩展与按需加载

## Why

当前为优化 bundle 体积，highlight.js 仅预置了 24 种常用语言。当用户预览包含其他编程语言（如 Kotlin、Rust、Scala、Ruby、PHP、R、MATLAB 等）的 Markdown 文档时，代码块会降级为纯文本显示，无语法着色。需要在保持性能优化成果的前提下，提供更广泛的语言覆盖。

## What Changes

- 实现语言按需动态加载机制（Dynamic Import）：渲染时检测代码块使用的语言，若未预置则动态加载对应语言包
- 扩展预置语言列表至涵盖最常用的 40+ 种语言
- 提供语言别名映射（如 `js` → `javascript`，`py` → `python`）
- 当语言无法识别时，提供可选的自动语言检测（基于 highlight.js 的 `highlightAuto`）

## Impact

- Affected specs: `code-highlight`（新建）
- Affected code:
  - `web-renderer/src/index.ts`（highlight.js 初始化和代码块渲染逻辑）
  - `web-renderer/package.json`（highlight.js 依赖不变，配置调整）
  - `web-renderer/test/`（新增测试）
