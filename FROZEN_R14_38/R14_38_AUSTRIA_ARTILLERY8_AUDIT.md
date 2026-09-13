# EW4 Web Port v0.61 — r14-38 Austria Artillery 8 audit

## Scope
This micro-batch adds Austria (`aus`) country-specific artillery native animation and completes the first fidelity pass of the original `form_getgeneral` Military Academy page. No Prussia artillery and no map-text layer are included in this delta.

## Austria artillery native assets
Units added:
- Light Artillery aus 1 / 2
- Heavy Artillery aus 1 / 2
- Siege Artillery aus 1 / 2
- Rocket aus 1 / 2

Original-state paths preserved:
- Light/Heavy: Ready + Attack + Reload + Finish -> Ready
- Siege: Ready + Attack + Finish -> Ready
- Rocket: Ready + Attack + Reload -> Ready
- Native time base: 24 FPS
- Total: 8 units / 28 unique original BILE motion assets
- The r14-34 path-level BILE cycle guard successfully extracts both Austria Siege Finish timelines without dropping the Finish state.

## Integration result
- Runtime core: `native_animation_core257.json` -> `native_animation_core265.json`
- Unit count: 257 -> 265
- Motion asset count: 1048 -> 1076
- Service Worker cache: `ew4-port-v061-r14-38-austriaartillery-academy`
- Every new runtime asset exposes a four-value `world_union` and a valid PNG runtime sheet.

## Regression evidence
- All 257 pre-r14-38 unit records compare JSON-value identical after merge.
- All 1048 pre-r14-38 motion records compare JSON-value identical after merge.
- 1076/1076 runtime sheets exist and have valid PNG signatures.
- `test_native_animation_integration.js` passes Austria artillery state-chain assertions.
- Full JS suite: 23/23 PASS.
