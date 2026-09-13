# EW4 r14-39 Post-Handoff 7 — Player Action Camera Focus

Base: cumulative Post-Handoff 6 tree.

## Native visibility threshold

The normal battle-mode area visibility helper at `0x7ff80` is now reproduced for action presentation.

`CEntityMap` construction at `0x83b84 -> 0xaadc0` proves every map-area rectangle is `64 x 72`; its center is stored as `x + width/2`, `y + height/2`.

For normal battle modes, `0x7ff80` requires the complete area rectangle to fit inside the current camera viewport after these world-space safe insets:
- horizontal: `64`
- vertical: `72`

The GameMode=4 multiplayer-specific lower-screen adjustment in the tail of `0x7ff80` is not activated by the normal campaign/conquest player path implemented here.

## Pair focus

Native pair wrapper around `0x85480`:
- checks both source and target area rectangles;
- if both are adequately visible and camera zoom is >= 0.5, action presentation proceeds without camera movement;
- otherwise the target camera position is the midpoint of the two area centers;
- when current zoom is below 0.5, target zoom is also restored to 1.0;
- presentation state waits for `CEntityCamera` moving to become false before advancing.

## Web integration in this patch

Player actions now use the proven presentation ordering:
1. user requests a legal move or attack;
2. source/target safe visibility is tested using native 64x72 area rectangles and the 64/72 camera safe insets;
3. if no focus is required, the existing gameplay mutation begins immediately;
4. if focus is required, the camera motor targets the exact source/target midpoint;
5. battle interaction controls are presentation-locked while the camera motor is active;
6. after the camera reaches target, the existing movement/attack rule mutation and animation begin.

The gameplay formulas themselves were not changed by this patch. `attackAI()` and the AI country-turn scheduler remain synchronous on purpose; AI presentation focus is a separate follow-up batch because it must preserve fast-forward and turn scheduling semantics.

## Remaining camera/presentation gaps

1. AI move/attack action focus + wait is not yet attached.
2. Native no-commander `ActionAssist` opening focus scoring is still unresolved.
3. Equal-cost native pathfinding neighbor tie-break order remains unresolved.
4. Original tutorial script execution (`moveto area`, waits, selections, etc.) is still absent; understanding its camera command is not equivalent to having the tutorial executor.

## Regression checkpoint

- Full JS suite: **67/67 PASS**.
- compact BILE parity: **1076/1076 PASS**.
- Machine Gun Finish corrected set: **18/18 PASS**.
