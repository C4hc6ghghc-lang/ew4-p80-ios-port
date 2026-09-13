# r14-39 Post-Handoff 16 — Native Campaign Result / Reward audit

## Frozen scope
Post-Handoff 16 replaces the remaining simplified Web campaign-result path with original-APK-evidenced result, reward, battle-medal, ContinueBattle, VictoryText, and SceneComplete behavior.

### Five-grade campaign result
Recovered from the original native library rather than inferred from the Web port:
- `turn <= best` => native score 5 / visible grade 1.
- `turn >= win` => native score 1 / visible grade 5.
- Middle grades use `trunc(((win - turn) * 4) / (win - best)) + 1`.
- Cumulative campaign medal table by native score: `0 / 0 / 5 / 15 / 25 / 50`.
- Replays only award the positive delta above the previously saved best native score for that BTL.
- `campaignBestRating` persists per battle and older save data remains accepted.

### Stage time limit
The prior Web controller parsed BTL `win`/`best` fields but did not enforce campaign timeout, and it called an undefined `nativeStageTurnLimits()` on some paths.
P16 provides the production helper and enforces failure once the battle round exceeds the original BTL `win` limit.

### Result form / generals
- Original `form_victory` result data is represented as five stars plus award/gain medal fields.
- `lbox_general` is no longer an empty placeholder: up to six unique participating player commanders are resolved from the actual battle units and rendered in result slots.
- Victory/failure description is no longer hard-coded inside the result form.

### Result presentation chain
Original-evidence presentation is separated into:
1. SceneTalk-style result narration.
2. On victory, the dedicated VictoryText presentation using original `board_victory.png`, `tex_victory.png`, and `sfx_celebrate.wav` for ~4.5 s.
3. SceneVictory result form.

Defeat uses its result audio path without injecting the victory presentation.

### CollectMedal / `getmedal`
Recovered from the original battle-effect dispatcher:
- This is a battle damage proc, not a kill reward.
- Final damage `<20`: no proc.
- Damage 20–24: adjusted random roll must be `>95`.
- 25–29: `>91`.
- 30–34: `>87`.
- >=35: `>82`.
- Native type mapping used by the recovered rule: infantry 0, cavalry 1, artillery 2, navy 3, fort 4.
- Infantry/navy add `2 * level` to the roll; cavalry adds `3 * level`; artillery/fort do not receive the level adjustment.
- Each successful player-side proc increments battle `CollectMedal` by one.
- `CollectMedal` is included in BattleSave schema 5; schemas 1–4 remain accepted and normalize missing collection count to zero.
- The original compact BILE `anim_upgrade/getmedal` resource is used (48 frames / 24 FPS / ~2 s) together with the original level-up sound.

### ContinueBattle / SceneComplete
- Campaign Continue does not directly load the next BTL from the result callback.
- P16 stores a transient ContinueBattle-equivalent zone state, transitions to SceneMain, and only then lets SceneMain consume the state and enter SceneSelBattle/openZone.
- Campaign completion is determined against the last non-hidden stage, matching recovered native control flow.
- Last non-hidden stage routes to SceneComplete.
- Six recovered first-clear completion reward triplets are implemented:
  - Zone 1: medal 0, badge 1, score 1
  - Zone 2: medal 50, badge 0, score 1
  - Zone 3: medal 50, badge 0, score 1
  - Zone 4: medal 0, badge 1, score 1
  - Zone 5: medal 50, badge 0, score 1
  - Zone 6: medal 0, badge 1, score 1
- Repeat completion gives zero additional completion reward.
- Original six campaign-end images are used.

### Offline PWA assets
Post-Handoff 16 Service Worker cache includes the new result-only assets that would otherwise pass online tests but fail after Add-to-Home-Screen/offline use:
- VictoryText background.
- all three `anim_upgrade` compact-BILE files.
- six campaign completion images.

## Regression
- Full independent Node suite: **84 / 84 PASS**.
- `test_native_result_p16_behavior.js` covers five-grade thresholds, medal delta, six generals, last-non-hidden completion decision, SceneComplete first/repeat reward, exact getmedal threshold strictness/type-level adjustment, and BattleSave schema 5 legacy acceptance.
- `test_native_result_p16_integration.js` covers SceneMain ContinueBattle handoff and P16 offline asset precache.

## Explicitly NOT frozen as solved
`def_battlelist.xml` contains multiple `hide=1` campaign stages. Native evidence proves that hidden stages are excluded from the ordinary "last visible main stage" completion test, but the exact condition that changes each hidden stage from hidden to selectable has not yet been proven. P16 therefore does **not** invent an unlock rule. Exact SceneSelBattle hidden-stage unlock semantics are the first recommended Post-Handoff 17 target.

## True-device caveat
84/84 proves checked data/controller contracts. Pixel-perfect iPhone result-window geometry, VictoryText timing under Safari audio policy, touch feel, and final z-order still require true-device calibration.
