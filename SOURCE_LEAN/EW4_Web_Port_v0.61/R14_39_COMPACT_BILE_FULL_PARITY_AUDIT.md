# EW4 Web Port v0.61 — r14-39 compact BILE full-parity audit

## Scope
This audit re-checks the current integrated `native_animation_core265.json` against the compact original BILE runtime source for **all 1076 integrated motion assets**, rather than using representative spot checks.

## Result
- Integrated unit definitions: **265**
- Integrated motion assets: **1076**
- Compact-vs-integrated parity: **1076/1076 PASS**
- Remaining geometry mismatches: **0**
- Historical Machine Gun Finish discrepancy set: **18** records
- Current core equals `new_world_union`: **18/18**
- Current core equals historical `old_world_union`: **0/18**

## Meaning
The earlier takeover note stating `1058/1076` parity with 18 Machine Gun Finish mismatches is now stale for the current working tree. The corrected Machine Gun Finish geometry has already propagated into the current integrated core and matches the compact parser.

This closes the geometry-parity blocker for the **currently integrated 1076-motion subset**. It does **not** mean the entire original animation corpus is migrated: the original APK still contains **877 Unit / 3519 Motion** definitions, while the integrated mainline remains **265 Unit / 1076 Motion**.

## Regression lock
`test_compact_bile_full_parity.js` now recomputes every integrated motion directly from compact BILE and checks:
1. frame count,
2. FPS,
3. four-value `world_union`,
4. all 18 Machine Gun Finish records use corrected `new_world_union`, never the historical old geometry.

Production replacement is still a separate task: `compact_bile_runtime.js` must be wired into the actual battle renderer and visually/device-tested before expanded runtime PNG cache can be considered fully retired.
