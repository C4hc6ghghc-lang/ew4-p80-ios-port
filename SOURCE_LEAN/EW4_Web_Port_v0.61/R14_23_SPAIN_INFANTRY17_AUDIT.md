# EW4 Web Port v0.61 — r14-23 Spain Infantry 17 Native Animation Audit

## Scope
This micro-batch adds Spain-specific complete infantry animation coverage only. It starts from the tested r14-22 Ottoman mainline and does not add Spanish cavalry/artillery yet.

## Original evidence
Authoritative APK SHA-256:
`20e609437a3659c5cc5573f7df70c75d48839a552e0120770a0afd8f068af05c`

Original `def_motion.xml` visual code: `spa`.

Spain has a full land visual group in the APK:
- Infantry: 17 definitions
- Cavalry: 8 definitions
- Artillery: 8 definitions

This batch implements the infantry 17:
- Militia spa 1/2/3
- Line Infantry spa 1/2/3
- Light Infantry spa 1/2/3
- Grenadier spa 1/2/3
- Guards spa 1/2/3
- Machine Gun spa 1/2

## Native motion production
Extracted from original BILE containers using the already-verified decoder.

Result:
- 17 units
- 72 unique motion assets
- 24 FPS native time base
- 6 Attack1 branches: Grenadier 1/2/3 + Guards 1/2/3
- Machine Gun 1/2: Ready -> Attack -> Finish
- Machine Gun attack speed attribute: 2.5

## Mainline integration
Previous r14-22:
- 119 animated unit definitions
- 504 motion assets
- `native_animation_core119.json`

New r14-23:
- 136 animated unit definitions
- 576 motion assets
- `assets/data/native_animation_core136.json`
- source pack tag: `spain_infantry17`

Runtime changes:
- `app.js` loads `native_animation_core136.json`
- Service Worker cache: `ew4-port-v061-r14-23-spainanim`

## Regression protection
Verified after integration:
- previous 119 unit records unchanged
- previous 504 asset records unchanged
- Spain units: 17/17 present
- Spain motion assets: 72/72 present
- Spain Attack1: 6/6 present
- Spain Machine Gun: 2/2 present with native state sequence and speed 2.5
- runtime PNG sheets: 576/576 present with valid PNG signatures
- full JS suite: 23/23 PASS
- `app.js` syntax PASS
- `native_animation_controller.js` syntax PASS

## Truthfulness boundary
Original evidence ✅
Code implemented ✅
Regression tested ✅
Real iPhone visual verification ⏳

Do not call this exact r14-23 build visually 1:1 until it is deployed and checked on the user's iPhone.
