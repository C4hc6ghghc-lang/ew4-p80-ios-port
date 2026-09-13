# EW4 r14-39 Post-Handoff Patch 4 — Native Camera / Layer / Low-Zoom LOD

Baseline required: **r14-39 frozen handoff + Post-Handoff Patch 1 + Patch 2 + Patch 3**, applied in that order.

Apply by merging the contained `EW4_Web_Port_v0.61/` directory over that cumulative tree and allowing same-path files to replace the older versions.

This micro-batch changes only the camera/gesture/render-order/low-zoom foundation and its audits/tests. It does **not** add naval effects or invent any unproven torpedo path.

Key native-backed behavior:
- camera zoom: 0.2 .. 1.0
- tactical interaction threshold: 0.5
- tap slop: <15 px on both axes
- pinch gate: both old/new separations >40 px
- pinch anchor: stationary other finger per move event
- drag: incremental delta/zoom
- ordinary drag edge margin: 16 world units
- low zoom: exact `mark_unit_0..21` strategic sprites, screen-space size
- battle order: SelectUpper -> global particle pass -> low-zoom strategic markers

Known unresolved fidelity points intentionally left untouched:
1. Native `0x84be0` 64/54 cell-hit convention still needs reconciliation with the already-validated Web/maptext anchor `x=q*64, y=r*53+(q&1)*26.5`; `nearestCell()` is not falsely relabeled as exact native parity.
2. Native low-zoom `0x5f050` also draws an HP/status primitive and a second indexed overlay; their complete visual identity/composition is not yet proven, so no Web substitute was invented.
3. Scripted camera easing/target moves exist in native, but free-drag fling inertia has not been proven and is not fabricated.

Validation target after apply:
- all `test_*.js`: **62/62 PASS**
- `node --check app.js`: PASS
- `node --check native_camera_core.js`: PASS
