#!/bin/bash
set -e

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "❌ Error: Please specify a version to delete."
    echo "Usage: ./scripts/delete_release.sh <version>"
    echo "Example: ./scripts/delete_release.sh 1.0.0"
    exit 1
fi

VERSION=${VERSION#v}
TAG="v$VERSION"

echo "⚠️  DANGER: You are about to DELETE release $TAG"
echo "   This will:"
echo "   1. Delete the release from GitHub (including assets)"
echo "   2. Delete the remote tag '$TAG'"
echo "   3. Delete the local tag '$TAG'"
echo ""
read -p "❓ Are you sure you want to continue? (y/N) " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted."
    exit 0
fi

echo "🗑️  Deleting GitHub Release..."
if gh release view "$TAG" >/dev/null 2>&1; then
    gh release delete "$TAG" --yes
    echo "   ✅ GitHub Release deleted."
else
    echo "   ⚠️  GitHub Release not found (skipping)."
fi

echo "🗑️  Deleting Remote Tag..."
if git ls-remote --tags origin | grep -q "refs/tags/$TAG"; then
    git push origin --delete "$TAG"
    echo "   ✅ Remote tag deleted."
else
    echo "   ⚠️  Remote tag not found (skipping)."
fi

echo "🗑️  Deleting Local Tag..."
if git rev-parse "$TAG" >/dev/null 2>&1; then
    git tag -d "$TAG"
    echo "   ✅ Local tag deleted."
else
    echo "   ⚠️  Local tag not found (skipping)."
fi

echo ""
echo "✅ Release $TAG deletion steps completed."
echo ""
echo "❓ Do you want to revert the local release commit (CHANGELOG/Version updates)?"
echo "   Only say 'y' if the release commit is the LATEST commit on your current branch."
read -p "   Revert HEAD commit? (y/N) " revert_confirm

if [[ "$revert_confirm" == "y" || "$revert_confirm" == "Y" ]]; then
    echo "🔄 Reverting local HEAD..."
    git reset --hard HEAD~1
    echo "✅ Local branch reverted."
    echo ""
    echo "⚠️  IMPORTANT: Your local branch has diverged from remote."
    echo "   You MUST run the following command manually to sync remote:"
    echo ""
    echo "   git push origin $(git branch --show-current) --force"
    echo ""
fi
