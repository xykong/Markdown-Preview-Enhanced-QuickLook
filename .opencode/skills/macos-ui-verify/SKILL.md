---
name: macos-ui-verify
description: |
  Use when you need to visually verify macOS native app UI after fixing bugs,
  without asking the user to manually test. Triggers when: a UI fix is implemented
  and needs screenshot-based self-validation; verifying that a visual bug is
  actually gone (e.g. focus ring, wrong color, missing indicator); closing a
  feedback loop on Settings/window UI changes in FluxMarkdown or similar macOS apps.
  Use proactively after ANY SwiftUI or AppKit UI change.
---

# macOS UI 截图自验证

通过截图 + AI 分析实现 macOS 原生 App 的 UI 自我验证，无需用户手动测试。

## 核心工具链

| 工具 | 作用 |
|------|------|
| `screencapture -l <windowID>` | 精确截取指定窗口（不受其他窗口遮挡影响） |
| Swift + CGWindowList | 获取窗口 ID |
| `osascript` | 键盘操作、打开窗口、Accessibility API |
| `cliclick c:x,y` | 鼠标点击（需 Accessibility 权限） |
| `look_at` | AI 分析截图内容 |

## 标准验证循环

```
1. 确保窗口打开并置前
2. 获取窗口 ID
3. 截图 → look_at 分析
4. 操作 UI（点击/键盘）
5. 再截图 → look_at 验证状态变化
6. 重复直到确认修复
```

## Step 1：获取窗口 ID

```bash
cat > /tmp/findwin.swift << 'EOF'
import Cocoa
let wins = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as! [[String: Any]]
for w in wins {
    let owner = w["kCGWindowOwnerName"] as? String ?? ""
    let name  = w["kCGWindowName"]      as? String ?? ""
    let wid   = w["kCGWindowNumber"]    as? Int    ?? 0
    if owner.contains("FluxMarkdown") || name.contains("设置") {
        print("ID=\(wid) Owner=\(owner) Name=\(name)")
    }
}
EOF
swiftc /tmp/findwin.swift -o /tmp/findwin && /tmp/findwin
```

输出示例：`ID=1067 Owner=FluxMarkdown Name=FluxMarkdown设置`

## Step 2：打开目标窗口

```bash
# 打开 Settings（Cmd+,）
osascript << 'EOF'
tell application "FluxMarkdown" to activate
delay 0.3
tell application "System Events"
    keystroke "," using {command down}
end tell
delay 1.2
EOF
```

## Step 3：精确截图

```bash
# 用窗口 ID 截图（不受遮挡影响）
screencapture -l <WINDOW_ID> /tmp/verify_before.png
```

然后用 `look_at` 分析：

```
look_at(
  file_path="/tmp/verify_before.png",
  goal="描述 Theme 区域三个按钮状态：哪个选中？有无 focus ring 蓝色发光边框？"
)
```

**提问技巧**：`goal` 要具体，指名要检查的元素和症状词（如 "focus ring"、"蓝色发光"、"底部线条"）。

## Step 4：操作 UI 触发状态变化

### 推荐方案：Swift AX API（按名称点击，不依赖坐标）

```bash
cat > /tmp/ax_click.swift << 'EOF'
import Cocoa
import ApplicationServices

func getAttrStr(_ elem: AXUIElement, _ attr: String) -> String? {
    var val: CFTypeRef?
    guard AXUIElementCopyAttributeValue(elem, attr as CFString, &val) == .success else { return nil }
    return val as? String
}
func getAttrArr(_ elem: AXUIElement, _ attr: String) -> [AXUIElement]? {
    var val: CFTypeRef?
    guard AXUIElementCopyAttributeValue(elem, attr as CFString, &val) == .success else { return nil }
    return val as? [AXUIElement]
}
func findByDesc(_ elem: AXUIElement, _ target: String, depth: Int = 0) -> AXUIElement? {
    guard depth < 12 else { return nil }
    let desc = getAttrStr(elem, kAXDescriptionAttribute as String) ?? ""
    let role = getAttrStr(elem, kAXRoleAttribute as String) ?? ""
    if role == "AXButton" && desc == target { return elem }
    if let children = getAttrArr(elem, kAXChildrenAttribute as String) {
        for child in children {
            if let found = findByDesc(child, target, depth: depth + 1) { return found }
        }
    }
    return nil
}
let apps = NSWorkspace.shared.runningApplications
guard let app = apps.first(where: { $0.localizedName?.contains("FluxMarkdown") == true }) else {
    print("not found"); exit(1)
}
let target = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ""
let root = AXUIElementCreateApplication(app.processIdentifier)
if let btn = findByDesc(root, target) {
    let ok = AXUIElementPerformAction(btn, kAXPressAction as CFString)
    print("Click '\(target)': \(ok == .success ? "OK" : "FAIL")")
} else { print("Not found: '\(target)'") }
EOF
swiftc /tmp/ax_click.swift -o /tmp/ax_click 2>/dev/null

# 按名称点击（desc 字段）
/tmp/ax_click "Rendering"   # 点侧边栏 Rendering 标签
/tmp/ax_click "Dark"        # 点 Theme 区域 Dark 按钮
/tmp/ax_click "System"      # 点 System 按钮
sleep 0.5
```

### 枚举当前页面所有可交互控件（含坐标）

```bash
cat > /tmp/ax_tree.swift << 'EOF'
import Cocoa
import ApplicationServices

func s(_ e: AXUIElement, _ a: String) -> String? {
    var v: CFTypeRef?
    return AXUIElementCopyAttributeValue(e, a as CFString, &v) == .success ? v as? String : nil
}
func arr(_ e: AXUIElement, _ a: String) -> [AXUIElement]? {
    var v: CFTypeRef?
    return AXUIElementCopyAttributeValue(e, a as CFString, &v) == .success ? v as? [AXUIElement] : nil
}
func pos(_ e: AXUIElement) -> String {
    var v: CFTypeRef?
    guard AXUIElementCopyAttributeValue(e, kAXPositionAttribute as CFString, &v) == .success,
          let av = v, CFGetTypeID(av) == AXValueGetTypeID() else { return "?" }
    var pt = CGPoint.zero; AXValueGetValue(av as! AXValue, .cgPoint, &pt)
    return "\(Int(pt.x)),\(Int(pt.y))"
}
func sz(_ e: AXUIElement) -> String {
    var v: CFTypeRef?
    guard AXUIElementCopyAttributeValue(e, kAXSizeAttribute as CFString, &v) == .success,
          let av = v, CFGetTypeID(av) == AXValueGetTypeID() else { return "?" }
    var sz = CGSize.zero; AXValueGetValue(av as! AXValue, .cgSize, &sz)
    return "\(Int(sz.width))x\(Int(sz.height))"
}
let interactive: Set<String> = ["AXButton","AXCheckBox","AXSlider","AXRadioButton","AXPopUpButton","AXTextField"]
func walk(_ e: AXUIElement, _ d: Int = 0) {
    guard d < 12 else { return }
    let role = s(e, kAXRoleAttribute as String) ?? ""
    if interactive.contains(role) {
        let title = s(e, kAXTitleAttribute as String) ?? ""
        let desc  = s(e, kAXDescriptionAttribute as String) ?? ""
        print("\(String(repeating:"  ",count:d))\(role) desc='\(desc)' title='\(title)' pos=\(pos(e)) size=\(sz(e))")
    }
    arr(e, kAXChildrenAttribute as String)?.forEach { walk($0, d+1) }
}
let apps = NSWorkspace.shared.runningApplications
if let app = apps.first(where: { $0.localizedName?.contains("FluxMarkdown") == true }) {
    walk(AXUIElementCreateApplication(app.processIdentifier))
}
EOF
swiftc /tmp/ax_tree.swift -o /tmp/ax_tree 2>/dev/null
/tmp/ax_tree
```

### 键盘操作

```bash
osascript -e 'tell application "System Events" to keystroke "," using {command down}'
```

### 坐标点击（备选，AX 找不到时用）

```bash
cliclick c:<x>,<y>   # 需要终端有辅助功能权限
sleep 0.5
```

### 鼠标点击

```bash
cliclick c:<x>,<y>
sleep 0.5
```

> ⚠️ `cliclick` 需要在「系统偏好设置 → 隐私 → 辅助功能」中授权终端。
> 若无效，改用 `osascript` 的 `click at {x, y}`。

### 键盘操作（更可靠）

```bash
osascript -e 'tell application "System Events" to keystroke "," using {command down}'
```

## Step 5：截图对比验证

```bash
screencapture -l <WINDOW_ID> /tmp/verify_after.png
```

```
look_at(
  file_path="/tmp/verify_after.png",
  goal="点击 Dark 按钮后：Dark 是否选中（蓝色背景+底部线）？
        有无 focus ring？Light/System 是否取消选中？"
)
```

## FluxMarkdown 专用：Settings 窗口完整验证

```bash
# 1. 确保 FluxMarkdown 运行并打开 Settings
osascript << 'EOF'
tell application "System Events"
    tell process "FluxMarkdown"
        repeat with w in every window
            try
                if title of w contains "设置" then click button 1 of w
            end try
        end repeat
    end tell
end tell
delay 0.5
tell application "FluxMarkdown" to activate
delay 0.3
tell application "System Events"
    keystroke "," using {command down}
end tell
delay 1.2
EOF

# 2. 获取窗口 ID
swiftc /tmp/findwin.swift -o /tmp/findwin 2>/dev/null && WIN_ID=$(/tmp/findwin | grep "设置" | grep -o 'ID=[0-9]*' | cut -d= -f2)
echo "Window ID: $WIN_ID"

# 3. 切换到 Appearance 标签（点击侧边栏第一行）
ROW1_POS=$(osascript << 'EOF'
tell application "System Events"
    tell process "FluxMarkdown"
        set w  to window "FluxMarkdown设置"
        set sg to splitter group 1 of group 1 of w
        set ol to outline 1 of scroll area 1 of group 1 of sg
        set r  to row 1 of ol
        set p  to position of r
        return (item 1 of p) & " " & (item 2 of p) & " " & (item 1 of size of r) & " " & (item 2 of size of r)
    end tell
end tell
EOF
)
# 解析坐标并点击中心
read -r x y w h <<< "$ROW1_POS"
cx=$((x + w/2)); cy=$((y + h/2))
cliclick c:$cx,$cy
sleep 0.5

# 4. 截图并分析
screencapture -l $WIN_ID /tmp/flux_settings_verify.png
```

## look_at 提问模板

| 场景 | goal 字段 |
|------|-----------|
| 检查 focus ring | "Theme 三个按钮有无 focus ring 蓝色发光边框？" |
| 检查选中状态 | "哪个按钮被选中？选中态视觉特征（背景色/底部线/边框）？" |
| 检查主题外观 | "页面整体是深色还是浅色主题？代码块背景色是什么？" |
| 检查 UI 元素存在 | "页面是否有重置缩放按钮？在哪里？" |

## 常见问题

| 问题 | 原因 | 解决 |
|------|------|------|
| `cliclick` 无效 | 无辅助功能权限 | 系统设置授权，或改用 `osascript click at` |
| 截到错误窗口 | 未用 `-l` 指定窗口 ID | 必须用 `screencapture -l <ID>` |
| `look_at` 分析错标签 | 截图时标签未切换完成 | `delay` 延长到 1.5s，或先确认标签再截图 |
| 窗口 ID 变了 | 窗口重新打开 | 每次操作前重新运行 `findwin` |
| 侧边栏点击不到 | 坐标偏移 | 用 Accessibility API 获取实时坐标 |

## 验证结论撰写规范

`look_at` 结果回来后，用以下格式记录：

```
✅ PASS: [具体观察] — [按钮X选中，无 focus ring，底部线干净]
❌ FAIL: [具体问题] — [按钮X 仍有蓝色发光边框（focus ring 未消除）]
→ 需要修复: [下一步行动]
```

只有 **所有检查项都 ✅** 才能标记 UI 修复完成。
