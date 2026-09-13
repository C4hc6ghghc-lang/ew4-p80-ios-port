# EW4 Web Port r14-21 — Prussia complete infantry17 native animation

## Scope
This checkpoint continues from the hash/test-verified r14-20 Austria handoff. It adds the complete Prussia (`pru`) infantry roster according to the original APK definition tree, preserving the corrected 17-definition infantry completeness rule.

## Coastal Fort / 海岸炮 preservation check
The original fort tree still includes **Coastal Fort** as a distinct fourth fort definition alongside Small Fortress, Fortress, and Large Fortress. It is not only listed in an audit: it is present in current runtime data for all nine army-stat templates (`fra/gbr/rus/pru/aus/tur/spa/usa/others`) with type `fort`, strength 90, attack 1–11, cannon weapon, range 1–2, and it has current Ready and Attack visual-manifest entries from `army_fort` / `coastalartillery_r`.

A regression assertion was added to `test_data_integrity.js` so future checkpoints fail if Coastal Fort disappears from stats or its ready/attack visual manifests.

## Prussia implementation
Added all **17 Prussia (`pru`) infantry definitions**:
- Militia 1/2/3
- Line Infantry 1/2/3
- Light Infantry 1/2/3
- Grenadier 1/2/3
- Guards 1/2/3
- Machine Gun 1/2

Native BILE extraction produced **72 motion assets**:
- Militia / Line / Light: Ready + Attack0 + Reload + Finish;
- Grenadier / Guards: Ready + Attack0 + Attack1 + Reload + Finish;
- Machine Gun: Ready + Attack0 + Finish, native attack speed attribute 2.5.

All frames are decoded from the user's SHA-256-verified original EW4 APK and use the native 24 FPS time base.

## Mainline delta
- r14-20: 85 animated unit definitions / 360 motion assets
- r14-21: **102 animated unit definitions / 432 motion assets**
- new runtime manifest: `assets/data/native_animation_core102.json`
- Service Worker cache: `ew4-port-v061-r14-21-prussiaanim`

Complete infantry groups now covered:
- generic: 17
- France (`fra`): 17
- Britain (`gbr`): 17
- Russia (`rus`): 17
- Austria (`aus`): 17
- Prussia (`pru`): 17

## Verification
- `node --check app.js`: PASS
- `node --check native_animation_controller.js`: PASS
- 23/23 JS regression tests: PASS
- 102 unit definitions / 432 motion assets: PASS
- Prussia 17/17 definitions: PASS
- Prussia Grenadier/Guards Attack1 6/6: PASS
- Prussia Machine Gun 1/2 Ready-Attack-Finish + attack speed 2.5: PASS
- every referenced runtime sheet exists: PASS
- Coastal Fort stats + Ready + Attack regression protection: PASS

Real iPhone visual verification for this exact r14-21 checkpoint remains pending.
