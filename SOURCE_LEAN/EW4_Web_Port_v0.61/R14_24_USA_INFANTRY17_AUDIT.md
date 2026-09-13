# r14-24 USA complete infantry native-animation audit

## Scope
This micro-batch continues from the verified r14-23 Spain mainline. It adds the original United States (`usa`) country-specific recruit-infantry animation family only; cavalry/artillery are not claimed complete in this checkpoint.

## Original evidence
Source APK SHA-256:
`20e609437a3659c5cc5573f7df70c75d48839a552e0120770a0afd8f068af05c`

`assets/def_motion.xml` contains country-specific United States entries for all of the following recruit infantry definitions:
- Militia usa 1/2/3
- Line Infantry usa 1/2/3
- Light Infantry usa 1/2/3
- Grenadier usa 1/2/3
- Guards usa 1/2/3
- Machine Gun usa 1/2

The same native motion table also confirms that USA has country-specific cavalry and artillery entries; those remain future batches rather than being replaced with generic motion here.

## Implemented
- 17 new USA unit definitions.
- 72 new BILE-derived native motion assets.
- Native playback time base remains 24 FPS.
- Grenadier and Guards grades 1–3 retain alternate Attack1: 6/6.
- Machine Gun grades 1–2 retain native Ready -> Attack -> Finish behavior; attack speed attribute = 2.5.
- Runtime manifest: `assets/data/native_animation_core153.json`.
- Mainline totals: 153 unit definitions / 648 unique motion assets.
- USA runtime-sheet PNG payload in this batch: 47,346,429 bytes.

## Regression / integrity checks
- Exact preservation check against r14-23 core136:
  - prior unit records: 136/136 unchanged
  - prior asset records: 576/576 unchanged
- USA unit coverage: 17/17.
- USA motion coverage: 72/72.
- USA Attack1 coverage: 6/6.
- USA Machine Gun coverage: 2/2.
- Every core153 runtime sheet exists and has a valid PNG signature: 648/648.
- `node --check app.js`: PASS.
- `node --check native_animation_controller.js`: PASS.
- JS regression suite: 23/23 PASS.

## Truthfulness boundary
- Original APK evidence ✅
- Code integrated + tested ✅
- Exact r14-24 iPhone/Safari visual verification ⏳ — requires user deployment/recording of this exact build.
