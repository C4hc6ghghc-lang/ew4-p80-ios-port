# HANDOFF P68

Authoritative checkpoint: **EW4 R14-39 P68 Native Regroup Confirm Preview Audited**, 2026-09-12.

Continue from P68; do not redo P50-P67. P68 is a narrow original-XML content recovery for `form_regroupconfirm`.

## Landed
- Restored the original source-commander preview region inside `form_regroupconfirm`: 78x98 `tmp_commander` authority at screen rect `(174,119,78,98)`.
- Reused mature 78x98 commander presentation evidence: 72x72 portrait, commander name, and military/nobility growth row.
- Restored the original 132x98 equipment group at `(261,119,132,98)`.
- Restored `text_equipitem`, original `common_lineframe_bold.png`, `infomarker_board.png`, `pattern_reoganizion.png`, and `common_line_hor.png` decoration/borders.
- Restored the original horizontal equipment list geometry: `(277,155,100,45)`, two 45x45 slots with 10px interval.
- The confirm preview consumes the **source** commander's real current `equipmentPair`; it does not preview the target commander and it does not invent replacement equipment.
- All 48 unique non-consumable equipment names resolve to existing Native `Resources/Items` artwork.
- Confirm preview remains display-only. `commitRegroup()` semantics, source deletion, equipment deletion, rank/nobility/stat transfer, inventory behavior, and all approved player modifications are unchanged.
- Added `P68RegroupConfirmPreviewFidelityTests.swift`.

## Verification
- Native **256/256 PASS** = 247 Swift Testing + 9 XCTest.
- Mature JS **126/126 PASS**.
- NativeCore Sources+Tests **174/174 parse PASS**; entire native Swift tree **176/176 PASS**.
- SOURCE_LEAN **6321/6321 unchanged**.
- Native Resources **1751/1751 byte-provenanced**.
- Runtime resource audit `errors=[]`: 101 battles, 7407/7407 unit visuals, 5482/5482 eligible building sprites, 877 animation units / 3519 motions, BILE 12/12.
- IPA preflight **26/26 PASS**; script syntax PASS; cross-project scope guard PASS.
- Equipment artwork path coverage **48/48 PASS** for unique non-consumable equipment names.

## P67 -> P68 scope
- Product Swift: **0 added / 2 modified / 0 deleted**.
  - `NativeOriginalFormGeometryCore.swift`
  - `NativeOriginalRegroupScene.swift`
- Test Swift: **1 added / 0 modified / 0 deleted**.
- Native Resources: **0/0/0**.
- SOURCE_LEAN: **0/0/0**.

## Next isolated work
The highest-priority proven form gap is now the **main `form_regroup` content layer**, not the confirmation dialog. Current Native still uses synthetic 120x142 source/target cards, while original XML specifies 78x98 `tmp_commander` source/target widgets, a 146x120 preview group, a 146x120 equipment group, and `arrow_reoganizion.png`. Recover those proven visual/content internals without altering regroup math or commit semantics.

Continue evidence-led Release-visible auditing after that. Do not reopen frozen map/LOD/unit/HUD/camera/AI systems without a proven defect.

## Still not verified
Apple SDK/Xcode/iPhoneOS compilation and real-device SpriteKit font metrics, item icon sizing, flip/anchor behavior for the bottom reorganization ornament, touch behavior, and final Release configuration. Linux/SwiftPM verification cannot substitute for device acceptance.
