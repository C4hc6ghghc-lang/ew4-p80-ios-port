# EW4 Web Port v0.61 — r14-38 `form_getgeneral` Military Academy audit

## Authority
The only layout authority used for this pass is the original APK `layout-568h.xml` `form_getgeneral` definition at logical 568x320, plus original `image_ui_hd` assets already extracted from the APK.

## Restored original geometry
- gray background/frame: y=93, h=152, full 568 width
- tier group: x=51, y=36, w=463, h=55
- tier buttons: x=0/156/312, w=152, h=55 inside the group
- selection strip: x=-5, y=0, w=158, h=58
- general list: x=25, y=110, w=519, h=98, item logical portrait size 78x78
- refresh button: x=234, y=257, w=100, h=40
- refresh children: x=15/43/70, y=12; progress plate x=10,y=9,w=80,h=22
- decorative `pattern_getgeneral_2_1` anchors and original ±0.8 / ±0.5 scaling restored rather than approximated with manually shifted unscaled images.
- original thin line y=27, bottom ornament y=303, bottom bold line y=316.

## Original interaction corrections in r14-38
- The old custom Web-card military-academy presentation is no longer the controlling layout; the 568x320 `form_getgeneral` geometry is the controlling layout.
- Tier candidate counts now follow the original button families: `button_general_6` -> 6, `button_general_4` -> 4, `button_general_2` -> 2.
- Tier pool mapping is corrected to match the original commander ordering: low tier IDs 105-200 -> 6 candidates; middle tier IDs 31-104 -> 4; high tier IDs 1-30 -> 2.
- Academy refresh remains unlimited as a player-side override; the original refresh control is preserved visually and can be used repeatedly.
- Medals and badges remain infinite player-side overrides; recruitment still goes through the original-form purchase controls instead of exposing a separate mod UI.
- General cap remains unlimited by player override.
- Navigation is origin-aware: opening Military Academy from deployment returns to deployment; opening from HQ returns to HQ.
- Invalid nested-button markup in candidate cells was removed so the native-style info button remains independently clickable.

## Still not claimed as 100% native-controller complete
The exact native `CSceneGetGeneral` pricing/currency-choice controller semantics (especially every badge-vs-medal branch for all tiers) are not yet fully reverse engineered from the stripped native library. This pass restores the original form geometry and the proven tier/count/navigation behavior, while keeping the user-requested infinite-resource backend overrides. Do not call this controller layer 1:1 until those remaining native branches are proven.
