#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPORT_DIR="$ROOT/build/reports"
mkdir -p "$REPORT_DIR"

say() { printf '\n== %s ==\n' "$*"; }
die() { echo "ERROR: $*" >&2; exit 2; }

say "EW4 Native preflight"
python3 "$ROOT/Tools/native_ipa_preflight.py" --report "$REPORT_DIR/native_preflight.json"
python3 "$ROOT/Tools/xcode_candidate_static_gate.py" --report "$REPORT_DIR/xcode_candidate_static_gate.json"

say "Apple build-tool availability"
command -v xcodegen >/dev/null || die "xcodegen required (recommended: brew install xcodegen)"
command -v xcodebuild >/dev/null || die "full Xcode + iPhoneOS SDK required"
command -v xcrun >/dev/null || die "xcrun required"
xcrun --sdk iphoneos --show-sdk-path >/dev/null || die "iPhoneOS SDK unavailable"
{
  echo "xcode-select: $(xcode-select -p 2>/dev/null || true)"
  xcodebuild -version
  xcodegen --version
  xcrun swift --version
  xcrun --sdk iphoneos --show-sdk-path
} | tee "$REPORT_DIR/apple_toolchain_versions.log"

SWIFT_MAJOR="$(xcrun swift --version | python3 -c 'import re,sys; s=sys.stdin.read(); m=re.search(r"Swift version\s+(\d+)",s); print(m.group(1) if m else "")')"
[ -n "$SWIFT_MAJOR" ] || die "could not parse Apple Swift version"
[ "$SWIFT_MAJOR" -ge 6 ] || die "Swift 6+ required by swift-tools-version 6.0; selected toolchain reports Swift $SWIFT_MAJOR"
XCODE_MAJOR="$(xcodebuild -version | python3 -c 'import re,sys; s=sys.stdin.read(); m=re.search(r"Xcode\s+(\d+)",s); print(m.group(1) if m else "")')"
[ -n "$XCODE_MAJOR" ] || die "could not parse Xcode version"
[ "$XCODE_MAJOR" -ge 16 ] || die "Xcode 16+ required for this Swift 6 handoff; selected Xcode is $XCODE_MAJOR"

say "Swift parity/regression tests"
(
  cd "$ROOT/NativeCore"
  swift test 2>&1 | tee "$REPORT_DIR/swift_test.log"
)
SWIFT_TESTING_COUNT="$(python3 - "$REPORT_DIR/swift_test.log" <<'PY'
import re,sys
s=open(sys.argv[1],encoding='utf-8',errors='replace').read()
m=re.findall(r'Test run with (\d+) tests\b[^\n]*\bpassed\b',s)
print(m[-1] if m else '')
PY
)"
XCTEST_COUNT="$(python3 - "$REPORT_DIR/swift_test.log" <<'PY'
import re,sys
s=open(sys.argv[1],encoding='utf-8',errors='replace').read()
m=re.findall(r'Executed (\d+) tests, with 0 failures.* seconds',s)
print(m[-1] if m else '')
PY
)"
[ -n "$SWIFT_TESTING_COUNT" ] || die "Swift Testing success summary not found"
[ "$SWIFT_TESTING_COUNT" -ge 286 ] || die "Swift Testing count regressed below P80 baseline: $SWIFT_TESTING_COUNT < 286"
[ -n "$XCTEST_COUNT" ] || die "XCTest success summary not found"
[ "$XCTEST_COUNT" -ge 9 ] || die "XCTest count regressed below P80 baseline: $XCTEST_COUNT < 9"
echo "P80 native test floor: SwiftTesting=$SWIFT_TESTING_COUNT XCTest=$XCTEST_COUNT" | tee "$REPORT_DIR/native_test_floor.log"

say "Full real-resource audit"
(
  cd "$ROOT/NativeCore"
  swift run EW4NativeAudit "$ROOT/Resources" 2>&1 | tee "$REPORT_DIR/native_resource_audit.json"
)
python3 - "$REPORT_DIR/native_resource_audit.json" <<'PY'
import json,sys
p=sys.argv[1]
s=open(p,encoding='utf-8').read()
start=s.find('{')
if start<0: raise SystemExit('audit JSON not found')
d=json.loads(s[start:])
assert d.get('errors') == [], d.get('errors')
assert d.get('battleCount') == 101, d
assert d.get('battleUnitVisualResolved') == d.get('battleUnitCount') == 7407, d
assert d.get('battleObjectSpriteResolved') == d.get('battleObjectSpriteEligible') == 5482, d
assert d.get('animationUnitCount') == 877, d
assert d.get('defMotionMotionCount') == 3519, d
assert d.get('bileDecoded') == d.get('bileResourceCount') == 12, d
print('resource audit contract: PASS')
PY

say "Generate + validate Xcode project"
cd "$ROOT/iOSApp"
rm -rf EW4NativePort.xcodeproj
xcodegen dump --spec project.yml > "$REPORT_DIR/xcodegen_resolved_spec.yml"
xcodegen generate --spec project.yml
[ -d EW4NativePort.xcodeproj ] || die "XcodeGen did not create EW4NativePort.xcodeproj"
xcodebuild -project EW4NativePort.xcodeproj -list -json | tee "$REPORT_DIR/xcodebuild_list.json"
python3 - "$REPORT_DIR/xcodebuild_list.json" <<'PY'
import json,sys
j=json.load(open(sys.argv[1]))
p=j.get('project',{})
assert 'EW4NativePort' in p.get('targets',[]), p
assert 'EW4NativePort' in p.get('schemes',[]), p
print('generated Xcode target/scheme: PASS')
PY
xcodebuild \
  -resolvePackageDependencies \
  -project EW4NativePort.xcodeproj \
  -scheme EW4NativePort \
  2>&1 | tee "$REPORT_DIR/xcodebuild_resolve_packages.log"

say "Unsigned Release iphoneos build"
rm -rf "$ROOT/build/DerivedData" "$ROOT/build/Payload"
mkdir -p "$ROOT/build/Payload" "$REPORT_DIR"
xcodebuild \
  -project EW4NativePort.xcodeproj \
  -scheme EW4NativePort \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$ROOT/build/DerivedData" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY='' \
  build 2>&1 | tee "$REPORT_DIR/xcodebuild_release.log"

APP="$(find "$ROOT/build/DerivedData/Build/Products/Release-iphoneos" -maxdepth 1 -type d -name '*.app' -print -quit)"
[ -n "$APP" ] && [ -d "$APP" ] || die "Release .app not found"
APP_NAME="$(basename "$APP" .app)"
EXEC="$APP/$APP_NAME"
[ -x "$EXEC" ] || die "app executable missing: $EXEC"
PLIST="$APP/Info.plist"
[ -f "$PLIST" ] || die "built Info.plist missing"
plutil -lint "$PLIST" | tee "$REPORT_DIR/info_plist_lint.log"
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$PLIST" 2>/dev/null || true)"
[ "$BUNDLE_ID" = "local.ew4.nativeport" ] || die "unexpected CFBundleIdentifier: $BUNDLE_ID"
/usr/libexec/PlistBuddy -c 'Print :UISupportedInterfaceOrientations' "$PLIST" > "$REPORT_DIR/orientations.txt" 2>&1 || die "UISupportedInterfaceOrientations missing"
grep -q 'UIInterfaceOrientationLandscapeLeft' "$REPORT_DIR/orientations.txt" || die "LandscapeLeft missing"
grep -q 'UIInterfaceOrientationLandscapeRight' "$REPORT_DIR/orientations.txt" || die "LandscapeRight missing"

say "Post-build architecture/linkage/resource gates"
xcrun lipo -info "$EXEC" | tee "$REPORT_DIR/lipo.txt"
xcrun lipo -info "$EXEC" | grep -qw arm64 || die "Release executable is not arm64"
if command -v otool >/dev/null; then
  otool -L "$EXEC" | tee "$REPORT_DIR/otool.txt"
  if grep -Eq '/(WebKit|JavaScriptCore)\.framework/' "$REPORT_DIR/otool.txt"; then
    die "native executable unexpectedly links WebKit/JavaScriptCore"
  fi
fi

for rel in \
  Resources/Data/battles_runtime.json \
  Resources/Data/worldmaps.json \
  Resources/Data/native_animation_core877.json \
  Resources/Bile/def_motion.xml \
  Resources/Maps/europe.png \
  Resources/Maps/america.png \
  Resources/Audio/battle1.mp3 \
  Resources/sprite_manifest.json; do
  [ -f "$APP/$rel" ] || die "bundle resource hierarchy broken; missing $rel"
done
[ ! -f "$APP/battles_runtime.json" ] || die "resource flattening detected"

if find "$APP" -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.html' -o -name '*.apk' -o -name '*.aab' \) -print -quit | grep -q .; then
  find "$APP" -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.html' -o -name '*.apk' -o -name '*.aab' \) -print >&2
  die "forbidden Web/APK/AAB payload found in native app"
fi

say "Create unsigned IPA"
cp -R "$APP" "$ROOT/build/Payload/"
IPA="$ROOT/build/EW4NativePort-unsigned.ipa"
rm -f "$IPA"
(cd "$ROOT/build" && /usr/bin/zip -qry "$(basename "$IPA")" Payload)
unzip -t "$IPA" > "$REPORT_DIR/ipa_zip_test.log"
python3 "$ROOT/Tools/verify_ipa_payload.py" "$IPA" --report "$REPORT_DIR/ipa_verify.json"

if command -v shasum >/dev/null; then
  shasum -a 256 "$IPA" | tee "$IPA.sha256"
elif command -v sha256sum >/dev/null; then
  sha256sum "$IPA" | tee "$IPA.sha256"
fi

say "PASS"
echo "Unsigned IPA: $IPA"
echo "Reports:      $REPORT_DIR"
