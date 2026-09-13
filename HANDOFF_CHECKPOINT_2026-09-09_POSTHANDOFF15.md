# EW4 Web Port r14-39 — Post-Handoff 15 Tutorial Executor Frozen Checkpoint

Frozen from the Post-Handoff 14 SceneShop baseline after formally landing the original APK Tutorial Script Executor.

## Production state
- P1-P11 preserved; completed camera/UI/logic work was not rolled back.
- P12 shared SceneShop remains frozen.
- P13 full compact animation remains frozen: 877/877 unit definitions, 3519/3519 motions, 7407/7407 battle units, 1754/1754 directional attack chains.
- P15 native Tutorial Script Executor is now frozen in production.

## Tutorial state
- 2 original APK tutorial scripts preserved byte-for-byte as XML evidence.
- 138 + 135 = **273 / 273 commands** parsed into runtime data.
- 17 basic + 16 advanced = **33 / 33 tutorial text steps** present.
- Real wait-state semantics for touch, map area, UI target, and action completion.
- Tutorial battles auto-start their matching script.
- Real battle movement/attack/undo/training events drive `wait action` completion.
- Original tutorial formation-size behavior recovered through repeated recruit-card taps.
- Original tutorial pointer asset and XML rectangle adjustments are wired.
- P15 tutorial runtime is included in the offline Service Worker cache.

## Regression
- Full current JS suites: **80 / 80 PASS**.
- See `TEST_RESULTS_POSTHANDOFF15_80_OF_80_PASS.txt`.

## Next major logic targets
1. Remaining obvious Web-replacement UI/controller parity, especially result/reward and GeneralInfo upgrade/regroup flows where the surface can look correct while the original transition/order is still wrong.
2. Continue original-evidence controller cleanup instead of inventing new Web flows.
3. Final iPhone true-device visual/audio/touch calibration.

## True-device caveat
80/80 regression proves the checked data/controller contracts, not pixel-perfect iPhone behavior. Do not mark final visual/touch parity complete until true-device testing.
