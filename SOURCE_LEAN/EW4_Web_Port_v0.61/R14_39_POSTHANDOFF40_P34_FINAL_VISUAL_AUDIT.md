# EW4 Web Port v0.61 — P34 Final Visual Closure Audit

Checkpoint date: 2026-09-10
Baseline: P33 Visual Timing Polish WIP / PORT_ONLY
Status: **final local-code/evidence candidate**. This closes the remaining items that can be resolved from the extracted native evidence in the package. It does not falsely claim that an iPhone/original side-by-side capture was performed inside this environment.

## 1. Combat presentation — closed from P33

P33's separation between immediate deterministic simulation and authored Attack-end presentation remains intact:

- damage RNG, HP result and counter eligibility are calculated immediately;
- HP arc, damage float, kill marker and disappearance commit at the authored Attack motion endpoint;
- a pending-kill unit remains renderable until that visual commit;
- result presentation cannot pre-empt the final hit;
- normal AI pacing waits for the presentation, while fast-forward compresses presentation only.

No combat formulas or AI decisions were changed in P34.

## 2. Transport ship rule / anchor / facing — closed for production

The original item definition identifies function `12` exclusively as **Armored Carrier** (`def_item.xml`, ids 40 / 14001..14004). P34 makes the visual rule explicit and single-sourced:

- ordinary embarked land unit -> `transportship1.png`;
- embarked unit carrying function-12 Armored Carrier -> `transportship2.png`;
- `transportship1` retains native ref `(70,107)` and natural right-facing art;
- `transportship2` retains native ref `(94,119)` and natural left-facing art;
- mirroring is performed around the native refpoint, never by translating the unit anchor;
- multi-segment movement updates facing from the current path segment.

The item semantic + dedicated second transport asset is sufficient for the production rule. No claim is made that a stripped native controller branch was re-disassembled in P34.

## 3. StageIntro — exact evidence-backed cleanup

Original `form_stageintro` remains 360x219 and centered on the 568x320 logical stage.

P34 closes three visible Web mismatches:

- native `user_window` keeps its empty 28px header/chrome band even though its title text is empty;
- `text_victory` / `text_bestvic` are placed at y=30 and centered across their full 180px condition group, matching the source layout rather than the old 125px Web box;
- `pattern_stage_intro.png` is a 63x36 HD resource and therefore renders at ~31.5x18 logical pixels; the old 126x18 stretched draft is removed and the decoration is horizontally centered at y=195.

## 4. Talk — exact layout geometry pass

Original `form_talk` evidence: 325x83; board=`board_dialog_ex.png`; portrait x=10,y=7; content x=88,y=7,w=220,h=76.

P34 uses:

- 78x78 logical portrait, which exactly spans x=10 -> x=88 before the content group;
- mirrored content x=17 on right-side dialogue (`325-(88+220)=17`);
- original `board_dialog_ex.png` stretch/extend presentation;
- `gray_board_dialoguearrow.png` at its HD half-scale 7.5x7 logical footprint (8x7 raster box).

Dialogue side/orientation remains driven by the extracted native dialogue `left` field, not by a new heuristic.

## 5. Low zoom / terrain / buildings / labels

Native camera contracts remain unchanged:

- zoom range 0.2..1.0;
- tactical/strategic split at 0.5;
- terrain, installations and buildings stay world-space and retain extracted refpoints;
- strategic unit markers remain screen-space after the effect pass;
- maptext stays in the original authored placement system.

P34 removes one surviving Web-only exception: city/port `area_name` text no longer has `Math.max(6, 7*zoom)`. Font size and outline now scale directly with camera zoom, so at low zoom labels do not remain artificially large while their buildings shrink.

## 6. Touch / camera

P34 intentionally does not replace proven native gesture math. The recovered values remain authoritative:

- tap slop: independent 15px axes;
- pinch requires both old/new separations >40px;
- pinch anchors the stationary finger;
- no drag fling;
- interrupted pointer capture / window blur clears stale gesture state.

## 7. Layer order / overlay anchors

The recovered native battle ordering remains:

`Background -> SelectLower -> Outline -> HexFrame -> Object -> SelectUpper -> global effects -> strategic low-zoom markers -> UI floats`.

Within a tactical unit, the production composition remains:

`flag/pole behind formation -> unit/transport model -> relation + HP + army-class marker -> commander bubble -> morale`.

P34 does not introduce an unproven z-order rearrangement.

## 8. Protected logic / player MOD invariants

P34 is presentation-only apart from documentation/cache metadata. It preserves the protected save/upgrade cores and the established player-only MOD rules:

- attack min +4 / max +4;
- base troop HP +120 (supersedes the older +40, never stacked);
- movement +2;
- AI receives none of those bonuses;
- all existing general/princess/resource/consumable modifications remain inherited.

## 9. Acceptance meaning

P34 is the final candidate for everything that can be closed from local code/data/native evidence. A physical iPhone/original side-by-side recording can still expose device-specific font rasterization, Safari compositing or a few-pixel subjective difference; that is an acceptance smoke test, not an unresolved production logic item.
