#!/usr/bin/env bash
# 验证 MacCalendar.app 签名；若未签名则 ad-hoc 补签
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

echo "==> 清除 quarantine 扩展属性"
xattr -cr "$APP_PATH"

if codesign --verify --deep "$APP_PATH" >/dev/null 2>&1; then
  echo "==> 已有有效签名，跳过补签"
else
  echo "==> 未签名或签名无效，执行 ad-hoc 补签"
  codesign --remove-signature "$APP_PATH" 2>/dev/null || true
  codesign --force --deep --sign - "$APP_PATH"
fi

echo "==> 签名信息"
codesign -dv --verbose=4 "$APP_PATH" 2>&1 | head -20

echo "==> 验证签名"
codesign --verify --deep --verbose=2 "$APP_PATH"

echo "==> 架构"
file "$EXECUTABLE"
if command -v lipo >/dev/null 2>&1; then
  lipo -info "$EXECUTABLE" 2>/dev/null || true
fi
