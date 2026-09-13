# r14-21 transport-package omissions

This package preserves the complete **current runtime**, current core102 animation payload, source JS, tests, audits, maps, sprites, active audio, and all 432 native animation sheets.

To keep the handoff archive below conversation attachment size limits, only files that are not referenced by the r14-21 runtime/tests were omitted:
- `assets/audio/battle2.mp3`, `battle3.mp3`, `battle4.mp3` (current HTML uses `battle1.mp3`; originals remain recoverable from the authoritative APK)
- `assets/data/battles.json` (superseded by runtime `battles_runtime.json`)
- historical animation manifests `native_animation_core30/45/60/68.json` (current runtime uses core102)
- `assets/units/` three old France animation proof files (not referenced by runtime manifests)

The authoritative original APK is unchanged and remains the source for restoring any omitted historical/dev artifact.
- additional unreferenced legacy/dev-only files removed for attachment size: `campaign_back.png`, `mainmenu_ip5.png`, `layout_534h.json`, `hexmaps.json`, `def_commander.xml`.

- historical `native_animation_core85.json` and `native_animation_infantry15.json` are omitted; current runtime uses core102.
