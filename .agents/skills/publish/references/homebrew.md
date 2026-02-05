# Homebrew Cask Update

After creating a GitHub release, update the Homebrew Cask formula so users can install via `brew install --cask markdown-preview-enhanced`.

## Step 1: Navigate to Homebrew Tap Repository

```bash
cd ../homebrew-tap
```

**Expected Repository:**
```
git@github.com:xykong/homebrew-tap.git
```

If not present, clone it:
```bash
git clone git@github.com:xykong/homebrew-tap.git ../homebrew-tap
```

## Step 2: Calculate DMG SHA256

```bash
# Return to main project
cd ../markdown-quicklook

# Calculate SHA256 hash
SHA256=$(shasum -a 256 build/artifacts/MarkdownPreviewEnhanced.dmg | awk '{print $1}')

echo "SHA256: $SHA256"
# Example: ca72b7201410962f0f5d272149b2405a5d191a8e692d9526f23ecad3882cd306
```

## Step 3: Update Cask File

```bash
cd ../homebrew-tap

# Edit Cask file
vim Casks/markdown-preview-enhanced.rb
```

**Update Two Lines:**

```ruby
cask 'markdown-preview-enhanced' do
  version '1.8.114'  # ← UPDATE THIS
  sha256 'ca72b7201410962f0f5d272149b2405a5d191a8e692d9526f23ecad3882cd306'  # ← UPDATE THIS
  
  url "https://github.com/xykong/markdown-quicklook/releases/download/v#{version}/MarkdownPreviewEnhanced.dmg"
  name 'Markdown Preview Enhanced'
  homepage 'https://github.com/xykong/markdown-quicklook'

  auto_updates true

  livecheck do
    url "https://xykong.github.io/markdown-quicklook/appcast.xml"
    strategy :sparkle, &:short_version
  end

  app 'Markdown Preview Enhanced.app'
end
```

## Step 4: Commit and Push

```bash
git add Casks/markdown-preview-enhanced.rb
git commit -m "chore(cask): update markdown-preview-enhanced to v1.8.114"
git push origin master
```

## Step 5: Verify Homebrew Tap Update

```bash
# Check commit pushed
git log -1 --oneline
# Expected: chore(cask): update markdown-preview-enhanced to v1.8.114

# Return to main project
cd ../markdown-quicklook
```

## Step 6: Test Homebrew Installation

**CRITICAL**: Test the actual installation to ensure the release works end-to-end.

```bash
# Update local tap
brew update

# Check cask info
brew info markdown-preview-enhanced
# Expected: Version: 1.8.114

# Verify SHA256 matches
brew info markdown-preview-enhanced | grep "SHA256"
# Expected: Same hash as calculated in Step 2

# Uninstall existing version
brew uninstall --cask markdown-preview-enhanced

# Install new version from Homebrew
brew install --cask markdown-preview-enhanced

# Verify installation
ls -la "/Applications/Markdown Preview Enhanced.app"

# Test QuickLook
qlmanage -p tests/fixtures/test-sample.md

# Expected: QuickLook preview opens with rendered Markdown
```

## Troubleshooting

### Issue: Homebrew Installation Fails with "SHA256 mismatch"

**Cause**: The SHA256 hash in the Cask file doesn't match the actual DMG hash.

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

### Issue: `git push` fails in homebrew-tap repository

**Cause**: Remote has changes that conflict with local changes.

**Solution:**
```bash
cd ../homebrew-tap
git status
git pull origin master --rebase

# Resolve conflicts if any
git add Casks/markdown-preview-enhanced.rb
git rebase --continue

# Push again
git push origin master
```

### Issue: QuickLook Doesn't Work After Installation

**Cause**: QuickLook cache not updated.

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
