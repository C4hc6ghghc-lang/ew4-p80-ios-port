# HANDOFF P74

Authoritative checkpoint: **EW4 R14-39 P74 Native RecruitGeneral Form Audited**, 2026-09-12.

Continue from P74; do not redo P50-P73. P74 closes the remaining presentation drift in battle `form_recruitgeneral` while preserving existing tavern recruitment semantics.

## Landed
- Original 300x275 four-row Tavern/RecruitGeneral geometry is now centralized in `NativeOriginalFormGeometryCore.Tavern`.
- Four 55px rows consume original bold row frames and 75x49 cost-group frames.
- Replaced star-string placeholder with actual `rank_*.png` military-rank and `class_*.png` nobility-rank artwork.
- General-info, nameboard, medals/money/industry and green recruit controls use frozen original assets.
- Visual and hit geometry for info/recruit controls is shared.
- Existing `NativeBattleTavernCore` availability and recruitment semantics remain unchanged.

## Verification
- Native **279/279 PASS** = 270 Swift Testing + 9 XCTest.
- Mature Web **126/126 PASS**.
- NativeCore Sources+Tests **184/184 parse PASS**; entire Native Swift tree **186/186 PASS**.
- SOURCE_LEAN **6321/6321 unchanged**.
- Native Resources **1751/1751 byte-provenanced**.
- Runtime resource audit `errors=[]`: 101 battles, 7407/7407 unit visuals, 5482/5482 building sprites, 877 animation units / 3519 motions, BILE 12/12.
- IPA preflight **26/26 PASS**; scope guard PASS; script syntax PASS.

## P73 -> P74 scope
- Product Swift: **0 added / 2 modified / 0 deleted**.
- Test Swift: **1 added / 0 modified / 0 deleted**.
- Native Resources: **0/0/0**.
- SOURCE_LEAN: **0/0/0**.

## Evidence boundary / next work
`form_recruitgeneral` outer layout and row composition are hard-backed. Exact internal packing behavior of the original composite `tmp_rank` widget remains unproved from the original binary, so do not over-tune it without harder evidence.

Continue the XML-form-to-Native-route census. Prefer Release-visible single-player gaps where XML + frozen resources + mature controller evidence converge. Do not invent ad/service/multiplayer/platform behavior.

## Still not verified
Apple SDK/Xcode/iPhoneOS compilation and real-device SpriteKit/UIKit type checking, font metrics, pressed states and Release configuration.
