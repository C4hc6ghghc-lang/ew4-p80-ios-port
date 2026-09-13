# HANDOFF P71

Authoritative checkpoint: **EW4 R14-39 P71 Native General Upgrade Audited**, 2026-09-12.

Continue from P71; do not redo P50-P70. P71 is a narrow recovery of the previously missing Native `form_generalupgrade` route.

## Landed
- HQ normal-general cards now expose the original 19x19 `button_rank.png` upgrade hotspot.
- Added a 325x185 GeneralUpgrade form with military, nobility and full-rank groups recovered from frozen 568h XML and mature P39 behavior.
- Military/nobility/full upgrade calculations use the mature P39 thresholds and formulas and write back to `NativePlayerProfile`.
- Player medals are **not deducted**, preserving the locked infinite-medals modification, while the original medal costs remain visible in the UI.
- Successful upgrade persists through the existing profile save path and plays `sfx_lvup2.wav`.
- Added `P71GeneralUpgradeNativeParityTests.swift`.

## Verification
- Native **267/267 PASS** = 258 Swift Testing + 9 XCTest.
- Mature JS **126/126 PASS**.
- NativeCore Sources+Tests **179/179 parse PASS**; entire Native Swift tree **181/181 PASS**.
- SOURCE_LEAN **6321/6321 unchanged**.
- Native Resources **1751/1751 byte-provenanced**.
- GeneralUpgrade core UI **10/10**, rank **14/14**, class **9/9** assets present.
- Runtime resource audit `errors=[]`: 101 battles, 7407/7407 unit visuals, 5482/5482 eligible building sprites, 877 animation units / 3519 motions, BILE 12/12.
- IPA preflight **26/26 PASS**; scope guard PASS; script syntax PASS.

## P70 -> P71 scope
- Product Swift: **2 added / 4 modified / 0 deleted**.
- Test Swift: **1 added / 0 modified / 0 deleted**.
- Native Resources: **0/0/0**.
- SOURCE_LEAN: **0/0/0**.

## Evidence boundary / next work
Do not reopen general growth rules or the infinite-medals override. The least-certain GeneralUpgrade detail is the XML `tcmder` 156x196 declaration inside a 325x185 window; P71 uses the recovered 2x `tmp_commander` interpretation and a 78x98 logical card. Confirm on Xcode/iPhone or stronger original-binary evidence before changing it.

For the next isolated Release-visible pass, first run the XML-form-to-Native-route audit again rather than polishing GeneralUpgrade speculatively. Prefer a form with XML + resource + mature-controller evidence; if only geometry is known, leave it alone.

## Still not verified
Apple SDK/Xcode/iPhoneOS compilation and real-device SpriteKit/UIKit font metrics, texture anchors, pressed states, touch hitboxes and Release configuration. Linux cannot type-compile the guarded SpriteKit/UIKit body and cannot substitute for device acceptance.
