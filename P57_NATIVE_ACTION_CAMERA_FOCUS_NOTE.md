# P57 — Native move/attack action camera focus + wait continuation

Base: frozen P56 camera motor.

## Landed
- Recovered pair-visibility decision: both source and target 64x72 cells must fit the safe viewport at zoom >= 0.5 or action focus is required.
- Focus target is the exact midpoint of source/target cell centers; zoom below 0.5 restores target zoom to 1.0.
- Player move/attack mutation is deferred until the programmatic camera motor finishes.
- AI next-action planning runs on local gameplay/driver copies; when focus is required those mutated copies remain off live state until camera completion, then commit once before presentation.
- Action-focus waits lock manual panning so the continuation cannot be stranded by user camera input.
- Existing movement/attack rules, P33 impact timing, map textures, LOD, unit anchors, flags, HP arcs and HUD geometry remain frozen.

## Verification
- Native: **221/221 PASS** = 212 Swift Testing + 9 XCTest.
- Mature JS: **126/126 PASS**.
- Swift independent parse: **164/164 PASS**.
- Native resource audit: `errors=[]`; 101 battles; 7407/7407 unit visuals; 5482/5482 building sprites; 877 units / 3519 motions; BILE 12/12.
- IPA preflight: **26/26 PASS**.
- SOURCE_LEAN: **6321/6321 unchanged**.
- P56 -> P57 product source: added 2, changed 2, deleted 0. Native Resources unchanged.

## Still pending
- Native AI fast-forward control/bypass is not yet exposed like mature Web `aiFastForward`; do not claim it is complete.
- Apple SDK/Xcode/iPhone device acceptance remains pending.
