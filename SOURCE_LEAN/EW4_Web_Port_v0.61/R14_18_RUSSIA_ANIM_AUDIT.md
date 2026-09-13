# EW4 Web Port r14-18 — Russia native infantry animation rebuild

Authority:
- Base mainline: r14-17 (`EW4_Web_Port_v0.61_r14-17_BRITAIN_ANIM.zip`).
- Original APK SHA-256: `20e609437a3659c5cc5573f7df70c75d48839a552e0120770a0afd8f068af05c`.
- Russia native country code in `def_motion.xml`: `rus`.
- Native animation time base: 24 FPS.

## Implemented
Rebuilt and integrated 15 Russia-specific basic infantry definitions directly from original APK BILE motion resources:
- Militia rus 1/2/3
- Line Infantry rus 1/2/3
- Light Infantry rus 1/2/3
- Grenadier rus 1/2/3
- Guards rus 1/2/3

Russia batch:
- 15 unit definitions
- 66 unique native motion assets
- Runtime-sheet bytes: 41,568,704
- Attack1 preserved for: Grenadier rus 1/2/3 and Guards rus 1/2/3

Mainline after merge:
- 60 animated unit definitions
- 264 unique native motion assets
- source packs: generic infantry 15 + France infantry 15 + Britain infantry 15 + Russia infantry 15
- new manifest: `assets/data/native_animation_core60.json`
- runtime now loads `native_animation_core60.json`
- Service Worker cache advanced to `ew4-port-v061-r14-18-rusanim`
- all 45 pre-r14-18 unit mappings and all 198 pre-r14-18 asset metadata entries are preserved byte-for-byte at the parsed JSON value level

## Verification
- `node --check app.js`: PASS
- `node --check native_animation_controller.js`: PASS
- 23/23 JS regression tests: PASS
- native animation integration: 60 units / 264 motions: PASS
- all 66 Russia runtime-sheet files exist: PASS
- all 66 Russia runtime sheets have valid PNG signatures: PASS
- Russia Grenadier/Guards Attack1 coverage (6 units): PASS
- Britain r14-17 unit/asset mappings preserved: PASS

## Truthfulness status
- Original evidence ✅: Russia `rus` definitions/motions extracted from supplied APK.
- Code implemented ✅: assets + manifest + runtime/SW integration are in r14-18 tree and tested.
- Real iPhone verified ⏳: this exact r14-18 build still requires user deployment/recording.

## Known limitation carried forward
This batch extends country-specific basic infantry only. Russia cavalry/artillery/navy/fort animations are not claimed complete. Austria/Prussia/Ottoman country-specific basic infantry are also not yet integrated.

## Next recommended micro-batch
Austria-specific basic infantry 15, then test/report. Do not redo Britain or Russia.
