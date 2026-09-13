# EW4 Web Port 0.61 r14-39 — Native timed battle SFX integration

## Native evidence
Each attack Motion in `def_motion.xml` carries an `effect` key. `def_effectsanim.xml` defines the matching right/left timeline and each sound cue's `at=` time in seconds.

The native attack path builds the effect-animation object from the Motion effect name plus direction and position. That constructor receives no Motion speed argument. Separately, unit BILE playback multiplies its delta time by `Motion@speed`. Therefore normal-speed effect/audio cue timestamps remain the authored `at=` real seconds rather than being divided by Motion speed.

Examples from the original APK:
- Militia 1: 0.92 / 1.04 / 1.17 s `sfx_fire.wav`.
- Machine Gun 1: two simultaneous 0.50 s `sfx_machine_gun.wav` cues.
- Light Cavalry 1: 0 / 0.5 / 1.0 / 1.1 s knife sequence.
- Light Artillery 1: 1.70 s `sfx_naval_gun.wav`.
- Rocket 1: 1.6 / 1.8 / 2.0 s `sfx_rocket.wav`.
- Ironclad: 0 / 0.2 / 0.3 / 0.4 / 0.5 s naval-gun sequence.

## Web integration
- `assets/data/native_effects_audio.json` is loaded with the battle data.
- `native_effect_audio_core.js` resolves original unit/grade/country/direction timeline and returns deterministic cue delays.
- `startAttackAnim()` schedules the original WAV cues from the attack start.
- The previous coarse immediate `gun/cannon/naval/knife` guess in `attack()` was removed, preventing double/incorrect sounds.
- same-timestamp cues can overlap by cloning an audio element instead of rewinding one shared element.
- SEVol controls the resulting sounds.

## Custom AI fast-forward isolation
The original 1x timing stays untouched. The Web project's AI presentation fast-forward is not an original Motion speed; only when that custom presentation compression is active are cue delays divided by the presentation multiplier so audio does not trail many seconds behind a 90ms compressed AI action.

## Remaining fidelity work
This pass schedules native sounds only. Visual sprites/particles named by each `effect=` cue (muzzle flash, rocket, explosion etc.) are not yet rendered by the Web battle layer. Those should be integrated as a separate evidence-driven batch.
