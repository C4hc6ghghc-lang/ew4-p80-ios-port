# HANDOFF P69

Authoritative checkpoint: **EW4 R14-39 P69 Native Main Regroup Parity Audited**, 2026-09-12.

Continue from P69; do not redo P50-P68. P69 is a narrow original-XML recovery pass for the main `form_regroup` surface only.

## Landed
- Replaced synthetic 120x142 source/target cards with original 78x98 `tmp_commander` geometry.
- Restored original 146x120 `group_infos` preview surface and its title/frame, rank/nobility preview, HP/recovery markers and 2x2 teaching-bonus grid.
- Restored original 146x120 `group_items` surface and two 45x45 equipment slots using frozen UI/Items assets.
- Restored `arrow_reoganizion.png`, original 83x35 red regroup button, notice line, separators, bottom ornament and bold line.
- Restored original 550x98 horizontal commander list geometry with 78px items and 10px interval; list selection/hit testing now uses the same recovered geometry.
- Preview HP/recovery values are derived from the same player override caps/max levels used by mature gameplay; teaching bonuses come from `regroupPreview()`.
- Main equipment preview currently follows the selected **source** commander's real `equipmentPair`, matching the destructive semantics the player must confirm. The original binary-controller binding of this specific main-form group has not been directly recovered and remains a validation point.
- `commitRegroup()` and all regroup math/source deletion/equipment deletion/growth transfer semantics remain unchanged.
- Added `P69MainRegroupFormFidelityTests.swift`.

## Verification
- Native **259/259 PASS** = 250 Swift Testing + 9 XCTest.
- Mature JS **126/126 PASS**.
- NativeCore Sources+Tests **175/175 parse PASS**; entire Native Swift tree **177/177 PASS**.
- SOURCE_LEAN **6321/6321 unchanged**.
- Native Resources **1751/1751 byte-provenanced**.
- Runtime resource audit `errors=[]`: 101 battles, 7407/7407 unit visuals, 5482/5482 eligible building sprites, 877 animation units / 3519 motions, BILE 12/12.
- IPA preflight **26/26 PASS**; script syntax PASS; cross-project scope guard PASS.

## P68 -> P69 scope
- Product Swift: **0 added / 2 modified / 0 deleted**.
  - `NativeOriginalFormGeometryCore.swift`
  - `NativeOriginalRegroupScene.swift`
- Test Swift: **1 added / 0 modified / 0 deleted**.
- Native Resources: **0/0/0**.
- SOURCE_LEAN: **0/0/0**.

## Next isolated work
Do **not** reopen regroup math. Highest-value follow-up is to validate the remaining main-form details that are still evidence-limited rather than inventing them: exact original `tmp_rank` art/behavior inside `group_infos`, exact original controller binding of `group_items` (source vs target), and true-device SpriteKit anchor/font/touch behavior. If no new original evidence is available, continue to the next proven Release-visible form gap instead of guessing.

Do not reopen frozen map/LOD/unit/HUD/camera/AI systems without a proven defect.

## Still not verified
Apple SDK/Xcode/iPhoneOS compilation and real-device SpriteKit font metrics, intrinsic-image anchor behavior, scrollbar/touch feel, and final Release configuration. Linux/SwiftPM verification cannot substitute for device acceptance.
