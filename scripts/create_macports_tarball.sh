#!/bin/bash
# Creates a MacPorts-compatible source tarball for flux-markdown.
#
# What's included vs. the default GitHub source tarball:
#   - web-renderer/dist    (pre-built; MacPorts sandbox has no npm)
#   - FluxMarkdown.xcodeproj (pre-generated; MacPorts has no xcodegen)
#   - Sparkle is REMOVED from project.yml + Swift sources (MacPorts manages updates)
#
# Usage: ./scripts/create_macports_tarball.sh [VERSION]
#   VERSION defaults to the content of .version

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."
cd "$PROJECT_ROOT"

VERSION="${1:-$(cat .version)}"
TARBALL_NAME="FluxMarkdown-${VERSION}-macports-source.tar.gz"
OUTPUT_DIR="build/artifacts"
STAGING_DIR="build/macports-staging/FluxMarkdown-${VERSION}"

echo "📦 Creating MacPorts source tarball for v${VERSION}..."

# ── 0. Prerequisites ──────────────────────────────────────────────────────────
if ! command -v xcodegen >/dev/null 2>&1; then
    echo "❌ xcodegen is required. Install with: brew install xcodegen"
    exit 1
fi
if ! command -v npm >/dev/null 2>&1; then
    echo "❌ npm is required."
    exit 1
fi

# ── 1. Build web-renderer ─────────────────────────────────────────────────────
echo "🔨 Building web-renderer..."
(cd web-renderer && npm install --no-audit --no-fund --loglevel=warn && npm run build)

# ── 2. Prepare staging directory ─────────────────────────────────────────────
echo "📂 Preparing staging directory..."
rm -rf "build/macports-staging"
mkdir -p "$STAGING_DIR"

# Copy entire project (respecting .gitignore is fine; we'll add what's needed)
git archive HEAD | tar -x -C "$STAGING_DIR"

# Overlay pre-built web-renderer/dist (not in git)
cp -R web-renderer/dist "$STAGING_DIR/web-renderer/dist"

# ── 3. Strip Sparkle from project.yml ────────────────────────────────────────
echo "🔧 Removing Sparkle from project.yml..."
python3 - "$STAGING_DIR/project.yml" <<'PYEOF'
import sys
import re

path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

# Remove the Sparkle package declaration block
content = re.sub(
    r'packages:\s*\n(\s+Sparkle:\s*\n(?:\s+.*\n)*)',
    '',
    content
)

# Remove Sparkle product dependency lines under targets
content = re.sub(
    r'[ \t]*- package: Sparkle\s*\n[ \t]*product: Sparkle\s*\n',
    '',
    content
)

with open(path, 'w') as f:
    f.write(content)

print("  ✅ Sparkle removed from project.yml")
PYEOF

# ── 4. Generate .xcodeproj (without Sparkle) ─────────────────────────────────
echo "🗂  Generating FluxMarkdown.xcodeproj..."
FULL_V="$VERSION"
MAJOR=$(echo "$FULL_V" | cut -d'.' -f1)
MINOR=$(echo "$FULL_V" | cut -d'.' -f2)
BUILD=$(echo "$FULL_V" | cut -d'.' -f3)

(
    cd "$STAGING_DIR"
    MARKETING_VERSION="$FULL_V" CURRENT_PROJECT_VERSION="$BUILD" \
        xcodegen generate --quiet
)
echo "  ✅ .xcodeproj generated"

# ── 5. Strip Sparkle from Swift sources ──────────────────────────────────────
echo "🩹 Removing Sparkle from Swift sources..."
python3 - "$STAGING_DIR" <<'PYEOF'
import sys, re
from pathlib import Path

staging = Path(sys.argv[1])

# --- UpdateDelegate.swift: replace entire file with a stub ---
ud = staging / "Sources/Markdown/UpdateDelegate.swift"
ud.write_text("import Cocoa\n\n// Sparkle auto-updater disabled for MacPorts builds.\n")
print("  ✅ UpdateDelegate.swift stubbed")

# --- MarkdownApp.swift: remove Sparkle import + updaterController + CheckForUpdatesView ---
ma = staging / "Sources/Markdown/MarkdownApp.swift"
content = ma.read_text()

# Remove `import Sparkle`
content = content.replace("import Sparkle\n", "")

# Remove updaterController property (multi-line)
content = re.sub(
    r'[ \t]*let updaterController = SPUStandardUpdaterController\([^)]+\)\s*\n',
    '',
    content,
    flags=re.DOTALL
)

# Remove the "Check for Updates" CommandGroup block
content = re.sub(
    r'[ \t]*CommandGroup\(after: \.appInfo\) \{\s*\n[ \t]*CheckForUpdatesView\(updaterController: appDelegate\.updaterController\)\s*\n[ \t]*\}\s*\n',
    '',
    content
)

# Remove CheckForUpdatesView struct definition at bottom of file
content = re.sub(
    r'\nstruct CheckForUpdatesView: View \{.*',
    '\n',
    content,
    flags=re.DOTALL
)

ma.write_text(content)
print("  ✅ MarkdownApp.swift cleaned")
PYEOF

# ── 7. Create tarball ─────────────────────────────────────────────────────────
echo "🗜  Creating tarball..."
mkdir -p "$OUTPUT_DIR"
tar -czf "$OUTPUT_DIR/$TARBALL_NAME" \
    -C "build/macports-staging" \
    "FluxMarkdown-${VERSION}"

TARBALL_PATH="$OUTPUT_DIR/$TARBALL_NAME"
SHA256=$(shasum -a 256 "$TARBALL_PATH" | awk '{print $1}')
RMD160=$(openssl dgst -rmd160 "$TARBALL_PATH" | awk '{print $2}')
SIZE=$(wc -c < "$TARBALL_PATH" | tr -d ' ')

echo ""
echo "✅ Created: $TARBALL_PATH"
echo "   Size: $(du -sh "$TARBALL_PATH" | cut -f1)"
echo ""
echo "📋 Checksums:"
echo "   sha256  $SHA256"
echo "   rmd160  $RMD160"
echo "   size    $SIZE"

PORTFILE="$PROJECT_ROOT/macports/Portfile"
if [ -f "$PORTFILE" ]; then
    echo ""
    echo "📝 Updating macports/Portfile checksums and version..."
    sed -i '' \
        -e "s|github.setup        xykong flux-markdown [^ ]* v|github.setup        xykong flux-markdown ${VERSION} v|" \
        -e "s|distname            FluxMarkdown-[^ ]*-macports-source|distname            FluxMarkdown-${VERSION}-macports-source|" \
        -e "s|rmd160  [0-9a-f]*|rmd160  ${RMD160}|" \
        -e "s|sha256  [0-9a-f]*|sha256  ${SHA256}|" \
        -e "s|size    [0-9]*|size    ${SIZE}|" \
        "$PORTFILE"
    echo "  ✅ macports/Portfile updated"
fi

# ── 8. Cleanup staging ────────────────────────────────────────────────────────
rm -rf "build/macports-staging"
