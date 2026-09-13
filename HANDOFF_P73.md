# HANDOFF P73

Authoritative checkpoint: **EW4 R14-39 P73 Native CampaignInfo Route Audited**, 2026-09-12.

Continue from P73; do not redo P50-P72. P73 closes the missing Native `form_campaigninfo` controller layer between Campaign-zone pins and the campaign list.

## Landed
- Campaign-zone tap no longer jumps directly to `form_compaignlist`.
- Restored mature/original route: `zone pin -> 155x83 CampaignInfo -> confirm -> campaign list`.
- Added full frozen six-row `def_battleline.xml` authority to Native `CampaignInfo` data: name/hide/start/end/stars/countries.
- CampaignInfo title uses original CN string key, age range and exact nation flag set.
- Reuses original `button_choosebattlezoneinfo.png`, `arrow_choosebattlezoneinfo.png`, `button_confrim.png` and frozen flag assets.
- Popup switching/outside-close/confirm behavior follows mature P25 controller semantics.
- Existing campaign progression, 73-stage long-session semantics, stars, hidden unlocks, two-country branch flow and battle launch rules are unchanged.

## Verification
- Native **275/275 PASS** = 266 Swift Testing + 9 XCTest.
- Mature Web **126/126 PASS**.
- NativeCore Sources+Tests **183/183 parse PASS**; entire Native Swift tree **185/185 PASS**.
- SOURCE_LEAN **6321/6321 unchanged**.
- Native Resources **1751/1751 byte-provenanced**.
- Runtime resource audit `errors=[]`: 101 battles, 7407/7407 unit visuals, 5482/5482 building sprites, 877 animation units / 3519 motions, BILE 12/12.
- IPA preflight **26/26 PASS**; scope guard PASS; script syntax PASS.

## P72 -> P73 scope
- Product Swift: **0 added / 2 modified / 0 deleted**.
- Test Swift: **1 added / 0 modified / 0 deleted**.
- Native Resources: **0/0/0**.
- SOURCE_LEAN: **0/0/0**.

## Evidence boundary / next work
CampaignInfo inner geometry/data/flow are hard-backed. Exact native popup offset remains a mature P25 pin-anchor/clamp adaptation because the original `.so` positioning function is unavailable.

Continue the XML-form-to-Native-route census. Prefer the next Release-visible single-player gap only where XML + frozen resources + mature controller evidence converge. Do not invent platform/service forms, ads, multiplayer, or unsupported online behavior.

## Still not verified
Apple SDK/Xcode/iPhoneOS compilation and real-device SpriteKit/UIKit type checking, font metrics, popup anchor feel, pressed states and Release configuration.
