# P62 Native Defense Card Art Parity

P62 is a narrow evidence-led `form_defense` presentation closure on top of P61. It does not add gameplay and does not reopen frozen battlefield systems.

## Evidence used
- Mature P39 `nativeDefenseChoices()` explicitly maps installation cards to `image_ui_hd/defense_moat.png`, `defense_fences.png`, and `defense_bunker.png`.
- The same mature controller explicitly maps fortress cards to `buildmarker_smallfortress.png`, `buildmarker_mediumfortress.png`, `buildmarker_largefortress.png`, and `buildmarker_coastalartillery.png` in the recovered recruit sprite folders.
- All seven mapped Native files exist and are SHA-256 byte-identical to their frozen SOURCE_LEAN counterparts (7/7).
- Mature P39 card CSS preserves a 72x65 transparent choice cell, centered 42x35 object-fit image, 11px name row, 12px resource row, and `item_selected_ex.png` as the selection overlay.

## Landed
- Added `NativeOriginalDefenseArtCore` with the seven proven original mappings.
- `NativeOriginalDefenseRenderer` now consumes those exact assets rather than text-only placeholder cards.
- Selection now uses the original `item_selected_ex.png` overlay rather than a custom brown selected-cell fill.
- Added the mature P39 card-content rectangles to `NativeOriginalFormGeometryCore.Defense` so renderer content no longer relies on ad-hoc placement.
- Added aspect-fit placement so 42x49 installation images and 31x31 fortress markers preserve their original aspect ratios inside the 42x35 card image box.
- Costs, construction rules, one-fortress-per-round behavior, installation penalties, combat/economy, AI, map, LOD, units, flags, HP/HUD, camera and P33 impact timing are unchanged.

## Verification
- Native: **236/236 PASS** = 227 Swift Testing + 9 XCTest.
- Mature JS: **126/126 PASS**.
- NativeCore source+test parse: **167/167 PASS**; whole project Swift parse: **169/169 PASS**.
- SOURCE_LEAN: **6321/6321 unchanged**.
- Native Resources: **1751/1751 byte-provenanced**; P61 -> P62 resource diff **0/0/0**.
- Runtime resource audit: `errors=[]`, 101 battles, 7407/7407 unit visuals, 5482/5482 eligible building sprites, 877 animation units / 3519 motions, BILE 12/12.
- IPA preflight: **26/26 PASS**; cross-project scope guard PASS.
