# EW4 Web Port r14-39 — Post-Handoff 11 Frozen Checkpoint

Frozen: 2026-09-09 15:35 local context.

## Authority / scope
- Original EW4 APK remains authoritative for UI, controller semantics, camera, map geometry, animation, effects, audio and timing whenever evidence exists.
- This is **EW4 Web Port**, not ImperialFrontier. Do not import ImperialFrontier custom mechanics unless explicitly re-authorized.
- Player modifications currently authorized include infinite medals and badges; battle consumables IDs 11–15 are usable without depletion; Military Academy infinite/zero-cost refresh remains authorized.
- Do not add Web-specific FREE/∞ advertising to original UI unless the original UI naturally shows a number.

## Reproducible source state
The source under `SOURCE_LEAN/EW4_Web_Port_v0.61/` is r14-39 baseline plus P1 → P11 merged in order.

Applied frozen deltas:
1. P1 `INFITEM_MGVIS`
2. P2 `ARTILLERY_VIS`
3. P3 `ROCKET_VIS`
4. P4 `NATIVE_CAMERA_LAYER`
5. P5 `NATIVE_HEX_LOWZOOM`
6. P6 `NATIVE_CAMERA_PRESENTATION`
7. P7 `PLAYER_ACTION_CAMERA_FOCUS`
8. P8 `AI_CAMERA_NATIVE_PATH`
9. P9 `VISUAL_UI`
10. P10 `NATIVE_CONQUEST_UI` (revised/fixed package)
11. P11 `NATIVE_MAIN_HQ_UI`

The applied delta archives are retained in `APPLIED_DELTAS/` for provenance only. Do not apply them again over this merged tree.

## Verified regression status
Fresh rebuild from base + P1..P11 was executed during packaging.
- JS regression suites: **76/76 PASS**
- `test_compact_bile_parity.js`: reports **1076/1076 PASS**
- Machine Gun Finish corrected set: **18/18 PASS**
- Rebuild required extracting the original APK `assets/layout-568h.xml` to the test's expected temporary path; after doing so, all 76 suites passed. The initial missing-file failure was environmental, not a code regression.

See `TEST_RESULTS_POSTHANDOFF11_76_OF_76_PASS.txt`.

## Major landed work since the 2026-09-08 handoff
### Player inventory overrides
- medals = Infinity
- badges = Infinity
- battle consumables IDs 11–15 (Wine, Spirit, Medikit, Medikit L, First Aid Box) can be used without depletion and remain available even at zero real stock.

### Battle effects
- machine-gun original visual cue/effect wired
- light/heavy/siege artillery original effect/timing/offset/rotation wired
- rocket original 1.6 / 1.8 / 2.0 triple-cue visual timeline wired
- original simple/moving particles and z-order work preserved
- effect/audio timelines continue to be driven from APK evidence

### Native camera / battlefield presentation
- zoom clamp restored to 0.2–1.0
- 0.5 semantic zoom threshold
- low-zoom strategic marker LOD with relation ring and native HP arc
- drag is incremental and has no invented fling inertia
- native tap/pinch thresholds and pan edge allowance restored
- programmatic camera motor separated from manual drag
- fresh-battle commander-first camera focus
- player action camera focus/wait
- AI action camera focus/wait, with presentation skipped by AI fast-forward path

### Native hex geometry / pathing
- old Web 64×53 odd-column approximation replaced with native odd-row geometry:
  - `x = col*64 + (row odd ? 32 : 0)`
  - `y = row*54 - 18`
- native world-to-cell hit-test restored
- odd-row neighbors / distance / pathing unified
- 101 BTL / 7407 units / 8001 objects roundtrip validation previously passed with zero cell mismatches
- native equal-cost path tie-break direction order restored:
  E → SE → SW → W → NW → NE

### Visual/UI cleanup through P11
- native tutorial/playnotice forms restored
- option GameSpeed and ShowGrids controller implemented
- unit-info and recruit form moved toward original fixed geometry
- main menu and campaign-node positions restored from 568h layout evidence
- single-player conquest flow corrected: it does NOT use multiplayer `form_selcountry`; P10 restores the native conquest branch and removes the old four-column Web country wall from the authoritative path
- main-menu HQ corrected to enter the native SceneDeployGeneral family instead of the old custom Web HQ card wall
- old HQ render/init remnants removed

## Highest-priority continuation
Read `WIP_P12_P13_NOT_FROZEN.md` first. The next model should re-land the already reverse-engineered SceneShop and full animation-manifest work, then run the full regression suite before claiming P12/P13 complete.

After that, continue the user's current directive: visual and logic parity to completion, prioritizing visible Web-replacement pages and controller mismatches before low-impact micro-details.

## Hard warnings
- Do not claim visual/UI or logic is 100% complete yet.
- Do not assume chat-reported P12/P13 78/78 or 80/80 status is persisted in this package; it is not.
- Do not revive the obsolete Web HQ card wall.
- Do not route single-player conquest through multiplayer `form_selcountry`.
- Do not reintroduce the old 64×53 odd-column battlefield geometry.
- Do not add torpedo gameplay merely because an APK effect resource resembles `torprdo`; actual usage must be proven.
