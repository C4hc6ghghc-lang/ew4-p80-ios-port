# HANDOFF P70

Authoritative checkpoint: **EW4 R14-39 P70 Native DeployItem Parity Audited**, 2026-09-12.

Continue from P70; do not redo P50-P69. P70 is a narrow original-XML recovery pass for `form_deployitem` only.

## Landed
- Recovered the 353x261 `form_deployitem` internal geometry from frozen `original_layout-568h.xml`.
- Restored the original general selector assets/commander presentation, rank/nobility group, equipment group, description group, 28-slot 7-column inventory grid, original scrollbar, selection overlay and 55x21 blue equip action.
- Four inventory rows are now genuinely scrollable within the original 95px viewport; max scroll is 94px.
- Visual item rectangles and touch hitboxes share the same geometry core.
- Empty selected bank slot correctly presents `btn_remove=卸下`; otherwise `btn_equip=装备`.
- Equipment gameplay continues through the existing `NativeHeadquartersManagementCore.equip(...)`; ownership, consumable restrictions, flag-skill restriction and commander cycling semantics were not rewritten.
- Added `P70DeployItemFormFidelityTests.swift`.

## Verification
- Native **263/263 PASS** = 254 Swift Testing + 9 XCTest.
- Mature JS **126/126 PASS**.
- NativeCore Sources+Tests **176/176 parse PASS**; entire Native Swift tree **178/178 PASS**.
- SOURCE_LEAN **6321/6321 unchanged**.
- Native Resources **1751/1751 byte-provenanced**.
- DeployItem referenced UI/rank/class assets: **10/10 + 14/14 + 9/9 present**.
- Runtime resource audit `errors=[]`: 101 battles, 7407/7407 unit visuals, 5482/5482 eligible building sprites, 877 animation units / 3519 motions, BILE 12/12.
- IPA preflight **26/26 PASS**; cross-project scope guard PASS; script syntax PASS.

## P69 -> P70 scope
- Product Swift: **0 added / 2 modified / 0 deleted**.
- Test Swift: **1 added / 0 modified / 0 deleted**.
- Native Resources: **0/0/0**.
- SOURCE_LEAN: **0/0/0**.

## Next isolated work
Do not reopen equipment rules or frozen map/LOD/unit/HUD/camera/AI systems. The next stronger Release-visible candidate is `form_generalupgrade`: frozen XML provides a 325x185 upgrade form and rank/nobility/full-rank groups while the current HQ management presentation still contains synthetic rank/progress text. Audit its original entry/controller evidence first; only recover geometry/art/interaction that is directly supported. If controller evidence is incomplete, move to another proven form rather than guessing.

## Still not verified
Apple SDK/Xcode/iPhoneOS compilation and real-device SpriteKit/UIKit font metrics, button pressed-state behavior, image anchors, clipping/scroll feel and Release configuration. Linux cannot type-compile the SpriteKit/UIKit-guarded renderer body and cannot substitute for device acceptance.
