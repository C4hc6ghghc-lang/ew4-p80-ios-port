# P46 — Native Player Profile / Effective Commander / Equipment parity

P46 translates mature P39 player-profile and battle-equipment behavior into the unified Swift/SpriteKit mainline. It does **not** rewrite Campaign, Conquest, map, animation, HUD, flag, HP-arc or zoom systems.

## Landed

- Lossless v61 player profile wrapper plus atomic filesystem store.
- All princess IDs 201...208 are owned in fresh profiles; only 204/205/208 receive user-requested overrides.
- Effective player commander merges P39 override stats/skills, persisted `generalStats`, equipment slots, rank and nobility.
- AI commander projection is intentionally raw: no player profile growth/equipment/mod leakage.
- Effective commander is injected into both fresh and restored battles and is reused by round settlement.
- App boot reads profile from Application Support; autosave callback writes the native schema6 autosave slot.
- Equipment movement parity: function 9 target-aware movement and function 0 terrain-ignore.
- Combat equipment parity: function 4 full formation; 10 armor; 11 fixed weapon damage; 12 armored carrier; adjacent 14 attack / 15 defense flags; training defense.
- Counterattack `DamageResult.value` now equals the 0.68-scaled value actually applied to HP.

## Verification

- Native Swift: 90/90 PASS.
- Mature SOURCE_LEAN: 126/126 PASS.
- Full resource audit: 101 battles, 7407/7407 battle units, 5482/5482 eligible building sprites, 877 animation units, 3519 motions, BILE 12/12, `errors=[]`.
- iOS Swift parse: PASS.
- Native IPA preflight: 26/26 PASS.
- P45 -> P46 SOURCE_LEAN: 6321 baseline files, changed 0, missing 0, new 0.

True Xcode/iPhoneOS build and real-device acceptance remain pending.
