#!/bin/bash

set -e

echo "🔍 Verifying Markdown QuickLook Extension..."
echo ""

# Find the app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/MarkdownQuickLook-*/Build/Products/Debug -name "MarkdownQuickLook.app" 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ App not found. Please run 'make app' first."
    exit 1
fi

echo "✅ Found app at: $APP_PATH"
echo ""

# Check if extension exists
EXT_PATH="$APP_PATH/Contents/PlugIns/MarkdownPreview.appex"
if [ ! -d "$EXT_PATH" ]; then
    echo "❌ Extension not found inside app bundle!"
    exit 1
fi

echo "✅ Extension exists: $EXT_PATH"
echo ""

# Open the app to register the extension
echo "📱 Opening app to register extension..."
open "$APP_PATH"
sleep 2

# Reset Quick Look
echo "🔄 Resetting Quick Look cache..."
qlmanage -r
qlmanage -r cache

echo ""
echo "🔍 Checking registered extensions..."
qlmanage -m | grep -i markdown || echo "⚠️  No markdown extension found"

echo ""
echo "📋 Extension Info.plist content:"
plutil -p "$EXT_PATH/Contents/Info.plist" | grep -A 10 "QLSupportedContentTypes"

echo ""
echo "✅ Verification complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Keep the app running"
echo "  2. Open test-sample.md in Finder"
echo "  3. Press Space to test Quick Look"
echo ""
echo "🐛 If it doesn't work, check logs with:"
echo "  log stream --predicate 'subsystem contains \"com.markdownquicklook\"' --level debug"
