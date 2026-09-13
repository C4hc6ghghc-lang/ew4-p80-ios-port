#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPORT="$PWD/visual-results"
mkdir -p "$REPORT"
xcrun simctl list devices available --json > "$REPORT/devices.json"
python3 - "$REPORT/devices.json" > "$REPORT/selected-devices.tsv" <<'PY'
import json,sys
catalog=json.load(open(sys.argv[1]))['devices']
runtime=next(k for k in catalog if 'iOS-18-5' in k)
for family in ('iPhone','iPad'):
    device=next(d for d in catalog[runtime] if d['name'].startswith(family) and d.get('isAvailable'))
    print(f"{family}\t{device['udid']}")
PY
cd "$ROOT/iOSApp"
xcodegen generate --spec project.yml
failed=0
while IFS=$'\t' read -r family udid; do
  xcrun simctl boot "$udid" || true
  xcrun simctl bootstatus "$udid" -b
  if xcodebuild -project EW4NativePort.xcodeproj -scheme EW4NativePort -configuration Release \
    -destination "platform=iOS Simulator,id=$udid" -derivedDataPath "$ROOT/build/VisualData" \
    -resultBundlePath "$REPORT/$family.xcresult" -parallel-testing-enabled NO \
    CODE_SIGNING_ALLOWED=NO test > "$REPORT/$family-test.log" 2>&1; then
    echo "VISUAL_UI_TEST_PASS: $family"
  else
    failed=1
    tail -n 70 "$REPORT/$family-test.log"
  fi
  xcrun xcresulttool export attachments --path "$REPORT/$family.xcresult" \
    --output-path "$REPORT/$family-screenshots" || true
  xcrun simctl spawn "$udid" log show --last 15m --style compact \
    --predicate 'subsystem == "local.ew4.nativeport"' > "$REPORT/$family-startup.log" 2>&1 || true
  xcrun simctl shutdown "$udid" || true
done < "$REPORT/selected-devices.tsv"
exit "$failed"
