#!/bin/bash
set -e

VERSION_FILE=".version"
CHANGELOG_FILE="CHANGELOG.md"
DMG_PATH="build/artifacts/MarkdownPreviewEnhanced.dmg"

if ! command -v gh &> /dev/null; then
    echo "❌ Error: 'gh' (GitHub CLI) is not installed."
    exit 1
fi

BUMP_TYPE=${1:-patch}

if [[ "$BUMP_TYPE" == "minus" ]]; then
    BUMP_TYPE="minor"
fi

if [[ "$BUMP_TYPE" != "major" && "$BUMP_TYPE" != "minor" && "$BUMP_TYPE" != "patch" ]]; then
    echo "❌ Error: Invalid bump type '$BUMP_TYPE'. Use major, minor, or patch."
    exit 1
fi

if [ ! -f "$VERSION_FILE" ]; then
    echo "1.0" > "$VERSION_FILE"
fi

BASE_VERSION=$(cat "$VERSION_FILE")
IFS='.' read -r major minor <<< "$BASE_VERSION"

if [[ "$BUMP_TYPE" == "major" ]]; then
    major=$((major + 1))
    minor=0
    echo "🚀 Bumping Major Version: $BASE_VERSION -> $major.$minor"
    echo "$major.$minor" > "$VERSION_FILE"
elif [[ "$BUMP_TYPE" == "minor" ]]; then
    minor=$((minor + 1))
    echo "🚀 Bumping Minor Version: $BASE_VERSION -> $major.$minor"
    echo "$major.$minor" > "$VERSION_FILE"
elif [[ "$BUMP_TYPE" == "patch" ]]; then
    echo "🚀 Patch release: Base version ($BASE_VERSION) unchanged. Commit count will increment."
fi

COMMIT_COUNT=$(git rev-list --count HEAD)
NEXT_COMMIT_COUNT=$((COMMIT_COUNT + 1))
NEW_BASE_VERSION=$(cat "$VERSION_FILE")
FULL_VERSION="$NEW_BASE_VERSION.$NEXT_COMMIT_COUNT"

echo "🎯 Target Version: $FULL_VERSION"

echo "📝 Extracting user-facing release notes..."
RELEASE_NOTES_FILE="release_notes_tmp.md"

python3 -c "
import sys
import re

BLACKLIST = ['架构', 'Architecture', '内部', 'Internal', '构建', 'Build', '测试', 'Test', 'CI', 'Refactor']

def is_user_facing(line):
    match = re.search(r'\*\*(.*?)\*\*:', line)
    if match:
        scope = match.group(1)
        for b in BLACKLIST:
            if b in scope:
                return False
    return True

try:
    with open('$CHANGELOG_FILE', 'r', encoding='utf-8') as f:
        content = f.read()
    
    pattern = r'## \[Unreleased\]\n(.*?)(\n## \[|$)'
    match = re.search(pattern, content, re.DOTALL)
    
    if match:
        raw_notes = match.group(1).strip()
        filtered_lines = []
        for line in raw_notes.split('\n'):
            if line.strip().startswith('-'):
                if is_user_facing(line):
                    filtered_lines.append(line)
            else:
                filtered_lines.append(line)
        
        final_notes = re.sub(r'\n{3,}', '\n\n', '\n'.join(filtered_lines)).strip()
        print(final_notes)
    else:
        sys.stderr.write('Warning: No [Unreleased] section found.\n')
except Exception as e:
    sys.stderr.write(f'Error: {e}\n')
    sys.exit(1)
" > "$RELEASE_NOTES_FILE"

if [ ! -s "$RELEASE_NOTES_FILE" ]; then
    echo "⚠️ Warning: Release notes are empty. Continuing..."
    echo "No significant user-facing changes." > "$RELEASE_NOTES_FILE"
else
    echo "✅ Release notes extracted:"
    cat "$RELEASE_NOTES_FILE"
    echo "----------------------------------------"
fi

DATE_STR=$(date "+%Y-%m-%d")
TEMP_CHANGELOG=$(mktemp)
sed "s/## \[Unreleased\]/## [Unreleased]\\
\\
## [$FULL_VERSION] - $DATE_STR/" "$CHANGELOG_FILE" > "$TEMP_CHANGELOG"
mv "$TEMP_CHANGELOG" "$CHANGELOG_FILE"

echo "💾 Committing changes..."
git add "$VERSION_FILE" "$CHANGELOG_FILE"
if git ls-files --error-unmatch .build_number >/dev/null 2>&1; then
    git rm .build_number
fi
if git ls-files --error-unmatch scripts/increment_version.sh >/dev/null 2>&1; then
    git rm scripts/increment_version.sh
fi

git commit -m "chore(release): bump version to $FULL_VERSION"
git tag "v$FULL_VERSION"

echo "☁️ Pushing to remote..."
git push origin master
git push origin "v$FULL_VERSION"

echo "🔨 Building project and DMG..."
make dmg

if [ ! -f "$DMG_PATH" ]; then
    echo "❌ Error: DMG not found at $DMG_PATH"
    exit 1
fi

echo "📦 Creating GitHub Release v$FULL_VERSION..."
gh release create "v$FULL_VERSION" "$DMG_PATH" \
    --title "v$FULL_VERSION" \
    --notes-file "$RELEASE_NOTES_FILE" \
    --draft=false \
    --prerelease=false

rm "$RELEASE_NOTES_FILE"

echo "🎉 Successfully released v$FULL_VERSION!"
