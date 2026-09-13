# EW4 Web Port v0.61 — r14-39 native option/audio audit

## Original evidence
- `assets/layout-568h.xml` defines `form_option` as a 360x218 `user_window`.
- Music label: x32 y35; music volume bar x25 y68; `sbar_music` x41 y68 w100 h18.
- Sound label: x206 y35; sound volume bar x202 y68; `sbar_sound` x218 y68 w100 h18.
- The same form also contains GameSpeed and ShowGrids controls; those controller semantics are deliberately not invented in this audio-only micro-batch.
- `assets/global_data.xml` default settings: `BGVol=50`, `SEVol=50`, `GameSpeed=2`, `ShowGrids=0`.

## Runtime correction
- Replaced the old Web-only battle-music on/off setting with persisted 0..100 background-music and sound-effect volume values.
- Legacy saves migrate: old `music=false` -> BGVol 0; old enabled/absent setting -> original BGVol 50. SEVol defaults to original 50.
- `battle1..4` and `defeat_music` use BGVol.
- UI/select/gun/cannon/cavalry/naval/fire effects use SEVol.
- The option screen top half now uses original `form_option` 568h coordinates/assets for the two sliders.
- GameSpeed / ShowGrids are rendered only as original-shaped placeholders for now; no speculative controller behavior was added.
