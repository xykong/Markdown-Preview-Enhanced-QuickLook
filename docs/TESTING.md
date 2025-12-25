# Testing Guide

## Local Verification (本地验证)

### Step 1: Build the App
```bash
make app
```

### Step 2: Run the Host App
After build succeeds, run:
```bash
open ~/Library/Developer/Xcode/DerivedData/MarkdownQuickLook-*/Build/Products/Debug/MarkdownQuickLook.app
```

Or in Xcode:
1. Open `MarkdownQuickLook.xcodeproj`
2. Select **MarkdownQuickLook** scheme
3. Press `Cmd+R` to run

**Important**: Keep the app running while testing. This registers the Quick Look extension with the system.

### Step 3: Reset Quick Look Cache
```bash
qlmanage -r
qlmanage -r cache
```

### Step 4: Test with a Markdown File
1. Create or select a `.md` file in Finder
2. Press **Space** to trigger Quick Look
3. Verify the rendering

## Test Cases

### Test File: `test-sample.md`
Create this file to verify all features:

```markdown
# Markdown Quick Look Test

## Basic Markdown
**Bold**, *Italic*, ~~Strikethrough~~

## Code Block
\`\`\`javascript
const hello = () => {
  console.log("Hello, World!");
};
\`\`\`

## Math (KaTeX)
Inline: $E=mc^2$

Block:
$$
\\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}
$$

## Mermaid Diagram
\`\`\`mermaid
graph TD;
    A[Start] --> B{Is it working?};
    B -->|Yes| C[Great!];
    B -->|No| D[Debug];
\`\`\`

## Task List
- [x] Build project
- [x] Run tests
- [ ] Deploy
```

## Troubleshooting

### Extension not loading?
1. Check if the app is running
2. Run `qlmanage -m` to list registered extensions
3. Look for `MarkdownPreview.appex`

### Old version cached?
```bash
killall Finder
qlmanage -r
qlmanage -r cache
```

### View console logs
```bash
log stream --predicate 'subsystem contains "com.markdownquicklook"' --level debug
```
