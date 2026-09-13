# P38 Native HUD Baseline Polish — WIP Checkpoint

Date: 2026-09-10

This checkpoint continues P37 only in the evidence-backed `form_game` presentation layer. It does **not** reopen map geometry, unit native refs/scales, 568x320 logical space, HiDPI backing, touch mapping, combat timing, transport, StageIntro/Talk, or protected gameplay/save/upgrade/warzone cores.

## Landed in P38

- Corrected `group_incom` lower text-row baseline: native XML places row-2 icons at y=26 and text at y=30, so slot2/slot4 text now uses local top=4 instead of the shared Web top=3.
- Corrected `group_funcres/btn_done` bitmap fill to the XML-authored 33x33 control box; the previous Web background width was 32px inside a 33px control.
- Restored `group_aiaction/text_playing` authored text-box height to 23px (x=44,y=7,w=40,h=23), instead of the Web-shortened 15px box.
- Added `test_p38_native_hud_baselines.js` to guard these corrections and preserve P35/P36/P37 frozen invariants.

## Explicitly audited but not changed

- `board_button.png` is 168x112 physical pixels, exactly 84x56 at the project's 2x logical asset scale; the existing 84x56 rendering is therefore correct and is not a stretch bug.
- `common_line_hor.png` is a uniform 133x1 single-color row; its current 68px presentation has no authored cap/detail to distort, so no speculative rewrite was made.

## Verification

- Full root `test_*.js`: 125/125 PASS.
- Protected cores: 4/4 SHA256 MATCH.
- Service Worker CORE: see `P38_SERVICE_WORKER_AUDIT.json`.
- APK/AAB recursive scan: see `P38_BINARY_SCAN_PREPACKAGE.json`.

## Next

Continue only evidence-backed native presentation cleanup. Highest-value remaining uncertainty is true-device iPhone/WebKit font rasterization and compositing; do not compensate by moving/resizing map or unit geometry.
