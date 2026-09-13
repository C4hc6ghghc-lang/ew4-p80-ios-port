# Apply/check post-handoff patch 9

Baseline: cumulative r14-39 with post-handoff patches 1 through 8 already applied.

Overlay the included `EW4_Web_Port_v0.61/` tree over the existing project, preserving existing files and replacing same-path files.

Then verify:
1. `node --check app.js`
2. `node --check native_impact_effect_core.js`
3. run all `test_*.js` — expected **73/73 PASS**
4. `node test_compact_bile_full_parity.js` — expected **1076/1076 PASS**, Machine Gun Finish 18/18
5. Service Worker cache id is `ew4-port-v061-r14-39-posthandoff9-visualui`.

This delta does not claim `SceneSelCountry` controller parity or full 3519-motion animation coverage; see `R14_39_POSTHANDOFF9_VISUAL_UI_AUDIT.md`.
