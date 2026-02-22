## ADDED Requirements

### Requirement: 图形化设置面板
Host App SHALL 提供一个原生 SwiftUI 设置面板，用户可通过图形界面配置预览偏好，无需修改代码或配置文件。

#### Scenario: 通过菜单打开设置面板
- **WHEN** 用户点击菜单栏中的"FluxMarkdown → Settings…"（或按 Cmd+,）
- **THEN** 弹出设置窗口，包含主题、字体大小等配置项

#### Scenario: 设置项持久化
- **WHEN** 用户在设置面板中修改任意配置项并关闭窗口
- **THEN** 该配置写入 UserDefaults，下次应用重启后仍然生效

---

### Requirement: 主题偏好配置
用户 SHALL 能够在设置面板中选择预览主题（Light / Dark / System），选择结果影响所有后续 QuickLook 预览窗口的外观。

#### Scenario: 选择 Dark 主题
- **WHEN** 用户在设置中选择"Dark"主题
- **THEN** 下次打开任意 Markdown 文件的 QuickLook 预览时，界面使用暗色主题，不依赖系统外观设置

#### Scenario: 选择 System 主题
- **WHEN** 用户在设置中选择"System"主题
- **THEN** 预览界面自动跟随 macOS 系统外观（Light/Dark）切换

---

### Requirement: 字体大小基准配置
用户 SHALL 能够在设置面板中调节预览内容的基准字体大小（范围 12–24pt，步进 1pt）。

#### Scenario: 调大字体后预览生效
- **WHEN** 用户将字体大小调整为 18pt 并关闭设置
- **THEN** 下次打开 QuickLook 预览时，正文字体大小以 18pt 为基准渲染

---

### Requirement: 渲染功能独立开关
用户 SHALL 能够在设置面板中独立开关以下渲染功能：Mermaid 图表、KaTeX 数学公式、Emoji 渲染。

#### Scenario: 关闭 Mermaid 后图表不再渲染
- **WHEN** 用户在设置中关闭 Mermaid 开关
- **THEN** 含有 mermaid 代码块的文件，图表代码以普通代码块形式显示，不执行渲染

#### Scenario: 关闭 KaTeX 后公式以代码形式显示
- **WHEN** 用户在设置中关闭 KaTeX 开关
- **THEN** 含有数学公式的文件，`$...$` 和 `$$...$$` 标记内容以原始文本显示，不渲染为公式
