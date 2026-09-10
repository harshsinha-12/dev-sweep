#!/usr/bin/env bash
# Package DevSweep.app into a drag-and-drop DMG (+ zip).
#
# Usage:
#   ./Scripts/package-dmg.sh
#   ./Scripts/package-dmg.sh /path/to/DevSweep.app
#   VERSION=0.1.0 ./Scripts/package-dmg.sh
#
# Optional env:
#   VERSION          Override marketing version (default: read from app Info.plist)
#   SKIP_BUILD=1     Do not build; require APP path argument or existing build
#   OUTPUT_DIR       Where to write artifacts (default: ./dist)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

OUTPUT_DIR="${OUTPUT_DIR:-$ROOT/dist}"
APP_NAME="DevSweep"
VOLUME_NAME="DevSweep"
SKIP_BUILD="${SKIP_BUILD:-0}"

if [[ $# -ge 1 ]]; then
  APP_PATH="$1"
elif [[ "$SKIP_BUILD" == "1" ]]; then
  APP_PATH="$ROOT/build/DerivedData/Build/Products/Release/$APP_NAME.app"
else
  APP_PATH="$("$ROOT/Scripts/build-release.sh" | tail -n 1)"
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "error: app not found at $APP_PATH" >&2
  exit 1
fi

if [[ -n "${VERSION:-}" ]]; then
  APP_VERSION="$VERSION"
else
  APP_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "0.1.0")"
fi

mkdir -p "$OUTPUT_DIR"
STAGE="$OUTPUT_DIR/dmg-stage"
DMG_OUT="$OUTPUT_DIR/${APP_NAME}-v${APP_VERSION}.dmg"
ZIP_OUT="$OUTPUT_DIR/${APP_NAME}-v${APP_VERSION}.zip"

rm -rf "$STAGE" "$DMG_OUT" "$ZIP_OUT"
mkdir -p "$STAGE"

echo "→ Staging app"
ditto "$APP_PATH" "$STAGE/$APP_NAME.app"
ln -sf /Applications "$STAGE/Applications"

# Prefer a simple compressed DMG. Finder AppleScript layout is unreliable in CI.
echo "→ Creating DMG"
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  "$DMG_OUT" >/dev/null

rm -rf "$STAGE"

echo "→ Creating zip"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_OUT"

cat > "$OUTPUT_DIR/INSTALL.txt" <<NOTE
DevSweep v${APP_VERSION}

Install
1. Open ${APP_NAME}-v${APP_VERSION}.dmg
2. Drag DevSweep into Applications
3. Open DevSweep from Applications / Launchpad

Gatekeeper (unsigned builds)
If macOS says the app can't be opened:
  Right-click DevSweep → Open → Open
Or:
  System Settings → Privacy & Security → Open Anyway

DevSweep moves selected developer folders to Trash. It does not permanently erase files.
NOTE

echo "✓ DMG  $DMG_OUT"
echo "✓ ZIP  $ZIP_OUT"
echo "✓ Note $OUTPUT_DIR/INSTALL.txt"
ls -lh "$DMG_OUT" "$ZIP_OUT"
