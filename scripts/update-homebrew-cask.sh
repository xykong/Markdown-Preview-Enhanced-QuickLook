#!/bin/bash
set -e

VERSION_FILE=".version"
DMG_PATH="build/artifacts/MarkdownPreviewEnhanced.dmg"
CASK_FILE="../homebrew-tap/Casks/markdown-preview-enhanced.rb"

if [ ! -f "$VERSION_FILE" ]; then
    echo "❌ Error: Version file not found: $VERSION_FILE"
    exit 1
fi

VERSION=$(cat "$VERSION_FILE")

if [ ! -f "$DMG_PATH" ]; then
    echo "❌ Error: DMG not found at $DMG_PATH"
    echo "Please build the DMG first with: make dmg"
    exit 1
fi

if [ ! -f "$CASK_FILE" ]; then
    echo "❌ Error: Homebrew Cask file not found at $CASK_FILE"
    echo "Please ensure homebrew-tap repository is cloned at ../homebrew-tap"
    exit 1

echo "🍺 Updating Homebrew Cask for v$VERSION..."
echo ""

SHA256=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')
echo "✅ Calculated SHA256: $SHA256"
echo ""

CURRENT_VERSION=$(grep "version '" "$CASK_FILE" | head -1 | sed "s/.*version '\(.*\)'/\1/")
CURRENT_SHA256=$(grep "sha256 '" "$CASK_FILE" | head -1 | sed "s/.*sha256 '\(.*\)'/\1/")

echo "📊 Current Cask Info:"
echo "   Version: $CURRENT_VERSION"
echo "   SHA256:  $CURRENT_SHA256"
echo ""
echo "📊 New Cask Info:"
echo "   Version: $VERSION"
echo "   SHA256:  $SHA256"
echo ""

if [ "$CURRENT_VERSION" = "$VERSION" ] && [ "$CURRENT_SHA256" = "$SHA256" ]; then
    echo "✅ Homebrew Cask is already up to date!"
    exit 0
fi

echo "🔧 Updating Cask file..."

sed -i '' "s/version '.*'/version '$VERSION'/" "$CASK_FILE"
sed -i '' "s/sha256 '.*'/sha256 '$SHA256'/" "$CASK_FILE"

if ! grep -q "auto_updates true" "$CASK_FILE"; then
    echo "🔧 Adding auto_updates configuration..."
    sed -i '' "/homepage /a\\
\\
  auto_updates true\\
\\
  livecheck do\\
    url \"https://xykong.github.io/markdown-quicklook/appcast.xml\"\\
    strategy :sparkle, \&:short_version\\
  end
" "$CASK_FILE"
fi

echo "✅ Cask file updated successfully"
echo ""

cd "$(dirname "$CASK_FILE")/.."

if ! git diff --quiet Casks/markdown-preview-enhanced.rb; then
    echo "📝 Changes detected:"
    git diff Casks/markdown-preview-enhanced.rb
    echo ""
    
    read -p "👉 Commit and push changes? (y/n) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add Casks/markdown-preview-enhanced.rb
        git commit -m "chore(cask): update markdown-preview-enhanced to v$VERSION"
        git push origin master
        echo "✅ Changes committed and pushed to homebrew-tap"
    else
        echo "⚠️  Changes not committed. Please commit manually:"
        echo "   cd $(pwd)"
        echo "   git add Casks/markdown-preview-enhanced.rb"
        echo "   git commit -m 'chore(cask): update markdown-preview-enhanced to v$VERSION'"
        echo "   git push origin master"
    fi
else
    echo "ℹ️  No changes detected in Cask file"
fi

echo ""
echo "🎉 Done! Users can now install v$VERSION with:"
echo "   brew update"
echo "   brew upgrade markdown-preview-enhanced"
