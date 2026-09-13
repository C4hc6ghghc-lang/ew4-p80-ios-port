# EW4 Web Port r14-17 — Britain native infantry animation rebuild

Authority:
- Base mainline: r14-16 (`EW4_Web_Port_v0.61_r14-16_FRANCE_ANIM_NATIVE_FORMS.zip`).
- Original APK SHA-256: `20e609437a3659c5cc5573f7df70c75d48839a552e0120770a0afd8f068af05c`.
- Britain native country code in `def_motion.xml` and battle runtime: `gbr`.
- Native animation time base: 24 FPS.

## Implemented
Rebuilt and integrated 15 Britain-specific basic infantry definitions directly from original APK BILE motion resources:
- Militia gbr 1/2/3
- Line Infantry gbr 1/2/3
- Light Infantry gbr 1/2/3
- Grenadier gbr 1/2/3
- Guards gbr 1/2/3

Britain batch:
- 15 unit definitions
- 66 unique native motion assets
- Runtime-sheet bytes: 43928805
- Attack1 preserved for: Grenadier gbr 1, Grenadier gbr 2, Grenadier gbr 3, Guards gbr 1, Guards gbr 2, Guards gbr 3

Mainline after merge:
- 45 animated unit definitions
- 198 unique native motion assets
- source packs: generic infantry 15 + France infantry 15 + Britain infantry 15
- new manifest: `assets/data/native_animation_core45.json`
- runtime now loads `native_animation_core45.json`
- Service Worker cache advanced to `ew4-port-v061-r14-17-gbranim`

## Verification
- `node --check app.js`: PASS
- `node --check native_animation_controller.js`: PASS
- 23/23 JS regression tests: PASS
- native animation integration: 45 units / 198 motions: PASS
- all 198 runtime-sheet files exist: PASS
- all 198 runtime sheets have valid PNG signatures: PASS
- Britain Grenadier/Guards Attack1 coverage: PASS
- Handoff-only `animation_tools/test_native_animation_controller.js`: NOT RUNNABLE from handoff as packaged because `proof/militia_generic_3grade_pack/family_manifest.json` is absent. This is a handoff proof-fixture omission, not a mainline regression; mainline `test_native_animation_integration.js` passes.

## Truthfulness status
- Original evidence ✅: Britain `gbr` definitions/motions extracted from supplied APK.
- Code implemented ✅: assets + manifest + runtime/SW integration are in r14-17 tree and tested.
- Real iPhone verified ⏳: this exact r14-17 build still requires user deployment/recording.

## Next recommended micro-batch
Russia-specific basic infantry 15, then test/report. Do not redo Britain.
