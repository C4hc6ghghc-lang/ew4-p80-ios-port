# EW4 Web Port v0.61 — P33 Visual Timing / Transport / Touch Audit

Checkpoint date: 2026-09-10
Baseline: P32 Visual Polish WIP / PORT_ONLY
Status: WIP visual-fidelity checkpoint, **not** final visual parity.

## 1. Attack impact-time visual commit

Native audit evidence in `R14_39_POSTHANDOFF9_VISUAL_UI_AUDIT.md` states that target-side impact begins at the **end of the authored Attack motion**, not after the full Attack -> Reload -> Finish chain.

P33 keeps combat simulation deterministic and immediate, but separates presentation commit:

- damage RNG / HP result / counterattack eligibility are still computed immediately;
- `deferVisual` carries the already-computed before/after HP and kill result into a presentation payload;
- target HP arc, damage float, death marker and visual disappearance commit at the native Attack-phase impact delay;
- a logically dead target remains renderable until its pending impact presentation commits;
- battle victory/defeat evaluation is deferred until the pending hit presentation has had time to commit, preventing result UI from pre-empting the hit;
- AI normal-speed chaining waits for its pending presentation; AI fast-forward continues to compress presentation time and does not change AI decisions, action count, combat RNG or damage.

The presentation-only fields are defined as **non-enumerable** runtime properties so they do not enter save payloads. `battle_save_core.js` is untouched and remains at the protected P21+ hash.

## 2. Transport ship orientation / anchor

Original transport assets and native reference points remain authoritative:

- `transportship1.png`: native asset/ref retained;
- `transportship2.png`: native asset/ref retained;
- ship drawing mirrors around the native ref point rather than shifting the anchor;
- embarked units now update facing from the current movement path segment, including turns during a multi-segment sea path;
- the two source PNGs keep their own natural-facing orientation instead of assuming both art assets face the same way.

Still **not claimed proven**: the exact original runtime rule deciding `transportship1` versus `transportship2` in every item/equipment combination. That remains true-device/native-controller calibration work.

## 3. StageIntro / Talk visual cleanup

- `form_stageintro` keeps the extracted original 360x219 geometry.
- The Web-only stage title text is now suppressed because the original extracted `form_stageintro` layout has an empty window title and no corresponding title text element.
- `form_talk` now uses extracted `board_dialog_ex.png` instead of the flat Web-only dialog-board border/background.

Exact font metrics, original extend/9-slice raster semantics, and device-scaled portrait/text baselines remain true-device calibration items.

## 4. Low zoom / touch handling

No speculative low-zoom rule was introduced. Existing proven native camera contracts remain unchanged:

- camera zoom: 0.2 .. 1.0;
- tactical interaction / strategic LOD split: 0.5;
- low-zoom unit markers: original `mark_unit_*` strategic presentation;
- original world-space terrain/building scaling retained;
- native maptext keeps original placement and has no invented per-label LOD threshold.

P33 adds gesture-state cleanup on `lostpointercapture` and window blur so an interrupted iOS pointer sequence cannot leave drag/pinch state stuck. This does not change pinch scale math, tap slop, camera bounds, fling policy or LOD thresholds.

## 5. Protected logic / MOD invariants

P33 does not intentionally alter gameplay rules, campaign progression, save schema or user MOD values.

Protected hashes checked after the patch:

- `battle_save_core.js` = `4858c7f862dac736d3624b8e64567af1484382b63bd8482aa544cd3204272dc2`
- `native_upgrade_core.js` = `2ae064cb5d8c3733945b970ef255cefa7c5b2ae4981f26099182f4206da7204c`
- `assets/data/native_warzone_tech.json` = `1c7a9d71d1f33cee03262908e8aa1195e543b44a53ef584a81dcdcbda0170da1`
- `assets/data/def_warzonetech.xml` = `35320e99f2c39ac998c92340cb221653ae3f2c9fe8bb24b9ee3bfb321efe64db`

Player-only rules remain inherited from the P30/P32 baseline, including player attack +4/+4, base troop HP +120, and movement +2; AI remains isolated from those player bonuses.

## 6. Regression

New P33 regression coverage locks:

- Attack-phase-derived impact delay;
- deferred visual HP/death commit;
- non-enumerable presentation fields;
- pending-death render visibility;
- delayed victory presentation gate;
- transport natural-facing mirror and current-segment facing;
- lost-pointer-capture cleanup.

Full JS suite: **119/119 PASS**.

Five consecutive full-suite runs: **5/5 runs at 119/119 PASS**.

These tests prove checked code/data contracts. They do **not** replace iPhone true-device visual timing, touch-feel or pixel-alignment verification.
