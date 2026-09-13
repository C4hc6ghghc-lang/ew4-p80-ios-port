# HANDOFF P61

Authoritative checkpoint: **EW4 R14-39 P61 Native Battle Auxiliary Forms Audited**, 2026-09-11.

Continue from P61; do not redo P50-P60. P61 is a narrow original-form cleanup, not a feature expansion.

## Landed
- `form_useitem` now uses recovered XML geometry through shared `NativeOriginalFormGeometryCore.UseItem` for both rendering and hit-testing.
- Removed raw item-ID placeholder cards and restored original frozen consumable artwork for Wine / Spirit / Medikit / Medikit L / First Aid Box.
- Restored original Chinese title/name/description string consumption for battle consumables.
- `form_defense` now consumes recovered XML list/description/button geometry through shared `NativeOriginalFormGeometryCore.Defense`; visual row positions and hitboxes no longer maintain separate math.
- Added shared `NativeOriginalItemArtCore` for deterministic original item filename mapping.
- No item effects, player non-consumption override, defense choices/costs, economy, combat, AI, map, LOD, units, HUD, camera or P33 timing rule changed.

## Verification
- Native **233/233 PASS** = 224 Swift Testing + 9 XCTest.
- Mature JS **126/126 PASS**.
- NativeCore real source+test files: **166/166 parse PASS**, build cache excluded. Entire project Swift tree additionally parses **168/168** including Package.swift and iOS app entrypoint.
- SOURCE_LEAN **6321/6321 unchanged**.
- Native Resources **1751/1751 byte-provenanced**.
- Resource runtime audit `errors=[]`: 101 battles, 7407/7407 unit visuals, 5482/5482 eligible building sprites, 877 units / 3519 motions, BILE 12/12.
- IPA preflight **26/26 PASS**; script syntax PASS; cross-project scope guard PASS.

## P60 -> P61 scope
- Product Swift: **1 added / 3 modified / 0 deleted**.
- Test Swift: **1 added / 0 modified / 0 deleted**.
- Native Resources: **0/0/0**.
- SOURCE_LEAN: **0/0/0**.
- Direct APK/AAB: **0**; 12 nested ZIPs, APK/AAB hits: **0**.
- Build cache directories: **0**.

## Next isolated work
Continue evidence-led form/window cleanup only. The most obvious remaining caveat in this exact area is `form_defense` card artwork: geometry/hitboxes are now evidence-backed, but full original facility-card art parity is **not** claimed because a proven one-to-one frozen resource mapping has not yet been established. Trace original evidence before changing it; do not invent replacement art.

## Still not verified
Apple SDK/Xcode/iPhoneOS compilation and real-device SpriteKit appearance/touch behavior. Linux/SwiftPM verification cannot substitute for device acceptance.
