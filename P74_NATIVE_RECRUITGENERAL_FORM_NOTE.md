# P74 Native RecruitGeneral Form Fidelity

Date: 2026-09-12
Parent: P73 Native CampaignInfo Route Audited

## Closed gap
`form_recruitgeneral` already had working battle-tavern recruitment semantics, but its Native presentation still used an approximate hand-drawn row and a star-string placeholder where the original XML declares separate military-rank and nobility-rank widgets. P74 restores the evidence-backed 300x275 four-row presentation without changing recruitment logic.

## Frozen authority used
- `original_layout-568h.xml` `form_recruitgeneral`: 300x275 user window, four 55px rows, 0.65 commander presentation, 24x24 general-info button, 75x15 name board, military/nobility rank widgets, 75x49 cost group and 80x40 recruit button.
- Mature P19 RecruitGeneral geometry/controller pass.
- Existing frozen UI assets: `form_back`, `common_lineframe_bold`, `common_lineframe`, `button_generalinfo_blue`, `general_nameboard`, `rank_1..14`, `class_1..9`, medals/money/industry markers and green recruit button.

## Restored presentation
- Four rows now consume shared `NativeOriginalFormGeometryCore.Tavern` geometry.
- Replaced the Native star-string placeholder with actual military-rank and nobility-rank artwork from Commander `rank` / `nobilityrank`.
- Restored original row and cost-group frames and original resource-marker placement.
- Visual recruit/info controls and hitboxes now share the same geometry source.

## Unchanged semantics
`NativeBattleTavernCore` remains authoritative for candidate visibility, round/resource/ownership locks and recruitment. Player infinite-medal policy, money/industry costs, owned-general rules and battle state are unchanged.

## Verification
- P74 directed contracts: 4/4 PASS.
- Native full: 279/279 PASS = 270 Swift Testing + 9 XCTest.
- Mature Web: 126/126 PASS.
- NativeCore Sources+Tests: 184/184 parse PASS.
- Entire Native Swift tree: 186/186 parse PASS.
- SOURCE_LEAN: 6321/6321 unchanged.
- Native Resources: 1751/1751 byte-provenanced.
- Runtime resource audit: errors=[]; 101 battles; 7407/7407 unit visuals; 5482/5482 building sprites; 877 animation units / 3519 motions; BILE 12/12.
- IPA preflight: 26/26 PASS; scope guard PASS.

## Scope
P73 -> P74 product Swift: 0 added / 2 modified / 0 deleted.
- `NativeOriginalFormGeometryCore.swift`
- `NativeOriginalTavernRenderer.swift`

Tests: 1 added.
Resources: 0/0/0.
SOURCE_LEAN: 0/0/0.

## Evidence boundary
The outer row/cost/button geometry is hard-backed by XML/P19. The internal visual packing of the original composite `tmp_rank` widget is not independently recovered from the original binary; P74 uses the frozen rank/class artwork inside the XML-declared rank regions rather than inventing a new rank system. Xcode/iPhoneOS and true-device visual/touch calibration remain pending.
