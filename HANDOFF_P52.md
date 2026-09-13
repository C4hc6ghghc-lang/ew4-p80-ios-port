# P52 handoff — Native HQ Shop + Military Academy

- **Authoritative mainline:** P39 -> ... -> P50 -> P51 -> **P52**. Do not fork, rename, or redo mature systems.
- **P52 landed:** Native HQ SceneShop; persistent 14-slot daily seller + 28-slot item bank; Native Military Academy SceneGetGeneral; persistent 6/4/2 candidates; purchase into owned generals; fixed-null purchased-out persistence; original-shell geometry/assets.
- **User modification preserved:** medals/badges remain effectively infinite. Prices are displayed and currency eligibility is respected, but acquisition/shop actions do not decrement a finite resource balance.
- **Verified:** Native **183/183 PASS**; mature JS **126/126 PASS**; resource audit `errors=[]`; Swift parse **116/116**; preflight **26/26**; SOURCE_LEAN 6321 frozen; Native Resources unchanged; 228/228 item icons present.
- **Continue, do not start over:** Academy info-detail route (small closure) -> DeployItem/equipment -> regroup/dismissal -> tavern/remaining HQ commerce.
- **Do not touch unless a proven defect exists:** map geometry, camera, unit anchors/scale, flags, HP arcs, HUD/text baselines, zoom/LOD, touch transforms, P33 impact timing.
- **Still unverified here:** Xcode/iPhoneOS semantic compile/link and real-device pixel/touch acceptance.
