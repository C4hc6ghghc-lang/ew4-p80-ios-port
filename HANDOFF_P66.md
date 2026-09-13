# HANDOFF P66

Authoritative checkpoint: **EW4 R14-39 P66 Native Tutorial / Regroup CN Fidelity Audited**, 2026-09-11.

Continue from P66; do not redo P50-P65. P66 is a narrow original-XML/string-authority and hitbox correction for Tutorial and Regroup confirmation surfaces.

## Landed
- `NativeOriginalTutorialScene` now consumes frozen `btn_basic = 基础教程`, `btn_classic = 高级教程`, and `btn_notice = 如何游戏`; removed nonexistent `tutorials1/tutorials2` string lookups.
- Tutorial menu buttons now use original `btn_common_green.png` and recovered XML geometry through `NativeOriginalFormGeometryCore.Tutorial`.
- Tutorial launch routing is unchanged (`tutorials1.btl` / `tutorials2.btl`).
- `NativeOriginalRegroupScene` confirmation now consumes original `title_notice = 注  意`, `text_regroupnotice`, `text_regroup`, `btn_confirm = 确认`, and `btn_cancel = 取消`.
- Restored original confirm/cancel order and XML hitboxes: confirm left at 75x30, cancel right at 75x30. Visual and touch geometry share `NativeOriginalFormGeometryCore.RegroupConfirm`.
- Restored the original confirmation gray-board and bold-line geometry without changing regroup gameplay semantics.
- Added `P66TutorialRegroupFidelityTests.swift` to lock frozen CN values, XML bindings, geometry, button art, and renderer consumption.
- No combat/economy/AI/save semantics, recruitment, items/defense rules, map/LOD/unit art, flags, HP/HUD, camera, P33 timing, Native Resources, or SOURCE_LEAN content changed.

## Verification
- Native **250/250 PASS** = 241 Swift Testing + 9 XCTest.
- Mature JS **126/126 PASS**.
- NativeCore Sources+Tests **171/171 parse PASS**; entire native Swift tree **173/173 PASS**.
- SOURCE_LEAN **6321/6321 unchanged**.
- Native Resources **1751/1751 byte-provenanced**.
- Runtime resource audit `errors=[]`: 101 battles, 7407/7407 unit visuals, 5482/5482 eligible building sprites, 877 animation units / 3519 motions, BILE 12/12.
- IPA preflight **26/26 PASS**; script syntax PASS; cross-project scope guard PASS.

## P65 -> P66 scope
- Product Swift: **0 added / 3 modified / 0 deleted**.
- Test Swift: **1 added / 0 modified / 0 deleted**.
- Native Resources: **0/0/0**.
- SOURCE_LEAN: **0/0/0**.

## Next isolated work
Highest-priority proven gap is `form_playnotice`: original XML defines a scrollable `HtmlBox` (390x186, `html_notice`, scroll track/thumb), while current Native notice truncates the frozen 24-item help text to the first 11 rendered lines and any touch closes the overlay. Recover scroll/crop/touch behavior so all 24 tips are reachable, without changing tutorial battle scripts.

Secondary proven visual gap: `form_regroupconfirm` original content also shows the source `tmp_commander` and a 132x98 equipment group. P66 restored title/text/button/board geometry and correct hitboxes but did not claim those commander/equipment preview internals are fully 1:1 yet.

## Still not verified
Apple SDK/Xcode/iPhoneOS compilation and real-device SpriteKit font metrics, layout, touch behavior, and final Release configuration. Linux/SwiftPM verification cannot substitute for device acceptance.
