#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-local}"

if [[ -z "$VERSION" || "$VERSION" == *"/"* ]]; then
    echo "版本字符串不能为空，也不能包含 /。" >&2
    exit 1
fi

BUILD_DIR="$ROOT_DIR/build/LocalRelease"
DERIVED_DATA_DIR="$BUILD_DIR/DerivedData"
STAGING_DIR="$BUILD_DIR/DMG"
OUTPUT_DIR="$ROOT_DIR/dist"
APP_NAME="KimiCodeBar"
APP_PATH="$DERIVED_DATA_DIR/Build/Products/Release/$APP_NAME.app"
DMG_PATH="$OUTPUT_DIR/$APP_NAME-$VERSION-macOS.dmg"

printf '开始构建 %s（Ad Hoc 本地签名）…\n' "$APP_NAME"
xcodebuild \
    -project "$ROOT_DIR/macOS/KimiCodeBar.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -derivedDataPath "$DERIVED_DATA_DIR" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY=- \
    DEVELOPMENT_TEAM="" \
    build

if [[ ! -d "$APP_PATH" ]]; then
    echo "构建完成，但没有找到 App：$APP_PATH" >&2
    exit 1
fi

printf '校验 App 签名…\n'
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
if ! codesign -dv "$APP_PATH" 2>&1 | grep 'Signature=adhoc' >/dev/null; then
    echo "签名校验失败：预期为 Ad Hoc 签名。" >&2
    exit 1
fi

printf '准备 DMG 安装内容…\n'
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR" "$OUTPUT_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

printf '生成 DMG：%s\n' "$DMG_PATH"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

printf '打包完成：%s\n' "$DMG_PATH"
