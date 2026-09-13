# EW4 R14-39 / P57 Full-Scope Audit — Wave 2

## Authority order
1. Original EW4 APK recovery evidence / native layout / recovered data.
2. Frozen mature EW4 truth layer `SOURCE_LEAN/EW4_Web_Port_v0.61` and its native-audit documents.
3. Explicit user-approved player-side modifications in `PLAYER_MOD_LOCKS_R14_39_2026-09-08.md` plus already-frozen approved mods (infinite medals/badges, battle consumables 11–15 non-consuming, dismissal).
4. Anything else is not allowed to silently become runtime behavior.

## Whole-package contamination checks completed
- Runtime Swift scanned: 97 files.
- Native runtime resources: 1751 files.
- Native resource SHA provenance: 1751/1751 exactly match at least one file in frozen SOURCE_LEAN; unmatched = 0.
- Frozen SOURCE_LEAN: 6321 expected / 6321 actual / 0 changed / 0 missing / 0 extra.
- No runtime marker for ImperialFrontier-specific systems such as `ImperialFrontier`, `leaningFrance`, `leaningCoalition`, `strictNeutral`, `大军团`, `天灾级`, `42国`, or the foreign five-speed `1×/2×/4×/8×` presentation.
- Known ImperialFrontier-specific balance numbers searched in runtime rule code (460 / 270 / 165 / 145 and 25-as-cost contexts): no matching foreign gameplay rule found.

## Confirmed corrections made in this clean WIP
1. Removed release-visible mod/cheat explanation from HQ shop and battle shop (`勋章无限`, `买卖不扣...`). Infinite currency remains backend-only.
2. Replaced resource emoji presentation (`🏅 💰 ⚙️ 🌾`) in battle shop, HQ shop, market, tavern, recruit and defense forms with original EW4 sprite resources:
   - `medals.png`
   - `marker_money.png`
   - `marker_industry.png`
   - `marker_food.png`
3. Removed an unreachable P55 placeholder fallback message from the exhaustive battle-action switch.
4. Added `VERIFY_EW4_SCOPE_GUARD.py` and wired it into `VERIFY_PACKAGE.sh`. Packaging now fails on known cross-project runtime markers, visible cheat copy, renderer resource emoji, or any Native resource not byte-provenanced to SOURCE_LEAN.

## Rule-table evidence rechecked
- Player +4/+4 attack interval, +120 base HP, +2 movement: explicit approved mod and mature tests.
- General military/nobility growth thresholds and multipliers: `R14_39_POSTHANDOFF18_NATIVE_GENERAL_AUDIT.md` / `native_general_core.js`.
- Training tables/costs: `native_training_core.js` / recovered tests.
- Construction upgrade costs: `NATIVE_CONSTRUCTION_ECONOMY_DEFENSE_AUDIT_R14_39.md`.
- Battle consumables 11–15 behavior: `NATIVE_USEITEM_RECOVER_AUDIT_R14_39.md`; non-consumption is approved mod.
- Battle/HQ shop pricing/stock: `ITEMSTORE_NATIVE_AUDIT_R14.md` and `R14_39_POSTHANDOFF14_SCENESHOP_AUDIT.md`; infinite medals are hidden backend mod only.
- Commerce exchange rates/buttons: `native_commerce_core.js` + original `form_exchange` XML.
- Camera pair-focus: `R14_39_POSTHANDOFF7_PLAYER_ACTION_CAMERA_FOCUS_AUDIT.md`; AI normal focus/bypass evidence: POSTHANDOFF8 audit.
- AI destination score currently matches frozen mature EW4 controller formula `100000 - hp*4 - nearest*100 - spentMovement`; no ImperialFrontier AI logic found.

## Important remaining original-port fidelity gaps (not cross-project contamination)
These prevent calling the current clean WIP a fully audited final baseline yet:
1. **Shop controller flow** — original `form_shop` is select item -> central info/price/description -> explicit `btn_buy`; current Native HQ/battle shop still commits buy/sell directly on grid tap. Rule math is evidence-backed; controller flow is not yet 1:1.
2. **General-info surface** — original `form_generalinfo` has commander block, equipment group, regroup/item buttons, four skill rows, military/nobility blocks and 8-stat values. Current battle general-info and Academy candidate info are simplified custom 440×217 surfaces. Outer size is right, internal content is not full original form parity.
3. **Recruit-unit form content** — outer `form_recruitunit` geometry and recruitment core are recovered, but current Native content is a simplified list/description rendering rather than full original `grid_info` presentation.
4. **Defense form item presentation** — original outer form/select/confirm flow is preserved, but row rendering still needs final evidence-level parity review.
5. A Chinese-string differential scan found 111 runtime string candidates not trivially found in original CN strings/XML. Many are DEBUG-only status text or approved-mod UI, so this is a triage list, not 111 confirmed bugs; release-visible candidates still need review.

## Validation after Wave-2 corrections
- `swiftc -parse`: all Swift files PASS.
- Native tests: 212 Swift Testing + 9 XCTest = **221/221 PASS**.
- Mature JS tests: **126/126 PASS**.
- EW4 scope guard: PASS, runtime Swift 97, Native resources 1751/1751 provenanced.
- Package preflight: 26/26 PASS.

## Freeze policy
Do NOT treat this WIP as a final replacement for P57 yet. Continue parity cleanup first. Do not start P58 or add new gameplay systems until the remaining original-port fidelity gaps are resolved or explicitly accepted by the user.
