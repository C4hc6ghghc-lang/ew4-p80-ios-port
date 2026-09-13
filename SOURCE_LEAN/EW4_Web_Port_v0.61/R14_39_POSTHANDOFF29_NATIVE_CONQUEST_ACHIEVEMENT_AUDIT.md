# R14-39 POSTHANDOFF29 — Native Conquest Achievement Audit

Date: 2026-09-10
Parent: P28 Native Achievement Exact Local Semantics Frozen
Authoritative source: original EW4 v1.4.42 APK embedded in checkpoint; x86_64 `libeuropean-war-4.so`.

## Scope

This pass resolves the native local formula that produces the Europe/America/Asia `统治 X 年` Achievement value and wires that formula into Web conquest victory persistence. It does **not** invent platform leaderboard/GameCenter behavior.

## Native proof anchors

- Conquest Achievement value generator: `~0x7e760`.
- Player-country lookup: `0x805b0` (first country record whose native side byte `+0x54 == 0`).
- Player-country Money / Industry / Food getters: `0x57a50` / `0x57b20` / `0x582a0`.
- Historical Campaign best-stage-star sum: `0x2c200`.
- Map continent getter: `0x839b0`; native `def_map.xml` loader maps Europe to `0`, America to `1`.
- Native result-state construction: `~0x7da10`; bytes `scene+0x91` = result decided, `scene+0x92` = victory.
- Fast-conquest eligibility: `~0x7eee0` / `~0x7ef50`.
- Normal pending result: `0x7ec51` calls `0x7e760(scene,false)` and stores native map continent index.
- Fast result override: `0x7efb8` calls `0x7e760(scene,true)` then overwrites pending record index with `2` (Asia).
- Final persistence: `~0x7efe0` calls max-only continent writer `0x2c560` exactly once.

## Shared inputs

### HQ/general contribution

Native loops exactly 12 original HQ slots. For each non-null commander, native reads the military-rank and nobility-rank **level/index fields** (not progress) and adds:

`10 * (militaryLevel + 1) * (militaryLevel + 2)`

plus

`25 * (nobilityLevel + 1) * (nobilityLevel + 2)`.

Because this project deliberately removes the original 12-general HQ cap, P29 uses the exact native per-general formula across all owned HQ generals. This is a documented user-Mod adaptation, not a claim that original EW4 iterated more than 12 slots.

### Resource contribution

Native player-country resources produce:

`trunc((2*Money + 4*Industry + Food) / 10)`.

Signed integer division truncates toward zero.

### Campaign-star contribution

This is the native historical Campaign best-rating sum from `0x2c200` — the same non-spendable historical total restored in P28. It is **not** the P21 spendable Campaign Upgrade Stars wallet.

## Normal Europe/America formula

HQ contribution is capped at `6999`.
Historical Campaign stars are multiplied by `10`, capped at `2333`.

Round contribution:

- `round <= 31`: `23330`.
- `round > 99`: `0`.
- `32..45`: `111*(100-round)*3.0`.
- `46..55`: `111*(100-round)*2.5`.
- `56..65`: `111*(100-round)*2.0`.
- `66..75`: `111*(100-round)*1.5`.
- `76..99`: `111*(100-round)*1.0`.

The native path uses single-precision arithmetic for the half-step multiplier before integer truncation. P29 mirrors this with `Math.fround`.

`total = resource + cappedHQ + cappedHistoricalStars + roundContribution`

`normalized = clamp(trunc(total*100 / 46660), 1, 100)`.

The x86_64 compiler magic `0xb3c814e5` plus the observed shift/add sequence was independently checked against signed division by `46660`.

Thresholds:

`[91,87,83,79,75,71,67,63,59,55,51,47,43,39,35,31,27,23,16,1]`

Mapped years:

`[1000,950,900,850,800,750,700,650,600,550,500,450,400,350,300,250,200,150,100,50]`.

If no threshold matches, native normal mode returns `0`.

The record key is native map continent: Europe index `0`, America index `1`.

## Fast-conquest / Asia formula

Fast mode is not an “Asian country” condition. Native first requires conquest result decided + victory, then applies map-specific round limits:

- Europe map: `round <= 65`.
- America map: `round <= 55`.

HQ contribution is capped at `17500`.
Historical Campaign stars are multiplied by `17`, capped at `7000`.

Round contribution:

- `round <= 20`: `21000`.
- `round > 99`: `0`.
- Europe: `21..30 k=4`, `31..40 k=3`, `41..50 k=2`, `51..60 k=1`, then `k=0`.
- America: `21..25 k=4`, `26..35 k=3`, `36..45 k=2`, `46..50 k=1`, then `k=0`.
- contribution: `65 * k * (100-round)`.

`total = resource + cappedHQ + cappedHistoricalStars + roundContribution`

`normalized = min(100, trunc(total / 700))`.

The x86_64 magic `0x5d9f7391` and shift sequence matches signed division by `700`.

Thresholds:

`[95,91,87,83,79,75,71,67,63,59,55,51,47,43,39,35,31,27,23,16]`

with the same year table. If no threshold matches, native fast mode returns `10`.

## Critical caller semantics

Native does **not** persist both a normal continent record and an Asia record for one fast victory.

1. Normal result code computes a pending Europe/America value and index.
2. If fast-conquest eligibility succeeds, `~0x7ef50` recomputes the special value and **overwrites** the pending index with `2` (Asia) and the pending value.
3. `~0x7efe0` performs one max-only write.

Therefore:

- ordinary conquest victory -> Europe or America record;
- qualifying fast victory -> Asia record **instead of** the normal map-continent record.

P29 reproduces this override behavior.

## Code implemented

- Added `native_conquest_achievement_core.js`.
- Added `test_p29_native_conquest_achievement.js`.
- `index.html` loads the core after `native_achievement_core.js`.
- `showBattleResult()` invokes conquest-Achievement persistence only after a conquest victory.
- Persistence uses P28 `recordConquestValue`, preserving native max-only behavior.
- Service Worker caches the new production core.

## Verification

- Full JS regression suite: 109/109 PASS.
- P25 six-zone Campaign long-session regression remains PASS.
- Service Worker CORE: 328/328 present.
- P21 protected upgrade/save/warzone-tech files remain byte-identical to P28 parent.

## Truth boundary

The local Europe/America/Asia `统治 X 年` generation and max-only persistence are now reconstructed and wired from native evidence. Champion/Ranking platform-service behavior remains a separate unresolved online/platform integration. Exact iPhone visual presentation remains true-device pending.
