# P70 Native DeployItem Parity Note

P70 closes the proven presentation/geometry gap in `form_deployitem` without changing equipment gameplay semantics.

## Landed
- Centralized the frozen 568h XML geometry in `NativeOriginalFormGeometryCore.DeployItem`: 353x261 form, 78x119 general group / 78x98 commander, 110x52 rank group, 110x74 equipment group, 142x120 description group, 344x99 items group, 342x95 7-column item grid and 55x21 equip action.
- Replaced generic green previous/next controls and literal arrow glyphs with the original `button_changegeneral_gray.png` / `_2.png` assets.
- Restored original rank/class artwork, HP/recovery markers, commander portrait/nameboard, equipment slots, selection overlay, description frame, split line and confirm-blue action art.
- The 28-slot ItemBank is rendered as the original four-row 7-column 45px grid with 3px gaps. The 95px viewport over 189px content yields a clamped 94px maximum scroll and uses original gray/dark-gray scrollbar art.
- Equipment and inventory selection hitboxes consume the same recovered geometry as rendering.
- Empty inventory selection with an occupied equipped slot now presents frozen `btn_remove=卸下`; non-empty selection presents `btn_equip=装备`.
- Commander cycling, consumable rejection, flag-bearer restriction, equipment ownership and actual `NativeHeadquartersManagementCore.equip(...)` semantics are unchanged.
- Added `P70DeployItemFormFidelityTests.swift`.

## Evidence boundary
Linux SwiftPM excludes the body guarded by `#if canImport(SpriteKit) && canImport(UIKit)`, so the SpriteKit renderer is syntax-parsed and source-contract tested here, but full UIKit/SpriteKit type compilation still requires Xcode/iPhoneOS. Exact internal behavior of the original composite `tmp_rank` widget is not claimed beyond the recovered XML regions and the frozen rank/class assets now consumed.

## Verification
- Native **263/263 PASS** = 254 Swift Testing + 9 XCTest.
- Mature JS **126/126 PASS**.
- NativeCore Sources+Tests **176/176 parse PASS**; entire Native Swift tree **178/178 parse PASS**.
- SOURCE_LEAN **6321/6321 unchanged**.
- Native Resources **1751/1751 byte-provenanced**.
- DeployItem referenced UI/rank/class assets present: **10/10 + 14/14 + 9/9**.
- Runtime resource audit `errors=[]`: 101 battles, 7407/7407 unit visuals, 5482/5482 eligible building sprites, 877 animation units / 3519 motions, BILE 12/12.
- IPA preflight **26/26 PASS**; scope guard PASS; script syntax PASS.

## P69 -> P70 scope
- Product Swift: **0 added / 2 modified / 0 deleted**.
  - `NativeOriginalFormGeometryCore.swift`
  - `NativeOriginalDeployItemScene.swift`
- Test Swift: **1 added / 0 modified / 0 deleted**.
- Native Resources: **0/0/0**.
- SOURCE_LEAN: **0/0/0**.
