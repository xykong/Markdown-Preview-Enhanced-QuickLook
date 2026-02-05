# Sparkle Appcast Update

**CRITICAL**: The `make release` script attempts to update appcast.xml but may fail if Sparkle keys are not configured properly. This manual step ensures the appcast is correctly signed and committed.

## What is Sparkle?

Sparkle is an auto-update framework for macOS apps. The `appcast.xml` file tells the app when new versions are available and where to download them.

## Step 1: Find Sparkle sign_update Tool

```bash
# Locate sign_update tool in Xcode DerivedData
SIGN_UPDATE=$(find ~/Library/Developer/Xcode/DerivedData -name "sign_update" 2>/dev/null | head -1)

if [ -z "$SIGN_UPDATE" ]; then
    echo "❌ sign_update tool not found"
    echo "   Build the project first: make app"
    exit 1
fi

echo "✅ Found: $SIGN_UPDATE"
```

**Expected Path:**
```
/Users/xykong/Library/Developer/Xcode/DerivedData/MarkdownPreviewEnhanced-*/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update
```

## Step 2: Sign the DMG

```bash
# Get DMG path
DMG_PATH="build/artifacts/MarkdownPreviewEnhanced.dmg"

# Sign the DMG (reads private key from Keychain)
SIGNATURE=$("$SIGN_UPDATE" "$DMG_PATH")

echo "Signature output:"
echo "$SIGNATURE"
```

**Expected Output:**
```
sparkle:edSignature="5VxgworFFL4pMFZN4y1WK2RAy9MOheAzf9aFYWoIQaPMvIjWaywSYfXK2EhGf7ZZnLDmqWl74WNDxU+p/FACBA==" length="7338577"
```

## Step 3: Extract Signature and Length

```bash
# Parse signature
SPARKLE_SIGNATURE=$(echo "$SIGNATURE" | grep -o 'sparkle:edSignature="[^"]*"' | cut -d '"' -f 2)
DMG_LENGTH=$(echo "$SIGNATURE" | grep -o 'length="[^"]*"' | cut -d '"' -f 2)

echo "Extracted:"
echo "  Signature: $SPARKLE_SIGNATURE"
echo "  Length: $DMG_LENGTH"
```

## Step 4: Update appcast.xml

**Manual Edit** (use your preferred editor):

```bash
vim appcast.xml
```

**Add New Entry** (at the top, after `<channel>`):

```xml
<item>
    <title>Version 1.8.114</title>
    <link>https://xykong.github.io/markdown-quicklook/appcast.xml</link>
    <sparkle:version>1.8.114</sparkle:version>
    <sparkle:shortVersionString>1.8.114</sparkle:shortVersionString>
    <description><![CDATA[
        <h2>What's New</h2>
        <ul>
            <li>Feature A: Description</li>
            <li>Fix B: Description</li>
        </ul>
    ]]></description>
    <pubDate>Thu, 05 Feb 2026 11:00:00 +0800</pubDate>
    <enclosure
        url="https://github.com/xykong/markdown-quicklook/releases/download/v1.8.114/MarkdownPreviewEnhanced.dmg"
        sparkle:edSignature="5VxgworFFL4pMFZN4y1WK2RAy9MOheAzf9aFYWoIQaPMvIjWaywSYfXK2EhGf7ZZnLDmqWl74WNDxU+p/FACBA=="
        length="7338577"
        type="application/octet-stream" />
</item>
```

**Key Fields:**
- `<title>`: "Version X.X.X"
- `<sparkle:version>`: Full version (e.g., "1.8.114")
- `<sparkle:shortVersionString>`: Same as version
- `<description>`: HTML summary of changes (copy from CHANGELOG or GitHub Release)
- `<pubDate>`: Current date in RFC 2822 format
- `<enclosure url>`: GitHub release DMG download URL
- `<enclosure sparkle:edSignature>`: Signature from Step 2
- `<enclosure length>`: DMG file size in bytes

**Get Current Date** (RFC 2822 format):
```bash
date "+%a, %d %b %Y %H:%M:%S %z"
# Example: Thu, 05 Feb 2026 11:00:00 +0800
```

## Step 5: Commit and Push

```bash
git add appcast.xml
git commit -m "chore(sparkle): update appcast.xml for v1.8.114"
git push origin master
```

## Step 6: Verify Accessibility

```bash
# Check file committed
git log -1 --oneline appcast.xml
# Expected: chore(sparkle): update appcast.xml for v1.8.114

# Verify appcast URL is accessible (may take a few minutes for GitHub Pages to update)
curl -I https://xykong.github.io/markdown-quicklook/appcast.xml
# Expected: HTTP/2 200
```

## Troubleshooting

### Error: "Sparkle EdDSA Private Key not found in Keychain"

```bash
# Check if key exists
security find-generic-password -l "Sparkle EdDSA Private Key"

# If not found, generate keys
./scripts/generate-sparkle-keys.sh

# Or import from backup
# (Requires manual Keychain import via Keychain Access.app)
```

### Error: sign_update produces invalid signature

This usually means the private key in Keychain doesn't match the public key in `Info.plist`.

**Option A: Use existing backup** (if available)
```bash
# Import backup key to Keychain
# Then retry signing
```

**Option B: Generate new keys** (WARNING: breaks existing installations)
```bash
# WARNING: This invalidates all previous releases
./scripts/generate-sparkle-keys.sh

# Update Info.plist with new public key
# Rebuild and re-release
```

**Option C: Skip appcast update** (temporary workaround)
```bash
# Release is still valid, but Sparkle auto-update won't work
# Users can still download manually or via Homebrew
# Update appcast.xml later when key issue is resolved
```
