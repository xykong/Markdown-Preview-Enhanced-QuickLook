#!/bin/bash

# Markdown QuickLook Installation Script
set -e

echo "🚀 Installing Markdown QuickLook..."
echo ""

# 1. Build the app
echo "📦 Building application..."
make app

# 2. Copy to Applications
echo "📋 Installing to /Applications..."
rm -rf /Applications/MarkdownQuickLook.app
cp -R ~/Library/Developer/Xcode/DerivedData/MarkdownQuickLook-*/Build/Products/Debug/MarkdownQuickLook.app /Applications/

# 3. Register with LaunchServices
echo "🔧 Registering with system..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/MarkdownQuickLook.app

# 4. Reset QuickLook
echo "🔄 Resetting QuickLook cache..."
qlmanage -r
qlmanage -r cache

echo ""
echo "✅ Installation complete!"
echo ""
echo "⚠️  IMPORTANT: To activate the QuickLook preview, you need to:"
echo "   1. Right-click任意 .md 文件"
echo "   2. 选择 '显示简介' (Get Info) 或按 ⌘+I"
echo "   3. 在 '打开方式' (Open with:) 部分，选择 'MarkdownQuickLook.app'"
echo "   4. 点击 '全部更改...' (Change All...) 按钮"
echo "   5. 点击 '继续' 确认"
echo ""
echo "💡 This sets MarkdownQuickLook as the default app for all .md files,"
echo "   which is required for the QuickLook extension to work."
echo ""
echo "🧪 After setting the default app, test with: qlmanage -p test-sample.md"
