# P51 handoff — first HQ binding batch

- **Authoritative mainline:** P39 -> ... -> P50 -> **P51**. Do not fork/rename and do not redo mature P39 systems.
- **P51 landed so far:** main-menu HQ now opens a Native original-shell `SceneDeployGeneral`-style scene; recovered shortcut/grid geometry; owned-general scrolling grid; Native general detail; original 8-princess window/order; battle-only deploy disabled in HQ context.
- **Verified:** Native **178/178 PASS**; mature JS **126/126 PASS**; resource audit `errors=[]`; Swift parse **112/112**; preflight **26/26**; SOURCE_LEAN 6321 frozen; Native Resources unchanged; frozen battle visuals untouched.
- **Continue P51, do not start over:** HQ SceneShop -> Military Academy -> DeployItem/regroup/dismissal -> tavern/remaining HQ commerce.
- **Do not touch unless a proven defect exists:** map geometry, camera, unit anchors/scale, flags, HP arcs, HUD/text baselines, zoom/LOD, touch transforms, P33 impact timing.
- **Still unverified here:** Xcode/iPhoneOS semantic compile/link and real-device pixel/touch acceptance.
