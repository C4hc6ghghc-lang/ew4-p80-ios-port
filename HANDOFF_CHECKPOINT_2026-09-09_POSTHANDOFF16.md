# EW4 Web Port r14-39 — Post-Handoff 16 Native Result Frozen Checkpoint

Frozen from Post-Handoff 15 after landing original-evidence campaign result/reward behavior.

## Production state
- P1–P15 preserved; no completed camera/UI/animation/shop/tutorial work was rolled back.
- P13 full compact animation remains 877/877 unit definitions, 3519/3519 motions, 7407/7407 battle units, 1754/1754 directional attack chains.
- P14 shared SceneShop remains frozen.
- P15 original Tutorial Script Executor remains frozen.
- P16 native campaign result / reward controller is now frozen.

## P16 recovered behavior
- Exact five-grade BTL result formula using original `win` / `best` thresholds.
- Cumulative medal table 0/0/5/15/25/50 with replay delta-only award.
- Real campaign timeout failure and fixed missing `nativeStageTurnLimits()` runtime helper.
- Up to six real participating player generals in the result list.
- SceneTalk-style narration -> VictoryText (~4.5 s) -> SceneVictory chain.
- Battle `CollectMedal/getmedal` damage proc with recovered strict thresholds and native type/level adjustments.
- Original compact getmedal BILE effect and audio.
- BattleSave schema 5 persists CollectMedal while accepting schemas 1–4.
- ContinueBattle state returns through SceneMain before SceneSelBattle/openZone instead of jumping directly from the result callback.
- Last non-hidden campaign stage routes to SceneComplete.
- Six original first-clear campaign completion reward triplets and images; repeat completion awards zero.
- P16-only visual/effect assets are included in the Service Worker offline cache.

## Regression
Full independent JS suites: **84 / 84 PASS**.
See `TEST_RESULTS_POSTHANDOFF16_84_OF_84_PASS.txt`.

## Important unresolved rule
Do **not** treat numeric `hide=1` campaign stages as ordinary sequential main-line rows, but also do **not** simply delete/hide them forever. The exact original condition that exposes hidden stages has not yet been proven from the native SceneSelBattle controller. This is intentionally isolated rather than guessed.

Known `hide=1` campaign rows found in original `def_battlelist.xml` include:
`campaign1_05`, `campaign1_18`, `campaign2_05`, `campaign2_14`, `campaign3_12`, `campaign3_14`, `campaign4_11`, `campaign4_12`, `campaign5_05`, `campaign5_09`, `campaign6_09`.

## Next major targets
1. Reverse and implement exact SceneSelBattle hidden-stage unlock/exposure semantics.
2. Continue remaining original-controller parity, especially GeneralInfo upgrade/regroup flows.
3. Final iPhone true-device visual/audio/touch calibration.

## True-device caveat
Do not equate 84/84 static/behavior regression with pixel-perfect true-device parity.
