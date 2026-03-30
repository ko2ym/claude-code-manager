#!/bin/bash
set -e

# ============================================================
# build_dmg.sh — Claude Code Manager DMG builder
# Usage: ./scripts/build_dmg.sh [version]
#   version: optional (default: reads from Info.plist)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCHEME="ClaudeCodeManager"
CONFIGURATION="Release"
APP_NAME="ClaudeCodeManager"
DIST_DIR="$PROJECT_ROOT/dist"

# バージョン取得
if [ -n "$1" ]; then
  VERSION="$1"
else
  VERSION=$(defaults read "$PROJECT_ROOT/ClaudeCodeManager/Resources/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0")
fi

DMG_NAME="${APP_NAME}_${VERSION}.dmg"
VOLUME_NAME="Claude Code Manager ${VERSION}"

echo "==> Building ${APP_NAME} v${VERSION} (${CONFIGURATION})"

# ---- 1. Release ビルド ----
xcodebuild \
  -project "$PROJECT_ROOT/ClaudeCodeManager.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  build

BUILD_DIR=$(xcodebuild \
  -project "$PROJECT_ROOT/ClaudeCodeManager.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -showBuildSettings 2>/dev/null \
  | grep "CONFIGURATION_BUILD_DIR" | head -1 | awk '{print $3}')

APP_PATH="$BUILD_DIR/${APP_NAME}.app"
echo "==> App built at: $APP_PATH"

# ---- 2. dist ディレクトリ準備 ----
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# ---- 3. DMG ステージング ----
STAGING="$DIST_DIR/staging"
mkdir -p "$STAGING"
cp -R "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# ---- 4. DMG 作成 ----
TMP_DMG="$DIST_DIR/tmp.dmg"
FINAL_DMG="$DIST_DIR/$DMG_NAME"

echo "==> Creating DMG..."
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  "$TMP_DMG"

mv "$TMP_DMG" "$FINAL_DMG"
rm -rf "$STAGING"

echo ""
echo "✓ Done: $FINAL_DMG"
echo "  Size: $(du -sh "$FINAL_DMG" | cut -f1)"
echo ""
echo "  codesign: $(codesign -dv "$FINAL_DMG" 2>&1 | head -1 || echo 'n/a')"
