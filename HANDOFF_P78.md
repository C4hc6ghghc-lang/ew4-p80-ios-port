# HANDOFF P78 — Map / Unit / Transport Closure + Xcode Candidate

Authoritative checkpoint: **EW4 R14-39 P78**, 2026-09-13.

Continue from P78. Do not redo P50-P77. Do not reopen frozen map/unit/HUD/camera constants without a real Xcode/device failure or new hard original evidence.

## What changed from P77
P78 found and closed one real presentation omission: embarked land units had no Native `transportship1/transportship2` rendering branch.

P78 adds:
- `NativeTransportPresentationCore.swift`;
- NativeBattleScene embarked transport rendering;
- function-12 Armored Carrier -> `transportship2`, otherwise `transportship1`;
- native half-scale refs and natural-facing mirroring;
- movement-segment transport facing updates;
- immediate visual refresh after embark;
- transport-safe READY/attack presentation behavior;
- `P78TransportPresentationTests.swift`;
- `P78_MAP_UNIT_VISUAL_AUDIT.py/.json/.log`.

No Native Resource or SOURCE_LEAN file changed.

## Current hard gates
- Native **287/287 PASS = 278 Swift Testing + 9 XCTest**;
- Mature Web **126/126 PASS**;
- NativeCore Sources+Tests **187/187 parse PASS**;
- full Native Swift tree **189/189 parse PASS**;
- Native Resources **1751/1751**;
- SOURCE_LEAN **6321/6321**;
- Native resource audit `errors=[]`: 101 battles, 7407/7407 unit visuals, 5482/5482 eligible building sprites, 877 animation units, 3519 motions, 12/12 BILE;
- P78 map/unit visual audit `errors=[]`.

## Map/unit confidence
Hard-proven before Xcode:
- Europe/America world maps exist, match frozen SOURCE_LEAN byte-for-byte and are selected by NativeBattleScene;
- all 101 battle rectangles and their 7407 units / 8001 objects are within authored bounds;
- all 7407 battle-unit instances resolve to valid animation-unit + READY-asset chains;
- all 12 BILE runtime triplets match frozen SOURCE_LEAN byte-for-byte;
- 22/22 army markers and four relationship ring sprites match frozen assets;
- native anchor, 0.5 scale and LOD contracts remain frozen;
- dynamic embarked transport visuals now have a real Native branch.

Still pending Apple/device proof:
- SpriteKit/UIKit type-check inside Apple SDK;
- final filtering/z-order/anchor appearance;
- touch/pinch feel;
- transport/ship/flag/HP-ring small visual calibration.

## Next milestone
**X1 — first real Xcode Release/iphoneos Build Succeeded.**

Run from package root on Mac:
`./BUILD_FROM_CODEX_MAC.sh`

Fix only real Apple compiler/build failures first. Do not ask Codex to broadly redesign the map, unit renderer, HUD, camera or gameplay.
