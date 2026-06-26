#!/usr/bin/env bash
# 本地打包 MacCalendar.dmg（需要完整 Xcode，Command Line Tools 不够）
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if ! xcodebuild -version >/dev/null 2>&1; then
  echo "错误：未检测到 Xcode。"
  echo "请从 App Store 安装 Xcode，然后执行："
  echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

BUILD_DIR="$ROOT_DIR/build"
DMG_SOURCE="$ROOT_DIR/dmg_source"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$BUILD_DIR/Release/MacCalendar.app"
DMG_PATH="$DIST_DIR/MacCalendar.dmg"

echo "==> 清理旧产物"
rm -rf "$BUILD_DIR" "$DMG_SOURCE" "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "==> 编译 Release（与上游 release.yml 一致）"
xcodebuild clean build \
  -project "MacCalendar.xcodeproj" \
  -scheme "MacCalendar" \
  -configuration Release \
  CODE_SIGN_IDENTITY="-" \
  DEVELOPMENT_TEAM="" \
  SYMROOT="$BUILD_DIR" \
  OBJROOT="$BUILD_DIR"

if [[ ! -d "$APP_PATH" ]]; then
  echo "错误：未找到 $APP_PATH"
  exit 1
fi

echo "==> 准备 create-dmg"
if ! command -v create-dmg >/dev/null 2>&1; then
  brew install create-dmg
fi

echo "==> 生成 DMG"
mkdir -p "$DMG_SOURCE"
ditto "$APP_PATH" "$DMG_SOURCE/MacCalendar.app"
xattr -cr "$DMG_SOURCE/MacCalendar.app"

create-dmg \
  --volname "MacCalendar Installer" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "MacCalendar.app" 150 120 \
  --hide-extension "MacCalendar.app" \
  --app-drop-link 450 120 \
  "$DMG_PATH" \
  "$DMG_SOURCE/" \
  || hdiutil create -volname "MacCalendar Installer" -srcfolder "$DMG_SOURCE" -ov -format UDZO "$DMG_PATH"

echo ""
echo "打包完成：$DMG_PATH"
echo ""
echo "安装后若提示无法打开，请执行："
echo "  xattr -cr /Applications/MacCalendar.app"
