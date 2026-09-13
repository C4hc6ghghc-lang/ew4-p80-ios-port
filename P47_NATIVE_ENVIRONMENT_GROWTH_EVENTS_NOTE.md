# P47 — Native battle environment / growth / script-event parity

P47 continues the same P39→P47 mainline. It does **not** rewrite Campaign or Conquest and does not alter the frozen map, camera, unit anchor/scale, flag, HP-arc, HUD or LOD geometry.

## Landed

- Real terrain, construction and field-installation reductions now feed the existing Swift combat resolver.
- Event morale lasts N/N+1/N+2, flank/surround morale is combined and Leadership clears negative morale, matching P39.
- General combat growth: rank/nobility thresholds, damage/kill inputs and skill/equipment growth multipliers.
- Shared mutable player-profile runtime: growth applies immediately to the next action and is persisted by the app.
- Battle training EXP remains after the primary hit + optional counter; dead units cannot be revived by a post-counter training level-up.
- Battle medal rolls use the same combat RNG stream and are accumulated through one sidecar reducer.
- Typed decoding of all 101 `battle_native_triggers.json` battle entries plus `native_trigger_targets.json` capture/death bindings.
- Capture, death and round events support morale, fire and dialogue sidecars with exact applied/fired dedupe keys.
- Fireproof behavior uses commander skill 2 or equipment function 16 and removes an existing fire cell when blocked.
- Event-applied morale/fire/applied/fired state remains inside schema6 snapshots.
- SpriteKit player/AI move and attack paths call the same event core; round events are applied after settlement.
- Fixed an actual P47 hardening find: `NativeBattleScene.applyBattleAttackSidecars` had accidental self-recursion. It is now non-recursive and covered by the centralized sidecar path.

## Verification

- Native discovered tests: **118/118 PASS** (109 Swift Testing + 9 XCTest).
- Mature SOURCE_LEAN regression: **126/126 PASS**.
- Full resource audit: **101 battles, 7407/7407 units, 5482/5482 building sprites, 877 animation units, 3519 motions, BILE 12/12, `errors=[]`**.
- iOS/renderer Swift syntax parse: **81 files, 0 failures**. This is not an Xcode/iPhoneOS typecheck/link substitute.
- IPA preflight: **26/26 PASS**, 1751 resources, 232 duplicate-basename groups protected by folder hierarchy.
- P46→P47 SOURCE_LEAN: **6321 files, changed 0, missing 0, new 0**.
- P46→P47 visual-sensitive Native paths: **0 changes**.

## Deliberately pending for P48

Event dialogue is now a typed sidecar/queue with exact fired-event state, but the original native Talk/StageIntro/Pause/Save/Load/Result forms are not yet fully bound in SwiftUI/SpriteKit. P48 must bind those using original layout/assets; do not invent a modern replacement UI.
