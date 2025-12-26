#!/bin/bash
set -e

APP_NAME="Markdown Preview Enhanced"
APP_BUNDLE="${APP_NAME}.app"
BUILD_DIR="${HOME}/Library/Developer/Xcode/DerivedData/MarkdownPreviewEnhanced-*"
DMG_NAME="MarkdownPreviewEnhanced.dmg"
OUTPUT_DIR="build/artifacts"

echo "🚀 Starting DMG creation for ${APP_NAME}..."

# 1. Ensure clean build
echo "📦 Building application..."
make app

# 2. Locate the built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "${APP_BUNDLE}" -path "*/Build/Products/Release/*" | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Error: Could not find built ${APP_BUNDLE}"
    exit 1
fi

echo "✅ Found app at: $APP_PATH"

# 3. Create artifacts directory
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/$DMG_NAME"

# 4. Create temporary folder for DMG content
TMP_DIR=$(mktemp -d)
echo "📂 Preparing DMG content in $TMP_DIR..."

cp -R "$APP_PATH" "$TMP_DIR/"
ln -s /Applications "$TMP_DIR/Applications"

# 5. Create DMG using hdiutil
echo "💿 Creating DMG..."
hdiutil create -volname "${APP_NAME}" -srcfolder "$TMP_DIR" -ov -format UDZO "$OUTPUT_DIR/$DMG_NAME"

# 6. Cleanup
rm -rf "$TMP_DIR"

echo ""
echo "✅ DMG created successfully at: $OUTPUT_DIR/$DMG_NAME"
echo ""