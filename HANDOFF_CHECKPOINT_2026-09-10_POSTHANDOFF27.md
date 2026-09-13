# HANDOFF — R14-39 POSTHANDOFF27 native form_achivement conservative runtime Frozen

Date: 2026-09-10
Parent: P26 native Campaign SelCountry + Save Frozen
Status: FROZEN / trusted checkpoint

## Completed in P27

1. Closed the real P26 functional gap: the main-menu Achievement button now opens/restores original `form_achivement` and returns correctly.
2. Rebuilt the original 568x320 Achievement geometry from `layout-568h.xml`, including Champion/Ranking, star display, military/nobility summary blocks, Europe/America/Asia domination areas, separators/pattern and the general strip.
3. Added production `native_achievement_core.js`. It exposes only real known persisted data: Campaign Stars and owned generals are live. It deliberately refuses to infer global Achievement military/nobility from per-general levels. Unknown continent conquest records remain locked/blank unless explicit persisted records exist.
4. Added all required Achievement assets (`rule_0..9` included) to Service Worker CORE and bumped cache generation to P27.
5. Added a regression contract that explicitly blocks the old temptation to derive global Achievement rank from `highestRank()` or equivalent per-general state.

## Verification

- Full source `test_*.js`: **107/107 PASS**.
- Service Worker CORE: **327/327 present**.
- P25 six-zone long-session regression: PASS (73 first clears + 73 worse replays; 292 BattleSave cycles; 500 Campaign meta reloads; 6/6 one-shot zone rewards).
- P21 protected files remain byte-identical to P26 parent.
- `node --check app.js`: PASS.
- `node --check sw.js`: PASS.

## Truth boundary / do not overclaim

The raw original APK/`.so` was not materializable from the current searchable library in this pass, and no dedicated prior Achievement-controller `.so` audit was recovered. Therefore do not claim the exact original derivation of global military/nobility score, continent rule/year progression, or Champion/Ranking online service behavior. The form/layout/assets are native-evidence-backed; the unknown data semantics remain intentionally blank rather than guessed.

## Recommended next

1. If the original APK or a saved native-code Achievement audit becomes accessible, decode the exact global rank / continent-record / Champion-Ranking controller semantics and replace only the conservative placeholders.
2. Continue residual single-player controller census for another **proven** runtime omission; do not redo controllers merely because the original literal form name is absent in Web code.
3. True-device iPhone calibration: Achievement font/general-strip behavior, Dock `transportship1/2`, particle z-order, CampaignInfo offset, font/marker alignment and touch/pinch feel.
