# Change: mermaid chunk 预热，消除首次冷启动加载延迟

## Why

mermaid chunk（522KB）+ 其依赖（cytoscape 431KB、treemap 366KB）合计约 1.3MB，首次冷启动动态 import 耗时约 380ms（Layer 1 benchmark：`05-mermaid.md` cold p50 = 399ms）。即使用户文档含 mermaid，也要等这 380ms 才能开始渲染。

WebKit 拥有文件系统缓存：一旦某个 chunk 被请求过，后续相同路径的请求直接从缓存读取，速度快 10× 以上。利用这一点，可以在 `renderMarkdown()` 首次完成后的空闲时刻，悄悄触发一次 mermaid 的动态 import 来预热缓存，而不实际渲染任何内容。

## What Changes

- 在 `renderMarkdown()` 成功返回后（非 mermaid 文档路径），用 `setTimeout(..., 0)` 调度一个后台 idle 任务
- 该任务检查 `mermaidInstance` 是否已加载；若未加载，执行 `import('mermaid')` 并赋值缓存
- 仅预热一次（`mermaidInstance` 非 null 后不再触发）
- 整个预热过程在渲染完成后异步执行，不阻塞任何当前渲染

## Impact

- Affected specs: `js-renderer`
- Affected code: `web-renderer/src/index.ts`（`renderMarkdown` 函数末尾）
- 预期收益: 用户在同一 QuickLook 会话中打开第二个文件时，若为 mermaid 文档，冷启动从 ~399ms 降至 ~20ms（WebKit 缓存命中）
- 首次打开 mermaid 文档延迟不变（~399ms），但后续所有文档均受益
- 无副作用：预热 import 仅加载模块，不调用 `initialize()` 也不操作 DOM
