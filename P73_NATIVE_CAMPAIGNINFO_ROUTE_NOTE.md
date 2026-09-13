# P73 Native CampaignInfo Route Fidelity

Date: 2026-09-12
Parent: P72 Native Achievement Route Audited

## Closed gap
Native Campaign selection previously skipped original `form_campaigninfo`: tapping a campaign-zone pin entered the campaign list immediately. Mature P25 and frozen original evidence require:

`tap zone pin -> form_campaigninfo -> confirm -> form_compaignlist`

P73 restores that missing controller layer without changing campaign progression, stars, save/meta rules, hidden-stage unlocks, country-variant selection, or battle launch semantics.

## Frozen authority used
- `original_layout-568h.xml` `form_campaigninfo`: 155x83, background, arrow, title/age/nation list, 31x32 confirm button.
- `def_battleline.xml`: all six battleline rows, including `hide` and `stars` fields.
- Mature P25 placement/controller contract: popup anchored to exact original campaign-pin rectangles and clamped to the 568x320 viewport; exact original `.so` popup offset remains unavailable.

## Restored behavior
- Tapping one of the six campaign pins opens the corresponding CampaignInfo popup.
- Popup title uses original `name_<battleline>` CN strings.
- Age range and country flags come from the frozen six-line battleline data.
- Tapping another campaign pin switches the popup to that zone.
- Tapping outside the popup closes only the popup.
- Tapping the original confirm control enters that zone's campaign list.

## Verification
- P73 targeted CampaignInfo contracts: 4/4 PASS.
- Native full: 275/275 PASS = 266 Swift Testing + 9 XCTest.
- Mature Web: 126/126 PASS.
- NativeCore Sources+Tests: 183/183 parse PASS.
- Entire Native Swift tree: 185/185 parse PASS.
- SOURCE_LEAN: 6321/6321 unchanged.
- Native Resources: 1751/1751 byte-provenanced.
- Runtime resource audit: errors=[]; 101 battles; 7407/7407 unit visuals; 5482/5482 building sprites; 877 animation units / 3519 motions; BILE 12/12.
- IPA preflight: 26/26 PASS; scope guard PASS.

## Scope
P72 -> P73 product Swift: 0 added / 2 modified / 0 deleted.
- `NativeOriginalOuterShellCore.swift`
- `NativeOriginalOuterMenuScene.swift`

Tests: 1 added.
Resources: 0/0/0.
SOURCE_LEAN: 0/0/0.

## Evidence boundary
The inner 155x83 layout/data/controller flow is hard-backed. Popup placement uses the mature P25 pin-anchor/clamp contract because the original binary `.so` offset function is not present in the lean evidence. Xcode/iPhoneOS and true-device visual/touch calibration remain pending.
