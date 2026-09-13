# EW4 r14-39 Post-Handoff 6 — Native Camera Presentation Audit

Base: cumulative Post-Handoff 5 tree.

## Proven native behavior integrated

### Manual touch is not fling
- Battle touch handlers `0x9fe40..0xa0758` apply direct incremental drag while a pointer moves.
- Pointer release performs tap/pointer-state handling; it does not start an inertial camera motor.
- Web manual drag therefore remains direct and stops on release.

### Programmatic camera motor
- Position target setup: `CEntityCamera` path around `0x7f8d0`.
- Position+zoom target setup: around `0x7fa90`.
- Per-frame update: around `0x7fc90`.
- Native tick multiplier: `60.0`.
- Position setup snap threshold: `1.0` world unit.
- Zoom setup snap threshold: `0.01`.
- `GameSpeed` coefficient table for settings 1..5: `0.012, 0.015, 0.020, 0.020, 0.020`.
- Original `assets/global_data.xml` defaults `GameSpeed` to `2`, therefore this port uses `0.015` until the currently visual-only GameSpeed option is wired to native behavior.
- Velocity is created once as `(target-current)*coefficient`; update advances by `velocity * dt * 60` and snaps to target instead of overshooting.

`native_camera_core.js` now exposes this as a separate programmatic motor. `app.js` steps it in the battle animation RAF. It is intentionally not conflated with manual touch.

### Script/action focus evidence
- Tutorial scripts contain commands such as `moveto area`; native executor routes them through map/camera focus.
- Single-area wrapper around `0x853c0`: if already visible and zoom >=0.5 it does nothing; otherwise focuses the area and restores zoom to 1.0 when starting below 0.5.
- Source/target wrapper around `0x85480` focuses their midpoint when either endpoint is not adequately visible; below 0.5 it also returns to 1.0.
- Battle presentation controller around `0x59f30` waits for the native camera moving flag before advancing specific action presentation states.

The motor is now present, but the synchronous Web move/attack controller is **not yet deferred behind this camera wait** in this patch. That is deliberately left for the next isolated presentation-controller batch rather than changing combat timing in the same patch as the camera-core correction.

## Fresh-battle opening camera correction

`def_battlelist.xml` `centerx/centery` are campaign-stage-selection layout coordinates, not battle camera coordinates. Post-Handoff 5 still used them in `openBattle`; that assumption is removed here.

Native new-battle path:
- scene init around `0x7d410`
- current player-operable country lookup around `0x805f0`
- opening/action-assist focus selection around `0x57240`
- direct single-area camera set via `0x85380`

`0x57240` scans the current player's actionable-cell list. `0x4db20(cell)` checks whether the unit/occupant on that cell has a commander/general pointer; a commander-bearing cell returns immediately. Only when no such cell exists does native `ActionAssist` scoring select the best cell.

The Web port now reproduces the high-confidence branch:
1. fresh battle: first player-owned live commander-bearing unit in BTL/runtime order;
2. if no commander unit exists: first player unit as an explicitly marked `actionassist-unresolved-fallback`;
3. if no player unit exists: battle-rectangle center fallback;
4. native-geometry save restore: preserve its saved camera instead of re-running opening focus.

The no-commander `ActionAssist` scoring remains unresolved and is not claimed as original parity.

## Still unresolved
1. Exact `ActionAssist` scoring priority for the rare no-commander opening case.
2. Exact equal-cost neighbor iteration/tie-break order in native pathfinding.
3. Full original tutorial script execution is still absent in the Web port even though the native `moveto area` camera behavior is now understood.
4. Action presentation camera focus/wait is proven but not yet attached to the synchronous Web move/attack pipeline in this patch.
