# EW4 Web Port v0.61 — r14-39 native effect-audio timeline audit

## Extracted source
`assets/def_effectsanim.xml` contains **143 named effect timelines**. The source has now been normalized to `assets/data/native_effects_audio.json` without changing cue time, effect name, position, rotation, or sound filename.

## Unit attack timeline resolution
The original names are systematic enough to resolve current army records by unit type + grade + left/right facing. A pure resolver lives in `native_effect_audio_core.js`.

Coverage check against current `army_stats.json`: **every current army type/grade resolves to an existing left and right timeline**. `Armored Car` correctly maps to the APK naming `armored chariot`; India-specific militia/light-infantry/guards variants are preserved.

## Examples proved directly from APK
- Militia 1 right: musket cues at 0.92 / 1.04 / 1.17 s (`sfx_fire.wav`).
- Machine Gun 1 right: two cues at 0.50 s (`sfx_machine_gun.wav`).
- Light Cavalry 1 right: 0.0 / 0.5 / 1.0 / 1.1 s knife sequence.
- Light Artillery 1 right: 1.70 s (`sfx_naval_gun.wav` + `effect_lightgun.xml`).
- Heavy Artillery 1 right: 1.50 s (`effect_gunnery.xml`).
- Siege Artillery 1 right: 1.45 s (`effect_gunnery1.xml`).
- Rocket 1 right: 1.6 / 1.8 / 2.0 s (`sfx_rocket.wav`).
- Ironclad right: 0.0 / 0.2 / 0.3 / 0.4 / 0.5 s naval-gun sequence.

## Deliberate stop point
This batch does **not** yet schedule these cues during battle. The remaining technical question is how the `at` seconds in `def_effectsanim.xml` align with each native BILE attack state's speed/timeline (including motion speed overrides such as Armored Car 2.5). Runtime hookup should be done only after that synchronization is proven, so audio is not merely 'close enough'.
