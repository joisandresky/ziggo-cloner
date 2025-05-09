#!/bin/sh
set -e

APP_NAME="ziggo-cloner"
OUT_DIR="release-bin"
ARCHIVE_DIR="release-archives"

mkdir -p "$OUT_DIR"
mkdir -p "$ARCHIVE_DIR"

build() {
  ARCH="$1"
  TARGET="$2"
  FOLDER_NAME="${APP_NAME}-${ARCH}"

  echo "▶ Building $FOLDER_NAME ($TARGET)..."

  zig build -Dtarget="$TARGET" -Doptimize=ReleaseFast

  BIN_PATH="zig-out/bin/$APP_NAME"
  [ "$ARCH" = "windows-x86_64" ] && BIN_PATH="$BIN_PATH.exe"

  DEST_DIR="$OUT_DIR/$FOLDER_NAME"
  mkdir -p "$DEST_DIR"

  DEST="$DEST_DIR/$APP_NAME"
  [ "$ARCH" = "windows-x86_64" ] && DEST="$DEST.exe"

  cp "$BIN_PATH" "$DEST"
  echo "✅ Built: $DEST"

  # Package as zip
  ZIP_PATH="$ARCHIVE_DIR/$FOLDER_NAME.zip"
  (cd "$OUT_DIR" && zip -r "../$ZIP_PATH" "$FOLDER_NAME")
  echo "📦 Packaged: $ZIP_PATH"
}

build "macos-arm64"    "aarch64-macos"
build "macos-x86_64"   "x86_64-macos"
build "linux-x86_64"   "x86_64-linux-gnu"
build "linux-musl"     "x86_64-linux-musl"
build "windows-x86_64" "x86_64-windows-gnu"

echo "✅ All builds and packages are complete."

