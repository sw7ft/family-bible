#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ -f .device ]]; then
  DEVICE="$(tr -d '[:space:]' < .device)"
else
  DEVICE="${DEVICE_ID:-}"
fi
if [[ -z "$DEVICE" ]]; then
  echo "Create .device with your iPhone UDID, or set DEVICE_ID." >&2
  exit 1
fi
python3 make-icon.py
/opt/homebrew/bin/xcodegen generate
DD="$PWD/.derivedData"
xcodebuild -project FamilyBible.xcodeproj -scheme FamilyBible \
  -destination "id=$DEVICE" \
  -derivedDataPath "$DD" \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  DEVELOPMENT_TEAM=RB6YQW2B5J \
  CODE_SIGN_STYLE=Automatic \
  -configuration Debug \
  build
APP="$DD/Build/Products/Debug-iphoneos/Family Bible.app"
echo "APP=$APP"
xcrun devicectl device install app --device "$DEVICE" "$APP" --timeout 180
xcrun devicectl device process launch --device "$DEVICE" com.sw7ft.quietbible || true
echo "DONE $(date)"
