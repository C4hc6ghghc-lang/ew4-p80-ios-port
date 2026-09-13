# EW4 Web Port 0.61 — Post-Handoff 19 Residual Controller Frozen

Date: 2026-09-09

## Authoritative baseline
This checkpoint supersedes Post-Handoff 18. P1-P18 remain frozen. P19 adds a bounded residual-controller pass: HQ dismissal MOD safety, native RoundTurn, and native Exchange/RecruitGeneral shell restoration.

Read first:
1. `CURRENT_STATUS.json`
2. `SOURCE_LEAN/EW4_Web_Port_v0.61/R14_39_POSTHANDOFF19_RESIDUAL_CONTROLLER_AUDIT.md`
3. `TEST_RESULTS_POSTHANDOFF19_93_OF_93_PASS.txt`

## Frozen P19 content
- Safe HQ-only general dismissal MOD with princess lock and atomic equipment return to 28-slot ItemBank.
- Original `form_roundturn` 320x175 end-of-player-round controller, including economy/industry, food add/delete, round/best/win thresholds and up to six generals.
- RoundTurn modal delays post-round dialogues/autosave until closed.
- RoundTurn image dependencies explicitly included in Service Worker precache.
- Original `form_exchange` 440x259 geometry and actual `btn_buy_1..4` / `btn_sell_1..4` aliases.
- Original `form_recruitgeneral` 300x275 shell/row geometry for battle taverns.
- P14 SceneShop and P15 Tutorial behavior preserved.

## Verification
Full independent JS tree: **93 / 93 PASS**.

## Intentionally unresolved
`form_stageintro` is isolated for the next native pass. Its layout is known, but its native Scene transition order relative to deployment must be recovered before integration.
