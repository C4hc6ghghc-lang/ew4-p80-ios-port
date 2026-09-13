# EW4 P80 SOURCE_NATIVE — dynamic fire-cell closure + Xcode handoff candidate

Unified lineage: **P39 -> ... -> P78 -> P79 -> P80**.

P80 preserves all P79 map/unit/transport/flag/commander/morale evidence and closes the remaining proven runtime fire presentation omission: gameplay/save/event logic already maintained `fireCells`, but Native SpriteKit did not render them. P80 adds the frozen mature six-frame `anim_fire_hd.png` path, 160ms timing, 42px logical height, alpha 0.86, live set synchronization, and z-order below units.

P79 -> P80 product delta is deliberately narrow:
- add `NativeBattleFirePresentationCore.swift`;
- modify `NativeBattleScene.swift`;
- add `P80BattleFirePresentationTests.swift`;
- Native Resources: 0 changes; SOURCE_LEAN: 0 changes.

Current Linux gates: **286 Swift Testing + 9 XCTest = 295 total**, Mature Web **126/126**, `P80_MAP_UNIT_DYNAMIC_STATE_AUDIT.json` **0 errors**, SOURCE_LEAN **6321/6321**, Native Resources **1751/1751**, IPA preflight **26/26**.

The next meaningful milestone is the first real **Xcode/iPhoneOS Release build**, followed by device battle smoke. Do not broadly refactor frozen map/unit/LOD/overlay/fire math to fix unrelated compiler errors.
