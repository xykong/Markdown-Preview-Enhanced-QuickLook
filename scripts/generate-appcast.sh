#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APPCAST_FILE="$PROJECT_ROOT/appcast.xml"
DMG_FILE="$1"

# Find sign_update tool from Sparkle
SIGN_UPDATE=""
if [ -x "$PROJECT_ROOT/sign_update" ]; then
    SIGN_UPDATE="$PROJECT_ROOT/sign_update"
else
    # Search in DerivedData (Sparkle from SPM)
    SIGN_UPDATE=$(find ~/Library/Developer/Xcode/DerivedData -name "sign_update" -type f -perm +111 2>/dev/null | grep "Sparkle/bin/sign_update" | head -1)
fi

if [ -z "$SIGN_UPDATE" ] || [ ! -x "$SIGN_UPDATE" ]; then
    echo "❌ Error: sign_update tool not found"
    echo "   Expected locations:"
    echo "   - Project root: ./sign_update"
    echo "   - DerivedData: ~/Library/Developer/Xcode/DerivedData/.../Sparkle/bin/sign_update"
    echo ""
    echo "   To fix:"
    echo "   1. Build the project once to download Sparkle via SPM"
    echo "   2. Or download Sparkle manually and place sign_update in project root"
    exit 1
fi

if [ -z "$DMG_FILE" ]; then
    echo "❌ Error: DMG file not specified"
    echo "Usage: $0 <path-to-dmg>"
    exit 1
fi

if [ ! -f "$DMG_FILE" ]; then
    echo "❌ Error: DMG file not found: $DMG_FILE"
    exit 1
fi

VERSION_FILE="$PROJECT_ROOT/.version"
if [ ! -f "$VERSION_FILE" ]; then
    echo "❌ Error: Version file not found: $VERSION_FILE"
    exit 1
fi

FULL_VERSION=$(cat "$VERSION_FILE")
BUILD_NUMBER=$(echo "$FULL_VERSION" | cut -d'.' -f3)

echo "📝 Generating Sparkle signature for v$FULL_VERSION..."
echo "   Using: $SIGN_UPDATE"
echo "   DMG: $DMG_FILE"
echo ""

# Generate signature using sign_update tool
# The tool automatically finds the private key in Keychain (account: markdown-quicklook)
SIGN_OUTPUT=$("$SIGN_UPDATE" "$DMG_FILE" 2>&1)

if [ $? -ne 0 ]; then
    echo "❌ Failed to generate signature"
    echo "$SIGN_OUTPUT"
    exit 1
fi

# Parse output: sparkle:edSignature="..." length="..."
ED_SIGNATURE=$(echo "$SIGN_OUTPUT" | grep -o 'sparkle:edSignature="[^"]*"' | cut -d'"' -f2)
FILE_SIZE=$(echo "$SIGN_OUTPUT" | grep -o 'length="[^"]*"' | cut -d'"' -f2)

if [ -z "$ED_SIGNATURE" ]; then
    echo "❌ Failed to parse signature from output:"
    echo "$SIGN_OUTPUT"
    exit 1
fi

PUB_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")

echo ""
echo "📦 Release Info:"
echo "   Version: $FULL_VERSION"
echo "   Build:   $BUILD_NUMBER"
echo "   Size:    $FILE_SIZE bytes"
echo "   Date:    $PUB_DATE"
echo "   Signature: ${ED_SIGNATURE:0:50}..."
echo ""

DOWNLOAD_URL="https://github.com/xykong/markdown-quicklook/releases/download/v$FULL_VERSION/MarkdownPreviewEnhanced.dmg"
RELEASE_URL="https://github.com/xykong/markdown-quicklook/releases/tag/v$FULL_VERSION"

# Extract changelog from CHANGELOG.md for this version
CHANGELOG_FILE="$PROJECT_ROOT/CHANGELOG.md"
if [ -f "$CHANGELOG_FILE" ]; then
    # Extract content between [FULL_VERSION] and next version heading
    CHANGELOG_ENTRY=$(awk "/## \[$FULL_VERSION\]/,/## \[/" "$CHANGELOG_FILE" | grep -v "^## \[" | sed 's/^### //' | head -50)
else
    CHANGELOG_ENTRY="Update to version $FULL_VERSION"
fi

# Simple HTML conversion for changelog
CHANGELOG_HTML="<h2>更新内容</h2><pre>$CHANGELOG_ENTRY</pre><p><a href=\"$RELEASE_URL\">查看完整更新日志</a></p>"

TEMP_ITEM=$(cat <<EOF
        <item>
            <title>Version $FULL_VERSION</title>
            <link>$RELEASE_URL</link>
            <sparkle:version>$BUILD_NUMBER</sparkle:version>
            <sparkle:shortVersionString>$FULL_VERSION</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>11.0</sparkle:minimumSystemVersion>
            <pubDate>$PUB_DATE</pubDate>
            <enclosure
                url="$DOWNLOAD_URL"
                sparkle:edSignature="$ED_SIGNATURE"
                length="$FILE_SIZE"
                type="application/octet-stream" />
            <description><![CDATA[
                $CHANGELOG_HTML
            ]]></description>
        </item>
        
EOF
)

if [ ! -f "$APPCAST_FILE" ]; then
    echo "❌ Error: Appcast file not found: $APPCAST_FILE"
    exit 1
fi

# Check if this version already exists in appcast
if grep -q "<sparkle:shortVersionString>$FULL_VERSION</sparkle:shortVersionString>" "$APPCAST_FILE"; then
    echo "⚠️  Warning: Version $FULL_VERSION already exists in appcast.xml"
    read -p "   Do you want to replace it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Cancelled."
        exit 0
    fi
    
    # Remove existing entry
    perl -i -0pe "s|<item>.*?<sparkle:shortVersionString>$FULL_VERSION</sparkle:shortVersionString>.*?</item>\s*||s" "$APPCAST_FILE"
    echo "   Removed existing entry for v$FULL_VERSION"
fi

# Insert new item after <language> tag
perl -i -pe "s|(<language>.*?</language>)\s*|\\1\n\n$TEMP_ITEM|s" "$APPCAST_FILE"

echo "✅ Appcast updated successfully!"
echo ""
echo "📄 File: $APPCAST_FILE"
echo ""
echo "Next steps:"
echo "  1. Review the appcast.xml file"
echo "  2. Commit and push:"
echo "     git add appcast.xml"
echo "     git commit -m 'chore(sparkle): update appcast.xml for v$FULL_VERSION'"
echo "     git push"
echo ""
