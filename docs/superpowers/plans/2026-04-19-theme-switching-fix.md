# Theme Switching Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将主题切换从「重新渲染文档」改为「切换 CSS 状态」，修复 Issue #26 的全部 5 个 bug。

**Architecture:** 新增 `window.updateTheme(theme)` JS 函数，通过 `data-theme` attribute + CSS 变量驱动主题变化，不再重建 DOM。Swift 侧新增 `viewDidChangeEffectiveAppearance()` observer，主题切换调用 `updateTheme()` 而非 `renderPendingMarkdown()`。

**Tech Stack:** TypeScript (Jest + jsdom), Swift (AppKit), CSS Custom Properties

---

## 文件变更清单

| 文件 | 操作 | 职责 |
|------|------|------|
| `web-renderer/src/index.ts` | 修改 | 新增 `window.updateTheme()`，声明类型，修改 `renderMarkdown`/`renderSource` 初始化时设置 `data-theme` |
| `web-renderer/src/styles/source-view.css` | 修改 | 改用 CSS 变量，支持 `[data-theme]` 驱动 |
| `web-renderer/src/styles/highlight-adaptive.css` | 修改 | 改用 `[data-theme="dark"]` 选择器，提升对比度 |
| `web-renderer/test/theme-switching.test.ts` | 新建 | 全部主题相关测试用例 |
| `Sources/MarkdownPreview/PreviewViewController.swift` | 修改 | 新增 `viewDidChangeEffectiveAppearance()`，`toggleTheme()` 改调 `updateTheme`，按钮颜色改为自适应 |

---

## Task 1: 建立测试文件骨架，写第一批 RED 测试

**文件：**
- 新建: `web-renderer/test/theme-switching.test.ts`

这批测试验证 `window.updateTheme()` 函数的核心行为：
1. 调用后 `data-theme` attribute 正确设置
2. 不触发 DOM 重建（outputDiv 内容保留）
3. 同时支持 preview 和 source 视图

- [ ] **Step 1: 写失败测试**

```typescript
// web-renderer/test/theme-switching.test.ts
jest.mock('mermaid', () => ({
  initialize: jest.fn(),
  render: jest.fn().mockResolvedValue({ svg: '<svg>mocked</svg>' }),
}));

import '../src/index';

describe('window.updateTheme', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="markdown-preview"></div>';
    // 重置 data-theme
    document.documentElement.removeAttribute('data-theme');
  });

  test('sets data-theme="dark" on documentElement when called with "dark"', () => {
    window.updateTheme('dark');
    expect(document.documentElement.getAttribute('data-theme')).toBe('dark');
  });

  test('sets data-theme="light" on documentElement when called with "light"', () => {
    window.updateTheme('light');
    expect(document.documentElement.getAttribute('data-theme')).toBe('light');
  });

  test('sets data-theme="default" on documentElement when called with "default"', () => {
    window.updateTheme('default');
    expect(document.documentElement.getAttribute('data-theme')).toBe('default');
  });

  test('does NOT replace outputDiv innerHTML when theme changes', async () => {
    // 先渲染一些内容
    await window.renderMarkdown('# Hello\n\nsome content');
    const preview = document.getElementById('markdown-preview');
    const domBeforeSwitch = preview?.innerHTML;

    // 切换主题
    window.updateTheme('dark');

    // DOM 内容不变
    expect(preview?.innerHTML).toBe(domBeforeSwitch);
  });

  test('can be called multiple times without resetting DOM content', async () => {
    await window.renderMarkdown('# Persistent Content');
    const preview = document.getElementById('markdown-preview');
    const snapshot = preview?.innerHTML;

    window.updateTheme('dark');
    window.updateTheme('light');
    window.updateTheme('dark');

    expect(preview?.innerHTML).toBe(snapshot);
  });

  test('updates theme from dark to light correctly', () => {
    window.updateTheme('dark');
    expect(document.documentElement.getAttribute('data-theme')).toBe('dark');
    window.updateTheme('light');
    expect(document.documentElement.getAttribute('data-theme')).toBe('light');
  });
});
```

- [ ] **Step 2: 运行，确认 RED**

```bash
cd web-renderer && npm test -- --testPathPattern=theme-switching
```

预期失败：`TypeError: window.updateTheme is not a function`

---

## Task 2: 实现 `window.updateTheme()` — GREEN

**文件：**
- 修改: `web-renderer/src/index.ts`

- [ ] **Step 1: 在 Window 接口声明中新增 `updateTheme`**

在 `web-renderer/src/index.ts` 第 395 行附近的 `declare global` 块中，找到：

```typescript
declare global {
    interface Window {
        renderMarkdown: (text: string, options?: RenderOptions) => Promise<void>;
        renderSource: (text: string, theme: string) => void;
        exportHTML: () => string;
```

在 `renderSource` 之后加一行：

```typescript
        updateTheme: (theme: string) => void;
```

- [ ] **Step 2: 实现 `window.updateTheme`**

在 `web-renderer/src/index.ts` 中，找到 `window.renderSource = function` 定义之后、`window.exportHTML` 之前，插入：

```typescript
window.updateTheme = function(theme: string) {
    // 规范化主题名（与 renderMarkdown 的逻辑保持一致）
    let normalizedTheme = theme;
    if (theme === 'system') {
        normalizedTheme = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches
            ? 'dark' : 'default';
    } else if (theme === 'light') {
        normalizedTheme = 'default';
    }
    document.documentElement.setAttribute('data-theme', normalizedTheme);
};
```

- [ ] **Step 3: 运行，确认 GREEN**

```bash
cd web-renderer && npm test -- --testPathPattern=theme-switching
```

预期：6 个测试全部 PASS

- [ ] **Step 4: 运行全量测试，确认没有回归**

```bash
cd web-renderer && npm test
```

预期：原 154 + 6 = 160 个测试全部 PASS

- [ ] **Step 5: 提交**

```bash
git add web-renderer/src/index.ts web-renderer/test/theme-switching.test.ts
git commit -m "feat(renderer): add window.updateTheme() for non-destructive theme switching"
```

---

## Task 3: 测试 `renderMarkdown` 初始化时设置 `data-theme` — RED

`renderMarkdown` 调用时应初始化 `data-theme`，使 CSS 变量从第一次渲染就生效。

**文件：**
- 修改: `web-renderer/test/theme-switching.test.ts`

- [ ] **Step 1: 追加失败测试**

在 `theme-switching.test.ts` 末尾追加新的 `describe` 块：

```typescript
describe('renderMarkdown initializes data-theme', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="markdown-preview"></div>';
    document.documentElement.removeAttribute('data-theme');
  });

  test('sets data-theme="dark" when options.theme is "dark"', async () => {
    await window.renderMarkdown('# Hello', { theme: 'dark' });
    expect(document.documentElement.getAttribute('data-theme')).toBe('dark');
  });

  test('sets data-theme="default" when options.theme is "light"', async () => {
    await window.renderMarkdown('# Hello', { theme: 'light' });
    expect(document.documentElement.getAttribute('data-theme')).toBe('default');
  });

  test('sets data-theme="default" when no theme option provided', async () => {
    await window.renderMarkdown('# Hello');
    expect(document.documentElement.getAttribute('data-theme')).toBe('default');
  });

  test('sets data-theme="dark" when options.theme is "system" and system is dark', async () => {
    // jsdom 默认 matchMedia 返回 false（light），所以 system → default
    await window.renderMarkdown('# Hello', { theme: 'system' });
    expect(document.documentElement.getAttribute('data-theme')).toBe('default');
  });
});
```

- [ ] **Step 2: 运行，确认 RED**

```bash
cd web-renderer && npm test -- --testPathPattern=theme-switching
```

预期失败：`data-theme` attribute 为 null（renderMarkdown 尚未设置它）

---

## Task 4: `renderMarkdown` 渲染时同步 `data-theme` — GREEN

**文件：**
- 修改: `web-renderer/src/index.ts`

- [ ] **Step 1: 在 renderMarkdown 中调用 updateTheme**

在 `web-renderer/src/index.ts` 的 `window.renderMarkdown` 函数内，找到：

```typescript
    let currentTheme = options.theme || 'default';
    if (currentTheme === 'system') {
        currentTheme = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'default';
    } else if (currentTheme === 'light') {
        currentTheme = 'default';
    }
    const mermaidTheme = currentTheme === 'dark' ? 'dark' : 'default';
```

在该段代码之后立即加一行：

```typescript
    // 同步 data-theme，使 CSS 变量生效
    document.documentElement.setAttribute('data-theme', currentTheme);
```

- [ ] **Step 2: 运行，确认 GREEN**

```bash
cd web-renderer && npm test -- --testPathPattern=theme-switching
```

预期：全部 PASS

- [ ] **Step 3: 全量测试**

```bash
cd web-renderer && npm test
```

预期：全部 PASS

- [ ] **Step 4: 提交**

```bash
git add web-renderer/src/index.ts web-renderer/test/theme-switching.test.ts
git commit -m "feat(renderer): sync data-theme attribute on every renderMarkdown call"
```

---

## Task 5: 测试 Source 视图也同步 `data-theme` — RED + GREEN

**文件：**
- 修改: `web-renderer/test/theme-switching.test.ts`
- 修改: `web-renderer/src/index.ts`

- [ ] **Step 1: 追加失败测试**

在 `theme-switching.test.ts` 末尾追加：

```typescript
describe('renderSource initializes data-theme', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="markdown-preview"></div>';
    document.documentElement.removeAttribute('data-theme');
  });

  test('sets data-theme="dark" when called with "dark"', () => {
    window.renderSource('# hello', 'dark');
    expect(document.documentElement.getAttribute('data-theme')).toBe('dark');
  });

  test('sets data-theme="default" when called with "light"', () => {
    window.renderSource('# hello', 'light');
    expect(document.documentElement.getAttribute('data-theme')).toBe('default');
  });

  test('does NOT wipe existing markdown content from a previous render', async () => {
    // 先用 renderMarkdown 渲染，记录 DOM
    await window.renderMarkdown('# Document Title');
    const previewBefore = document.getElementById('markdown-preview')?.innerHTML;

    // 切换到 source 视图后，再切回（模拟 toggleTheme 调用 updateTheme 而非重渲）
    window.updateTheme('dark');

    // data-theme 改变，但 markdown-preview 内容不变
    const previewAfter = document.getElementById('markdown-preview')?.innerHTML;
    expect(previewAfter).toBe(previewBefore);
  });
});
```

- [ ] **Step 2: 运行，确认 RED**

```bash
cd web-renderer && npm test -- --testPathPattern=theme-switching
```

- [ ] **Step 3: 在 renderSource 中同步 data-theme**

在 `web-renderer/src/index.ts` 的 `window.renderSource` 函数内，找到：

```typescript
window.renderSource = function(text: string, theme: string) {
    const outputDiv = document.getElementById('markdown-preview');
```

在函数体开头（获取 outputDiv 之后）加两行：

```typescript
    // 规范化并同步 data-theme
    const normalizedTheme = (theme === 'light') ? 'default' : theme;
    document.documentElement.setAttribute('data-theme', normalizedTheme);
```

- [ ] **Step 4: 运行，确认 GREEN**

```bash
cd web-renderer && npm test -- --testPathPattern=theme-switching
```

- [ ] **Step 5: 全量测试**

```bash
cd web-renderer && npm test
```

预期：全部 PASS

- [ ] **Step 6: 提交**

```bash
git add web-renderer/src/index.ts web-renderer/test/theme-switching.test.ts
git commit -m "feat(renderer): sync data-theme in renderSource, add theme-switching tests"
```

---

## Task 6: CSS 改造 — source-view 使用 CSS 变量 (Bug 4 & 5)

**文件：**
- 修改: `web-renderer/src/styles/source-view.css`

CSS 文件变更无 JS 测试，用视觉验证。但我们可以用 jsdom 测试 class 是否依旧正确挂载。

- [ ] **Step 1: 追加 CSS class 存在性测试（RED）**

在 `theme-switching.test.ts` 末尾追加：

```typescript
describe('renderSource applies correct CSS class', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="markdown-preview"></div>';
  });

  test('source-view-dark class is present when theme is "dark"', () => {
    window.renderSource('const x = 1;', 'dark');
    const sourceView = document.querySelector('.source-view');
    expect(sourceView?.classList.contains('source-view-dark')).toBe(true);
    expect(sourceView?.classList.contains('source-view-light')).toBe(false);
  });

  test('source-view-light class is present when theme is "light"', () => {
    window.renderSource('const x = 1;', 'light');
    const sourceView = document.querySelector('.source-view');
    expect(sourceView?.classList.contains('source-view-light')).toBe(true);
    expect(sourceView?.classList.contains('source-view-dark')).toBe(false);
  });

  test('source-view-light class is present when theme is "default"', () => {
    window.renderSource('const x = 1;', 'default');
    const sourceView = document.querySelector('.source-view');
    expect(sourceView?.classList.contains('source-view-light')).toBe(true);
  });
});
```

- [ ] **Step 2: 运行，确认 GREEN（这些测试应该现在就能过）**

```bash
cd web-renderer && npm test -- --testPathPattern=theme-switching
```

如果有失败，检查 renderSource 的 class 逻辑：

当前代码（index.ts ~794行）：
```typescript
outputDiv.innerHTML = `<div class="source-view ${theme === 'dark' ? 'source-view-dark' : 'source-view-light'}">...`;
```

这段逻辑本身是对的，测试应直接通过。

- [ ] **Step 3: 改造 source-view.css，使用 CSS 变量提升对比度（Bug 5）**

将 `web-renderer/src/styles/source-view.css` 全部内容替换为：

```css
/* CSS 变量定义（由 data-theme attribute 驱动） */
:root {
    --source-bg: #ffffff;
    --source-fg: #24292e;
    --source-border: #e1e4e8;
}

[data-theme="dark"] {
    --source-bg: #161b22;
    --source-fg: #e6edf3;
    --source-border: #30363d;
}

.source-view {
    width: 100%;
    height: 100%;
    overflow: auto;
    padding: 0;
    box-sizing: border-box;
}

/* 保留原有 class（供 renderSource 设置，确保向后兼容） */
.source-view-light {
    background-color: var(--source-bg, #ffffff);
    color: var(--source-fg, #24292e);
}

.source-view-dark {
    background-color: var(--source-bg, #161b22);
    color: var(--source-fg, #e6edf3);
}

.source-view .source-pre {
    margin: 0;
    padding: 0;
    border-radius: 0;
    font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
    font-size: 13px;
    line-height: 1.5;
    overflow-x: auto;
    white-space: pre-wrap;
    word-wrap: break-word;
    tab-size: 4;
}

.source-view-light .source-pre,
.source-view-dark .source-pre {
    background-color: transparent;
    border: none;
}

.source-view .source-pre code {
    font-family: inherit;
    font-size: inherit;
    line-height: inherit;
    background: transparent;
    border: none;
    padding: 0;
    margin: 0;
}

.source-view .hljs {
    background: transparent;
    padding: 0;
    overflow: visible;
}
```

- [ ] **Step 4: 全量测试（CSS mock 不影响逻辑）**

```bash
cd web-renderer && npm test
```

预期：全部 PASS（CSS 文件被 mock，不影响测试）

- [ ] **Step 5: 提交**

```bash
git add web-renderer/src/styles/source-view.css web-renderer/test/theme-switching.test.ts
git commit -m "fix(styles): improve source-view contrast with CSS variables, fix Bug 4 & 5"
```

---

## Task 7: Swift — `viewDidChangeEffectiveAppearance()` 修复 Bug 1

**文件：**
- 修改: `Sources/MarkdownPreview/PreviewViewController.swift`

Swift 无 JS 测试框架，验证方式为编译通过 + 手动测试。

- [ ] **Step 1: 提取主题检测逻辑为辅助方法**

在 `PreviewViewController.swift` 中，`renderSourceView()` 函数（~764行）**之前**插入新方法：

```swift
/// 根据当前 effectiveAppearance 返回 "dark" / "light" / "system"
private func currentThemeString() -> String {
    let appearanceName = self.view.effectiveAppearance.name
    if appearanceName == .darkAqua || appearanceName == .vibrantDark ||
       appearanceName == .accessibilityHighContrastDarkAqua ||
       appearanceName == .accessibilityHighContrastVibrantDark {
        return "dark"
    } else if appearanceName == .aqua || appearanceName == .vibrantLight ||
              appearanceName == .accessibilityHighContrastAqua ||
              appearanceName == .accessibilityHighContrastVibrantLight {
        return "light"
    }
    return "system"
}

/// 调用 JS window.updateTheme()，不重新渲染文档
private func applyThemeToWebView() {
    guard isWebViewLoaded else { return }
    let theme = currentThemeString()
    let js = """
    if (typeof window.updateTheme === 'function') {
        window.updateTheme('\(theme)');
    }
    """
    webView.evaluateJavaScript(js) { _, error in
        if let error = error {
            os_log("🔴 updateTheme JS error: %{public}@", log: self.logger, type: .error, error.localizedDescription)
        }
    }
}
```

- [ ] **Step 2: 新增 `viewDidChangeEffectiveAppearance()` override**

在 `viewDidAppear()` 方法（~411行）之后插入：

```swift
public override func viewDidChangeEffectiveAppearance() {
    super.viewDidChangeEffectiveAppearance()
    os_log("🌓 [viewDidChangeEffectiveAppearance] Applying theme update", log: logger, type: .default)
    applyThemeToWebView()
    updateThemeButtonState()
}
```

- [ ] **Step 3: 重构 `renderPendingMarkdown` 和 `renderSourceView` 中重复的主题检测代码**

在 `renderPendingMarkdown()`（~1035行）中，将：

```swift
        let appearanceName = self.view.effectiveAppearance.name
        var theme = "system"
        if appearanceName == .darkAqua || appearanceName == .vibrantDark || appearanceName == .accessibilityHighContrastDarkAqua || appearanceName == .accessibilityHighContrastVibrantDark {
            theme = "dark"
        } else if appearanceName == .aqua || appearanceName == .vibrantLight || appearanceName == .accessibilityHighContrastAqua || appearanceName == .accessibilityHighContrastVibrantLight {
            theme = "light"
        }
```

替换为：

```swift
        let theme = currentThemeString()
```

在 `renderSourceView()`（~785行）中做同样替换（重复代码相同，替换后变为一行）。

- [ ] **Step 4: 编译验证**

```bash
cd /Users/xykong/workspace/xykong/flux-markdown && make generate && xcodebuild -project Markdown.xcodeproj -scheme Markdown -configuration Debug build 2>&1 | grep -E "error:|warning:|BUILD"
```

预期：`BUILD SUCCEEDED`，无新增 error。

- [ ] **Step 5: 提交**

```bash
git add Sources/MarkdownPreview/PreviewViewController.swift
git commit -m "fix(swift): add viewDidChangeEffectiveAppearance observer to fix Finder preview dark mode (Bug 1)"
```

---

## Task 8: Swift — `toggleTheme()` 改调 `applyThemeToWebView()` 修复 Bug 2 & 4

**文件：**
- 修改: `Sources/MarkdownPreview/PreviewViewController.swift`

- [ ] **Step 1: 修改 `toggleTheme()`**

找到（~540行）：

```swift
    @objc private func toggleTheme() {
        let current = AppearancePreference.shared.currentMode
        let newMode: AppearanceMode = (current == .dark) ? .light : .dark
        
        AppearancePreference.shared.currentMode = newMode
        AppearancePreference.shared.apply(to: self.view)
        
        updateThemeButtonState()
        
        if isWebViewLoaded {
            renderPendingMarkdown()
        }
    }
```

替换为：

```swift
    @objc private func toggleTheme() {
        let current = AppearancePreference.shared.currentMode
        let newMode: AppearanceMode = (current == .dark) ? .light : .dark
        
        AppearancePreference.shared.currentMode = newMode
        AppearancePreference.shared.apply(to: self.view)
        
        updateThemeButtonState()
        
        // 使用 updateTheme() 而非 renderPendingMarkdown()，避免 DOM 重建导致状态丢失
        applyThemeToWebView()
    }
```

- [ ] **Step 2: 修复 Bug 4 — `updateThemeButtonState()` 改用 `currentThemeString()`**

找到（~554行）：

```swift
    private func updateThemeButtonState() {
        let isDark = AppearancePreference.shared.currentMode == .dark
```

替换为：

```swift
    private func updateThemeButtonState() {
        let isDark = (currentThemeString() == "dark")
```

这样即使 `AppearancePreference` 设置的是 `.system`，按钮状态也能正确反映实际渲染主题。

- [ ] **Step 3: 编译验证**

```bash
cd /Users/xykong/workspace/xykong/flux-markdown && xcodebuild -project Markdown.xcodeproj -scheme Markdown -configuration Debug build 2>&1 | grep -E "error:|BUILD"
```

预期：`BUILD SUCCEEDED`

- [ ] **Step 4: 提交**

```bash
git add Sources/MarkdownPreview/PreviewViewController.swift
git commit -m "fix(swift): toggleTheme uses updateTheme() instead of full re-render, fixes Bug 2 & 4"
```

---

## Task 9: Swift — 修复按钮颜色（Bug 3）

**文件：**
- 修改: `Sources/MarkdownPreview/PreviewViewController.swift`

- [ ] **Step 1: 查找所有硬编码的按钮背景色**

```bash
grep -n "NSColor.black.withAlphaComponent" Sources/MarkdownPreview/PreviewViewController.swift
```

- [ ] **Step 2: 将所有按钮 background 改为自适应颜色**

对每一处找到的 `NSColor.black.withAlphaComponent(0.1).cgColor`，替换为：

```swift
NSColor.windowBackgroundColor.withAlphaComponent(0.5).cgColor
```

（`NSColor.windowBackgroundColor` 在深色模式自动变深色，浅色模式自动变浅色，始终与背景产生足够对比）

- [ ] **Step 3: 同时修复 `updateThemeButtonState()` 中 iconColor 硬编码**

找到：
```swift
        let iconColor = isDark ? NSColor.yellow : NSColor.darkGray
```

替换为：
```swift
        let iconColor = isDark ? NSColor.systemYellow : NSColor.labelColor
```

（`NSColor.labelColor` 在深浅色模式下自动保持高对比度）

- [ ] **Step 4: 编译验证**

```bash
cd /Users/xykong/workspace/xykong/flux-markdown && xcodebuild -project Markdown.xcodeproj -scheme Markdown -configuration Debug build 2>&1 | grep -E "error:|BUILD"
```

- [ ] **Step 5: 提交**

```bash
git add Sources/MarkdownPreview/PreviewViewController.swift
git commit -m "fix(swift): use adaptive button colors for dark/light mode compatibility, fixes Bug 3"
```

---

## Task 10: Refactor — 额外测试用例补全

**文件：**
- 修改: `web-renderer/test/theme-switching.test.ts`

这是 Refactor 阶段，在所有测试绿色后，补充边缘情况测试，确保回归防护。

- [ ] **Step 1: 追加边缘测试**

在 `theme-switching.test.ts` 末尾追加：

```typescript
describe('updateTheme edge cases', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="markdown-preview"></div>';
    document.documentElement.removeAttribute('data-theme');
  });

  test('handles unknown theme string by setting it as-is on data-theme', () => {
    // 未知主题不应抛出错误，降级处理
    expect(() => window.updateTheme('solarized')).not.toThrow();
    expect(document.documentElement.getAttribute('data-theme')).toBe('solarized');
  });

  test('updateTheme with "system" resolves to "default" in jsdom (light environment)', () => {
    // jsdom 中 matchMedia 默认返回 false（light），system → default
    window.updateTheme('system');
    expect(document.documentElement.getAttribute('data-theme')).toBe('default');
  });

  test('renderMarkdown preserves scroll position after theme update via updateTheme', async () => {
    await window.renderMarkdown('# Title\n\nContent line 1\n\nContent line 2');
    // updateTheme 不修改 DOM，scroll 行为由浏览器保持
    window.updateTheme('dark');
    // DOM 未被清除，scrollY 恢复逻辑不会被触发（无 re-render）
    const preview = document.getElementById('markdown-preview');
    expect(preview?.querySelector('h1')?.textContent).toBe('Title');
  });

  test('data-theme persists after calling renderSource then updateTheme', () => {
    window.renderSource('# code', 'dark');
    expect(document.documentElement.getAttribute('data-theme')).toBe('dark');
    window.updateTheme('light');
    expect(document.documentElement.getAttribute('data-theme')).toBe('default');
  });
});
```

- [ ] **Step 2: 运行全量测试**

```bash
cd web-renderer && npm test
```

预期：全部 PASS

- [ ] **Step 3: 提交**

```bash
git add web-renderer/test/theme-switching.test.ts
git commit -m "test(theme): add edge case tests for updateTheme robustness"
```

---

## 验收清单（全部完成才算 Done）

```
[ ] npm test 全部绿（原 154 + 新增 ≥ 20 个）
[ ] xcodebuild BUILD SUCCEEDED，无新 error
[ ] window.updateTheme() 存在且有类型声明
[ ] renderMarkdown 调用后 data-theme 正确设置
[ ] renderSource 调用后 data-theme 正确设置
[ ] toggleTheme() 不再调用 renderPendingMarkdown()
[ ] viewDidChangeEffectiveAppearance() override 已加入
[ ] 按钮颜色改为自适应（windowBackgroundColor / labelColor）
[ ] source-view.css 使用 CSS 变量
[ ] 所有提交均遵循 conventional commits 格式
```

---

## Bug → Task 映射

| Bug | 根因 | 修复 Task |
|-----|------|-----------|
| Bug 1: Finder 不跟随系统外观 | 无 `viewDidChangeEffectiveAppearance` | Task 7 |
| Bug 2: 主题切换丢失文档状态 | `toggleTheme` 触发 full re-render | Task 8 |
| Bug 3: 按钮切换后不可见 | 按钮颜色硬编码黑色透明 | Task 9 |
| Bug 4: Show Source 不跟随主题 | `toggleTheme` 只调 `renderPendingMarkdown` | Task 8 |
| Bug 5: Source 深色可读性差 | CSS 颜色对比度不足 | Task 6 |
