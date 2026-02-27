#!/bin/bash
set -e

APP_NAME="FluxMarkdown"
APP_BUNDLE="${APP_NAME}.app"
BUILD_DIR="${HOME}/Library/Developer/Xcode/DerivedData/FluxMarkdown-*"
DMG_NAME="FluxMarkdown.dmg"
OUTPUT_DIR="build/artifacts"

echo "🚀 Starting DMG creation for ${APP_NAME}..."

# 1. Ensure clean build
echo "📦 Building application..."
make app

# 2. Locate the built app
EXPECTED_VERSION="$(cat .version 2>/dev/null || true)"
APP_PATH=""

if [ -n "$EXPECTED_VERSION" ]; then
    while IFS= read -r candidate; do
        info_plist="$candidate/Contents/Info.plist"
        if [ ! -f "$info_plist" ]; then
            continue
        fi

        candidate_version=$(/usr/bin/defaults read "$info_plist" CFBundleShortVersionString 2>/dev/null || true)
        candidate_build=$(/usr/bin/defaults read "$info_plist" CFBundleVersion 2>/dev/null || true)

        if [ "$candidate_version" = "$EXPECTED_VERSION" ]; then
            APP_PATH="$candidate"
            break
        fi

        expected_build="$(echo "$EXPECTED_VERSION" | awk -F. '{print $3}')"
        if [ -n "$expected_build" ] && [ "$candidate_build" = "$expected_build" ]; then
            APP_PATH="$candidate"
            break
        fi
    done < <(find "$HOME/Library/Developer/Xcode/DerivedData" -name "${APP_BUNDLE}" -path "*/Build/Products/Release/*" 2>/dev/null)
fi

if [ -z "$APP_PATH" ]; then
    APP_PATH=$(find "$HOME/Library/Developer/Xcode/DerivedData" -name "${APP_BUNDLE}" -path "*/Build/Products/Release/*" | head -n 1)
fi

if [ -z "$APP_PATH" ]; then
    echo "❌ Error: Could not find built ${APP_BUNDLE}"
    exit 1
fi

echo "✅ Found app at: $APP_PATH"

# 3. Create artifacts directory
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/$DMG_NAME"

# 4. Prepare appdmg configuration
echo "📂 Preparing appdmg configuration..."
APP_DMG_JSON="build/appdmg.json"
cat << EOF > "$APP_DMG_JSON"
{
  "title": "Install ${APP_NAME}",
  "background": "$(pwd)/assets/dmg/background.png",
  "icon-size": 100,
  "contents": [
    { "x": 150, "y": 200, "type": "file", "path": "${APP_PATH}" },
    { "x": 450, "y": 200, "type": "link", "path": "/Applications" }
  ],
  "window": {
    "size": { "width": 600, "height": 400 },
    "position": { "x": 400, "y": 400 }
  }
}
EOF

# 5. Create DMG using appdmg
echo "💿 Creating styled DMG using appdmg..."
npx appdmg "$APP_DMG_JSON" "$OUTPUT_DIR/$DMG_NAME"

# 6. Cleanup
rm -f "$APP_DMG_JSON"

echo ""
echo "✅ DMG created successfully at: $OUTPUT_DIR/$DMG_NAME"
echo ""
