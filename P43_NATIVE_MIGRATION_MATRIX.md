# P42 Native Migration Matrix — unified mainline

P42 continues the recovered unified mainline and does **not** restart the game. It preserves the complete P39 single-player PORT_ONLY tree and integrates the already-written Swift/SpriteKit work under `SOURCE_NATIVE/EW4_iOS_NativePort`.

## Status meanings
- **Native landed**: a Swift/NativeCore or SpriteKit implementation exists and has native tests/resource audit coverage.
- **Partial native**: important native pieces exist, but the complete P39 behavior/presentation contract is not yet replaced.
- **P39 truth / pending native parity**: the feature is already implemented in the mature P39 mainline; it is *not missing from the project*. It simply has not yet been completely replaced by Swift.

## Migration map

| P39 mature subsystem / contract | P40 native status | Native implementation / next parity source |
|---|---|---|
| 568×320 logical space, odd-r hex, camera/touch math | Native landed | `LogicalGeometry.swift`, `NativeCamera.swift`, `NativeMovementCore.swift` |
| 101 battle + 2 world data loading | Native landed | `BattleSession.swift`, `ResourceModels.swift`, `NativeResourceAudit.swift` |
| 877 units / 3519 motions / compact BILE | Native landed | `CompactBILE.swift`, `DefMotion.swift`, `NativeAnimationSequenceCore.swift`, renderer |
| 7407 battle-unit visual resolution / 5482 building sprites | Native landed | `NativeBattlePresentation.swift`, `NativeResourceAudit.swift`, SpriteKit renderer |
| player +4/+4 attack, +120 HP, +2 movement | Native landed | `PlayerUnitRules.swift`, combat/gameplay tests |
| select/reachable/move/capture/undo/attack/counter/death/cavalry extra action | Native landed core; presentation partial | `BattleGameplayCore.swift`, `NativeBattleScene.swift` |
| semantic unit LOD / relation ring / HP arc / READY/attack playback | Partial native, substantial | `NativePresentationLODCore.swift`, `NativeUnitStatusCore.swift`, renderer |
| AI target planner + move/capture/attack primitives + deterministic headless round | Native landed core; visible stepwise driver pending | `NativeAIPlannerCore.swift`, `NativeAIRoundSimulationCore.swift` |
| attack impact timing / delayed HP+death/result gate | **P39 truth / partial native** | P39 P33 timing contract is authoritative; Native currently separates simulation/presentation but does not yet commit at authored impact point |
| movement path animation/effects | **P39 truth / partial native** | P39 movement-effect pipeline already exists; Native current movement position update still needs parity playback |
| BattleSave schema 6 / compatibility envelope | **Native landed contract; runtime rehydration pending** | `NativeBattleSaveCore.swift`; schemas 1..6, camera normalization, extended state fields, transient animation-key stripping |
| round settlement, food, healing | **Native landed parity core; live scene binding pending** | `NativeRoundSettlementCore.swift`, `NativeTrainingParityCore.swift`; exact P39 economy/training/supply/special-heal formulas |
| stage turn limits | **Native landed in result core** | `NativeResultCore.swift` + Campaign BTL turn-limit tests |
| result controller / five-grade awards / replay delta | **Native landed core; result scene presentation pending** | `NativeResultCore.swift`; exact five-grade formula, cumulative medal deltas, campaign completion rewards, collect-medal proc |
| Campaign targets, hidden stages, session persistence, six-zone long session | **P39 truth / pending native parity** | `native_campaign_*`, P17/P24/P25 tests |
| Conquest extinction / victory-defeat outcome | **Native landed core; selection/failure/complete/challenge UI pending** | `NativeConquestExtinctionCore.swift`; user-locked land-army + land-facility + port extinction rule |
| HQ / general info / upgrades / regroup / deployment / dismissal | **P39 truth / pending native parity** | `native_general_core.js`, `general_deployment_core.js`, P18/P19/P24 tests |
| Princess ownership/overrides/deployment | **P39 truth / pending native parity** | `player_princess_overrides.json`, princess tests |
| ItemBank / deploy item / consumables | **P39 truth / pending native parity** | `item_inventory_core.js`, `native_useitem_core.js`, deployitem tests |
| Shop / battle ItemStore / commerce / tavern | **P39 truth / pending native parity** | `native_scene_shop_core.js`, `native_commerce_core.js`, shop/tavern tests |
| Military Academy / infinite refresh / candidate logic | **P39 truth / pending native parity** | `native_academy_core.js`, academy/getgeneral tests |
| campaign upgrades / warzone tech / recruitment gates | **P39 truth / pending native parity** | `native_upgrade_core.js`, `native_warzone_tech.json`, P21 tests |
| construction / facility upgrades / training | **P39 truth / pending native parity** | `native_construction_core.js`, training/construction tests |
| tutorial 273/273 commands / native tutorial forms | **P39 truth / pending native parity** | `native_tutorial_core.js`, tutorial tests |
| achievements | **P39 truth / pending native parity** | `native_achievement_core.js`, P27/P28/P29 tests |
| 43/43 native audio, battle music randomization, 143 timed SFX timelines | **P39 truth / pending native runtime binding** | audio manifests and `native_*audio*` cores/tests |
| StageIntro / Talk / Pause / UnitInfo / native-form geometry | **P39 truth / pending native SwiftUI/SpriteKit parity** | original 568h layout + P20/P22/P23/P24/P34/P36 tests |

## Non-negotiable lineage rule

From this checkpoint forward the mainline is **P39 → P40 → P41 → P42 → P43...**. Do not rename the project into a separate `Native vX` mainline. `SOURCE_NATIVE` is an implementation layer inside the same project. A feature absent from `SOURCE_NATIVE` must be checked against the P39 mature source/tests before anyone calls it "not implemented" or rewrites it.

## P43 build/handoff hardening landed

| Contract | P43 status |
|---|---|
| Unified numbering / no parallel Native-vX branch | **Locked** by current `START_HERE.md` + `NEXT_MODEL_PROMPT.txt` |
| Native Resources hierarchy preserved in Xcode | **Locked**: `../Resources` is `type: folder`, `buildPhase: resources` |
| Resource exact snapshot | **Locked**: 1751-file SHA-256 manifest + preflight |
| Duplicate-basename flattening hazard | **Detected and gated**: 232 case-insensitive groups at P43 |
| Noon-regression native constants | **Locked**: Python preflight + Swift `NativeNoonRegressionLockTests` |
| Production boot full resource audit | **Removed from Release path**; DEBUG-only, build preflight remains authoritative |
| No Web runtime shortcut | **Gated** in native build inputs and post-build linkage/payload checks |
| Codex/macOS unsigned IPA build | **One-command scripted**; real execution still requires Xcode/iPhoneOS SDK |
| Post-build arm64/resource/IPA verification | **Scripted**; cannot be executed in Linux until `.app` exists |
