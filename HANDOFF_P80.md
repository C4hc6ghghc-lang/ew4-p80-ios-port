# HANDOFF P80 — Dynamic Fire Presentation Closure

Authoritative checkpoint: **P80**, 2026-09-13.

## Why P80 exists
P78/P79 closed transport ships and unit overlays, then a final runtime-state audit found another presentation-only omission: battle `fireCells` were fully tracked and persisted but invisible in Native SpriteKit. P80 closes that gap.

## Current hard gates
- Native: **295/295 PASS** = 286 Swift Testing + 9 XCTest.
- Mature SOURCE_LEAN JS: **126/126 PASS**.
- NativeCore Sources+Tests parse: **191/191 PASS**.
- Whole Native Swift tree parse: **193/193 PASS**.
- SOURCE_LEAN: **6321/6321**, unchanged.
- Native Resources: **1751/1751**, unchanged.
- runtime resource audit: 101 battles, 7407/7407 unit visuals, 5482/5482 building sprites, 877 animation units, 3519 motions, 12/12 BILE, errors `[]`.
- P80 map/unit/dynamic-state audit: errors `[]`, including transports, flags, 190 battle commander portraits, morale and live fire-cell rendering.
- IPA preflight: 26/26 PASS.

## Product scope delta from P79
Exactly:
- + `NativeBattleFirePresentationCore.swift`
- ~ `NativeBattleScene.swift`
- + `P80BattleFirePresentationTests.swift`
No Native Resources or SOURCE_LEAN changes.

## Next action
On a real Mac run **`./BUILD_FROM_CODEX_MAC.sh`**. First milestone is **Xcode Build Succeeded**. Do not reopen frozen map/unit/LOD/overlay/fire math for unrelated compiler errors. Then do real-device battle smoke including fire event appearance/removal, transport, flags, commander bubble, morale, HP/relation layers, movement/attack, AI and save/load.
