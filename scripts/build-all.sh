#!/bin/sh
set -e

APP_NAME="ziggo-cloner"
OUT_DIR="release-bin"
mkdir -p "$OUT_DIR"

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
}

build "macos-arm64"    "aarch64-macos"
build "macos-x86_64"   "x86_64-macos"
build "linux-x86_64"   "x86_64-linux-gnu"
build "linux-musl"     "x86_64-linux-musl"
build "windows-x86_64" "x86_64-windows-gnu"

