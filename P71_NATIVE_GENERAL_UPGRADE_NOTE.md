# P71 Native General Upgrade Note

P71 restores the missing Native `form_generalupgrade` route and presentation without rewriting general growth semantics or spending the player's infinite medals.

## Landed
- Restored the mature HQ entry point: every normal owned general card now exposes the original 19x19 `button_rank.png` hotspot at the top-right of the card.
- Added `NativeGeneralUpgradeCore` using the mature P39 growth thresholds and formulas:
  - military thresholds: 500, 800, 1200, 1900, 3000, 4800, 7500, 12000, 19000, 30000, 48000, 76000, 120000, 200000;
  - military next-rank cost = `ceil(remaining * 0.008)`;
  - nobility thresholds: 100, 200, 300, 450, 675, 1000, 1500, 2250, 3375;
  - nobility next-level cost = `ceil(remaining * 0.2)`;
  - full-upgrade displayed cost is capped at 3600;
  - maximum military rank 14 / nobility 9.
- Upgrade actions modify only the selected general's growth state. Medals are displayed as the original cost currency but are not deducted, preserving the already locked infinite-medals player override.
- Restored the 325x185 `form_generalupgrade` shell with the three original upgrade groups: military, nobility, and full-rank; original medal-cost buttons, rank/class art, HP/recovery markers, `marker_max_2.png`, `arrow_reoganizion.png`, and `pattern_stage_intro.png` are consumed from frozen Native Resources.
- Upgrade success writes the profile through the existing coordinator save path and plays `sfx_lvup2.wav`, then rerenders the form.
- Added `P71GeneralUpgradeNativeParityTests.swift`.

## Evidence boundary
The frozen XML declares the `tcmder` element as 156x196 inside a 325x185 window. That cannot be a literal on-screen footprint. P71 interprets it through the project's recovered 2x `tmp_commander` scale and renders the commander at a 78x98 logical footprint, consistent with the mature commander widgets used elsewhere. This is the least-certain geometry detail and remains an Apple-device/original-binary visual acceptance item.

Linux SwiftPM also excludes code guarded by `#if canImport(SpriteKit) && canImport(UIKit)`. The renderer has full Swift syntax parsing plus source-contract tests, while true SpriteKit/UIKit type compilation still requires Xcode/iPhoneOS.

## Verification
- Native **267/267 PASS** = 258 Swift Testing + 9 XCTest.
- Mature JS **126/126 PASS**.
- NativeCore Sources+Tests **179/179 parse PASS**; entire Native Swift tree **181/181 parse PASS**.
- SOURCE_LEAN **6321/6321 unchanged**.
- Native Resources **1751/1751 byte-provenanced**.
- GeneralUpgrade UI assets **10/10**, rank icons **14/14**, class icons **9/9** present.
- Runtime resource audit `errors=[]`: 101 battles, 7407/7407 unit visuals, 5482/5482 eligible building sprites, 877 animation units / 3519 motions, BILE 12/12.
- IPA preflight **26/26 PASS**; scope guard PASS; script syntax PASS.

## P70 -> P71 scope
- Product Swift: **2 added / 4 modified / 0 deleted**.
  - Added `NativeGeneralUpgradeCore.swift`.
  - Added `NativeOriginalGeneralUpgradeScene.swift`.
  - Modified `NativeHeadquartersCore.swift`.
  - Modified `NativeOriginalFormGeometryCore.swift`.
  - Modified `NativeOriginalHeadquartersScene.swift`.
  - Modified `EW4NativePortApp.swift`.
- Test Swift: **1 added / 0 modified / 0 deleted**.
- Native Resources: **0/0/0**.
- SOURCE_LEAN: **0/0/0**.
