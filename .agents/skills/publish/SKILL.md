---
name: publish
description: Complete release workflow for Markdown Preview Enhanced. Use when publishing a new version, bumping versions, or updating distribution channels (GitHub, Sparkle, Homebrew). Triggers include "release", "publish", "bump version", "make release", "create release", or any request involving version management and distribution updates.
---

# Publish Skill

Automates the complete release workflow for Markdown Preview Enhanced, including version bumping, CHANGELOG management, GitHub releases, Sparkle appcast updates, and Homebrew Cask distribution.

## When to Use

- Publishing a new version (major/minor/patch)
- Creating GitHub releases with DMG artifacts
- Updating Sparkle appcast.xml for auto-updates
- Updating Homebrew Cask distribution

## Quick Reference

### Release Command

```bash
# Default: minor release
make release

# Or specify type
make release [major|minor|patch]
```

**Release Types:**
- `major`: Breaking changes (1.8 → 2.0)
- `minor`: New features (1.8 → 1.9) [DEFAULT]
- `patch`: Bug fixes only (base version unchanged, commit count increments)

## Workflow Overview

### 1. Pre-Release Preparation

**Check CHANGELOG.md:**
```bash
# Verify [Unreleased] section exists and has content
grep -A 10 "## \[Unreleased\]" CHANGELOG.md
```

**Update README.md if needed:**
- New user-facing features? Update feature list
- New installation instructions? Update installation section
- Screenshots outdated? Update screenshots

Commit README changes BEFORE running `make release`:
```bash
git add README.md
git commit -m "docs(readme): update for v<NEXT_VERSION> features"
git push origin master
```

### 2. Run Release Command

```bash
make release [major|minor|patch]
```

**What this does automatically:**
1. Calculates new version from `.version` + git commit count
2. Updates `.version` file (if major/minor)
3. Transforms CHANGELOG.md (`[Unreleased]` → versioned section)
4. Creates git commit and tag
5. Pushes to GitHub
6. Builds DMG artifact
7. Creates GitHub Release with DMG asset

### 3. Update Sparkle Appcast (Manual)

**Required for auto-update functionality.**

See [references/sparkle.md](references/sparkle.md) for complete instructions.

**Quick Steps:**
```bash
# 1. Find sign_update tool
SIGN_UPDATE=$(find ~/Library/Developer/Xcode/DerivedData -name "sign_update" 2>/dev/null | head -1)

# 2. Sign DMG
SIGNATURE=$("$SIGN_UPDATE" build/artifacts/MarkdownPreviewEnhanced.dmg)

# 3. Extract signature and length
SPARKLE_SIGNATURE=$(echo "$SIGNATURE" | grep -o 'sparkle:edSignature="[^"]*"' | cut -d '"' -f 2)
DMG_LENGTH=$(echo "$SIGNATURE" | grep -o 'length="[^"]*"' | cut -d '"' -f 2)

# 4. Update appcast.xml with new <item> entry

# 5. Commit and push
git add appcast.xml
git commit -m "chore(sparkle): update appcast.xml for v<VERSION>"
git push origin master
```

### 4. Update Homebrew Cask (Manual)

**Required for Homebrew distribution.**

See [references/homebrew.md](references/homebrew.md) for complete instructions.

**Quick Steps:**
```bash
# 1. Calculate SHA256
SHA256=$(shasum -a 256 build/artifacts/MarkdownPreviewEnhanced.dmg | awk '{print $1}')

# 2. Update Cask file
cd ../homebrew-tap
vim Casks/markdown-preview-enhanced.rb
# Update: version '...' and sha256 '...'

# 3. Commit and push
git add Casks/markdown-preview-enhanced.rb
git commit -m "chore(cask): update markdown-preview-enhanced to v<VERSION>"
git push origin master
cd -
```

### 5. Verification

**GitHub Release:**
```bash
gh release view v<VERSION>
```

**Appcast XML:**
```bash
curl -s https://xykong.github.io/markdown-quicklook/appcast.xml | grep "<VERSION>"
```

**Homebrew Cask:**
```bash
brew update
brew info markdown-preview-enhanced
# Expected: Version: <VERSION>
```

**Local Installation Test:**
```bash
brew uninstall --cask markdown-preview-enhanced
brew install --cask markdown-preview-enhanced
qlmanage -p tests/fixtures/test-sample.md
```

## Success Criteria

All of the following must be true:

- [ ] `.version` file updated to new base version
- [ ] CHANGELOG.md transformed with new versioned section
- [ ] Git commit and tag created and pushed
- [ ] DMG built successfully
- [ ] GitHub Release created with DMG asset
- [ ] Appcast.xml updated and accessible
- [ ] Homebrew Cask updated with correct version and SHA256
- [ ] Local installation test passed

## Detailed References

**IMPORTANT:** For detailed instructions, troubleshooting, and error handling, see:

- **[Prerequisites](references/prerequisites.md)** - Required tools, repository state checks
- **[Version Bump Process](references/version-bump.md)** - How versioning works, CHANGELOG transformation
- **[Sparkle Appcast](references/sparkle.md)** - Signing DMG, updating appcast.xml
- **[Homebrew Cask](references/homebrew.md)** - Updating Cask formula, SHA256 calculation
- **[Troubleshooting](references/troubleshooting.md)** - Error handling, rollback procedures

## Common Issues

### "gh: command not found"
```bash
brew install gh
gh auth login
```

### "sign_update: No such file or directory"
```bash
# Build the project first
make app
```

### "Sparkle EdDSA Private Key not found in Keychain"
```bash
./scripts/generate-sparkle-keys.sh
```

### Homebrew Installation Fails with "SHA256 mismatch"
Re-calculate SHA256 and update Cask file. See [references/troubleshooting.md](references/troubleshooting.md).

## External Documentation

- [docs/RELEASE_PROCESS.md](../../../docs/RELEASE_PROCESS.md) - Complete PR handling and release workflow
- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
- [Sparkle Framework](https://sparkle-project.org/)
- [Homebrew Cask Documentation](https://docs.brew.sh/Cask-Cookbook)
