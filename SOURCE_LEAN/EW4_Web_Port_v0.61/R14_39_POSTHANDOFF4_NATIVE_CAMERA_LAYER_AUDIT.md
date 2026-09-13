# r14-39 Post-Handoff 4 — Native camera / layer audit

This micro-batch intentionally prioritizes uncertain foundational interaction over adding more battle effects.

## Proven camera constants / behavior (x86_64 libeuropean-war-4.so)

- `CEntityCamera` setter at `0x7f3e0` clamps zoom to **0.2 .. 1.0** (`0x1b442c = 0.2f`, `0x1b42f0 = 1.0f`).
- Screen/world conversion wrappers `0x84bc0/0x84bd0` call camera transforms `0x7fe60/0x7fe90`; logical viewport center is 284x160 for the 568x320 battle surface.
- One-finger move around `0x9ff17` applies **previousTouch-currentTouch divided by zoom** through battle camera pan wrapper `0x85330 -> 0x7f640`. This is incremental, not drag-start based.
- Pinch around `0x9ff80..0xa0206` requires both old and new finger separation to exceed **40 px** (`0x1b43b4 = 40.0f`). Scale update is incremental `currentZoom * newDistance / oldDistance`.
- Each pinch move preserves the **stationary other finger's world point**, not a fixed gesture midpoint.
- Release around `0xa06b2..0xa0715` treats a touch as a tap only when **abs(dx) < 15 AND abs(dy) < 15** (`0x1b4404 = 15.0f`).
- At zoom **< 0.5** (`0x1b431c = 0.5f`), native tap selection is rejected (`0xa044e..0xa045c`). Zoom/pinch paths also clear an existing selected object when crossing into that range (`0x9fdcb..0x9fe06`, `0xa00c6...`).

## Changes in this patch

- Replaced Web-only `.58 .. 1.65` zoom with native `.2 .. 1.0` limits.
- Replaced drag-start panning with native-style incremental panning. This fixes edge-stick behavior after dragging outward against a map boundary.
- Replaced fixed-midpoint pinch with native event-by-event stationary-finger anchoring.
- Added native 40 px pinch gate.
- Replaced 3 px Euclidean move/tap discriminator with the native 15 px per-axis release test.
- Disabled tactical tap selection below 0.5 and clear current selection when zooming down across the 0.5 threshold.
- Kept current map-bounds clamp because its center/half-viewport formula matches `CEntityCamera`; exact native battle-map rectangle padding remains separately audited.

## Layer evidence

Battle construction at `0x84910..0x84b15` creates named native layers:

- `CLayerBackground` -> member `+0x20`
- `CLayerSelectLower` -> `+0x28`
- `CLayerOutline` -> `+0x30`
- `CLayerHexFrame` -> `+0x38`
- `CLayerObject` -> `+0x40`
- `CLayerSelectUpper` -> `+0x48`

The visible-region service loop walks these member slots in the above order. This is hard evidence for the lower/object/upper separation, but the observed virtual call is not yet proven to be the final draw call, so this patch does **not** reshuffle Web rendering solely from that evidence.

Movement effects (`effect_moving1..4.xml`) are created by native unit-side code around `0x51230..0x512e3` and retained in the unit object, but their final renderer attachment relative to `CLayerObject` is not yet proven. Therefore the Web `drawNativeSimpleEffects()` global post-unit pass remains explicitly unresolved rather than being guessed.

## Important unresolved native low-zoom visual behavior

When camera zoom is below 0.5, battle update code at `0x84eb9..0x84edd` calls a dedicated path at `0xaaa20`. It iterates visible grid entities, converts their coordinates through the camera, and invokes entity-side presentation logic (`0x50fc0`). This strongly indicates a native low-zoom/strategic presentation path.

The exact sprite/marker composition of that <0.5 mode is **not yet proven**, so this patch implements only the hard interaction rules and does not invent a replacement strategic marker. This is the highest-priority remaining camera-visual gap.

## Exact hex hit-test status

Native has a parity/corner-corrected screen/world-to-cell routine (`0x84be0` / click wrapper `0x851f0`) using 64/54-era internal geometry. The Web port currently uses the previously reconstructed map anchor `x=q*64, y=r*53+(q&1)*26.5`. Those coordinate conventions need reconciliation before replacing `nearestCell`; changing it blindly risks shifting the already-correct map/unit anchors. Marked unresolved; do not fake exact parity yet.

## Proven low-zoom unit LOD (implemented)

The native `< 0.5` path is now backed by both code and atlas evidence rather than a Web approximation:

- `image_ui_hd.xml` exposes the named strategic marker family (`mark_unit_militia`, `mark_unit_line`, ... `mark_unit_coastalartillery`).
- The extracted `buildings_hd` atlas contains `mark_unit_0.png` through `mark_unit_21.png`.
- Their dimensions match the named marker family *exactly and sequentially* (15x22, 19x23, ... 16x16), proving that marker index is the native army-type index 0..21.
- Native low-zoom function `0x50fc0 -> 0x5f050` indexes a sprite table by the entity army-type argument, positions that sprite after world-to-screen conversion, and normally uses scale 1.0. This is consistent with a screen-space strategic marker rather than a camera-scaled tactical BILE model.

Web implementation therefore switches `drawUnit()` at `zoom < 0.5` to exact `mark_unit_<army_id>.png`, drawn at intrinsic sprite dimensions/refpoint in screen space. Full tactical model, flag, commander portrait, tactical HP bar and morale badge are not reused in this mode.

Still unresolved: native `0x5f050` also services a shared HP/status primitive (`Resource+0x1a8`) and a second indexed presentation table (`Resource+0xd8`). Their exact visual identity/composition is not yet proven, so the Web port deliberately does **not** invent those overlays.

## Proven global effect render order (implemented)

The prior uncertainty about whether movement dust/smoke should be embedded inside each unit renderer is now materially resolved.

- Normal movement-effect creation at unit code `0x511e0..0x512e3` obtains the global effect manager from `0xbfc90`, creates `effect_moving1..4.xml` through `0xbfca0`, and stores the returned effect handle in the unit only for lifetime/position control.
- `0xbfca0` creates the effect through that singleton manager; it is not inserted into a battle `CLayerObject` child list.
- Battle render path `0x84e23..0x84e73` services the six battle layers in member order `+0x20 .. +0x48`: Background, SelectLower, Outline, HexFrame, Object, SelectUpper.
- Immediately afterward, `0x84e75..0x84e7f` calls global effect manager `0xbfc90 -> 0xc0100`.
- `0xc0100` iterates effect emitters and calls `0xc8ff0`; `0xc8ff0` computes per-particle RGBA/size and submits sprite drawing (`0xc6020`). This establishes that this call is a real particle render pass, not merely an update tick.
- Native low-zoom strategic marker pass `0x84eb9..0x84edd -> 0xaaa20` occurs after the global particle render pass.

Therefore the Web renderer is now ordered as: tactical Object units -> SelectUpper selection overlay -> global native-simple effects -> (if zoom < 0.5) strategic `mark_unit_*` pass -> battle UI floats. The former Web order that put SelectUpper after particles, and the first low-zoom draft that put strategic markers before particles, were both corrected.

## Native drag-edge margin (implemented)

`CEntityCamera` incremental move at `0x7f640` loads the exact float `16.0f` from rodata `0x1b4488` when its boolean clamp mode is false. The battle one-finger wrapper `0x85330` always passes false, so ordinary drag panning permits a 16-world-unit boundary margin. Zoom/reposition code uses the tighter zero-margin clamp path.

The Web camera now mirrors that distinction: incremental one-finger pan clamps with a 16-world-unit edge margin, while wheel/pinch zoom and other camera poses use zero margin. This avoids the former overly rigid "hard wall" feel at the map edge without inventing fling inertia.
