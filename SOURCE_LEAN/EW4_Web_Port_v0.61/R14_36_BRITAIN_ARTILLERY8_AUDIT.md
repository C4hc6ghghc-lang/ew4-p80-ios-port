# EW4 Web Port v0.61 — r14-36 Britain Artillery 8 audit

## Scope
This micro-batch adds only the original British (`gbr`) artillery animation group on top of the verified r14-35 France-artillery baseline. No Russia/Austria/etc. artillery was started.

## Original APK targets
Eight British artillery definitions were read from original `def_motion.xml` and extracted from original BILE motion resources:

- Light Artillery gbr 1 / 2
- Heavy Artillery gbr 1 / 2
- Siege Artillery gbr 1 / 2
- Rocket gbr 1 / 2

All use original `army_artillery`, native anchor x=5, y=5, and the original 24 FPS time base.

## Native state shapes preserved
- Light Artillery 1/2: Ready -> Attack -> Reload -> Finish -> Ready
- Heavy Artillery 1/2: Ready -> Attack -> Reload -> Finish -> Ready
- Siege Artillery 1/2: Ready -> Attack -> Finish -> Ready; no invented Reload
- Rocket 1/2: Ready -> Attack -> Reload -> Ready; no invented Finish

## Native frame counts
- Light Artillery gbr 1/2: Ready 10, Attack 64, Reload 60, Finish 39
- Heavy Artillery gbr 1/2: Ready 10, Attack 64, Reload 60, Finish 39
- Siege Artillery gbr 1: Ready 10, Attack 64, Finish 67
- Siege Artillery gbr 2: Ready 10, Attack 64, Finish 66
- Rocket gbr 1: Ready 10, Attack 64, Reload 44
- Rocket gbr 2: Ready 10, Attack 64, Reload 68

## Asset production
- Added units: 8
- Added unique motions: 28
- Previous core: 241 units / 992 motions
- New core: 249 units / 1020 motions
- Runtime pack: `assets/data/native_animation_core249.json`
- Source manifest: `R14_36_BRITAIN_ARTILLERY8_SOURCE_MANIFEST.json`

No prior unit or asset id was overwritten.

## BILE cycle-guard continuity
The path-local BILE cycle guard introduced at r14-34 remains in use. Both British Siege Artillery Finish motions extracted completely (67 / 66 frames). No Finish was skipped or replaced with a static pose.

## Runtime geometry
Each new asset carries authoritative `world_union` geometry reconstructed from its per-asset extractor manifest. This is tested along with PNG existence/signature so a pack cannot pass merely because image files exist.

## Regression results
- Britain artillery unit coverage: 8/8 PASS
- Britain artillery motion coverage: 28/28 PASS
- Existing r14-35 units unchanged: 241/241 PASS
- Existing r14-35 motions unchanged: 992/992 PASS
- Runtime PNG existence/signature + world_union: 1020/1020 PASS
- `test_native_animation_integration.js`: PASS
- Full JS test suite: 23/23 PASS
- `node --check` updated runtime/test files: PASS

## Truthfulness boundary
Original evidence ✅: British unit names, resource mappings, anchors, motion shapes, frame counts and frames come from the original APK.

Code implemented ✅: core249, runtime sheets, app/SW references and regression checks are physically present in this checkpoint.

Real iPhone verified ⏳: this exact r14-36 checkpoint has not yet been visually verified on the user's iPhone, so no 1:1 visual claim is made.
