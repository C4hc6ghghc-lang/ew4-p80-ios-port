# EW4 r14-39 Post-Handoff 8 — AI Action Camera + Native Path Tie-Break

Base: cumulative Post-Handoff 7 tree.

## 1. AI action presentation camera

The native battle action presentation controller around `0x59f30` is shared by player and AI actions. It has a skip-presentation input path which bypasses camera focus/wait, while the normal path uses the same area pair focus logic already integrated for player actions.

Web integration in this patch:
- normal AI direct attacks use native source/target safe-visibility testing before rules/animation begin;
- normal AI movement uses source/destination focus before mutating the unit position;
- a move-followed-by-attack performs the second source/target focus check before attack;
- if focus is required, the existing AI continuation is stored in `cameraAfterMotion` and resumes only after the native camera motor reports completion;
- damage, counterattack, training XP, cavalry extra-action `i--`, country economy settlement, and country sequencing remain on the existing gameplay paths;
- enabling enemy fast-forward sets `aiFastForward` even while an AI camera presentation is active; subsequent AI actions bypass camera focus, matching the native skip-presentation branch. The already-running camera motion is conservatively allowed to finish rather than inventing a mid-motion native cancellation that is not yet proven.

## 2. Native movement direction enum

`CEntityMap` neighbor lookup is implemented at `0x858f0`. Direction indices 0..5 map to the same geometric order for both row parities:

0. East
1. South-East
2. South-West
3. West
4. North-West
5. North-East

Odd-row coordinates:
- E `(q+1,r)`
- SE `(q+1,r+1)`
- SW `(q,r+1)`
- W `(q-1,r)`
- NW `(q,r-1)`
- NE `(q+1,r-1)`

Even-row coordinates:
- E `(q+1,r)`
- SE `(q,r+1)`
- SW `(q-1,r+1)`
- W `(q-1,r)`
- NW `(q-1,r-1)`
- NE `(q,r-1)`

## 3. Native movement path search proves tie-break relevance

The route entry point used by unit movement is `0x85850`:
- it initializes the movement-search state through `0x8ddc0`;
- `0x8ddc0` repeatedly expands frontier entries through `0x8dc40`;
- `0x8dc40` initializes the direction index to 0 and loops through exactly `0..5`, calling `0x858f0` for each neighbor;
- candidate insertion/update is handled by `0x8db70`;
- the existing-candidate comparison retains the existing candidate on an equal remaining-cost/value result, so the first equal-cost predecessor survives;
- `0x8e1c0` reconstructs the final route from those stored predecessor records.

Therefore the native 0..5 direction order is gameplay-significant for equal-cost path selection, not merely a rendering enum.

Web changes:
- `EW4NativeHex.neighbors()` now returns E -> SE -> SW -> W -> NW -> NE exactly;
- `movementPath()` uses an explicit monotonically increasing insertion serial after movement cost, making equal-cost queue ordering deterministic rather than depending on JS sort implementation details;
- an equal-cost alternate route still does not overwrite an already-recorded predecessor, matching native first-predecessor behavior.

## 4. Regression checkpoint

- Full JS suite: **69/69 PASS**.
- compact BILE full parity: **1076/1076 PASS**.
- Machine Gun Finish corrected set: **18/18 PASS**.
- Native path-direction/tie-break contract: PASS.

## Remaining uncertainty

1. The no-commander opening-camera `ActionAssist` scoring formula is still not fully reversed.
2. The exact behavior of a native fast-forward request issued *during* an already-running camera motion is not proven; this patch deliberately does not invent mid-motion cancellation.
3. Full tutorial-script execution (`moveto area`, wait/select commands, etc.) remains unimplemented even though its camera motor path is understood.
