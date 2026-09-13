# EW4 v0.61 — P35 Final Native Presentation Audit

Checkpoint date: 2026-09-10
Baseline: P34 Final Visual Candidate / PORT_ONLY
Status: **final local native-presentation candidate**. This pass targets systemic map/unit raster and transformed-touch artifacts without changing recovered logical geometry, unit size rules, combat, AI, save semantics or user MOD rules.

## 1. Battlefield raster pipeline

The battle remains authored in the recovered **568x320 logical coordinate space**. P35 separates logical size from raster backing density:

- `BATTLE_LOGICAL_W=568`, `BATTLE_LOGICAL_H=320`;
- backing scale derives from `devicePixelRatio * stageScale`;
- scale rounds upward to a stable 0.5 step and is capped at 4x for iPhone memory safety;
- the context transform maps all existing logical drawing commands back into 568x320 coordinates;
- high-quality smoothing is requested for scaled source sprites.

This removes the previous pipeline where the browser could enlarge a single 568x320 bitmap to the full modern iPhone display, which blurred map art and unit overlays together.

## 2. Unit/map geometry remains native-ref driven

P35 deliberately does **not** retune unit scale or anchors to compensate for blur. The following remain unchanged:

- native hex cell centers;
- extracted sprite `refx/refy`;
- tactical/strategic LOD boundary;
- `unitVisualZoom` behavior;
- transport native refs and P34 selection/facing rule;
- tactical overlay z-order.

The new asset-integrity regression proves all manifest files exist, 161 high-risk native-ref sprites carry finite geometry, all 877 READY visuals are valid, and all 7407 battle units resolve to a READY visual.

## 3. Transformed touch mapping

The stage still uses CSS scaling for the fixed native 568x320 composition. P35 no longer trusts `offsetX/offsetY` on the CSS-transformed battle canvas. Every battle pointer position is inverted as:

`client coordinate -> canvas screen rect -> 568x320 logical coordinate`.

This keeps tap selection, path selection, panning and stationary-finger pinch anchors aligned with the same hex geometry at every CSS scale and backing density. P34's recovered gesture constants remain unchanged.

## 4. Conquest map

The 410x320 conquest country preview now uses a HiDPI backing store while preserving its 410x320 logical map/marker coordinate system. No country marker coordinates or conquest data are changed.

## 5. Native application shell presentation

User-facing shell cleanup removes avoidable port signatures without touching save compatibility:

- document title: `欧陆战争 IV`;
- manifest name/short name no longer expose `Web Port`;
- Apple standalone metadata is present;
- long-press text selection/touch callout and document overscroll are disabled;
- the 568x320 stage no longer has a Web-card drop shadow.

Internal save/migration keys retain their historical names intentionally.

## 6. Inherited P33/P34 visual contracts

P35 retains without reinterpretation:

- immediate deterministic combat simulation + authored Attack-end HP/damage/death visual commit;
- pending-kill rendering and result presentation gate;
- function-12 Armored Carrier -> `transportship2`, ordinary embarkation -> `transportship1`;
- native transport refs/path-segment facing;
- evidence-backed StageIntro/Talk geometry;
- 0.2..1.0 camera and 0.5 tactical/strategic split;
- world-space low-zoom labels/buildings/terrain behavior;
- native recovered battle/effect/marker/overlay ordering.

## 7. Protected logic / user MOD invariants

Protected hashes remain byte-identical:

- `native_upgrade_core.js` = `2ae064cb5d8c3733945b970ef255cefa7c5b2ae4981f26099182f4206da7204c`;
- `battle_save_core.js` = `4858c7f862dac736d3624b8e64567af1484382b63bd8482aa544cd3204272dc2`;
- `assets/data/native_warzone_tech.json` = `1c7a9d71d1f33cee03262908e8aa1195e543b44a53ef584a81dcdcbda0170da1`;
- `assets/data/def_warzonetech.xml` = `35320e99f2c39ac998c92340cb221653ae3f2c9fe8bb24b9ee3bfb321efe64db`.

Player rules remain attack +4/+4, base troop HP +120 and movement +2; AI remains isolated from those bonuses. All previously accepted general/princess/resource/consumable changes remain inherited.

## 8. Verification

- full JS suite: **122/122 PASS**;
- repeated full suite: **5/5 runs at 122/122 PASS**;
- Service Worker CORE: **1054/1054 present**;
- map/unit asset integrity: **PASS**;
- pre-package direct APK/AAB: **0**;
- nested ZIPs scanned: **12**, APK/AAB entries **0**, scan errors **0**.

## 9. Remaining uncertainty

No physical iPhone/original side-by-side capture was performed by this build environment. The residual uncertainty is device-specific raster/compositing/font behavior or a subjective few-pixel difference visible only on hardware. P35 should be reopened only for a concrete true-device defect or new original evidence, not for stale P29-P34 TODO language.
