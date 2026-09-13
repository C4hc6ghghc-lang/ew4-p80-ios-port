# P44 Native Migration Matrix — unified mainline

Status language:
- **Native landed** = Swift/SpriteKit implementation exists with parity coverage.
- **Partial native** = substantial native implementation exists but a mature P39 contract still needs binding/presentation work.
- **P39 truth / pending native parity** = already implemented in the mature P39 line; do not redesign or call it missing.

| Mature subsystem / contract | P44 status | Native source / next boundary |
|---|---|---|
| 568x320 logical space, hex, camera/touch, P35 LOD | **Native landed + frozen** | geometry/camera/LOD cores + P43 noon-regression gates |
| 101 battles / 2 worlds / BTL loading | **Native landed** | `BattleSession.swift`, `ResourceModels.swift` |
| 877 units / 3519 motions / compact BILE | **Native landed** | BILE/def-motion/animation cores + renderer |
| 7407 unit visuals / 5482 building sprites | **Native landed** | presentation resolver + resource audit |
| player +4/+4 attack, +120 HP, +2 movement | **Native landed** | player/combat/gameplay cores |
| select/move/capture/undo/attack/counter/death/cavalry extra action | **Native landed** | gameplay core + SpriteKit binding |
| movement path presentation | **Native landed parity core + Scene binding** | `NativeMovementPresentationCore.swift`, `NativeBattleScene.swift` |
| authored Attack-end HP/death impact timing | **Native landed parity core + Scene binding** | `NativeImpactPresentationCore.swift`, pending-impact queue |
| AI planner/execution/headless deterministic round | **Native landed** | existing AI cores |
| AI stepwise visible presentation | **Native landed core + Scene binding** | `NativeAIPresentationDriverCore.swift` |
| BattleSave schema 1..6 envelope | **Native landed** | `NativeBattleSaveCore.swift` |
| BattleSave runtime rehydration | **Native landed** | `NativeBattleRehydrationCore.swift`; no double +120 HP |
| Native runtime -> schema6 snapshot round-trip | **Native landed** | `NativeBattleSnapshotCore.swift` |
| autosave + 6 manual slot file store | **Native landed core** | `NativeBattleSaveSlotStore.swift`; original form binding pending |
| persisted training/construction unit state | **Native landed** | runtime/model/snapshot/rehydration support, BTL raw[20] initial training |
| round economy/training/facility/special healing math | **Native landed parity math; live hookup pending** | P42 `NativeRoundSettlementCore.swift`, `NativeTrainingParityCore.swift`; P45 target |
| fortress construction round progression | **P39 truth / pending live native parity** | next after settlement sequencing is fixed |
| result scoring/replay delta/collect medal | **Native landed core; result form pending** | P41 result core |
| conquest extinction | **Native landed core; forms pending** | P41 extinction core |
| Campaign targets/hidden stages/session/long-session meta | **P39 truth / pending native parity** | mature `native_campaign_*` truth; **not rewritten in P44** |
| HQ/general/rank/nobility/regroup/deployment | **P39 truth / pending native parity** | general/deployment cores/tests |
| princess system and explicit Lan/Victoria/Isabela overrides | **P39 truth / pending native parity** | existing override data/tests |
| ItemBank/deploy item/non-consuming consumables | **P39 truth / pending native parity** | mature inventory/useitem truth |
| shop/ItemStore/commerce/tavern | **P39 truth / pending native parity** | mature scene-shop/commerce/tavern truth |
| academy/unlimited zero-cost refresh | **P39 truth / pending native parity** | mature academy truth |
| campaign upgrades/warzone tech/recruit gates | **P39 truth / pending native parity** | protected upgrade/warzone truth |
| tutorial / achievements | **P39 truth / pending native parity** | mature native tutorial/achievement truth |
| 43/43 audio + 143 effect timelines | **P39 truth / pending native runtime binding** | audio manifests/cores/tests |
| StageIntro/Talk/Pause/UnitInfo/original forms | **P39 truth / pending native UI binding** | original 568h geometry + mature tests |

## P45 sequencing warning

The mature end-of-round order is authoritative. Do not reset player `attacked` flags before tent-heal evaluation. Current incremental AI driver still completes the headless round through existing gameplay APIs, so P45 must refactor the round boundary into an explicit settlement-ready step rather than bolting settlement onto `.roundCompleted` afterward.
