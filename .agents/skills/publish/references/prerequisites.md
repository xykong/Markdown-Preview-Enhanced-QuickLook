# Prerequisites

Before starting the release process, verify all required tools and resources are available.

## 1. Required Tools Check

```bash
# GitHub CLI
command -v gh >/dev/null 2>&1 || echo "❌ Missing: gh (brew install gh)"

# Git
command -v git >/dev/null 2>&1 || echo "❌ Missing: git"

# Make
command -v make >/dev/null 2>&1 || echo "❌ Missing: make"

# Sparkle sign_update tool
SIGN_UPDATE=$(find ~/Library/Developer/Xcode/DerivedData -name "sign_update" 2>/dev/null | head -1)
if [ -z "$SIGN_UPDATE" ]; then
    echo "❌ Missing: Sparkle sign_update tool"
    echo "   Build the project first to generate Sparkle artifacts"
else
    echo "✅ Found: $SIGN_UPDATE"
fi

# Python 3
command -v python3 >/dev/null 2>&1 || echo "❌ Missing: python3"
```

## 2. Repository State Verification

```bash
# Check working directory is clean
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "❌ Working directory has uncommitted changes"
    git status
    exit 1
fi

# Check on master branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "master" ]; then
    echo "❌ Not on master branch (current: $CURRENT_BRANCH)"
    exit 1
fi

# Pull latest changes
git pull origin master
```

## 3. Keychain Access Confirmation

```bash
# Verify Sparkle private key is in Keychain
security find-generic-password -l "Sparkle EdDSA Private Key" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Sparkle private key not found in Keychain"
    echo "   Generate keys with: ./scripts/generate-sparkle-keys.sh"
    exit 1
fi
```

## 4. Homebrew Tap Repository Check

```bash
# Verify homebrew-tap repository exists
if [ ! -d "../homebrew-tap" ]; then
    echo "❌ Homebrew tap repository not found at ../homebrew-tap"
    echo "   Clone it with: git clone git@github.com:xykong/homebrew-tap.git ../homebrew-tap"
    exit 1
fi

# Check homebrew-tap is on master and clean
cd ../homebrew-tap
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "❌ Homebrew tap has uncommitted changes"
    git status
    exit 1
fi
git pull origin master
cd -
```

## 5. CHANGELOG.md Verification

```bash
# Check [Unreleased] section exists and is not empty
if ! grep -q "## \[Unreleased\]" CHANGELOG.md; then
    echo "❌ CHANGELOG.md missing [Unreleased] section"
    exit 1
fi

# Extract unreleased content
UNRELEASED_CONTENT=$(sed -n '/## \[Unreleased\]/,/## \[/p' CHANGELOG.md | sed '$d' | tail -n +2)

if [ -z "$UNRELEASED_CONTENT" ] || echo "$UNRELEASED_CONTENT" | grep -q "^_无待发布的变更_$"; then
    echo "⚠️  Warning: [Unreleased] section is empty"
    echo "   Add changes to CHANGELOG.md before releasing"
    exit 1
fi

echo "✅ CHANGELOG.md [Unreleased] section:"
echo "$UNRELEASED_CONTENT"
```

**Expected Format:**
```markdown
## [Unreleased]

### Added
- **[Scope]**: Description. (Thanks [@username](https://github.com/username) [#PR](link))
  - Technical detail 1
  - Technical detail 2

### Fixed
- **[Scope]**: Description. (Thanks [@username](https://github.com/username) [#PR](link))
  - Technical detail 1
```
