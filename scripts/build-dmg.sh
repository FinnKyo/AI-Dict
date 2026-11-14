#!/bin/bash
# Builds a universal, ad-hoc signed AI-Dict.app and packages it as dist/AI-Dict-<version>.dmg.
# Ad-hoc signing needs no developer certificate and embeds no personal identity. The app is not
# notarized, so users open it via System Settings → Privacy & Security → Open Anyway.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT=$(pwd)
DERIVED="${DERIVED_DATA:-$HOME/Library/Developer/Xcode/DerivedData/AIDict-DMG}"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

xcodebuild build \
  -workspace Easydict.xcworkspace -scheme Easydict -configuration Release \
  -derivedDataPath "$DERIVED" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
  ENABLE_HARDENED_RUNTIME=NO \
  -quiet

APP="$DERIVED/Build/Products/Release/AI-Dict.app"
VERSION=$(defaults read "$APP/Contents/Info.plist" CFBundleShortVersionString)

mkdir -p "$WORK/root"
ditto "$APP" "$WORK/root/AI-Dict.app"
# A plain build keeps debug symbols; strip them, then re-sign the whole bundle.
strip -S -x "$WORK/root/AI-Dict.app/Contents/MacOS/AI-Dict" 2>/dev/null
codesign --force --deep --sign - --timestamp=none \
  --entitlements "$ROOT/Easydict/App/Easydict.entitlements" "$WORK/root/AI-Dict.app"
codesign --verify --deep --strict "$WORK/root/AI-Dict.app"
ln -s /Applications "$WORK/root/Applications"

mkdir -p dist
DMG="dist/AI-Dict-$VERSION.dmg"
rm -f "$DMG"
hdiutil create -volname "AI-Dict" -srcfolder "$WORK/root" -format UDZO -fs HFS+ "$DMG" -quiet
codesign --force --sign - "$DMG"
hdiutil verify "$DMG" -quiet

echo "$ROOT/$DMG"
shasum -a 256 "$DMG"
