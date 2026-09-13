# P53 Native HQ Management + Tavern note

P53 closes the next Native shell gap without rewriting the mature single-player backend.

### HQ management
- Added `NativeHeadquartersManagementCore` with atomic equipment, dismissal and regroup mutations.
- Added SpriteKit Native original-shell surfaces for DeployItem, regroup and dismissal.
- Wired HQ general detail buttons through the app coordinator and persisted to `player_profile_v61.json`.
- Added dedicated tests for item replacement/return, consumable/flag locks, full-bank dismissal blocking, dismissal return, regroup deletion and mature transfer tables.

### Battle Tavern
- Added `NativeBattleTavernCore` using recovered battle Tavern catalog/state.
- Added original-shell Tavern renderer and battle-scene modal routing.
- New battles initialize Tavern sidecar state only when absent; loaded saves keep their existing Tavern state.
- Recruitment commits battle resources + owned commander + shifted Tavern queue before autosave.
- Added tests for recovered state normalization, resource/medal semantics, queue shifting and lock behavior.

### Safety scope
No Native runtime resource files and no SOURCE_LEAN files changed. `NativeBattleScene.swift` changed only for Tavern state initialization/modal routing/input blocking/recruit persistence. Frozen map, camera, LOD, unit visuals, flags, HP arcs, HUD geometry and combat/impact timing were not rewritten.
