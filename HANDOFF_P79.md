# HANDOFF P79 — Native Battlefield Overlay Closure

Authoritative checkpoint: **P79**, 2026-09-13.

## Why P79 exists
P78 closed the dynamic transport-ship visual gap, but a second current-code audit found that historical P32/P36 notes had overstated Native parity: current `NativeBattleScene` still lacked country flags, commander battlefield bubbles and morale markers. P79 closes those actual Native renderer gaps and upgrades the machine gate so they cannot silently disappear again.

## Current hard gates
- Native: **291/291 PASS** = 282 Swift Testing + 9 XCTest.
- Mature SOURCE_LEAN JS: **126/126 PASS**.
- NativeCore Sources+Tests parse: **189/189 PASS**.
- Whole Native Swift tree parse: **191/191 PASS**.
- SOURCE_LEAN: **6321/6321**, unchanged.
- Native Resources: **1751/1751**, unchanged.
- runtime resource audit: 101 battles, 7407/7407 unit visuals, 5482/5482 building sprites, 877 animation units, 3519 motions, 12/12 BILE, errors `[]`.
- P79 map/unit/dynamic-overlay audit: errors `[]`.
- IPA preflight: 26/26 PASS.

## Product scope delta from P78
Exactly:
- + `NativeBattlefieldOverlayCore.swift`
- ~ `NativeBattleScene.swift`
- + `P79BattlefieldOverlayParityTests.swift`
No Native Resources or SOURCE_LEAN changes.

## Next action
On a real Mac, run **`./BUILD_FROM_CODEX_MAC.sh`**. Do not broadly refactor map/unit/HUD/camera or gameplay. First goal is **Xcode Build Succeeded**. Then do a real-device battle smoke focused on map drag/pinch, normal units, transport ships, flags, commander bubble, morale, HP/relation layers, movement/attack, AI and save/load.
