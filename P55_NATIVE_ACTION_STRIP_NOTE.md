# P55 NOTE — Native Battle Action Strip / Battle Operation Forms

Date: 2026-09-11

## Scope
P55 continues directly from P54. It does not replace the mature Web truth layer and does not rewrite the frozen battle world/presentation baseline. The pass closes the Native battle action strip and the original battle operation surfaces required by ordinary play and the recovered Tutorial scripts.

## Landed
- Reusable Native action strip for selected player facilities/units.
- Recruit-unit core + original-style recruit form: recovered army IDs/card/build-card availability, resource costs, technology training level, occupied-cell checks, player +120 HP modification, action-state commit and autosave integration.
- Battle consumables: Wine, Spirit and three medical-kit tiers using mature conditions; player inventory remains non-consuming per the locked infinite-item modification.
- Defense / fortress construction: recovered money/industry costs, construction state persistence, one-fortress-per-round contract, and defense world sprites rebuilt after creation/load.
- Facility upgrades with recovered fixed costs and architecture-skill 3/5 truncation.
- Training confirmation/action chain and transport-ship conversion using recovered runtime rules/data.
- Battle commerce/market with recovered business-star pricing; battle shop 14 seller slots + 28-slot player bank buy/sell behavior.
- Battle general deployment with occupied-commander exclusion, duplicate prevention and absolute-damage preservation.
- Unit information form with recovered unit art/stats and commander detail entry.
- Tavern remains routed through the selected-facility action strip.
- Tutorial aliases such as `btn_city`, `btn_item`, `btn_defense`, `btn_training`, `btn_upgrade`, `btn_trading`, `btn_bar`, `btn_ship`, list/grid aliases and confirmation/close aliases now bind to real Native controls.

## Verification
- Native clean-cache gate: **212/212 PASS** = 203 Swift Testing + 9 XCTest.
- Mature SOURCE_LEAN JS: **126/126 PASS**.
- Swift syntax parse: **161/161 PASS**.
- Native resource audit: `errors=[]`; battles 101; unit visuals 7407/7407; building sprites 5482/5482; animation units 877; motions 3519; BILE 12/12.
- SOURCE_LEAN freeze: 6321 expected / 6321 actual / changed 0 / missing 0 / extra 0.
- IPA preflight: **26/26 PASS**.
- P54 -> P55 SHA audit: product source 25 added / 4 changed / 0 deleted; Native Resources 0/0/0; SOURCE_LEAN 0/0/0.

## Existing product files changed vs P54
- `BattleGameplayCore.swift`
- `NativeRoundSettlementCore.swift`
- `NativeBattleScene.swift`
- `NativeResourceStore.swift`

All other P55 product implementation is additive source/test files. No Native runtime resource file changed.

## Do not misreport
- This is not an Xcode/iPhoneOS Release build and not a signed IPA.
- Linux syntax parsing does not prove Apple-framework semantic/link correctness.
- True-device SpriteKit hitboxes/pixel alignment/audio-session behavior remain pending acceptance.
- P55 touches `NativeBattleScene.swift` to route real action-strip/forms and world defense overlays; that is intentional. It does not justify changing frozen map textures, camera transforms, unit anchors/scale, flags, HP arcs, HUD/text baselines, zoom/LOD, or P33 attack-impact timing without evidence.

## Next boundary
Prefer P56 as an integration/acceptance closure pass: run the recovered Tutorial end-to-end as a coverage guide, fix only remaining proven battle-operation gaps, then move to macOS/Xcode iPhoneOS Release build + IPA/device testing. Avoid reopening already completed HQ/Campaign/Conquest or mature visual baselines.
