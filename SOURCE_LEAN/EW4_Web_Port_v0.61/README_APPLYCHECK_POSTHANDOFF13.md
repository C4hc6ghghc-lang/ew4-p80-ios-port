# Apply/check — Post-Handoff 13 full animation checkpoint

This checkpoint is intended to be used as a full frozen source tree, not as a requirement to regenerate expanded animation PNG sheets.

Production requirements:
- `assets/data/native_animation_core877.json`
- `assets/bile_runtime/*`
- `compact_bile_runtime.js`
- `native_animation_controller.js`

Expected checks:
- all `test_*.js`: 77/77 PASS
- `test_full_animation_877.js`: 877/877 units, 3519/3519 motions, 1754/1754 directional attack chains, 7407/7407 battle units
- `test_compact_bile_full_parity.js`: 1076/1076 historical repaired subset, Machine Gun Finish 18/18

Do not switch production back to `native_animation_core265.json`.
Do not restore expanded `runtime_sheet.png` files merely to satisfy old development-cache assumptions.
