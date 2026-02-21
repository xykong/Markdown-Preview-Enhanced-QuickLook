# Change: KaTeX 改为动态懒加载，缩减主 chunk 体积

## Why

`@iktakahiro/markdown-it-katex` 通过静态 `import` 将 KaTeX（~259KB minified）拉入 `index.js` 主 chunk，导致所有文档冷启动都要解析这 259KB，即使文档中根本没有数学公式。当前 `index.js` 为 554KB，KaTeX 贡献约 47%。

## What Changes

- 移除 `import mk from '@iktakahiro/markdown-it-katex'` 静态导入
- 改为"探测 → 懒加载 → 渲染"两阶段流程：
  1. 渲染前用正则探测文档是否含 `$...$` 或 `$$...$$`
  2. 若有公式，动态 `import('@iktakahiro/markdown-it-katex')` 并注册插件，再渲染
  3. 若无公式，跳过 KaTeX，直接渲染（`$ ` 文本原样输出）
- KaTeX CSS（`katex/dist/katex.min.css`）同步静态 import 保留（CSS 不阻塞 JS 执行，且体积小）
- 用模块级缓存变量 `katexPlugin` 避免重复 import

## Impact

- Affected specs: `js-renderer`
- Affected code: `web-renderer/src/index.ts`（import 区域 + `renderMarkdown` 函数）
- 预期收益: `index.js` 从 ~554KB 降至 ~295KB（-47%）；无公式文档冷启动减少约 10–20ms JS 解析时间
- 无公式文档：行为完全不变（`$` 字符不会被 KaTeX 处理，原本也不应处理）
- 含公式文档：首次渲染多一次动态 import（磁盘读取，~5ms），后续渲染复用缓存
