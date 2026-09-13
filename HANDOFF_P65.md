# HANDOFF P65

Authoritative checkpoint: **EW4 R14-39 P65 Native Outer/HQ CN Fidelity Audited**, 2026-09-11.

Continue from P65; do not redo P50-P64. P65 is a narrow evidence-led Release-visible string-authority pass for outer/HQ/general-deployment surfaces.

## Landed
- `NativeOriginalAcademyScene` now consumes frozen `title_buygeneral = 军事学院` and `title_generaltips = 获得将军`; removed the Native-only `获得上将` near-match.
- `NativeOriginalBattleGeneralDeploymentRenderer` now consumes original `btn_deploy = 出征` for the primary action instead of renderer-local `确　定`.
- `NativeOriginalHeadquartersScene` now loads frozen CN strings and consumes direct original keys for `btn_princess`, `btn_college`, `title_headquarters`, `text_equipitem`, `btn_regroup`, `btn_equip`, `btn_infantry`, `btn_cavalry`, `btn_artillery`, `btn_navy`, `btn_fortress`, and `text_economy`. The Release-visible general detail title is now original `指挥部` instead of Native-only `总　部`.
- `NativeOriginalOuterMenuScene` conquest preview now consumes original `text2_american / text2_european` instead of renderer-local literals.
- Added `P65OuterHQStringFidelityTests.swift` to lock exact frozen CN values, XML bindings, and renderer consumption.
- No combat/economy/AI/save semantics, recruitment, item/defense behavior, map/LOD/unit art, flags, HP/HUD, camera, P33 timing, Native Resources, or SOURCE_LEAN content changed.

## Verification
- Native **246/246 PASS** = 237 Swift Testing + 9 XCTest.
- Mature JS **126/126 PASS**.
- NativeCore Sources+Tests **170/170 parse PASS**; NativeCore including Package.swift **171/171**; entire native Swift tree **172/172 PASS**.
- SOURCE_LEAN **6321/6321 unchanged**.
- Native Resources **1751/1751 byte-provenanced**.
- Runtime resource audit `errors=[]`: 101 battles, 7407/7407 unit visuals, 5482/5482 eligible building sprites, 877 animation units / 3519 motions, BILE 12/12.
- IPA preflight **26/26 PASS**; script syntax PASS; cross-project scope guard PASS.

## P64 -> P65 scope
- Product Swift: **0 added / 4 modified / 0 deleted**.
- Test Swift: **1 added / 0 modified / 0 deleted**.
- Native Resources: **0/0/0**.
- SOURCE_LEAN: **0/0/0**.

## String-triage rule going forward
Continue from actual Release-visible render paths only. Centralize a renderer-local literal only when original XML/`strings_cn.json` or another frozen mature authority proves the binding. Dynamic/custom copy without direct authority remains untouched. Do not count DEBUG-only status text as Release UI debt.

## Next isolated work
Continue the same evidence-led pass on remaining renderer-local Release labels. Strong candidates remain deploy-item/regroup/tutorial/menu surfaces, but only static labels with proven original keys should move. In particular, dynamic growth/equipment descriptions must not be rewritten just because they contain Chinese literals. Do not reopen frozen map/LOD/unit/HUD/camera/AI systems without a proven defect.

## Still not verified
Apple SDK/Xcode/iPhoneOS compilation and real-device SpriteKit font metrics, layout, touch behavior, and final Release configuration. Linux/SwiftPM verification cannot substitute for device acceptance.
