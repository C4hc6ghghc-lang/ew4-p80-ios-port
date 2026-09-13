# EW4 Web Port r14-39 post-handoff patch 1

Baseline: `EW4_R14_39_HANDOFF_2026-09-08_2254.zip`.

## User-authorized scope update

The player-side backend overrides now explicitly include:

- medals: unlimited
- badges/shields: unlimited
- Military Academy refresh: unlimited / zero-cost
- in-battle SceneUseItem consumables IDs 11..15: unlimited use / no consumption
  - 11 Wine
  - 12 Spirit
  - 13 Medikit
  - 14 Medikit L
  - 15 First Aid Box

Original price/item UI is preserved. Do not add FREE/∞ advertising solely for these overrides.
The five battle consumables expose at least one virtual usable count if the real inventory has none and are not removed after use.

## Mainline continuation: machine-gun visual timeline

The existing 143 `def_effectsanim.xml` timelines now drive both timed audio cues and supported timed visual cues.
This patch integrates only the proven machine-gun visual effect path:

- `effect_mgunfire.xml`
- two original emitters: `gunflash1`, `gunflashsmoke1`
- original `eff.png` atlas rectangles
- additive blend
- original machine-gun timeline timing at 0.5s
- original per-muzzle x/y offsets
- original left/right rotation (0 / 180 degrees)

Do not claim artillery / rocket / naval visual timelines are completed by this patch. They remain next work.

## Regression

58 / 58 `test_*.js` PASS after restoring the APK test fixture path from the APK included in the frozen handoff.

## Next mainline micro-batches

1. artillery fire/smoke visual timeline
2. rocket visual timeline
3. naval/torpedo visual timeline
4. particle z-order/native fidelity after those visual groups are wired
