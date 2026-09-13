# EW4 Web Port v0.61 — r14-35 France Artillery 8 audit

## Scope
This micro-batch adds only the original French (`fra`) artillery animation group on top of the verified r14-34 generic-artillery baseline. No Britain/Russia/etc. artillery was started in this batch.

## Original APK targets
Eight French artillery unit definitions were read from original `def_motion.xml` and extracted from the APK BILE motion resources:

- Light Artillery fra 1 / 2
- Heavy Artillery fra 1 / 2
- Siege Artillery fra 1 / 2
- Rocket fra 1 / 2

All use the original `army_artillery` motion container and native anchor x=5, y=5.

## Native state shapes preserved
- Light Artillery 1/2: Ready -> Attack -> Reload -> Finish -> Ready
- Heavy Artillery 1/2: Ready -> Attack -> Reload -> Finish -> Ready
- Siege Artillery 1/2: Ready -> Attack -> Finish -> Ready (no invented Reload)
- Rocket 1/2: Ready -> Attack -> Reload -> Ready (no invented Finish)

## Native frame counts
- Light Artillery fra 1/2: Ready 10, Attack 64, Reload 60, Finish 39
- Heavy Artillery fra 1/2: Ready 10, Attack 64, Reload 60, Finish 39
- Siege Artillery fra 1: Ready 10, Attack 64, Finish 67
- Siege Artillery fra 2: Ready 10, Attack 64, Finish 66
- Rocket fra 1: Ready 10, Attack 64, Reload 44
- Rocket fra 2: Ready 10, Attack 64, Reload 68

Native time base remains 24 FPS.

## Asset production
- Added units: 8
- Added unique motions: 28
- Previous core: 233 units / 964 motions
- New core: 241 units / 992 motions
- Runtime pack: `assets/data/native_animation_core241.json`
- Source manifest: `R14_35_FRANCE_ARTILLERY8_SOURCE_MANIFEST.json`

The 28 French assets are distinct from the previous r14-34 core; no existing asset id or unit definition was overwritten.

## BILE cycle-guard continuity
r14-34 introduced a path-local BILE cycle guard after original Siege Artillery Finish exposed a recursive resource reference. The same corrected extractor was used for French Siege Artillery. Both French Siege Finish motions extracted completely (67 / 66 frames); no Finish state was skipped or substituted.

The r14-34 regression that re-extracted normal Light Artillery assets byte-identically remains the safety evidence that the guard does not alter non-cyclic resources.

## Integration correction caught during this batch
The family-pack builder intentionally emits compact asset entries and does not include `world_union` in the family-level JSON. A first integration check correctly failed on this missing runtime geometry field. r14-35 reconstructs `world_union` from each extracted BILE asset's authoritative `manifest.json` before merging into core241; the integration test then passes.

This prevents a false-green package in which frames exist but native overlay geometry is incomplete.

## Regression results
- France artillery unit coverage: 8/8 PASS
- France artillery motion coverage: 28/28 PASS
- Existing r14-34 units unchanged: 233/233 PASS
- Existing r14-34 motions unchanged: 964/964 PASS
- Runtime PNG existence/signature: 992/992 PASS
- `test_native_animation_integration.js`: PASS
- Full JS test suite: 23/23 PASS
- `node --check` for updated runtime/test files: PASS

## Truthfulness boundary
Original evidence ✅: French artillery names, resources, anchors, motion states, frame counts and BILE frames come from the original APK.

Code implemented ✅: core241, runtime sheets, app/SW references and regression coverage are physically present in this checkpoint.

Real iPhone verified ⏳: this exact r14-35 checkpoint has not yet been visually verified on the user's iPhone, so no 1:1 visual claim is made.
