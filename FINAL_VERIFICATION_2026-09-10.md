# EW4 R14-39 P35 Final Native Presentation — Verification

> P35 supersedes P34 as the authoritative PORT_ONLY local candidate. No claim is made that this build environment performed a physical iPhone/original side-by-side capture.

## Baseline / source policy
P35 continues the reconstructed single-player project. The original APK/AAB binary is intentionally excluded from this distribution.

## JS regression
- Full suite: **122/122 PASS**.
- Repeated full suite: **5/5 runs at 122/122 PASS**.
- New P35 regressions cover HiDPI logical/backing separation, CSS-transformed touch inversion, iOS shell cleanup, map/unit native-ref asset integrity and all-battle-unit READY resolution.

## Service Worker CORE
- **1054/1054 present; missing=0**.
- Cache generation: `posthandoff49-p35-native-presentation`, chosen to force a new runtime while remaining compatible with historical cache-generation contracts.

## P35 presentation hardening
- 568x320 remains the authoritative battle logical coordinate system.
- Canvas backing scales with device density/stage scale up to 4x, preventing whole-stage low-resolution browser upscale.
- Battle touch uses `clientX/clientY -> getBoundingClientRect -> 568x320` inverse mapping; battle pointer handlers no longer depend on `offsetX/offsetY`.
- Conquest country preview receives equivalent HiDPI raster hardening without moving logical markers.
- Unit scale, native refpoints, native hex centers, camera/LOD constants and P34 z-order are unchanged.
- Public title/manifest no longer expose Web-port wording; iOS standalone/touch shell is hardened; legacy save keys remain unchanged.
- P33/P34 impact timing, transport, StageIntro/Talk and low-zoom closures remain intact.

## Map/unit integrity
- 161 critical native-ref sprites validated.
- 877/877 READY visuals validated.
- 7407/7407 battle units resolve a READY visual.
- Sprite/READY/terrain manifest file references: missing=0.

## User MOD locks
Player unit rules remain attack +4/+4, base troop HP +120, movement +2; AI unchanged. Existing general/princess/resource/consumable modifications remain inherited.

## Protected P21+ core hash guard
- `native_upgrade_core.js` = `2ae064cb5d8c3733945b970ef255cefa7c5b2ae4981f26099182f4206da7204c` MATCH
- `battle_save_core.js` = `4858c7f862dac736d3624b8e64567af1484382b63bd8482aa544cd3204272dc2` MATCH
- `assets/data/native_warzone_tech.json` = `1c7a9d71d1f33cee03262908e8aa1195e543b44a53ef584a81dcdcbda0170da1` MATCH
- `assets/data/def_warzonetech.xml` = `35320e99f2c39ac998c92340cb221653ae3f2c9fe8bb24b9ee3bfb321efe64db` MATCH

## Package preflight
- Pre-package direct APK/AAB: **0**.
- Nested ZIPs scanned: **12**.
- Nested APK/AAB entries: **0**.
- Nested scan errors: **0**.
- Machine-readable evidence: `P35_SERVICE_WORKER_AUDIT.json`, `P35_PROTECTED_CORE_HASHES.json`, `P35_BINARY_SCAN.json`.

## Remaining non-code uncertainty
A physical iPhone/original side-by-side may still expose device-specific font rasterization, WebKit/GPU compositing or a subjective few-pixel difference. That is a final acceptance smoke-test uncertainty, not an unresolved local map/unit production rule.
