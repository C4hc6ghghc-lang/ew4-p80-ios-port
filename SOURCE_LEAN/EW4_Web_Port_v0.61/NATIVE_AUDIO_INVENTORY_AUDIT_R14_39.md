# EW4 Web Port v0.61 — r14-39 native audio inventory audit

## APK inventory
The authoritative APK contains exactly **43 audio files** in `assets/`:
- **5 MP3**: battle1..4 + defeat_music
- **38 WAV** original effects

The Web source now preserves all 43 byte-for-byte under `assets/audio/`. The 38 WAV payload is only ~0.73 MiB, so keeping the complete original SFX source does not threaten the <450 MB handoff ceiling.

`assets/data/native_audio_inventory.json` records APK path, byte size, SHA-256 and XML reference files for each asset.

## Important controller evidence
- `layout-568h.xml` assigns `sfx_pop.wav` to original `user_window` forms such as `form_generalinfo`, `form_option`, `form_save`, `form_upgrade`, `form_princess`, and `form_complete`.
- `form_getgeneraltips` uses `sfx_lvup2.wav`.
- `def_effectsanim.xml` contains timed combat sound cues, including musket/fire variants, machine gun, naval gun, knife/strike, cannon/rocket/explosion families.

## Current runtime status after later r14-39 work
The earlier coarse one-SFX-per-attack limitation has been retired. Production now schedules the original `def_effectsanim.xml` timed multi-cue sequences against the native animation timing path. The current regression covers **143 timed effect/audio timelines**, with AI presentation-speed scaling isolated from simulation. All 43 original audio files remain preserved byte-for-byte.
