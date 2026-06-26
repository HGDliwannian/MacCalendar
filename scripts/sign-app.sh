#!/usr/bin/env bash
# 验证 MacCalendar.app 签名；若未签名则 ad-hoc 补签
set -uo pipefail

APP_PATH="${1:-}"
if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  echo "用法: $0 path/to/MacCalendar.app"
  exit 1
fi

EXECUTABLE="$APP_PATH/Contents/MacOS/MacCalendar"

if [[ ! -f "$EXECUTABLE" ]]; then
  echo "错误：找不到可执行文件 $EXECUTABLE"
  exit 1
fi

echo "==> 清除 quarantine 扩展属性"
xattr -cr "$APP_PATH"

if codesign --verify --deep "$APP_PATH" >/dev/null 2>&1; then
  echo "==> 已有有效签名"
else
  echo "==> 补签 ad-hoc"
  codesign --force --deep --sign - "$APP_PATH"
  codesign --verify --deep "$APP_PATH"
fi

echo "==> 架构: $(file "$EXECUTABLE")"
