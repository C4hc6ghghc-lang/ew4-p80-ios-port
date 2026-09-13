# P53 handoff — Native HQ Management + Battle Tavern

- **Authoritative mainline:** P39 -> ... -> P50 -> P51 -> P52 -> **P53**. Continue forward; do not redo mature systems.
- **P53 landed:** Native DeployItem/equipment; HQ regroup; HQ dismissal; battle Tavern recruitment bound to recovered `extra == 3` facilities and recovered `battle_taverns.json` state.
- **Critical semantics preserved:** equip replacement returns old item; consumables cannot equip; flag requires flag skill; regroup deletes source commander and source equipment; dismissal returns equipment atomically and blocks when the bank is full; princesses cannot be dismissed.
- **Tavern preserved:** max four visible candidates; round/owned/money/industry locks; queue shifts after purchase; medal is display-only/non-deducted; player profile/resources/tavern sidecar autosave together.
- **Verified clean-path:** Native **191/191 PASS**; mature JS **126/126 PASS**; resource audit `errors=[]`; Swift parse **127/127**; IPA preflight **26/26**; SOURCE_LEAN 6321 frozen; Native Resources unchanged.
- **P52 -> P53 code scope:** 8 Swift files added, 4 changed, 0 removed. `NativeBattleScene.swift` is intentionally changed only for Tavern modal/input/persistence routing; map/camera/LOD/unit/flag/HP/combat presentation contracts remain frozen.
- **Continue, do not start over:** Academy info-detail closure -> exact original Tavern facility-action presentation -> Tutorial/Options/audio -> macOS Xcode/iPhoneOS and real-device acceptance.
- **Still unverified here:** iPhoneOS semantic compile/link, actual SpriteKit pixel alignment and touch feel on iPhone.
