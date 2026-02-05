# Troubleshooting and Error Handling

## Error 1: `make release` Fails

**Symptoms**: Script exits with error during version bump or build.

**Diagnosis:**
```bash
# Check error message
make release minor 2>&1 | tee release.log

# Common causes:
# 1. Missing dependencies (gh, python3)
# 2. Build failure (npm, xcodebuild)
# 3. Git conflicts
```

**Fix and Continue:**

**If version bump succeeded but build failed:**
```bash
# Check what was committed
git log -1 --oneline
# If "chore(release): bump version to X.X.X" exists:

# Check what was pushed
git log origin/master..HEAD
# If commits not pushed yet, rollback:
git reset --hard HEAD~1
git tag -d vX.X.X

# Fix the issue (install dependencies, fix build errors)
# Re-run release
make release [type]
```

**If commits were already pushed:**
```bash
# DO NOT rollback pushed commits
# Instead, fix the issue and complete manually:

# Fix build errors
# Then manually build DMG
make dmg

# Manually create GitHub Release
VERSION="1.8.114"  # Use actual version
gh release create "v$VERSION" \
    build/artifacts/MarkdownPreviewEnhanced.dmg \
    --title "v$VERSION" \
    --notes-file <(sed -n '/## \['"$VERSION"'\]/,/## \[/p' CHANGELOG.md | sed '$d' | tail -n +3)

# Continue with Sparkle and Homebrew steps
```

---

## Error 2: Appcast Signing Fails

**Symptoms**: `sign_update` command fails or produces invalid signature.

**Diagnosis:**
```bash
# Check private key in Keychain
security find-generic-password -l "Sparkle EdDSA Private Key" -g 2>&1

# If not found:
# ERROR: The specified item could not be found in the keychain.
```

**Fix:**

**Option A: Regenerate Keys** (if you have backups)
```bash
# If you have a backup of the private key
# Import it to Keychain (requires password)
# Then retry signing
```

**Option B: Generate New Keys** (will break existing installations)
```bash
# WARNING: This invalidates all previous releases
# Only do this if you have no private key backup

# Generate new keys
./scripts/generate-sparkle-keys.sh

# Update Info.plist with new public key
# Rebuild and re-release
```

**Option C: Skip Appcast Update** (temporary workaround)
```bash
# Release is still valid, but Sparkle auto-update won't work
# Users can still download manually or via Homebrew
# Update appcast.xml later when key issue is resolved
```

---

## Error 3: DMG Download Test Fails

**Symptoms**: Downloaded DMG has different SHA256 or cannot be opened.

**Diagnosis:**
```bash
# Re-download and compare
curl -L -o /tmp/test.dmg \
    "https://github.com/xykong/markdown-quicklook/releases/download/v1.8.114/MarkdownPreviewEnhanced.dmg"

shasum -a 256 /tmp/test.dmg
shasum -a 256 build/artifacts/MarkdownPreviewEnhanced.dmg

# If hashes differ, DMG was corrupted during upload
```

**Fix:**
```bash
# Delete and re-upload DMG
gh release delete-asset v1.8.114 MarkdownPreviewEnhanced.dmg

# Re-upload
gh release upload v1.8.114 build/artifacts/MarkdownPreviewEnhanced.dmg

# Re-calculate SHA256 and update Homebrew Cask
```

---

## Complete Rollback (Nuclear Option)

**ONLY use if release is completely broken and cannot be fixed.**

```bash
# 1. Delete GitHub Release
gh release delete v1.8.114 --yes

# 2. Delete Git Tag (local and remote)
git tag -d v1.8.114
git push origin :refs/tags/v1.8.114

# 3. Revert .version file
git checkout HEAD~1 -- .version

# 4. Revert CHANGELOG.md
git checkout HEAD~1 -- CHANGELOG.md

# 5. Commit revert
git add .version CHANGELOG.md
git commit -m "revert: rollback failed release v1.8.114"
git push origin master

# 6. Revert Homebrew Cask
cd ../homebrew-tap
git checkout HEAD~1 -- Casks/markdown-preview-enhanced.rb
git commit -m "revert: rollback failed release v1.8.114"
git push origin master
cd -

# 7. Revert appcast.xml
git checkout HEAD~1 -- appcast.xml
git commit -m "revert: rollback failed release v1.8.114"
git push origin master

# 8. Start over
# Fix the root cause, then re-run make release
```

---

## Common Issues

### "gh: command not found"

**Solution:**
```bash
brew install gh
gh auth login
```

### "sign_update: No such file or directory"

**Solution:**
```bash
# Build the project first to generate Sparkle artifacts
make app

# Then find the tool
find ~/Library/Developer/Xcode/DerivedData -name "sign_update"
```

### "Sparkle EdDSA Private Key not found in Keychain"

**Solution:**
```bash
# Check if key exists
security find-generic-password -l "Sparkle EdDSA Private Key"

# If not found, generate keys
./scripts/generate-sparkle-keys.sh

# Or import from backup
# (Requires manual Keychain import via Keychain Access.app)
```

### Homebrew Installation Fails with "SHA256 mismatch"

**Solution:**
```bash
# Re-calculate correct SHA256
shasum -a 256 build/artifacts/MarkdownPreviewEnhanced.dmg

# Update Homebrew Cask with correct hash
cd ../homebrew-tap
vim Casks/markdown-preview-enhanced.rb
git add Casks/markdown-preview-enhanced.rb
git commit --amend
git push origin master --force
```

### QuickLook Doesn't Work After Installation

**Solution:**
```bash
# Reset QuickLook cache
qlmanage -r
qlmanage -r cache

# Kill QuickLook server
killall QLManageService

# Re-test
qlmanage -p tests/fixtures/test-sample.md
```
