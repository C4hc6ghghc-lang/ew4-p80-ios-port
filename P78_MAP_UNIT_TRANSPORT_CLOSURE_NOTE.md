# P78 — Map / Unit / Transport Visual Closure

Checkpoint: **EW4 R14-39 P78**, 2026-09-13.

## Why P78 exists
P77 was a hardened Xcode handoff candidate, but a targeted pre-Xcode audit found one real dynamic presentation gap that the previous 7407/7407 static battle-unit resolver audit could not expose: an embarked land unit had correct gameplay state and combat rules, but `NativeBattleScene` had no dedicated `transportship1/transportship2` render branch.

P78 closes that gap and adds a machine-readable map/unit audit. No game resources and no mature SOURCE_LEAN files are modified.

## Transport closure
Recovered P34 rule is now consumed by Native SpriteKit:
- ordinary embarked land unit -> `transportship1.png`;
- function-12 Armored Carrier -> `transportship2.png`;
- ship 1 source size/ref: **151×170 / (70,107)**, natural facing **right**;
- ship 2 source size/ref: **150×194 / (94,119)**, natural facing **left**;
- visual scale remains the frozen native **0.5**;
- movement updates transport facing from the current authored path segment;
- embark immediately refreshes the tactical model to the transport ship;
- disembark restores the ordinary unit model when the completed move refreshes the unit;
- READY/attack animation playback no longer overwrites an embarked transport model with the land-unit BILE model.

Gameplay was not rewritten. Dock permission, Troopship cost, embarked state, function-12 combat exemption and normal embarked combat penalty stay in the existing gameplay core.

## P78 map/unit audit — zero errors
`P78_MAP_UNIT_VISUAL_AUDIT.json` is generated directly from the current package.

### World/map layer
- worlds: **2**;
- Europe: **79×68 = 5372 cells**;
- America: **55×76 = 4180 cells**;
- battles: **101**;
- map distribution: **84 Europe / 17 America**;
- every battle header rectangle fits its selected world;
- every one of the **7407 units** is inside its authored battle rectangle;
- every one of the **8001 battle objects** is inside its authored battle rectangle;
- `Maps/europe.png` SHA-256 is byte-identical to frozen SOURCE_LEAN;
- `Maps/america.png` SHA-256 is byte-identical to frozen SOURCE_LEAN.

Map SHA-256:
- Europe: `d614cb88599c3d926ac623bf008daf5453081d854268855c5b8eefb8b04f99fa`
- America: `ac7a24db6ae06be7a02fbda2e32fe27d02cc962deb4263f9e16e07999de98c22`

### Unit/animation layer
- battle unit instances: **7407**;
- resolved visual instances: **7407/7407**;
- distinct battle army families: **22**;
- native animation units: **877**;
- animation assets: **1272**;
- def-motion motions: **3519**;
- compact BILE resources: **12/12 decoded**;
- all 12 BILE `.bin/.xml/.png` trios are byte-identical to frozen SOURCE_LEAN runtime copies;
- every resolved battle unit has a valid READY motion and asset/resource chain.

Battle-family coverage:
- infantry families: Militia 224, Line Infantry 528, Light Infantry 357, Grenadier 528, Guards 508, Machine Gun 43;
- cavalry/mobile: Light Cavalry 352, Heavy Cavalry 431, Guards Cavalry 361, Armored Car 60;
- artillery: Light 597, Heavy 547, Siege 78, Rocket 125;
- navy: Privateer 208, Frigate 476, Battleship 297, Ironclad 17;
- fort: Small Fortress 431, Fortress 495, Large Fortress 272, Coastal Fort 472.

### Status / LOD layer
- four relationship/HP ring source sprites exist and match frozen assets;
- `mark_unit_0.png ... mark_unit_21.png`: **22/22** exist and match frozen assets;
- native anchor math remains consumed by `NativeAnimationTiming`;
- frozen LOD constants remain: detail switch **0.5**, unit visual zoom min **0.76**, max **1.18**, exponent **0.46**;
- native authored unit asset scale remains **0.5**.

## P77 -> P78 source delta
Product Swift:
- **+1** `EW4NativeCore/NativeTransportPresentationCore.swift`
- **1 modified** `EW4NativeRenderer/NativeBattleScene.swift`
- **0 deleted**

Tests:
- **+1** `P78TransportPresentationTests.swift`

Frozen data:
- Native Resources **1751/1751 unchanged**;
- SOURCE_LEAN **6321/6321 unchanged**.

## Regression state
- Native: **287/287 PASS = 278 Swift Testing + 9 XCTest**;
- Mature Web: **126/126 PASS**;
- NativeCore Sources+Tests: **187/187 parse PASS**;
- full Native Swift tree: **189/189 parse PASS**;
- Native resource audit: `errors=[]`, 7407/7407 unit visuals, 5482/5482 eligible building sprites, 12/12 BILE;
- P78 map/unit visual audit: `errors=[]`.

## Evidence boundary
P78 substantially lowers the risk of missing maps, unresolved unit families, missing BILE/READY assets, lost native anchors, or absent transport-ship rendering.

It still does **not** claim true-device pixel acceptance. Xcode/iPhone must still verify SpriteKit filtering, real touch/pinch feel, final z-order, font metrics, per-frame appearance and small anchor/flag/HP-ring differences.
