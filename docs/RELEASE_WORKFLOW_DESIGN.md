# Release Workflow Design

## Problem Statement

### Version Inconsistency Issue

**Current problematic flow:**
```
Commit #136: "feat: some feature"
Commit #137: "chore(release): bump version to 1.12.136"  ← VERSION MISMATCH!
```

**Result:**
- Git tag: v1.12.136 (points to commit #137)
- GitHub Release: v1.12.136
- Sparkle appcast: v1.12.137 (calculated from commit #137)
- **MISMATCH**: Sparkle users get version 137 but GitHub shows 136

### Root Cause

Version calculation: `FULL_VERSION = BASE_VERSION.COMMIT_COUNT`
- The release commit increments commit count
- Version number is calculated BEFORE the commit
- Subsequent operations see different commit count

## Solution: Tag-First Workflow

### Design Principle

**The git tag should point to the last feature commit, not the version bump commit.**

Rationale:
- Tags represent code snapshots users will download
- Version bump commits contain no functional changes
- Appcast and Release must reference the same commit count

### Correct Workflow (Tag-First)

```
Step 1: Calculate version from CURRENT commit
   HEAD: commit #136 (last feature)
   Version: 1.12.136

Step 2: Update .version and CHANGELOG.md
   .version: 1.11 → 1.12
   CHANGELOG: Move [Unreleased] → [1.12.136]

Step 3: Create tag at CURRENT commit (before version commit)
   git tag v1.12.136
   (Tag points to commit #136)

Step 4: Build DMG
   Uses commit #136, version 1.12.136

Step 5: Create GitHub Release
   Release v1.12.136 with DMG from commit #136

Step 6: Update appcast.xml
   sign_update generates signature for DMG
   Appcast references commit #136 → version 1.12.136
   ✅ CONSISTENT

Step 7: Commit version changes
   git add .version CHANGELOG.md appcast.xml
   git commit -m "chore(release): release v1.12.136"
   (This becomes commit #137, but tag already exists at #136)

Step 8: Push
   git push origin master
   git push origin v1.12.136
```

### Key Changes from Old Workflow

| Old Workflow | New Workflow |
|--------------|--------------|
| Commit → Tag → Build | Tag → Build → Commit |
| Tag points to version commit (#137) | Tag points to feature commit (#136) |
| Version in commit name is wrong | Version in commit name is correct |
| appcast.xml committed separately | appcast.xml in same commit |

## Implementation Details

### Version Calculation

```bash
# Always calculate from CURRENT commit (before any changes)
BASE_VERSION=$(cat .version)
COMMIT_COUNT=$(git rev-list --count HEAD)
FULL_VERSION="$BASE_VERSION.$COMMIT_COUNT"
```

### Tag Creation Timing

```bash
# Create tag BEFORE making any commits
git tag "v$FULL_VERSION"

# Then make version commit
git add .version CHANGELOG.md appcast.xml
git commit -m "chore(release): release v$FULL_VERSION"
```

### Build from Tag

```bash
# Build should checkout the tag
git checkout "v$FULL_VERSION"
make dmg
git checkout master  # return to master
```

### Appcast Generation

```bash
# appcast.xml must be generated BEFORE committing
./scripts/generate-appcast.sh build/artifacts/MarkdownPreviewEnhanced.dmg

# Then include it in the release commit
git add appcast.xml
```

## Verification Checklist

After release, verify:
- [ ] Git tag exists: `git tag -l "v1.12.136"`
- [ ] Tag points to feature commit: `git show v1.12.136` (should NOT show version bump)
- [ ] GitHub Release exists with correct version
- [ ] DMG file uploaded to GitHub Release
- [ ] appcast.xml contains entry with matching version
- [ ] Homebrew Cask updated with matching version and SHA256
- [ ] All version numbers match across:
  - Git tag
  - GitHub Release title
  - DMG filename
  - appcast.xml `<sparkle:shortVersionString>`
  - Homebrew Cask `version`

## Edge Cases

### Case 1: Release Commit Pushed But Tag Not Pushed

**Scenario:** Commit #137 pushed, but tag v1.12.136 not pushed yet.

**Problem:** Others pulling master will see commit count #137+, creating version mismatch.

**Solution:**
- Always push tag immediately after pushing commit
- Or push both atomically: `git push origin master v1.12.136`

### Case 2: Need to Re-release Same Version

**Scenario:** Release v1.12.136 failed, need to retry.

**Solution:**
- Delete tag: `git tag -d v1.12.136 && git push origin :refs/tags/v1.12.136`
- Delete GitHub Release
- Revert version commit: `git revert HEAD`
- Start workflow again from Step 1

### Case 3: Hotfix After Release

**Scenario:** Released v1.12.136, need hotfix without version bump.

**Solution:** Not supported with commit-count versioning. Must create new version:
- Make fix commit (becomes #137)
- Release v1.12.137

## Migration Path

For existing releases with version mismatch:
1. **Do not retroactively fix**: Users may already have installed mismatched versions
2. **Document in CHANGELOG**: Add note about version number change in next release
3. **Start clean**: Apply new workflow for all future releases

## Testing

### Pre-release Dry Run

```bash
# Simulate workflow without pushing
./scripts/release-dry-run.sh minor

# Should output:
# - Calculated version
# - Git operations (without pushing)
# - Build commands
# - Verification checklist
```

### Post-release Verification

```bash
# Verify all version numbers match
./scripts/verify-release.sh v1.12.136

# Should check:
# - Git tag exists
# - GitHub Release exists
# - appcast.xml contains version
# - Homebrew Cask matches
```

## References

- Semantic Versioning: https://semver.org/
- Sparkle Documentation: https://sparkle-project.org/documentation/
- Keep a Changelog: https://keepachangelog.com/
