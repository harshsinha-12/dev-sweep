#!/usr/bin/env bash
# Build a Release .app for DevSweep (unsigned by default).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA="${DERIVED_DATA:-$ROOT/build/DerivedData}"
PRODUCTS_DIR="$DERIVED_DATA/Build/Products/$CONFIGURATION"
APP_NAME="DevSweep"

if [[ -f project.yml ]] && command -v xcodegen >/dev/null 2>&1; then
  echo "→ Generating Xcode project"
  xcodegen generate
fi

echo "→ Building $APP_NAME ($CONFIGURATION)"
xcodebuild \
  -scheme DevSweep \
  -project DevSweep.xcodeproj \
  -destination 'platform=macOS' \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}" \
  CODE_SIGNING_REQUIRED="${CODE_SIGNING_REQUIRED:-NO}" \
  CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED:-NO}" \
  build

APP_PATH="$PRODUCTS_DIR/$APP_NAME.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "error: expected app not found at $APP_PATH" >&2
  exit 1
fi

echo "✓ Built $APP_PATH"
echo "$APP_PATH"
