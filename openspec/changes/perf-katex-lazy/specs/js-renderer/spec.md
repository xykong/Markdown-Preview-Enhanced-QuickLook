## MODIFIED Requirements

### Requirement: KaTeX 按需动态加载
渲染引擎 SHALL 仅在文档内容中检测到数学公式标记（`$...$` 或 `$$...$$`）时，才动态加载 KaTeX 插件。加载后的插件实例 SHALL 被缓存，后续含公式的渲染直接复用，不重复 import。

#### Scenario: 无公式文档不触发 KaTeX 加载
- **WHEN** `renderMarkdown()` 被调用，且文档内容不含 `$` 数学标记
- **THEN** KaTeX 相关 JS chunk 不被请求或执行
- **AND** 渲染结果与之前相同，纯文本 `$` 字符原样输出

#### Scenario: 含公式文档正常渲染
- **WHEN** `renderMarkdown()` 被调用，且文档内容含有效 KaTeX 公式（如 `$E=mc^2$`）
- **THEN** KaTeX 插件被动态 import 并缓存
- **AND** 公式被正确渲染为 HTML

#### Scenario: 主 chunk 体积缩减
- **WHEN** 执行 `npm run build`
- **THEN** `dist/assets/index-*.js` 的体积 SHALL 不超过 320KB（相比优化前 ~554KB 减少 40% 以上）
