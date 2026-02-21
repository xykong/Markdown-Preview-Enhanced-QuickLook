## 1. 实现 mermaid idle 预热

- [ ] 1.1 在 `web-renderer/src/index.ts` 的 `renderMarkdown()` 函数末尾（`try` 块成功完成后），添加预热逻辑：
  ```typescript
  setTimeout(() => {
      if (!mermaidInstance) {
          import('mermaid').then(m => { mermaidInstance = m.default; });
      }
  }, 0);
  ```
- [ ] 1.2 确认该 `setTimeout` 放置在 `renderMarkdown` 的 `try` 块内部、最后一个 `await` 语句之后，保证只在渲染成功后触发

## 2. 验证

- [ ] 2.1 运行 `npm run build`，确认构建成功
- [ ] 2.2 运行 `npm test`，确认全部 Jest 测试通过
- [ ] 2.3 手动测试：先打开无 mermaid 的文档，再切换到含 mermaid 的文档，确认图表正常渲染
- [ ] 2.4 手动验证预热生效：在 Safari Web Inspector 中观察第二次打开 mermaid 文档时，mermaid chunk 的加载时间是否显著缩短
- [ ] 2.5 运行 Layer 1 benchmark，重点关注 `05-mermaid.md` warm p50（目标：≤ 20ms，从当前 ~190ms 降至接近零）
