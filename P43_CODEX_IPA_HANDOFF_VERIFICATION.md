# P43 Codex / IPA Handoff Hardening — verification

P43 is a hardening checkpoint on the unified `P39 -> P40 -> P41 -> P42 -> P43` mainline. It does not restart or redesign the game.

## Verified in the current Linux environment

- Preserved mature `SOURCE_LEAN`: **6321 / 6321 exact SHA-256**, missing 0, changed 0.
- P42 -> P43 native preservation: existing native files missing 0; only three existing build/handoff files intentionally changed (`iOSApp/project.yml`, `iOSApp/App/EW4NativePortApp.swift`, `Tools/build_unsigned_ipa.sh`). No existing gameplay/AI/Campaign/save/combat Core file changed.
- Swift native regression: **55 / 55 PASS**.
- P39/P42 mature JS reference regression: **126 / 126 PASS**.
- Native real-resource audit: 101 battles; 7407/7407 unit visuals; 5482/5482 eligible building sprites; 877 animation units; 3519 motions; compact BILE 12/12; `errors=[]`.
- iOS Swift source parse: PASS.
- Native IPA preflight: PASS, 26 checks.
- Native resource snapshot: **1751 / 1751 exact SHA-256**.
- Resource collision audit: **232 case-insensitive duplicate-basename groups**; therefore resource hierarchy preservation is mandatory.
- Linux fail-closed build-gate test: PASS. The one-command build runs preflight/tests/resource audit and then stops at the unavailable XcodeGen/iPhoneOS step with exit code 2; no fake IPA is emitted.

## P43 build-specific hardening

- XcodeGen now declares `../Resources` as `type: folder` + `buildPhase: resources` so directory namespaces survive bundle copying.
- Release app startup no longer runs the full resource auditor; the expensive audit is DEBUG/build-preflight only.
- Added a Swift noon-regression lock for 568x320, camera/LOD, touch thresholds, native half-scale and battle-corner HUD geometry.
- Added full native-resource SHA-256 manifest and full mature-SOURCE_LEAN SHA-256 freeze.
- Added post-Xcode build gates for arm64, WebKit/JavaScriptCore linkage, bundle resource hierarchy, forbidden Web/APK/AAB payload files, IPA CRC and SHA-256.
- Replaced stale P36-era `START_HERE.md` / `NEXT_MODEL_PROMPT.txt` instructions with the P43 unified-mainline/Codex contract.

## Not verified here

No Xcode/iPhoneOS SDK is installed in the Linux environment, so an actual arm64 `.app`/IPA build is **not claimed**. On macOS/Codex the authoritative entrypoint is package-root `./BUILD_FROM_CODEX_MAC.sh`; it must pass all gates before an unsigned IPA is accepted.
