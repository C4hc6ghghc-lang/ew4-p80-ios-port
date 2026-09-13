# EW4 r14 · Native ItemStore audit

Source baseline: original `libeuropean-war-4.so` from EW4 v1.4.42 APK. Addresses below are x86_64 virtual addresses used for the current static audit; they are evidence for structure/behavior, not stable public ABI symbols.

## Confirmed ItemStore record layout

`CEntityItemStore` owns a vector of per-store records. A store record is initialized by the routine around `0x5af20 / 0x5afc0` and is approximately `0xA0` bytes.

The seller inventory has **14 native slots**. For slot `i` (0..13):

- `record + i*8 + 0`: signed item id (`-1` means empty)
- `record + i*8 + 4`: quantity/count
- `record + 0x70 + i`: per-slot active/availability byte

Additional confirmed fields:

- `record + 0x80`: store/entity id used by the map ItemStore lookup
- references continue at `+0x88`, `+0x90`, `+0x98`

The initializer sets all 14 item ids to `-1`, all counts to `0`, and availability bytes to `1`.

## Confirmed shop rendering / lookup behavior

The shop form path around `0x464f0` resolves the selected map facility, obtains `ItemStore`, and looks up a per-facility store record through the map/entity lookup around `0x83120`. The shop renderer around `0x45ba0` loops **exactly 14 slots**, producing the original 2 x 7 seller grid.

`0x5b0d0(record,index)` addresses a slot. `0x5b0f0` only returns an item id when the slot count is positive. `0x5b280` reads the slot availability byte. The purchase eligibility path around `0x5b620` requires both positive count and active state before continuing into pricing/eligibility logic.

Therefore the Web port must **not** expose the entire item definition table as a shop catalog. Native shop stock is finite, slot-based, quantity-bearing, and facility/store specific.

## Stock-generation boundary still unresolved

The path around `0x5b8c0` clears and dynamically generates stock when the store id at `+0x80` is negative, using the global item manager and randomized eligible ids. This path visibly populates specific slot pairs, but the exact source/population rule for positive per-facility store ids has not yet been proven from the BTL serialization.

Until that source is decoded, r14 intentionally does **not** invent facility shop stock ids.

## Related confirmed pricing

The native shop price path already audited in `native_commerce_core.js` applies a business-skill discount of `businessStars * 4%` to the item base price (0/4/8/12/16/20% for 0..5 stars, integer truncation).
