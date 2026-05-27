#!/bin/bash
set -e

APP_NAME="PDF合并工具"
BUNDLE_DIR="$APP_NAME.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$(dirname "$0")"

echo "🔨 编译中..."

rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

swiftc PDFMergerApp.swift \
    -o "$MACOS_DIR/PDFMerger" \
    -framework SwiftUI \
    -framework PDFKit \
    -framework UniformTypeIdentifiers \
    -target arm64-apple-macosx13.0 \
    -parse-as-library

cp Info.plist "$CONTENTS_DIR/Info.plist"

echo "✅ 编译成功！"
echo "📦 应用位置: $(pwd)/$BUNDLE_DIR"
echo ""
echo "运行: open \"$BUNDLE_DIR\""
