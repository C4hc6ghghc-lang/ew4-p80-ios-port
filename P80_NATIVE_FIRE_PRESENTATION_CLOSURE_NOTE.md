# P80 Native Fire Presentation Closure

P80 closes a runtime-only battle presentation gap that static map/unit audits could not expose. `fireCells` already existed in battle events, save/rehydration and fireproof clearing logic, but current Native SpriteKit did not render those cells.

P80 adds `NativeBattleFirePresentationCore.swift` and a narrow `NativeBattleScene.swift` integration using the frozen mature `anim_fire_hd.png` atlas. Contract: six source frames, 160ms cadence, 42 logical px height, alpha 0.86, layer below units, live add/remove synchronization from `persistenceContext.fireCells`, and automatic restoration after load.

No battle rules changed. No Native Resources changed. No SOURCE_LEAN changed.
