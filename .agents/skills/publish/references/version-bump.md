# Version Bump and CHANGELOG Transformation

## Version Calculation

The project uses a hybrid versioning scheme:

```bash
# Read base version from .version file
BASE_VERSION=$(cat .version)  # e.g., "1.8"

# Calculate commit count
COMMIT_COUNT=$(git rev-list --count HEAD)
NEXT_COMMIT_COUNT=$((COMMIT_COUNT + 1))

# Full version = base.commit_count
FULL_VERSION="$BASE_VERSION.$NEXT_COMMIT_COUNT"  # e.g., "1.8.114"
```

## Release Types

| Type | Base Version Change | Example | Use Case |
|------|---------------------|---------|----------|
| `major` | 1.8 → 2.0 | Breaking changes | API changes, major rewrites |
| `minor` | 1.8 → 1.9 | New features | Feature additions, enhancements |
| `patch` | 1.8 → 1.8 | Bug fixes only | Base version unchanged, commit count increments |

## What `make release` Does

The `scripts/release.sh` script performs these steps:

### 1. Version Calculation

```bash
# Read current base version
BASE_VERSION=$(cat .version)  # e.g., "1.8"

# Calculate new base version based on release type
case "$RELEASE_TYPE" in
  major)
    MAJOR=$(echo "$BASE_VERSION" | cut -d. -f1)
    NEW_BASE_VERSION="$((MAJOR + 1)).0"  # 1.8 → 2.0
    ;;
  minor)
    MAJOR=$(echo "$BASE_VERSION" | cut -d. -f1)
    MINOR=$(echo "$BASE_VERSION" | cut -d. -f2)
    NEW_BASE_VERSION="$MAJOR.$((MINOR + 1))"  # 1.8 → 1.9
    ;;
  patch)
    NEW_BASE_VERSION="$BASE_VERSION"  # 1.8 → 1.8
    ;;
esac

# Calculate full version with commit count
COMMIT_COUNT=$(git rev-list --count HEAD)
NEXT_COMMIT_COUNT=$((COMMIT_COUNT + 1))
FULL_VERSION="$NEW_BASE_VERSION.$NEXT_COMMIT_COUNT"
```

### 2. Base Version Update

```bash
# Update .version file
echo "$NEW_BASE_VERSION" > .version
```

### 3. Release Notes Extraction

```bash
# Extract content from [Unreleased] section
UNRELEASED_CONTENT=$(sed -n '/## \[Unreleased\]/,/## \[/p' CHANGELOG.md | sed '$d' | tail -n +2)

# Filter out internal changes (blacklist)
# Sections excluded: Architecture, Internal, Build, Test, CI, Refactor
FILTERED_NOTES=$(echo "$UNRELEASED_CONTENT" | grep -v "^### Architecture$" | grep -v "^### Internal$" ...)

# Generate release_notes_tmp.md for GitHub Release
echo "$FILTERED_NOTES" > release_notes_tmp.md
```

### 4. CHANGELOG Transformation

```bash
# Before:
## [Unreleased]

### Added
- Feature A

# After:
## [Unreleased]
_无待发布的变更_

## [1.8.114] - 2026-02-05

### Added
- Feature A
```

**Script Logic:**
```bash
# Get current date
RELEASE_DATE=$(date '+%Y-%m-%d')

# Create new versioned section
NEW_SECTION="## [$FULL_VERSION] - $RELEASE_DATE"

# Replace [Unreleased] section with:
# 1. Empty [Unreleased] section
# 2. New versioned section with previous unreleased content
sed -i '' '/## \[Unreleased\]/,/## \[/{
  /## \[Unreleased\]/!{
    /## \[/!d
  }
}' CHANGELOG.md

# Insert new sections
sed -i '' "/## \[Unreleased\]/a\\
_无待发布的变更_\\n\\
$NEW_SECTION\\n\\
$UNRELEASED_CONTENT
" CHANGELOG.md
```

### 5. Git Commit and Tag

```bash
git add .version CHANGELOG.md
git commit -m "chore(release): bump version to $FULL_VERSION"
git tag "v$FULL_VERSION"
git push origin master
git push origin "v$FULL_VERSION"
```

### 6. Build DMG

```bash
make dmg
# This runs:
# 1. npm install && npm run build (web-renderer)
# 2. xcodegen generate (Xcode project)
# 3. xcodebuild -scheme Markdown -configuration Release
# 4. create-dmg build/artifacts/MarkdownPreviewEnhanced.dmg
```

### 7. Create GitHub Release

```bash
gh release create "v$FULL_VERSION" \
    build/artifacts/MarkdownPreviewEnhanced.dmg \
    --title "v$FULL_VERSION" \
    --notes-file release_notes_tmp.md \
    --draft=false \
    --prerelease=false
```

## Verification

### Check Version Bump

```bash
# Check .version file updated
cat .version
# Expected: New base version (e.g., "1.9" for minor bump)

# Check CHANGELOG.md transformed
head -n 20 CHANGELOG.md
# Expected:
# ## [Unreleased]
# _无待发布的变更_
# 
# ## [1.9.115] - 2026-02-05

# Check git tag created
git tag -l | tail -1
# Expected: v1.9.115

# Check commits pushed
git log --oneline -3
# Expected: chore(release): bump version to 1.9.115
```

### Check DMG and GitHub Release

```bash
# Check DMG created
ls -lh build/artifacts/MarkdownPreviewEnhanced.dmg
# Expected: DMG file with size ~7-8 MB

# Check GitHub Release created
gh release view v1.8.114
# Expected: Release with DMG asset and release notes

# Or visit URL
echo "https://github.com/xykong/markdown-quicklook/releases/tag/v1.8.114"
```
