# P36 Native HUD Polish — Handoff Checkpoint

Date: 2026-09-10

This is a **handoff checkpoint**, not a claim that true-device visual acceptance is finished. It starts from P35 Final Native Presentation and preserves all P21-P35 gameplay, map, unit-anchor, combat-timing, transport, StageIntro/Talk, low-zoom, HiDPI and touch-mapping work.

## What P36 has already landed

- Restored `form_game` undo button geometry to native `x=0, y=293, 37x37`.
- Replaced whole-bitmap stretching for `board_resources`, `board_buttons`, and `board_terrain_info` with native-style horizontal extension that preserves authored end caps (`DrawMode="hextend"` evidence).
- Corrected top resource HUD anchors: icons at native 3/53/103 and text at 21/70/125, with HD markers at ~20x20 logical size.
- Corrected terrain/facility summary marker anchors and kept the authored board edge geometry.
- Added the original-style AI action strip (`board_aiaction` + country flag + `>>>`) and kept the old Web text turn label hidden.
- Added P36 HUD geometry evidence/audit data and `test_p36_native_hud_hextend.js`.
- Service Worker cache generation was advanced for the P36 HUD assets without reopening gameplay cores.

## Current verification

- Full JS regression at handoff: **123/123 PASS**.
- P35's previously frozen 5x 122/122 verification remains historical evidence for the inherited P35 baseline.
- Protected campaign/save/upgrade/warzone cores must remain byte-identical.
- Original APK/AAB binaries are excluded from PORT_ONLY deliverables.

## Next target for the new conversation

1. Continue the **last native-presentation / anti-Web-port pass only**: inspect remaining visible battle HUD controls, text baselines, button/filter effects, and any CSS treatment that duplicates shadows or stretches authored PNGs.
2. Keep **map and unit geometry frozen**. Do not enlarge units, alter native refpoints, change 568x320 logical coordinates, or undo P35 HiDPI/touch mapping merely for appearance.
3. Prefer exact `original_layout-568h.xml` / extracted native asset evidence. If evidence is weak, do not invent a modern Web UI rule.
4. After each material visual patch, run the full `test_*.js` tree. Before any next final package, repeat map/unit asset integrity, Service Worker presence, protected hashes, ZIP integrity, and recursive APK/AAB scan.
5. True-device iPhone A/B remains the final acceptance gate for sub-pixel font/compositing/touch feel.

## Do not reopen

Do not redo P29-P35 historical TODOs unless a concrete true-device defect or new native evidence proves a real regression. In particular, do not retune unit scale/native refs to compensate for blur; P35 HiDPI backing is the raster fix.
