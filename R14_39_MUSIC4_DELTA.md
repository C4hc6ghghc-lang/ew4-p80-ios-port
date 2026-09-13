# r14-39 WIP music micro-batch — 2026-09-08

This delta does not change the frozen baseline (r14-38) and does not declare r14-39 frozen.

Completed:
- reverse-engineered original battle-music selection from the authoritative APK/native library;
- confirmed all five ABI libraries contain `battle%d.mp3` and `defeat_music.mp3`;
- x86_64 battle-scene setup proves `rand()%4 + 1` selects `battle1..battle4`, with repeats allowed;
- restored original APK `battle2.mp3`, `battle3.mp3`, `battle4.mp3` byte-for-byte into Web source;
- Web battle scene now selects one original track per newly constructed battle scene and loops it;
- default BGM volume aligned to original `BGVol=50`;
- all four original battle tracks are Service Worker precached;
- added `SOURCE_LEAN/EW4_Web_Port_v0.61/NATIVE_BATTLE_MUSIC_AUDIT_R14_39.md`;
- added `test_native_battle_music.js`.

Regression in the lean source:
- 27 tests discovered;
- 26 PASS;
- 1 expected FAIL: `test_native_animation_integration.js`, because the lean handoff intentionally omits the 1076 expanded `runtime_sheet.png` development-cache files. This is not a music regression.
- `test_compact_bile_runtime.js` remains PASS.

Not done in this delta:
- original `form_option` BGVol/SEVol slider controller is not yet reconstructed;
- no external/custom/copyrighted track was added;
- no IPA work was attempted.
