# EW4 Web Port v0.61 — r14-37 Russia Artillery 8 audit

## Scope
This micro-batch adds only Russia (`rus`) country-specific artillery native animation. No Austria artillery work is included.

Units added:
- Light Artillery rus 1 / 2
- Heavy Artillery rus 1 / 2
- Siege Artillery rus 1 / 2
- Rocket rus 1 / 2

## Original evidence / extracted native paths
- 8 Russia-specific unit definitions
- 28 unique original BILE motion assets
- Native time base: 24 FPS
- Light/Heavy: Ready + Attack + Reload + Finish
- Siege: Ready + Attack + Finish
- Rocket: Ready + Attack + Reload
- r14-34 path-level BILE cycle guard successfully extracts both Russia Siege Finish timelines without skipping the Finish state.

## Integration result
- Runtime core: `native_animation_core249.json` -> `native_animation_core257.json`
- Unit count: 249 -> 257
- Motion asset count: 1020 -> 1048
- Service Worker cache: `ew4-port-v061-r14-37-russiaartillery`
- Every new runtime asset restores authoritative `world_union` and `per_frame_bounds` from its extracted BILE manifest.

## Regression evidence
- All 249 pre-r14-37 unit records compare unchanged by canonical JSON SHA-256.
- All 1020 pre-r14-37 motion records compare unchanged by canonical JSON SHA-256.
- 1048/1048 runtime sheets exist, have valid PNG signatures, and all assets expose a four-value `world_union`.
- `test_native_animation_integration.js` passes Russia artillery state-chain assertions.
- Full JS suite: 23/23 PASS.
- `node -c app.js` and `node -c native_animation_controller.js` PASS.

## Size observation (not a release-size claim)
At this checkpoint the unpacked development work tree is about 695 MiB. Native animation assets dominate: `assets/unit_anim_native` is about 613 MiB and the 1048 `runtime_sheet.png` files alone are about 600 MiB. This is the current expanded PNG development/runtime representation, not a target IPA size. Final IPA work must include animation-storage repacking/compression; deleting audits/tests alone cannot return the project near the original ~200 MB installed-size range.
