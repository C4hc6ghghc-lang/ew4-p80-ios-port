# P39 Native HUD Safety / Noon-Regression Lock — WIP Checkpoint

Date: 2026-09-10

This checkpoint continues P38 with a safety-first rule: do not repeat a visual-polish regression by touching frozen map/unit geometry or WebKit touch/raster foundations.

## Landed

- Added an explicit battlefield compositing guard: `#battle-map` / `#battle-canvas` are kept transform-neutral, filter-neutral, fully opaque, with normal image rendering. The only display scaling remains the frozen 568x320 `#stage` transform + P35 HiDPI backing.
- Added `test_p39_noon_regression_lock.js`, which fails if later work changes the 568x320 logical space, HiDPI backing transform, pointer inversion, frozen unit visual scale/native-anchor route, form_game corner-button geometry, HUD hextend assets, or anti-Web HUD processing rules.
- Advanced the Service Worker cache generation because `r14_native_forms.css` changed; otherwise iPhone could remain on P38 cached CSS and create a false visual regression.
- Corrected stale `CURRENT_STATUS.json` lineage: P38 had already reached 125/125, but its status metadata still identified P37/124. P39 now records the actual inherited baseline.

## Deliberately not changed

- Map geometry / coordinates.
- Unit native refs, visual zoom curve, `.5*uz` HD-to-logical scale, READY/attack draw origins.
- Touch mapping / camera math.
- Battle timing / transport / StageIntro / Talk.
- Gameplay/save/upgrade/warzone protected cores.
- No speculative font rasterization tweaks.

## Principle

From P39 onward, a visual tweak that would touch a frozen invariant must first prove an actual regression with native evidence or true-device A/B. Clarity alone is not justification for resizing/re-anchoring units or changing map/canvas transforms.

## Verification

- Full root `test_*.js`: **126/126 PASS**.
- Protected cores: **4/4 SHA256 MATCH**.
- Service Worker CORE: **1058/1058 present**; cache generation advanced to P39.
- Prepackage recursive APK/AAB scan: direct 0; 12 nested ZIPs scanned; nested APK/AAB 0; errors 0.
- True-device iPhone A/B remains pending for font rasterization/compositing/touch feel.
