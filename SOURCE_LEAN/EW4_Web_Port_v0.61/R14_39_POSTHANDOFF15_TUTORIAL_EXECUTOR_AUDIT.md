# r14-39 Post-Handoff 15 — native Tutorial Script Executor audit

## Frozen scope
The APK tutorial XML is now a production runtime input rather than documentation-only evidence.

### Original evidence preserved
- `tutorials_script1.xml`: 138 commands / 17 tutorial text steps.
- `tutorials_script2.xml`: 135 commands / 16 tutorial text steps.
- Combined: **273 / 273 original commands**.
- Source XML SHA-256 is checked by `test_native_tutorial_core.js`.
- Europe area encoding remains `areaId = r * 79 + q`; all referenced tutorial areas are inside their original BTL battle rectangles.

### Runtime executor
`native_tutorial_core.js` implements the original command family:
- `rand seed`
- `show text` / `hide text`
- `draw rect` / `clear rect`
- `draw ui rect`
- `moveto area`
- `sel area` / `unsel area`
- `wait touch`
- `wait area`
- `wait ui`
- `wait action`
- `exit`

The runner is a real wait-state machine. Wrong areas and wrong UI controls do not advance `wait area` / `wait ui`.

### Battle/controller integration
- Tutorial battles auto-start the matching original script from `openBattle()`.
- Map taps feed original `wait area` ids before the real battle action controller executes.
- UI clicks are resolved through original control aliases (`btn_city`, `btn_factory`, `btn_item`, `btn_training`, `btn_upgrade`, `btn_trading`, `btn_buy_1`, `btn_buy_3`, etc.).
- `wait action` is bridged to real player action completion for movement, attack/counter presentation, undo, and manual training; existing build/use-item bridges remain harmless when the runner is waiting for another condition.
- Movement/attack wait-action release is delayed until the corresponding native presentation duration has completed instead of advancing on the initial tap.
- Dynamic panels trigger a second-frame highlight re-position so the tutorial arrow/box follows controls created by the click that advanced the previous step.

### Original tutorial-exposed behavior recovered
The basic tutorial repeats `lbox_unit row=2` three times while teaching formation size. Recruitment now treats repeated taps on the same recruit card as 1-formation -> 2-formation -> 3-formation (up to the building's original recruit cap) rather than interpreting those commands as duplicate no-ops.

### Tutorial visual layer
- Original `tutorials_point.png` is used for the pointer.
- All 33 Chinese tutorial text strings resolve from the original string table.
- World highlights use original XML cell-relative x/y/w/h values.
- UI highlights consume original XML w/h rectangle adjustments (for example button `-4/-4`, close button `-24/-22`, resource-group width corrections) instead of ignoring them.

### Offline/cache
Service Worker cache advanced to `ew4-port-v061-r14-39-posthandoff15-tutorial` and now includes:
- `native_tutorial_core.js`
- `native_tutorial_scripts.json`
- both source tutorial XML files
- original `tutorials_point.png`

## Regression
- Full current JS suites: **80 / 80 PASS**.
- `test_native_tutorial_core.js`: exact XML SHA + 273-command parse/wait semantics.
- `test_native_tutorial_integration.js`: all 273 commands represented, 19 wait-UI aliases, controller/action bridges, formation behavior, area bounds, text completeness, offline cache, and scripted wait-sequence exit for both original tutorials.

## Remaining caveat
This freezes controller/data behavior, not a claim of pixel-perfect iPhone true-device replay. Final touch feel, exact overlay geometry under device scaling, audio-session behavior, and visual z-order still require true-device calibration.
