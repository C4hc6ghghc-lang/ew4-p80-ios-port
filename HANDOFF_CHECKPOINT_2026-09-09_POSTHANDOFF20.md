# EW4 Web Port 0.61 — Post-Handoff 20 SceneStageIntro Frozen

Date: 2026-09-09

## Authoritative baseline
This checkpoint supersedes Post-Handoff 19. P1-P19 remain frozen. P20 restores native campaign SceneStageIntro timing/geometry and closes the stale-overlay re-entry edge case.

Read first:
1. `CURRENT_STATUS.json`
2. `SOURCE_LEAN/EW4_Web_Port_v0.61/R14_39_POSTHANDOFF20_STAGEINTRO_AUDIT.md`
3. `TEST_RESULTS_POSTHANDOFF20_94_OF_94_PASS.txt`

## Frozen P20 content
- Original `form_stageintro` 360x219 campaign intro shell.
- Fresh campaign SceneGame only: restored saves, Tutorial and Conquest do not auto-open it.
- Victory and Best Victory turn thresholds are populated from native stage limits.
- Commander portrait/name and stage description are rendered before first-round control.
- First-round dialogue/autosave is gated behind StageIntro close.
- New battle/load/restart clears any stale StageIntro overlay and continuation without executing it.
- StageIntro original image dependencies are included in Service Worker precache.
- P19 RoundTurn/Exchange/RecruitGeneral and all prior frozen behavior preserved.

## Verification
Full independent JS tree: **94 / 94 PASS**.

## Next pass
Continue the residual native Scene/controller census. Do not reopen P20 unless a true runtime regression is reproduced. Prioritize high-frequency single-player flows and then long-session save/load integration before iPhone true-device calibration.
