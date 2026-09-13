# EW4 Web Port r14-20 — original recruit-tree audit + Austria infantry17

## Scope
This checkpoint corrects the migration accounting after the Machine Gun omission discovered in r14-19, audits the original APK's recruitable army-definition tree, and integrates Austria (`aus`) as a complete 17-definition infantry animation set.

## Original evidence: `def_army.xml`
For every full army-stat template (`fra`, `gbr`, `rus`, `pru`, `aus`, `tur`, `spa`, `usa`, `others`), the original APK defines exactly **41 army definitions**:

| Native type | Families | Grades | Definitions |
|---|---|---:|---:|
| infantry | Militia, Line Infantry, Light Infantry, Grenadier, Guards | 3 each | 15 |
| infantry | Machine Gun | 2 | 2 |
| cavalry | Light Cavalry, Heavy Cavalry, Guards Cavalry, Armored Car | 2 each | 8 |
| artillery | Light Artillery, Heavy Artillery, Siege Artillery, Rocket | 2 each | 8 |
| warship | Privateer, Frigate, Battleship, Ironclad | 1 each | 4 |
| fort | Small Fortress, Fortress, Large Fortress, Coastal Fort | 1 each | 4 |
| **total** |  |  | **41** |

Therefore:
- a complete infantry roster is **17**, not 15;
- a complete cavalry roster is **8** and must include **Armored Car**;
- a complete artillery roster is **8** and must include **Rocket**;
- navy is 4 and forts are 4.

## Original evidence: `def_motion.xml`
Gameplay-stat country templates and visual animation variants are **not the same thing**.

`def_motion.xml` contains country-specific land-unit motion names for a much wider set of visual country codes. The common 26 visual variants are:

`generic, alg, aus, bad, bav, bru, egy, fra, gbr, hes, hre, mar, mek, nas, old, per, pru, rhc, rus, sax, spa, tri, tun, tur, usa, wur`

India (`ind`) is a partial extra visual variant:
- present for Militia, Light Infantry, Guards, Guards Cavalry;
- absent for Line Infantry, Grenadier, Machine Gun, Light Cavalry, Heavy Cavalry, Armored Car, and all four artillery families, which therefore fall back to generic when no exact country motion exists.

Warships and forts are generic in `def_motion.xml` (one definition each, no country suffix).

This means the future migration plan must not stop after the major powers. Minor-country land visuals exist in the original APK and should be migrated systematically if full visual fidelity is the goal.

## Austria implementation
Added all **17 Austria (`aus`) infantry definitions**:
- Militia 1/2/3
- Line Infantry 1/2/3
- Light Infantry 1/2/3
- Grenadier 1/2/3
- Guards 1/2/3
- Machine Gun 1/2

Native motion extraction produced **72 motion assets**:
- Militia / Line / Light: Ready + Attack0 + Reload + Finish;
- Grenadier / Guards: Ready + Attack0 + Attack1 + Reload + Finish;
- Machine Gun: Ready + Attack0 + Finish, with native attack speed attribute 2.5.

All are decoded from the user's hash-verified original APK BILE containers and run at the native 24 FPS time base.

## Mainline delta
- r14-19: 68 animated unit definitions / 288 motion assets
- r14-20: **85 animated unit definitions / 360 motion assets**
- new runtime manifest: `assets/data/native_animation_core85.json`
- Service Worker cache: `ew4-port-v061-r14-20-austriaanim`

Covered complete infantry groups now:
- generic: 17
- France (`fra`): 17
- Britain (`gbr`): 17
- Russia (`rus`): 17
- Austria (`aus`): 17

## Verification
- `node --check app.js`: PASS
- `node --check native_animation_controller.js`: PASS
- 23/23 JS regression tests: PASS after updating a stale test-only r14 cache-version regex to accept r14-20+
- 85 unit definitions / 360 motion assets: PASS
- Austria 17/17 definitions: PASS
- Austria Grenadier/Guards Attack1 6/6: PASS
- Austria Machine Gun 1/2 Ready-Attack-Finish and attack speed 2.5: PASS
- every referenced runtime sheet exists and has a valid PNG signature: PASS

## Migration rule going forward
Do not infer completeness from broad military categories. Use the original APK's exact definition tree and exact `def_motion` names. In particular, do not omit Armored Car or Rocket, and do not assume minor countries have only generic visuals.

Real iPhone visual verification for this exact r14-20 checkpoint remains pending.
