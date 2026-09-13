#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPORT="$PWD/smoke-results"
mkdir -p "$REPORT"
cd "$ROOT/iOSApp"
xcodegen generate --spec project.yml
xcodebuild -project EW4NativePort.xcodeproj -scheme EW4NativePort -configuration Release \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$ROOT/build/SimulatorData" CODE_SIGNING_ALLOWED=NO build > "$REPORT/simulator-build.log" 2>&1
APP="$ROOT/build/SimulatorData/Build/Products/Release-iphonesimulator/EW4NativePort.app"
test -d "$APP"
xcrun simctl list devices available --json > "$REPORT/devices.json"
python3 - "$REPORT/devices.json" > "$REPORT/selected-devices.tsv" <<'PY'
import json,sys
catalog=json.load(open(sys.argv[1]))['devices']
runtime=next((k for k in catalog if 'iOS-18-5' in k),None)
if not runtime:
    runtime=next(k for k in sorted(catalog,reverse=True) if '.iOS-' in k)
devices=catalog[runtime]
for family in ('iPhone','iPad'):
    device=next(d for d in devices if d['name'].startswith(family) and d.get('isAvailable'))
    print(f"{family}\t{device['udid']}")
PY
while IFS=$'\t' read -r family udid; do
  xcrun simctl boot "$udid" || true
  xcrun simctl bootstatus "$udid" -b
  xcrun simctl install "$udid" "$APP"
  xcrun simctl launch "$udid" local.ew4.nativeport | tee "$REPORT/$family-launch.txt"
  sleep 15
  xcrun simctl spawn "$udid" launchctl list > "$REPORT/$family-processes.txt"
  grep 'local.ew4.nativeport' "$REPORT/$family-processes.txt" | tee "$REPORT/$family-alive.txt"
  xcrun simctl io "$udid" screenshot "$REPORT/$family.png"
  xcrun simctl terminate "$udid" local.ew4.nativeport
  xcrun simctl shutdown "$udid"
done < "$REPORT/selected-devices.tsv"
echo 'SIMULATOR_LAUNCH_SMOKE_PASS: iPhone and iPad'
