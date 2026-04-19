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

## 工具选型结论（实测验证）

### 推荐优先级

| 优先级 | 工具 | 适用场景 | 可靠性 |
|--------|------|---------|--------|
| ✅ **首选** | Swift AX API (`ax_click`) | 有 label/desc 的 AXButton | 最高，不依赖坐标 |
| ✅ **次选** | `osascript click at {x,y}` | 有 AX action 但无名称的控件（checkbox、slider） | 高，在 AX 层执行 |
| ✅ **三选** | `cgclick`（CGEvent 低级点击） | SwiftUI AXGroup（无任何 AX action，如 Theme 选择按钮） | 高，绕过 AX 层直接发硬件事件 |
| ❌ **禁用** | `cliclick c:x,y` | — | 全部失败（第一次点击只激活窗口） |
| ❌ **不引入** | Appium mac2 | — | SwiftUI Settings 窗口坐标全零，实际失效 |
| ❌ **不引入** | Macaca macOS | — | 本质是 osascript 封装，2023 停维 |

### 为什么 cliclick 失败？

cliclick 发送硬件级鼠标事件（CGEvent）。macOS 规定：点击 inactive 窗口的**第一次点击只激活窗口**，不传递到控件。
`osascript click at` 在 System Events 进程内直接触发 AX Press action，完全绕过窗口激活流程。

### 为什么需要 cgclick（第三选）？

某些 SwiftUI 控件（如 Settings 里的 Theme 选择按钮）在 AX 树中被标记为 `AXGroup` 而非 `AXButton`，**没有任何 AX action**。
- `ax_click` 无效（只搜索 AXButton）
- `osascript click at` 无效（AXGroup 上没有 Press action 可调用）
- 必须绕过 AX 层，使用 `CGEvent` 直接向 HID 层发送鼠标按下/抬起事件
- **前提**：应用必须已在前台（先 `tell application "FluxMarkdown" to activate`）

### 为什么 Appium mac2 对 Settings 失效？

SwiftUI `Settings` scene 是辅助窗口（secondary window），WDA 只扫 active 主窗口，Settings 窗口的所有控件坐标返回 `{y:982, x:0, w:0, h:0}`。

## 核心工具链

| 工具 | 作用 |
|------|------|
| `screencapture -l <windowID>` | 精确截取指定窗口（不受其他窗口遮挡影响） |
| Swift + CGWindowList | 获取窗口 ID |
| Swift AX API (`ax_click`) | 按名称点击控件（最可靠，首选） |
| `osascript click at {x,y}` | 按坐标点击有 AX action 的控件（次选） |
| `cgclick`（CGEvent 低级点击） | 点击 SwiftUI AXGroup（无 AX action 的控件，第三选） |
| `osascript` | 键盘操作、打开窗口 |
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

### CGEvent 低级点击（第三选：SwiftUI AXGroup 无 AX action 的控件）

适用场景：控件在 AX 树中为 `AXGroup`，没有任何 AX action，`ax_click` 和 `osascript click at` 都无效时。
典型案例：FluxMarkdown Settings 中的 Light/Dark/System Theme 选择按钮。

**前提**：应用必须已在前台（先 activate）。

```bash
cat > /tmp/cgclick.swift << 'EOF'
import Cocoa
guard CommandLine.arguments.count == 3,
      let x = Double(CommandLine.arguments[1]),
      let y = Double(CommandLine.arguments[2]) else {
    print("Usage: cgclick <x> <y>")
    exit(1)
}
let pt  = CGPoint(x: x, y: y)
let src = CGEventSource(stateID: .combinedSessionState)
let dn  = CGEvent(mouseEventSource: src, mouseType: .leftMouseDown,
                  mouseCursorPosition: pt, mouseButton: .left)!
dn.post(tap: .cghidEventTap)
Thread.sleep(forTimeInterval: 0.05)
let up  = CGEvent(mouseEventSource: src, mouseType: .leftMouseUp,
                  mouseCursorPosition: pt, mouseButton: .left)!
up.post(tap: .cghidEventTap)
print("CGEvent click at \(Int(x)),\(Int(y))")
EOF
swiftc /tmp/cgclick.swift -o /tmp/cgclick 2>/dev/null

# 使用（先确保应用在前台）：
osascript -e 'tell application "FluxMarkdown" to activate'
sleep 0.3
/tmp/cgclick 710 529   # Light 按钮中心
/tmp/cgclick 831 530   # Dark 按钮中心
/tmp/cgclick 953 530   # System 按钮中心
sleep 0.5
```

**坐标来源**：先用 `ax_full`（见下方）枚举指定 Y 范围内的所有元素，取中心点坐标。

#### 枚举指定 Y 范围内所有元素（含 AXGroup）

```bash
cat > /tmp/ax_full.swift << 'EOF'
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
func pos(_ e: AXUIElement) -> CGPoint? {
    var v: CFTypeRef?
    guard AXUIElementCopyAttributeValue(e, kAXPositionAttribute as CFString, &v) == .success,
          let av = v, CFGetTypeID(av) == AXValueGetTypeID() else { return nil }
    var pt = CGPoint.zero; AXValueGetValue(av as! AXValue, .cgPoint, &pt); return pt
}
func sz(_ e: AXUIElement) -> CGSize? {
    var v: CFTypeRef?
    guard AXUIElementCopyAttributeValue(e, kAXSizeAttribute as CFString, &v) == .success,
          let av = v, CFGetTypeID(av) == AXValueGetTypeID() else { return nil }
    var s = CGSize.zero; AXValueGetValue(av as! AXValue, .cgSize, &s); return s
}
// 枚举 Y 范围内所有元素（不限制 role）
let yMin = CommandLine.arguments.count > 1 ? (Double(CommandLine.arguments[1]) ?? 0) : 0
let yMax = CommandLine.arguments.count > 2 ? (Double(CommandLine.arguments[2]) ?? 9999) : 9999
func walk(_ e: AXUIElement, _ d: Int = 0) {
    guard d < 14 else { return }
    if let p = pos(e), let z = sz(e) {
        let cy = p.y + z.height/2
        if cy >= yMin && cy <= yMax && z.width > 10 && z.height > 10 {
            let role  = s(e, kAXRoleAttribute  as String) ?? ""
            let title = s(e, kAXTitleAttribute as String) ?? ""
            let desc  = s(e, kAXDescriptionAttribute as String) ?? ""
            let cx = Int(p.x + z.width/2); let cy2 = Int(p.y + z.height/2)
            print("\(String(repeating:"  ",count:d))\(role) title='\(title)' desc='\(desc)' center=\(cx),\(cy2) size=\(Int(z.width))x\(Int(z.height))")
        }
    }
    arr(e, kAXChildrenAttribute as String)?.forEach { walk($0, d+1) }
}
if let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName?.contains("FluxMarkdown") == true }) {
    walk(AXUIElementCreateApplication(app.processIdentifier))
}
EOF
swiftc /tmp/ax_full.swift -o /tmp/ax_full 2>/dev/null

# 枚举 Y=500~560 范围内的元素（找 Theme 按钮）
/tmp/ax_full 500 560
```

### 键盘操作

```bash
osascript -e 'tell application "System Events" to keystroke "," using {command down}'
```

### 坐标点击（次选：有 AX action 但无名称的控件，如 checkbox/slider）

```bash
# ⚠️ 不要用 cliclick！它只激活窗口，不触发按钮。
# 必须用 osascript click at（在 AX 层执行，绕过窗口激活流程）
osascript -e 'tell application "System Events" to tell process "FluxMarkdown" to click at {975, 519}'
sleep 0.5
```

坐标来源：先用 `ax_tree` 获取控件坐标，中心点 = `pos_x + width/2, pos_y + height/2`。
对于 AXGroup 控件，改用 `ax_full <yMin> <yMax>` 枚举该 Y 范围内所有元素。

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
# 解析坐标并点击中心（用 osascript，不用 cliclick）
read -r x y w h <<< "$ROW1_POS"
cx=$((x + w/2)); cy=$((y + h/2))
osascript -e "tell application \"System Events\" to tell process \"FluxMarkdown\" to click at {$cx, $cy}"
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
| `cliclick` 无效 | 第一次点击只激活窗口，不触发控件 | **改用 `osascript click at {x,y}`**，永远不用 cliclick |
| `osascript click at` 也无效 | 控件是 AXGroup，没有 AX action | **改用 `cgclick`（CGEvent）**，先 activate 应用再点击 |
| 截到错误窗口 | 未用 `-l` 指定窗口 ID | 必须用 `screencapture -l <ID>` |
| `look_at` 分析错标签 | 截图时标签未切换完成 | `sleep 0.5` 后再截图 |
| 窗口 ID 变了 | 窗口重新打开后 ID 会变 | 每次操作前重新运行 `findwin` |
| ax_click 找不到控件 | 控件没有 desc/label（是 AXGroup）| 用 `ax_full` 枚举坐标 + `cgclick` 点击 |
| Appium/WDA 坐标全零 | SwiftUI Settings 是辅助窗口，WDA 不可见 | 不要用 Appium 操作 Settings；用 AX API |

## FluxMarkdown 专用：Theme 按钮坐标参考

Theme 选择按钮（AXGroup，无 AX action，必须用 `cgclick`）：

| 按钮 | 中心坐标（Settings 窗口位于 X=438,Y=390 时） |
|------|----------------------------------------------|
| Light | `710, 529` |
| Dark | `831, 530` |
| System | `953, 530` |

Toolbar 主题切换按钮 desc 随状态变化（可用 `ax_click` 按 desc 点击）：

| 当前模式 | desc 字段 |
|---------|----------|
| System | `circle.lefthalf.filled` |
| Light | `调高亮度` |
| Dark | `勿扰模式` |

> ⚠️ 坐标与窗口位置相关。若窗口移动，需重新用 `ax_full` 枚举。

## 验证结论撰写规范

`look_at` 结果回来后，用以下格式记录：

```
✅ PASS: [具体观察] — [按钮X选中，无 focus ring，底部线干净]
❌ FAIL: [具体问题] — [按钮X 仍有蓝色发光边框（focus ring 未消除）]
→ 需要修复: [下一步行动]
```

只有 **所有检查项都 ✅** 才能标记 UI 修复完成。
