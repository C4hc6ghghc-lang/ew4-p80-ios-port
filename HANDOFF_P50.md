# P50 handoff

- **Authoritative mainline:** P39 → … → **P50**. Do not fork/rename and do not redo mature P39 systems.
- **P50 landed:** Native main menu; Campaign zone/stage/2-country selection; Conquest scenario/country selection; Campaign Complete / Asia Challenge / Conquest Summary; coordinator routing; autosave restore. Hardcoded Toulon boot is gone.
- **Verified:** Native **175/175 PASS**; mature JS **126/126 PASS**; resource audit `errors=[]`; Swift parse **109/109**; preflight **26/26**; SOURCE_LEAN/Native Resources unchanged vs P49; frozen battle visuals unchanged.
- **Next = P51:** bind existing P39 HQ/general/princess/item/shop/tavern/academy systems and original forms to `NativePlayerProfile`. Tutorial/options/audio can follow.
- **Do not touch unless a proven defect exists:** map geometry, camera, unit anchors/scale, flags, HP arcs, HUD/text baselines, zoom/LOD, touch transforms. Xcode/iPhoneOS build + true-device acceptance are still pending.
