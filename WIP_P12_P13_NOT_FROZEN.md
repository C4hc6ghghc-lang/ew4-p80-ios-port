# P12 / P13 historical recovery notes — BOTH NOW FROZEN

This file preserves the latest work from the conversation that was discussed and partially implemented in a transient worktree but did not survive as a reusable delta in the current filesystem. Historical note: these findings originally described transient work. P13 was frozen at Post-Handoff 13 and P12 SceneShop was frozen at Post-Handoff 14. Do not reimplement them unless a regression proves necessary.

## P12 — shared native SceneShop
Reverse-engineered rules:
- HQ and battlefield facilities share the original `form_shop` shell but use different seller sources.
- HQ shop seller is the Headquarters-specific store; battlefield shop seller comes from current Map/ItemStore.
- Original seller inventory is 14 slots.
- Buyer ItemBank is 28 slots and should be scrollable/fully accessible, not truncated to 14.
- HQ store refreshes when date changes and persists its daily stock.
- HQ daily stock:
  - first 5 slots: random from all `consumable=1` items, duplicates allowed (Wine / Spirit / Medikit / Medikit L / First Aid Box / Star as represented by original data)
  - slots 7 and 8: two distinct non-consumable unique items not already owned/unlocked/equipped
  - other slots empty
- HQ buying uses original displayed price; user's infinite-medal override means medals are not depleted.
- HQ shop supports selling back from ItemBank.
- HQ sell price = `max(1, floor(basePrice * 0.60))`.
- Battlefield commerce modifies both sides symmetrically:
  - buy multiplier decreases 4 percentage points per commerce star
  - sell multiplier = `60% + 4% * commerceStars`, capped at 80%
- Consumables sell one unit at a time; unique equipment becomes unowned on sale and can become buyable again if present in seller stock.
- Do not show FREE/∞ labels just because medals are infinite.

Intended architecture:
- one native SceneShop renderer/controller
- separate seller-source adapters for HQ and battlefield contexts
- dedicated `native_hq_shop_core.js`/shared commerce core with tests

Resolved at Post-Handoff 14: the shared SceneShop is present in production and the full regression is 78/78 PASS.

## P13 — full compact BILE animation coverage
High-confidence findings:
- Full compact BILE source already contains **877/877 unit definitions and 3519/3519 motions**.
- Existing production manifest `native_animation_core265.json` is the coverage bottleneck; raw source assets are not missing.
- A lightweight full manifest can represent all 877 units / 3519 motions without generating expanded PNG sheets. Chat work generated one around ~695 KB.
- 3519 motion references map to roughly 1263 unique BILE motion items because many units reuse native motion data.
- Production renderer should continue drawing compact BILE/atlas directly; do not restore `runtime_sheet.png` expanded-sheet production assets.
- All 101 BTLs / 7407 battle units were reported to resolve to the full pack in the transient worktree.

Important direction finding:
- naval attacks expose the need for directional attack selection; many naval definitions have left/right attack motions rather than `attack all`.
- transient validation reportedly constructed 877 units × 2 directions = 1754 attack chains successfully after passing target-relative left/right into the animation controller.

Native state-machine correction:
- normal attack does **not** insert a READY wind-up.
- native normal chain is effectively Attack → optional Reload → optional Finish → return to static Ready pose.
- Ready is a static base pose after completion, not an idle loop invented by Web.
- UNDREADY belongs to another cancel/withdraw-preparation path and must not be forced into normal attacks.

Resolved at Post-Handoff 13: production uses the full 877/3519 compact manifest with directional attack handling and full coverage tests.

## Tutorial executor — next major logic gap
Not yet landed.
Original APK contains complete tutorial XMLs:
- basic tutorial: 17 segments
- advanced tutorial: 16 segments

Known command family includes:
- show/hide text
- moveto area
- wait area
- sel/unsel area
- draw rect
- draw UI rect
- wait touch
- wait UI
- wait action
- exit

Area encoding on Europe map was reverse engineered as `areaId = r*79 + q` (example: 2550 -> q22,r32 matches BTL evidence).
Do not implement a fake 'tap anywhere to continue' tutorial. Native UI tags / wait conditions should be respected.

## Remaining high-value parity work after P12/P13
- complete Tutorial Script Executor
- audit and remove remaining obvious Web replacement forms/controllers
- verify general-info upgrade/reorganize controllers against native behavior
- finish result/reward controller parity where still unresolved
- true-device visual calibration of z-order, touch feel, audio autoplay/session behavior
- finish any remaining controller/data-source mismatches before claiming 1:1
