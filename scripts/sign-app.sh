#!/usr/bin/env bash
# 对 MacCalendar.app 做 ad-hoc 签名，避免 macOS 报「已损坏或不完整」
set -euo pipefail

APP_PATH="${1:-}"
if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  echo "用法: $0 path/to/MacCalendar.app"
  exit 1
fi

ENTITLEMENTS="$(cd "$(dirname "$0")/.." && pwd)/MacCalendar/MacCalendar.entitlements"
EXECUTABLE="$APP_PATH/Contents/MacOS/MacCalendar"

if [[ ! -f "$EXECUTABLE" ]]; then
  echo "错误：找不到可执行文件 $EXECUTABLE"
  exit 1
fi

echo "==> 清除扩展属性"
xattr -cr "$APP_PATH"

echo "==> ad-hoc 签名"
if [[ -f "$ENTITLEMENTS" ]]; then
  codesign --force --deep --sign - --entitlements "$ENTITLEMENTS" "$APP_PATH"
else
  codesign --force --deep --sign - "$APP_PATH"
fi

echo "==> 验证签名"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "==> 架构"
file "$EXECUTABLE"
if command -v lipo >/dev/null 2>&1; then
  lipo -info "$EXECUTABLE" || true
fi
