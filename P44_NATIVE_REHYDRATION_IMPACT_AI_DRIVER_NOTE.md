# P44 Native Rehydration / Impact / Incremental AI — Checkpoint Note

Date: 2026-09-10
Lineage: **P39 -> P40 -> P41 -> P42 -> P43 -> P44**.

P44 does not rewrite campaign content, AI strategy, battle rules, or P39 systems. `SOURCE_LEAN/EW4_Web_Port_v0.61` remains the byte-frozen mature truth. P44 translates already-proven behavior into the Swift/SpriteKit implementation layer.

## Native parity landed in P44

- BattleSave schema 1..6 can be rehydrated into `NativeBattleGameplayState` without reapplying the player's +120 HP bonus.
- New battle and restored battle share one `installBattleRuntime(...)` path in SpriteKit.
- Restored runtime returns the complete persistence sidecar instead of silently dropping country resources, assignments, installations, fire/events, ItemStore, tavern, collect-medal or campaign-tech state.
- Native runtime can produce a schema-6 snapshot, JSON encode it, decode it, and rehydrate it without state drift in the covered fields.
- Native save slots reproduce the mature P39 contract: one autosave plus six manual slots, atomic writes, corrupt/unsupported saves treated as empty slots, and native-form-ready metadata.
- Runtime now carries P39 persisted unit state that had previously been absent from Swift: training level/EXP, fortress construction state, and player commander HP-bonus marker. Fresh BTL loading uses authored `raw[20]` training level.
- Player movement presentation uses the authoritative reconstructed path and P39 timing contract instead of teleporting directly to the destination.
- Authored impact timing is native: simulation can resolve first, but HP/death visibility is committed at the authored Attack impact point; counterattack has its own impact event; pending-killed units remain visible until commit.
- AI presentation is incremental. It consumes the existing native AI planner/gameplay logic and yields country/move/attack/round events one at a time; fixed-RNG final state matches the deterministic headless full-round simulator.
- SpriteKit round-button flow consumes the incremental AI driver and prevents overlapping AI rounds; READY playback pauses while movement/impact presentation owns the unit.

## Verification

- Native Swift: **72/72 PASS**.
- Mature P39/P43 JS truth: **126/126 PASS** from the correct `SOURCE_LEAN/EW4_Web_Port_v0.61` working directory.
- Full native resource audit: 101 battles, 2 worlds, Europe 79x68, 8001 battle objects, 5482/5482 eligible building sprites, 7407/7407 battle-unit visuals, 877 animation units, 1272 assets, 3519 motions, BILE 12/12, `errors=[]`.
- iOS Swift parse: **PASS** for all 63 current Swift source files. This is syntax validation only; real UIKit/SpriteKit typecheck/link still requires Xcode/iPhoneOS SDK.
- P43 preflight: **26/26 PASS**; resource hierarchy remains 1751 frozen files with 232 duplicate-basename groups protected against Xcode flattening.
- P43 -> P44 preservation: `SOURCE_LEAN` 6321/6321 byte-identical, missing=0, changed=0. Native existing files missing=0. Exactly three existing native code files intentionally changed (`BattleGameplayCore.swift`, `ResourceModels.swift`, `NativeBattleScene.swift`), plus new P44 parity cores/tests. The regenerated preflight JSON also changes as derived audit output.

## Explicitly still pending

- P42 round-settlement formulas exist in Swift, but the live round boundary is not yet wired to them. This must be done with an explicit effective commander/equipment/nobility projection; do not treat base commander data as the upgraded player state.
- Fortress construction round advancement still needs live native integration.
- Autosave must be placed at the proven mature round/dialogue boundary after settlement/round UI logic, not at an invented moment.
- Campaign/HQ/general/shop/academy/tutorial/audio/form systems remain mature P39 truth until each is parity-translated to native code. Their absence from Swift is not permission to redesign them.
- Actual unsigned IPA creation, iPhoneOS arm64 compilation, CoreGraphics/SpriteKit affine/texture verification, memory/FPS/thermal and touch A/B remain macOS/Xcode/real-device gates.
