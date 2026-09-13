# EW4 Web Port r14-15 core-animation reconstruction

## Source recovery status
- Original APK pinned at `/mnt/data/ew4_takeover/reference/EW4_original_v1.4.42.apk` with SHA-256 `20e609437a3659c5cc5573f7df70c75d48839a552e0120770a0afd8f068af05c`.
- The only fully recoverable deploy tree was r14-9.
- r14-13 core map/unit fixes were reconstructed from the preserved audit and re-applied to a fresh mainline.
- The exact r14-12 native-form source edits were not recoverable as code; their audit is preserved but this reconstruction does not falsely claim those form edits are already restored.

## Re-applied core fixes
- Native Europe grid origin: `x=q*64`, `y=r*53+(q&1)*26.5`.
- Touch nearest-cell math uses the same origin.
- Static unit poses use `def_motion` ready x/y plus per-pose crop bounds rather than center/bottom-only placement.

## Native animation merge
- Added `native_animation_controller.js`.
- Added `assets/data/native_animation_infantry15.json`: 15 generic infantry definitions / 66 native motion assets.
- Added fixed-cell runtime sheets under `assets/unit_anim_native/assets/...`.
- Runtime uses native Attack0 -> optional Reload -> optional Finish -> Ready; Attack1 -> Ready.
- `weapon=guns` against fort/warship can select Attack1 where present.
- AI fast-forward time-compresses presentation only.
- Units not present in the native pack fall back to the existing static-pose renderer; no national skin is silently replaced by a generic animation.

## Validation
- `node --check app.js`: PASS
- `node --check native_animation_controller.js`: PASS
- 22/22 current JS tests: PASS
- Static HTTP smoke: index/app/sw/controller/manifest/sample runtime sheet all HTTP 200.

## Important remaining recovery gap
Before calling the UI mainline fully restored, the r14-12 form-layout work must be rebuilt again from `layout-568h.xml` / preserved audit. This snapshot intentionally prioritizes the map + unit-animation core and does not mislabel the old r14-9 Web form shells as restored r14-12 UI.
