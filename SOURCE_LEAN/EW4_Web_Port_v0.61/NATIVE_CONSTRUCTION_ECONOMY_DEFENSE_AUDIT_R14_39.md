# EW4 Web Port r14-39 — Native construction economy / defense audit

Authority: original EW4 v1.4.42 APK (`def_construction.xml`, `layout-568h.xml`, x86_64 `libeuropean-war-4.so`).

## Construction level records
Each native level record stores: `tax`, `industry`, `food`, `supply`, `avoid`.

- City L1..L7: `(3,0,0,1,3) (6,0,0,2,6) (12,0,0,4,9) (20,2,0,6,12) (30,4,0,8,15) (45,6,0,10,18) (60,8,0,12,20)`
- Factory L1..L4: `(0,4,0,2,3) (0,8,0,4,6) (0,12,0,6,9) (0,16,0,8,12)`
- Stable L1..L3: `(2,0,0,2,3) (4,0,0,4,6) (6,0,0,6,9)`
- Port L1..L3: `(3,1,0,2,3) (6,2,0,4,6) (9,3,0,6,9)`
- Farmland L1..L3: `(0,0,5,0,0) (0,0,15,0,0) (0,0,40,0,0)`

Tuple order is `(money/tax, industry, food, round supply HP, ALL/avoid)`.

## ALL icon semantics
The native construction parser stores `avoid` at level-record +0x10. Getter `0x545b0` returns the integer for UI; getter `0x54570` converts it to float and divides by `100.0` using the 100.0 constant at `0x1b4318`. Therefore `marker_dfs_all.png` is the generic all-unit construction avoidance/defense percentage. Example: City L5 `ALL 15` => 0.15 in the native defense calculation.

`form_game/group_incom` is a dynamic four-slot readout, not four hard-coded meanings. Native icon candidates are money, industry, food, ALL, infantry defense, cavalry defense, artillery defense. Current Web now resolves the icon/value dynamically.

## Construction vs terrain / field-work
Native defense selector around x86_64 `0x4e7d0` branches on the construction pointer first. If a construction exists it reads construction avoidance (`0x54570`) and returns through that branch. Only when no construction exists does it calculate terrain/class defense and max it with field-installation defense. Thus construction avoidance replaces the terrain/field-work map-defense layer rather than being added to it. This remains true for farmland: construction present + avoid 0 means no terrain avoidance is added back.

Fortress-family entities are army units (`def_army.xml`), not `def_construction.xml`, explaining why they do not use the same ALL construction readout.

## Native construction upgrade cost
The original `def_card.xml` record for card 44 (`Upgrade Construction`) stores `price=0` and `industry=0`; construction upgrade cost is not card data.

x86_64 native helpers prove the real cost tables and their level-independence:

- `0x54250` indexes `.rodata 0x1b5e90` by `construction.type` only and returns Money cost.
- `0x542e0` indexes `.rodata 0x1b5e70` by `construction.type` only and returns Industry cost.
- Neither helper reads `construction.level` (`+0x8`), so every upgrade step of the same construction type costs the same resources.
- The type order follows native construction IDs / `def_construction.xml`: city=0, industry=1, stable=2, port=3, farmland=4.

Raw tables:

- Money (`0x1b5e90`): `[65, 60, 80, 75, 40]`
- Industry (`0x1b5e70`): `[0, 20, 5, 10, 0]`

Thus:

- City: 65 Money / 0 Industry
- Factory: 60 / 20
- Stable: 80 / 5
- Port: 75 / 10
- Farmland: 40 / 0

`0x54370` uses those helpers for affordability. `0x54930` repeats the same cost lookup, deducts Money via `0x57a60`, Industry via `0x57b30`, then increments `construction.level` by exactly one (`add [construction+0x8],1`). Therefore there is no hidden per-level multiplier in the upgrade transaction.

Both cost helpers test commander skill ID 30 (Architecture / 建筑学). If present, the native integer arithmetic returns `trunc(base * 3 / 5)` for both resource components. Current Web centralizes this in `EW4NativeConstruction.upgradeCost()`.
