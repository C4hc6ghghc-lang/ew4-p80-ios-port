# EW4 Web Port r14-39 — Post-Handoff 14 SceneShop Frozen Checkpoint

Frozen from the 15:55 P13 full-animation baseline after formally landing P12 SceneShop.

## Production state
- P1-P11 preserved; no completed camera/UI/logic work was rolled back.
- P13 full compact animation remains frozen: 877/877 unit definitions, 3519/3519 motions, 7407/7407 battle units, 1754/1754 directional attack chains.
- P12 shared native SceneShop is now frozen in production.

## SceneShop state
- Shared form shell for HQ and battlefield shop contexts.
- 14-slot seller inventory.
- 28-slot player ItemBank, scrollable and fully accessible.
- HQ daily stock persistence and date refresh.
- HQ slots 1-5 consumables; slots 7-8 distinct unowned non-consumables.
- HQ buy at base price; HQ sell at 60% floor.
- Battlefield business-star buy discount and 60%-80% sell rate.
- Buy/sell both use inventory-backed item ownership.
- Infinite medals remain hidden as a backend override.

## Regression
- Full current JS suites: **78 / 78 PASS**.
- See `TEST_RESULTS_POSTHANDOFF14_78_OF_78_PASS.txt`.

## Next major logic target
Complete the original Tutorial Script Executor from APK tutorial XML evidence. Do not replace it with tap-anywhere Web scripting.
Known command family remains: show/hide text, moveto/wait area, sel/unsel area, draw rect, draw UI rect, wait touch, wait UI, wait action, exit.
Europe area encoding remains `areaId = r*79 + q`.

## True-device caveat
Full iPhone visual/audio/touch calibration remains pending. Static/controller regression success is not proof of pixel-perfect true-device behavior.
