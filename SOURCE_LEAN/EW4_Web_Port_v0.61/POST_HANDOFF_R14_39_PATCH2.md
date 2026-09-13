# EW4 r14-39 post-handoff patch 2 — artillery native visual timelines

Scope: one small fidelity batch after patch 1. No new gameplay rules.

## Integrated
- Original `def_effectsanim.xml` visual cues for Light Artillery 1/2:
  `effect_lightgun.xml` at native 1.6–1.7s timing and native left/right offsets/rotation.
- Original Heavy Artillery 1/2 cues via `effect_gunnery.xml` at native 1.5–1.6s timing.
- Original Siege Artillery 1/2 cues via `effect_gunnery1.xml` at native 1.45–1.5s timing.
- Parsed every native emitter from those three XMLs into the existing `eff.png` particle atlas runtime:
  - light gun: 4 emitters
  - heavy gunnery: 4 emitters
  - siege gunnery: 3 emitters
- Corrected unit-local effect rotation so a timeline rotation rotates both particle sprite orientation and the emitter motion vector. This is required for non-zero-speed artillery smoke/fire particles and preserves the already-wired machine-gun behavior.

## Not claimed
- Rocket visuals are not integrated in this patch.
- Naval visual effects are not integrated in this patch.
- `effect_torprdo.xml` remains unhooked pending proof of an actual original runtime call path.
- Exact particle z-order relative to units/flags/HP remains unresolved pending native/controller or visual evidence.

## Regression
- Added `test_native_artillery_visual_timeline.js`.
- Service Worker cache: `ew4-port-v061-r14-39-artilleryvisual2`.
