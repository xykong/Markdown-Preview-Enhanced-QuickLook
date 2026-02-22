## ADDED Requirements

### Requirement: HTML 导出入口
Host App SHALL 在菜单栏 File 分组下提供 "Export as HTML…" 菜单项，快捷键为 `Cmd+Shift+E`。该菜单项在无 Markdown 文档打开时 SHALL 处于禁用状态。

#### Scenario: 有文档时菜单项可用
- **WHEN** 用户打开了一个 Markdown 文档
- **THEN** "Export as HTML…" 菜单项处于可点击状态

#### Scenario: 无文档时菜单项禁用
- **WHEN** 未打开任何 Markdown 文档
- **THEN** "Export as HTML…" 菜单项处于禁用（grayed out）状态

---

### Requirement: 自包含 HTML 导出内容
导出的 HTML 文件 SHALL 完全自包含：所有 CSS、JavaScript、字体和本地图片 SHALL 以内联形式嵌入文件，导出文件在无网络环境下 SHALL 可在任意现代浏览器中正确渲染，与预览效果一致。

#### Scenario: 导出文件离线可打开
- **WHEN** 用户导出 HTML 并在断网环境下用浏览器打开
- **THEN** 文档内容、样式、代码高亮、数学公式和图表完整显示，无任何资源加载失败

#### Scenario: 本地图片内联为 base64
- **WHEN** Markdown 文档引用了相对路径的本地图片
- **THEN** 导出的 HTML 中该图片以 `data:image/...;base64,...` 形式内联，图片正常显示

#### Scenario: 导出内容不含交互 UI 元素
- **WHEN** 用户导出 HTML
- **THEN** 导出文件中不包含 TOC 侧边栏、搜索框、主题切换按钮等交互控件，仅保留正文渲染内容

---

### Requirement: 保存文件交互
触发导出后 SHALL 弹出系统标准 `NSSavePanel`，默认文件名为源 Markdown 文件名（扩展名替换为 `.html`），允许用户修改保存路径和文件名。

#### Scenario: 默认文件名来自源文件
- **WHEN** 用户对 `meeting-notes.md` 触发 "Export as HTML…"
- **THEN** 保存面板默认文件名为 `meeting-notes.html`

#### Scenario: 用户取消时不写入文件
- **WHEN** 用户在保存面板点击取消
- **THEN** 不写入任何文件，当前文档状态不变
