#!/bin/bash
set -e

echo "🧪 Sparkle 更新测试（从旧版本更新到新版本）"
echo ""
echo "原理：安装一个旧版本（v1.6.96），然后测试更新到最新版本（v1.6.100+）"
echo ""

read -p "这会临时安装旧版本应用。继续？[y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "📦 步骤 1/3: 下载旧版本 (v1.6.96)..."
OLD_DMG_URL="https://github.com/xykong/markdown-quicklook/releases/download/v1.6.96/MarkdownPreviewEnhanced.dmg"
TMP_DIR=$(mktemp -d)
OLD_DMG="$TMP_DIR/old_version.dmg"

if ! curl -L -o "$OLD_DMG" "$OLD_DMG_URL" 2>&1 | grep -v "^  "; then
    echo "❌ 下载失败"
    rm -rf "$TMP_DIR"
    exit 1
fi

echo "   ✓ 旧版本已下载"

echo ""
echo "📲 步骤 2/3: 安装旧版本 (v1.6.96)..."
hdiutil attach "$OLD_DMG" -mountpoint "$TMP_DIR/mount" -quiet
rm -rf "/Applications/Markdown Preview Enhanced.app"
cp -R "$TMP_DIR/mount/Markdown Preview Enhanced.app" "/Applications/"
hdiutil detach "$TMP_DIR/mount" -quiet
xattr -cr "/Applications/Markdown Preview Enhanced.app"

echo "   ✓ 旧版本已安装"

rm -rf "$TMP_DIR"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  ✅ 测试环境准备完成"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📋 测试信息:"
echo "   • 已安装版本: v1.6.96"
echo "   • 可更新版本: v1.6.100+"
echo ""
echo "🧪 开始测试:"
echo "   1. 打开 'Markdown Preview Enhanced' 应用"
echo "   2. 点击 '检查更新...' 或按 ⌘U"
echo "   3. 应该检测到新版本（v1.6.100 或更高）"
echo "   4. 点击 'Install' 按钮"
echo "   5. 观察是否成功安装（不应报错）"
echo ""
echo "🔄 恢复最新版本:"
echo "   ./scripts/install.sh"
echo ""
