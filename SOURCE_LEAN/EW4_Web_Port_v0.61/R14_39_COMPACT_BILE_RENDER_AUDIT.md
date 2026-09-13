# EW4 Web Port v0.61 — r14-39 compact BILE production-render audit

## What changed
The battle renderer no longer requires pre-expanded `runtime_sheet.png` files for integrated native animation playback.

Runtime path:
1. `compact_bile_runtime.js` loads before `native_animation_controller.js`.
2. `loadDB()` creates `EW4CompactBile.BrowserPack('assets/bile_runtime')`.
3. Battle asset priming loads only BILE resource families actually used by units in the current battle.
4. `NativeAnimationPlayer` still resolves native state/timing/frame index from `native_animation_core265.json`.
5. The selected BILE item is drawn directly into the main battle Canvas with `Bile.drawFrame()`.
6. Expanded `runtime_sheet.png` is not required by the production draw path.

## Coordinate rule
For direct BILE drawing:

`origin = unitScreenPoint + native_anchor * (0.5 * unitZoom)`

Do **not** apply `world_union` again. The old expanded-sheet path had already translated raw BILE world coordinates into a fixed canvas using the union; adding it again in direct rendering would double-shift the sprite.

The formula is now centralized as `EW4NativeAnimation.compactDrawOrigin()` and regression-tested.

## Visual-path validation
A Skia Canvas smoke test loaded original compact BILE atlases and executed the same `Bile.drawFrame()` raster path for three representative motions:

- `Militia 1 / attack / frame 8`: 1999 non-transparent pixels
- `Machine Gun 1 / attack / frame 20`: 2509 non-transparent pixels
- `Light Artillery aus 1 / attack / frame 12`: 2906 non-transparent pixels

Raster alpha bounds matched transformed compact geometry within 0–1 pixel rasterization tolerance.

A Chromium localhost smoke was attempted, but this container's managed Chromium policy blocks `127.0.0.1` with an organization-policy page before project JavaScript can load. That environment restriction is **not** counted as a project runtime failure.

## Offline/PWA support
Service Worker precache now includes:
- `compact_bile_runtime.js`
- compact `manifest.json`
- `def_motion.xml`
- all 12 BILE resource families (`.bin`, `.xml`, `.png`)

The compact source pack remains around 10 MiB and is the production animation source path.

## Remaining boundary
This closes renderer wiring for the currently integrated **265 Unit / 1076 Motion** subset and removes dependency on the 600+ MiB expanded PNG cache.

It does **not** prove real-iPhone visual fidelity. Final verification still needs a device build/run (planned for the later Codex/IPA stage) and the project still has only ~30% of the original `877 Unit / 3519 Motion` animation definitions integrated into the main runtime manifest.
