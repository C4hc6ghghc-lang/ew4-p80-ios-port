# EW4 Web Port v0.61 — r14-22 Ottoman Infantry 17 Native Animation Audit

## Scope
This micro-batch starts from the preserved r14-21 Prussia-complete mainline and adds the complete Ottoman (`tur`) recruitable infantry animation set. No cavalry, artillery, navy, fort, map, campaign, general/HQ, commerce, or reinforcement logic was redesigned in this batch.

## Original evidence
Authoritative source APK:
`ouluzhanzheng4_v1.4.42_uhrfojh_anfensi.com(1)(3).apk`
SHA-256 previously verified against the handoff baseline:
`20e609437a3659c5cc5573f7df70c75d48839a552e0120770a0afd8f068af05c`

`def_motion.xml` contains the Ottoman country-specific infantry visual code `tur` with exactly these recruitable infantry definitions:
- Militia tur 1/2/3
- Line Infantry tur 1/2/3
- Light Infantry tur 1/2/3
- Grenadier tur 1/2/3
- Guards tur 1/2/3
- Machine Gun tur 1/2

That is 17 unit definitions.

## Native animation extraction
All motions were extracted from the original APK BILE containers using the already-verified BILE decoder and original affine transforms.

Results:
- 17 Ottoman unit definitions
- 72 unique native motion assets
- 24 FPS native time base
- Grenadier 1/2/3: Attack1 preserved
- Guards 1/2/3: Attack1 preserved
- Machine Gun 1/2: native `Ready -> Attack -> Finish` chain
- Machine Gun Attack speed attribute: 2.5

No French/British/Russian/Austrian/Prussian animation was substituted for an Ottoman unit.

## Mainline integration
Previous r14-21 baseline:
- 102 animated unit definitions
- 432 native motion assets

New r14-22 mainline:
- 119 animated unit definitions
- 504 native motion assets

Runtime manifest:
`assets/data/native_animation_core119.json`

Source-pack lineage now records:
- generic_infantry15
- france_infantry15
- britain_infantry15
- russia_infantry15
- machinegun_completion_generic_fra_gbr_rus_8
- austria_infantry17
- prussia_infantry17
- ottoman_infantry17

`app.js` now loads `native_animation_core119.json`.
Service Worker cache key advanced to:
`ew4-port-v061-r14-22-ottomananim`

## Regression and integrity checks
Incremental preservation check:
- all prior 102 unit records structurally identical
- all prior 432 asset records structurally identical
- 17/17 Ottoman units present
- 72/72 new Ottoman runtime PNG sheets present and valid PNGs
- Attack1 6/6 present for Ottoman Grenadier/Guards grades 1-3
- Machine Gun 2/2 uses Ready/Attack/Finish and attack speed 2.5

Full JS regression suite after integration:
- 23/23 PASS

The data-integrity test continues to protect Coastal Fort / 海防炮 from disappearing from the original army tree.

## Truthfulness status
- Original APK evidence: VERIFIED
- BILE extraction: VERIFIED
- Code integration: VERIFIED
- Automated regression: VERIFIED
- Exact-build iPhone/Safari visual verification: NOT YET VERIFIED

Do not call the result visually 1:1 until this exact r14-22 build is tested on the user's device.

## Next recommended micro-batch
Do not redo Ottoman infantry. The next logical national infantry batch is Spain (`spa`) 17 if continuing the same production line, but before declaring all infantry complete, preserve the country-code/visual-code audit because many smaller states have their own native visual families.
