# HANDOFF P72

Authoritative checkpoint: **EW4 R14-39 P72 Native Achievement Route Audited**, 2026-09-12.

Continue from P72; do not redo P50-P71. P72 closes the Native main-menu Achievement route that was visually present but not wired in the App coordinator.

## Landed
- Main-menu `btn_achi` / `achievementHandler` is now wired to a Native Achievement scene and Back returns to Main.
- Added Swift `NativeAchievementCore`, porting mature P28 local semantics: historical Campaign stars / 420, global military/nobility level+score formulas over the user-mod unlimited owned-general set, and Europe/America/Asia max-only rule-year display.
- Added `NativeOriginalAchievementScene` consuming frozen original Achievement assets and current profile/commander state. Champion/Ranking retain original controls and selection feedback only; platform/GameCenter service navigation is not invented in PORT_ONLY.
- Bottom owned-general strip uses actual owned IDs, portraits and names with horizontal scrolling.
- Added reusable `NativeOriginalClaimScene` shell for original `form_claim` 200x100 medal/item presentation. It is intentionally **not** attached to Achievement without a proven native local claim trigger.
- Added `P72AchievementNativeParityTests.swift`.

## Verification
- Native **271/271 PASS** = 262 Swift Testing + 9 XCTest.
- Mature JS **126/126 PASS**.
- NativeCore Sources+Tests **182/182 parse PASS**; entire Native Swift tree **184/184 PASS**.
- SOURCE_LEAN **6321/6321 unchanged**.
- Native Resources **1751/1751 byte-provenanced**.
- Runtime resource audit `errors=[]`: 101 battles, 7407/7407 unit visuals, 5482/5482 eligible building sprites, 877 animation units / 3519 motions, BILE 12/12.
- IPA preflight **26/26 PASS**; scope guard PASS; script syntax PASS.

## P71 -> P72 scope
- Product Swift: **2 added / 2 modified / 0 deleted**.
  - Added `NativeAchievementCore.swift`.
  - Added `NativeOriginalAchievementScene.swift` (also contains the reusable Claim shell).
  - Modified `NativeOriginalFormGeometryCore.swift`.
  - Modified `EW4NativePortApp.swift`.
- Test Swift: **1 added / 0 modified / 0 deleted**.
- Native Resources: **0/0/0**.
- SOURCE_LEAN: **0/0/0**.

## Evidence boundary / next work
Do not invent Champion/Ranking online service behavior or an Achievement reward-claim trigger. P28 proves local Achievement display semantics; `form_claim` exists as a generic reward shell but no proven local Achievement trigger was recovered.

The next XML-to-Native-route audit should continue from forms whose single-player controller path is locally provable. `form_recruitgeneral` / remaining academy-tavern surfaces and save/new-game notice shells are candidates only after checking whether an existing Native scene already covers them.

## Still not verified
Apple SDK/Xcode/iPhoneOS compilation and real-device SpriteKit/UIKit type checking, font metrics, texture anchors, general-strip scroll feel, pressed states and Release configuration. Linux cannot substitute for true-device acceptance.
