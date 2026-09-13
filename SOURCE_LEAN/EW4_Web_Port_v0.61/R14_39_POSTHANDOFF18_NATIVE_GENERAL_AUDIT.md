# R14-39 Post-Handoff 18 Native General Audit

## Recovered native growth writers
- Military/rank growth writer: native wrapper at `0x557e0` (delegates to `0x556a0`), with level/progress in the native general object.
- Nobility growth writer: native wrapper at `0x55900` (delegates to `0x55800`).
- Both automatically consume thresholds and cross levels.

## Thresholds and upgrade prices
Military thresholds: `500, 800, 1200, 1900, 3000, 4800, 7500, 12000, 19000, 30000, 48000, 76000, 120000, 200000`.

Nobility thresholds: `100, 200, 300, 450, 675, 1000, 1500, 2250, 3375`.

Displayed next-level medal prices are based on remaining progress: military rate `0.008`, nobility rate `0.2`; all-full purchase is capped at 3600 medals. The user MOD keeps medal balance infinite while preserving these original displayed prices.

## Battle growth
The combat result structure stores primary and optional secondary damage separately. Native combat code sums both, doubles the sum, and passes it to the military-growth wrapper. Web therefore awards `2 * actual damage` per damage event; separate future splash events sum equivalently.

Native victim value for nobility is `unit grade + 1`, doubled if the defeated unit carries a commander. This value is passed to the killer commander's nobility-growth wrapper on death resolution.

### Growth multipliers
Native scans the two equipped item slots first and takes the highest matching item value:
- item `function=1`: nobility growth, e.g. Golden Staff 200%, Crown 400%.
- item `function=2`: military growth, e.g. Art Of War 200%, On War 300%.

If no matching item is equipped, skills are used:
- zero-based skill 19 (UI skill 20, Nobility): 1.5x nobility.
- zero-based skill 20 (UI skill 21, War Expert): 1.4x military.
- zero-based skill 21 (UI skill 22, War Master): 1.8x military and takes precedence over War Expert.

Matching equipment replaces, rather than stacks with, the skill multiplier. Native float-to-int conversion truncates positive values; Web uses `Math.floor`.

## Regroup
Military and nobility use separate retention tables. Transfer includes base growth (300 military, 60 nobility), completed thresholds and current progress, then applies the source-level retention percentage. Seven teaching skills (zero-based 33..39) grant +1 to infantry/cavalry/artillery/warship/fort/business/movement respectively, capped at 5.

Original Regroup confirmation deletes the source general and source items; P18 preserves that original behavior.

## DeployItem
Original `layout-568h.xml` geometry reproduced:
- form 353x261
- general group 78x119
- level group 110x52
- equip group 110x74
- description group 142x120
- ItemBank group 344x99, 7 columns
- Equip button 55x21

P18 renders all 28 ItemBank positions in stable slot order. Consumables remain visible for description/inventory fidelity but cannot be equipped. Empty bank slots can be selected to unequip the current equipment slot.
