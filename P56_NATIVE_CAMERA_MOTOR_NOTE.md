# P56 — Native programmatic camera motor

Date: 2026-09-11

P56 is an isolated camera-runtime closure on top of frozen P55. It does not reopen the P55 action strip or frozen map/unit/HUD presentation baseline.

## Landed
- Recovered CEntityCamera-style programmatic motor in `NativeCamera.swift`.
- Recovered GameSpeed coefficients: 1..5 = `0.012 / 0.015 / 0.020 / 0.020 / 0.020`.
- Native tick multiplier `60.0`, position snap `1.0`, zoom snap `0.01`.
- Native battle scene consumes persisted GameSpeed for programmatic camera motion.
- Tutorial `moveto area` now uses the motor instead of teleporting the camera.
- Manual/direct `setCamera` cancels a pending programmatic motor, preserving direct-drag semantics.
- Frame delta is capped at `0.1s`, matching the recovered mature integration and preventing long-frame camera jumps.
- Recovered focus visibility inset is preserved.

## Verification
- Native: **216/216 PASS** = 207 Swift Testing + 9 XCTest.
- Mature SOURCE_LEAN JS: **126/126 PASS**.
- Project Swift independent parse: **162/162 PASS**.
- Native resource audit: `errors=[]`; 101 battles; 7407/7407 battle unit visuals; 5482/5482 building sprites; 877 units / 3519 motions; BILE 12/12.
- SOURCE_LEAN: 6321/6321, changed 0 / missing 0 / extra 0.
- IPA preflight: 26/26 PASS.
- P55 -> P56 product source: changed 3 / added 1 test source / deleted 0; Native Resources unchanged; SOURCE_LEAN unchanged.

## Deliberate next boundary
P56 does **not** yet attach the recovered source/target camera-focus-and-wait continuation to every player/AI move and attack presentation. That is the next isolated camera integration step; do not mix it with map/LOD/unit-anchor rewrites.

Apple SDK/Xcode/iPhone true-device semantic/runtime acceptance is still pending.
