# R14-39 Post-Handoff 27 — native form_achivement conservative runtime audit

Date: 2026-09-10
Parent: P26 native Campaign SelCountry + Save Frozen

## Scope

This pass closes the concrete P26 functional gap where the main-menu Achievements button existed visually but had no runtime handler. The original `form_achivement` layout and original UI assets are restored as the geometry/visual source of truth. Unknown native scoring semantics are deliberately **not invented**.

## Original evidence restored

`layout-568h.xml` defines `form_achivement` on the 568x320 logical canvas with:

- Champion button x=15 y=31 49x32
- Ranking button x=80 y=31 49x32
- stage-star icon x=193 y=37 and score text x=218 y=38
- Military summary group x=327 y=28 120x38
- Nobility summary group x=448 y=28 120x38
- Europe / America / Asia domination sections with original continent buttons and three `rule_*` markers each
- General list x=23 y=223 w=600 h=98 with scale=0.75
- original separator lines and bottom pattern

The runtime uses the corresponding original images (`button_champion`, `button_rank`, `board_rankclass`, `marker_rank`, `marker_class`, continent rule buttons, `rule_0..9`, `stage_star`, `pattern_bg_bottom`, `board_smallgenerals`).

## Production implementation

- Main-menu `btn_achi` / `#main-achievement` now opens the Achievement screen and Back returns to Main.
- New production `native_achievement_core.js` builds a conservative view model.
- The top star value uses the real persisted Campaign Stars wallet and clamps to the established 0..999 range.
- The bottom general strip is generated from the actual owned-general set, deduplicated and range-checked, using current commander names and portraits.
- Global military/nobility summary is **not** guessed from the strongest owned general. It is rendered only when an exact persisted `achievementProfile` record is available; otherwise it remains `--`.
- Continent domination markers/year are rendered only from explicit persisted `achievementConquests` records; without a proven record they remain `rule_0` / `--`.
- Champion/Ranking buttons retain their original visual controls but no fabricated online/GameCenter destination is attached; until native service semantics are proven they only provide normal selection feedback.

## Deliberate truth boundary

The P26/P27 lean source does not contain the raw original `libeuropean-war-4.so`, and the currently searchable file library did not surface the original APK itself. Historical audits prove the APK hash and many native behaviors, but no prior dedicated Achievement-controller audit was recovered. Therefore this checkpoint does **not** claim proof for:

- exact native global military-rank score derivation;
- exact native global nobility-score derivation;
- exact Europe/America/Asia conquest rule-level/year update semantics;
- exact Champion/Ranking service navigation.

Do not fill these fields from per-general rank/nobility or arbitrary Conquest wins without stronger `.so`/save-format evidence.

## Regression

- P27 native Achievement contract: PASS.
- Full `test_*.js`: 107/107 PASS.
- Service Worker CORE: 327/327 referenced resources present.
- P25 six-zone long-session persistence: PASS (73 first clears + 73 worse replays; 292 BattleSave lifecycles; 500 Campaign-meta reloads; 6/6 one-shot warzone rewards).
- P21 protected Campaign Upgrade/save files remain byte-identical to P26.

## Device boundary

No real iPhone visual/touch comparison occurred in this pass. HD-to-logical asset scale, font baseline, general-strip clipping/scroll feel and exact native service-button response remain true-device/native-code verification items.
