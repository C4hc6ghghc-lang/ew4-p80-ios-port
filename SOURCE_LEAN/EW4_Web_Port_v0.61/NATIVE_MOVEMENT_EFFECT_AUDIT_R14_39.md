# EW4 r14-39 native movement-effect audit

Evidence source: original APK `effect_moving1.xml`..`effect_moving4.xml`, `eff.xml`/`eff.png`, and original x86_64 `libeuropean-war-4.so`.

## Movement effect selection

Native function around `0x511e0..0x512e3` owns one movement effect instance and selects it in this order:

1. sea/transport state -> `effect_moving4.xml`;
2. otherwise native unit type `0` (infantry) -> `effect_moving1.xml`;
3. native unit type `1` (cavalry) -> `effect_moving2.xml`;
4. remaining movable land branch used by artillery -> `effect_moving3.xml`.

The Web resolver is isolated in `native_movement_effect_core.js`. Fort units have no movement effect because they do not move.

## Original area emitter and motion integration

The area spawn path at `0xC9D64..0xC9E3E` uses one shared random interpolation value along the previous/current emitter segment, then independent centered width/height jitter. This is why the Web moving emitter updates its area rectangle from the unit's previous world position to its current world position every frame: particles are emitted along the actual movement segment, not at the destination cell.

The particle update at `0xC93C0+` proves explicit per-frame order:

- position += direction * current speed-track multiplier * dt;
- vertical direction += current gravity * dt;
- gravity/speed/scale/rotation/color track values advance;
- particle age advances and life-track keys update their slopes.

The Web runtime implements the recovered movement-relevant subset: direction/speed, gravity, rotation, scale/color/alpha life-track interpolation, area emission, continuous emitter lifetime, alpha/additive blending, and per-particle RGB modulation.

## Original moving XML data

- `effect_moving1`: infantry dust, area 20x20, `cloud5.png`, particle 35x35, 300/s, life 0.5-0.8s, speed 20-25, gravity -40..-20.
- `effect_moving2`: cavalry dust; same physical parameters, particle 40x40.
- `effect_moving3`: artillery dust; same physical parameters, particle 45x45.
- `effect_moving4`: water movement, area 10x10, `water001.png`, particle 30x25, additive blend, 100/s, life 0.25-0.5s, speed 20-25, gravity 0.

`mode="cont"` does not self-stop at emitter `life`; the owning movement controller stops emission when movement ends. Already emitted particles finish their individual lifetime.

## Runtime integration

`startMoveAnim()` now creates the matching native movement emitter before unit state is committed to the destination. `drawNativeSimpleEffects()` updates the emitter segment in world coordinates, stops it at the move-animation end, and keeps old particles in world space so the trail remains behind the moving unit.

AI fast-forward remains a presentation-layer compression: because the move interval is shorter, fewer particles are emitted in fast-forward, without changing simulation rules.

## Current boundary

The mapping, emitter path, particle physics subset and rasterization are regression-tested. Exact native scene-graph z-order of movement particles relative to every unit/UI layer has not yet been proven and should not be claimed as pixel-perfect until that controller/render ordering is reverse-engineered.
