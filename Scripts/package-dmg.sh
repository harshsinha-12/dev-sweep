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
DMG_RW="$OUTPUT_DIR/${APP_NAME}-rw.dmg"
DMG_OUT="$OUTPUT_DIR/${APP_NAME}-v${APP_VERSION}.dmg"
ZIP_OUT="$OUTPUT_DIR/${APP_NAME}-v${APP_VERSION}.zip"

rm -rf "$STAGE" "$DMG_RW" "$DMG_OUT" "$ZIP_OUT"
mkdir -p "$STAGE"

echo "→ Staging app"
ditto "$APP_PATH" "$STAGE/$APP_NAME.app"
ln -s /Applications "$STAGE/Applications"

# Optional custom DMG background
BACKGROUND_SRC="$ROOT/Design/dmg-background.png"
if [[ -f "$BACKGROUND_SRC" ]]; then
  mkdir -p "$STAGE/.background"
  cp "$BACKGROUND_SRC" "$STAGE/.background/background.png"
fi

echo "→ Creating temporary DMG"
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDRW \
  -size 200m \
  "$DMG_RW" >/dev/null

echo "→ Mounting DMG for layout"
MOUNT_DIR="$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_RW" | awk 'END{print $NF}')"
VOLUME_PATH="/Volumes/$VOLUME_NAME"

# Wait for mount
for _ in {1..20}; do
  [[ -d "$VOLUME_PATH" ]] && break
  sleep 0.25
done

if [[ ! -d "$VOLUME_PATH" ]]; then
  echo "error: failed to mount DMG at $VOLUME_PATH" >&2
  exit 1
fi

echo "→ Applying Finder layout"
BG_LINE=""
if [[ -f "$VOLUME_PATH/.background/background.png" ]]; then
  BG_LINE='set background picture of viewOptions to file ".background:background.png"'
fi

osascript <<EOF
tell application "Finder"
  tell disk "$VOLUME_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {120, 120, 740, 520}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 128
    $BG_LINE
    set position of item "$APP_NAME.app" of container window to {160, 220}
    set position of item "Applications" of container window to {460, 220}
    update without registering applications
    delay 1
    close
  end tell
end tell
EOF

sync
hdiutil detach "$MOUNT_DIR" >/dev/null || hdiutil detach "$VOLUME_PATH" -force >/dev/null

echo "→ Compressing final DMG"
hdiutil convert "$DMG_RW" -format ULMO -o "$DMG_OUT" >/dev/null
rm -f "$DMG_RW"
rm -rf "$STAGE"

echo "→ Creating zip"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_OUT"

# Write a short install note next to artifacts
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
