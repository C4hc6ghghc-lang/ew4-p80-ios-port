# EW4 Web Port r14-39 — Post-Handoff 13 Full Animation Frozen Checkpoint

Frozen after the P11 merged source plus the full compact-BILE production animation pass.

## Frozen production animation state
- 877 / 877 native unit definitions exposed to production.
- 3519 / 3519 native motion references exposed to production.
- 1754 / 1754 unit-direction attack chains (877 x left/right) construct successfully.
- 101 BTL / 7407 / 7407 runtime battle units resolve into the full animation pack.
- Production remains compact BILE + original atlas. No expanded `runtime_sheet.png` dependency was reintroduced.
- Production manifest is `assets/data/native_animation_core877.json`; do not switch back to core265.

## Historical repaired subset
- compact BILE repaired subset parity remains 1076 / 1076 PASS.
- Machine Gun Finish corrected set remains 18 / 18 PASS.

## Regression
- Full current JS suites: 77 / 77 PASS.
- See `TEST_RESULTS_POSTHANDOFF13_77_OF_77_PASS.txt`.

## State-machine finding after full coverage
Native normal attack remains:
Attack -> optional Reload -> optional Finish -> static Ready.
Do not invent a Ready wind-up. UNDREADY belongs to a separate cancel/withdraw-preparation path.

## Next major logic work already reverse-engineered
Tutorial XML exists in the original APK:
- basic tutorial: 17 segments
- advanced tutorial: 16 segments
Known commands include show/hide text, moveto/wait area, sel/unsel area, draw rect, draw UI rect, wait touch, wait UI, wait action, exit.
Europe tutorial area encoding: `areaId = r*79 + q`.
Do not implement a fake tap-anywhere tutorial.

## Important scope note
This quick P13 freeze deliberately prioritizes the user's request to preserve the newly completed full-animation work immediately. The P11 frozen source remains the controller/UI baseline. Earlier P12 SceneShop reverse-engineering findings are preserved in `WIP_P12_P13_NOT_FROZEN.md`; do not claim that transient P12 implementation is frozen here unless it is re-landed and retested.
