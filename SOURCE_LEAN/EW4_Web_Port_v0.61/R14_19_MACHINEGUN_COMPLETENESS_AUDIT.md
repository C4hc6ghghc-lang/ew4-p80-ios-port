# EW4 Web Port r14-19 — Machine Gun infantry completeness correction

## Why this patch exists
The previous r14-16/r14-17/r14-18 reports used an overly narrow phrase, "15 basic infantry". That covered five 3-grade infantry families but omitted the sixth recruit-card family: Machine Gun.

Original APK evidence:
- `def_army.xml`: `Machine Gun` is explicitly `type="infantry"` and `weapon="mgun"`.
- Machine Gun has two grades only (grade 0 and grade 1), unlike Militia / Line Infantry / Light Infantry / Grenadier / Guards, which each have three grades.
- Therefore a complete animated national infantry roster is 5 x 3 + 2 = 17 unit definitions.
- `def_motion.xml`: Machine Gun uses `res="army_armoredcar"` and native motion chain Ready / Attack / Finish (no Reload), with Attack `speed="2.5"`.

## Implemented
Added the eight missing Machine Gun native animation definitions to the current mainline:
- Machine Gun 1 / 2 (generic)
- Machine Gun fra 1 / 2
- Machine Gun gbr 1 / 2
- Machine Gun rus 1 / 2

Each definition contains three native motions:
- Ready: 20 frames
- Attack: 72 frames, speed 2.5
- Finish: grade 1 = 27 frames; grade 2 = 30 frames

Patch delta:
- +8 unit definitions
- +24 native motion assets
- core60 -> core68
- 60 -> 68 animated unit definitions
- 264 -> 288 native motion assets

This makes the already-covered groups complete at the infantry-recruit-family level:
- generic: 17
- France: 17
- Britain: 17
- Russia: 17

## Runtime integration
- New manifest: `assets/data/native_animation_core68.json`
- `app.js` loads core68
- `sw.js` pre-caches core68
- cache key: `ew4-port-v061-r14-19-machinegunfix`

## Verification
- `node --check app.js`: PASS
- `node --check native_animation_controller.js`: PASS
- 23/23 JS regression tests: PASS
- native animation integration: 68 units / 288 motions: PASS
- all eight Machine Gun definitions present: PASS
- each Machine Gun definition uses Ready / Attack / Finish only: PASS
- each Machine Gun Attack speed attribute = 2.5: PASS
- all referenced runtime-sheet files exist: PASS

## Truthfulness / migration rule going forward
Do not call a country infantry animation set complete at 15 units. For countries with the original six recruit families, the correct complete target is 17 definitions: 15 from the five 3-grade families + 2 Machine Gun grades.

Real iPhone visual verification for this exact r14-19 build remains pending.
