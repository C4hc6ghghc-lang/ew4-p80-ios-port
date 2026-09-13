# EW4 r14-39 post-handoff patch 3 — Rocket native visual timeline

Scope: one small original-fidelity batch after patch 2. No gameplay-stat changes.

## Integrated
- `rocket 1 right/left` and `rocket 2 right/left` use the original `def_effectsanim.xml` three-cue timing: **1.6 / 1.8 / 2.0 seconds**.
- Each cue uses the original `effect_rocket1.xml` and `sfx_rocket.wav`.
- Original cue offsets are preserved: grade 1 right `(25,-23)`, left `(-25,-23)`; grade 2 right `(12,-20)`, left `(-12,-20)`.
- Original left rotation is **220°**; it is not replaced with a generic 180° mirror.
- Parsed both native emitters from `effect_rocket1.xml`: `cloud` and additive `firecloud`, using the existing original `eff.png` atlas.

## Deliberately not integrated
- `effect_rocket2.xml` is present in the APK but is not referenced by the four normal Rocket attack timelines above; it is therefore not substituted into them.
- `effect_rocketartillery1.xml` / `effect_rocketartillery2.xml` are not hooked in this patch because their actual runtime call path has not yet been proven.
- Naval effects remain for the next audited batch. `effect_torprdo.xml` remains unhooked pending proof of a real original runtime call.
- Exact particle z-order relative to unit sprites, flags and HP bars remains unresolved.

## Regression
- Added `test_native_rocket_visual_timeline.js`.
- Service Worker cache: `ew4-port-v061-r14-39-rocketvisual3`.
