## 1. 改造 KaTeX 为动态加载

- [x] 1.1 在 `web-renderer/src/index.ts` 中移除 `import mk from '@iktakahiro/markdown-it-katex'`
- [x] 1.2 在模块顶层（`mermaidInstance` 变量附近）添加缓存变量：
  ```typescript
  let katexPlugin: ((md: MarkdownIt) => void) | null = null;
  ```
- [x] 1.3 在 `renderMarkdown()` 中，渲染前用正则 `/\$[\s\S]+?\$|\$\$[\s\S]+?\$\$/` 探测文档是否含公式
- [x] 1.4 若有公式且 `katexPlugin` 为 null，执行 `const m = await import('@iktakahiro/markdown-it-katex'); katexPlugin = m.default`
- [x] 1.5 根据 `katexPlugin` 是否存在，动态决定是否 `md.use(katexPlugin)` — 注意 `markdown-it` 的 `use()` 是幂等的，可安全多次调用

## 2. 验证

- [x] 2.1 运行 `npm run build`，确认 `index.js` 体积相比优化前明显缩小
- [x] 2.2 运行 `npm test`，确认全部 Jest 测试通过
- [x] 2.3 手动测试：打开含 KaTeX 公式的文档（`06-katex.md`），确认公式正常渲染
- [x] 2.4 手动测试：打开无公式文档（`01-tiny.md`），确认 `$` 符号原样输出，不崩溃
- [x] 2.5 运行 Layer 1 benchmark，对比 `06-katex.md` cold p50 和 `01-tiny.md` cold p50
