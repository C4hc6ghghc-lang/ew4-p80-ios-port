# HANDOFF P63

Authoritative checkpoint: **EW4 R14-39 P63 Native CN String Fidelity Audited**, 2026-09-11.

Continue from P63; do not redo P50-P62. P63 is a narrow release-visible original-Chinese-string fidelity pass. It does not add gameplay and does not reopen frozen battlefield presentation systems.

## Landed
- Triaged the historical runtime-string differential instead of mass-replacing it. `statusHandler` / `setStatus` development strings such as `Native Market`, `Native Shop`, and `Native battle` are DEBUG-only in the iOS app and are not treated as Release UI defects.
- Restored direct frozen `strings_cn.json` authority for six release-visible Native surfaces:
  - `form_exchange`: `title_business` -> `交易所`.
  - `form_deploygeneral`: `title_deploygeneral` -> `指挥部`.
  - `form_unitinfo`: `title_unitinfo` -> `信  息`.
  - `form_stageintro`: `text_victory` / `text_bestvic` / `text_round_word` -> `胜利` / `重大胜利` / `回合`.
  - battle `form_shop`: `title_shop`, `name_Seller`, `text_sellersays`, `text_buy`, `text_sell`.
  - HQ shop surface: same original shop/seller/greeting/buy/sell keys.
- The previous invented stage-intro label `最佳胜利` is no longer a rendered authority; frozen CN `text_bestvic` is `重大胜利`.
- The previous shop fallback `出售` is replaced by frozen CN `text_sell` = `卖出` where the original shop action label is rendered.
- Added `NativeOriginalStringFidelityTests.swift` to lock exact frozen CN values and renderer source contracts.
- No combat, economy, AI, recruitment, item behavior, defense behavior, save logic, map/LOD, unit art, flags, HP/HUD, camera, P33 timing, Native Resources, or SOURCE_LEAN content changed.

## Verification
- Native **240/240 PASS** = 231 Swift Testing + 9 XCTest.
- Mature JS **126/126 PASS**.
- NativeCore source+test files: **168/168 parse PASS**; entire project Swift tree: **170/170 PASS**.
- SOURCE_LEAN **6321/6321 unchanged**.
- Native Resources **1751/1751 byte-provenanced**.
- Runtime resource audit `errors=[]`: 101 battles, 7407/7407 unit visuals, 5482/5482 eligible building sprites, 877 animation units / 3519 motions, BILE 12/12.
- IPA preflight **26/26 PASS**; script syntax PASS; cross-project scope guard PASS.

## P62 -> P63 scope
- Product Swift: **0 added / 6 modified / 0 deleted**.
- Test Swift: **1 added / 0 modified / 0 deleted**.
- Native Resources: **0/0/0**.
- SOURCE_LEAN: **0/0/0**.

## String-triage rule going forward
The historical `111` candidate count is not a bug count. Continue only by proving that a candidate is Release-visible and then matching it to original CN strings/XML or another frozen mature authority. Do not touch DEBUG-only status text, approved gameplay modifications, dynamic interpolated status copy, or text with no direct original authority merely to reduce the candidate count.

## Next isolated work
Continue release-visible runtime-string triage from actual SpriteKit/SwiftUI render calls (`SKLabelNode`, button titles, visible overlay text), especially remaining custom literals that may still have direct `strings_cn.json` or original XML keys. Keep uncertain functional labels untouched until evidence is found. Do not reopen frozen map/LOD/unit/HUD/camera/AI systems without a proven defect.

## Still not verified
Apple SDK/Xcode/iPhoneOS compilation and real-device SpriteKit font metrics, layout, touch behavior, and final Release configuration. Linux/SwiftPM verification cannot substitute for device acceptance.
