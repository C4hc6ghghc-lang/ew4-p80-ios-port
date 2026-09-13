# EW4 Web Port 0.61 r14-39 — native battle music audit

## Original APK evidence
Authoritative APK SHA-256: `20e609437a3659c5cc5573f7df70c75d48839a552e0120770a0afd8f068af05c`.

Original package contains five MP3 files:
- `assets/battle1.mp3`
- `assets/battle2.mp3`
- `assets/battle3.mp3`
- `assets/battle4.mp3`
- `assets/defeat_music.mp3`

`assets/global_data.xml` defines `BGMusic="battle1.mp3"` as the file-constant default and `BGVol=50` as the default background-music volume.

All five ABI variants of `libeuropean-war-4.so` contain the format string `battle%d.mp3` and `defeat_music.mp3`.
On the x86_64 build, the battle-scene setup path at approximately `0x9eba4` does:
1. call the native random helper with argument `4`;
2. the helper is `rand() % n` (verified at approximately `0xf44a0`);
3. add `1` to the result;
4. format `battle%d.mp3`;
5. pass the selected file through the native audio system with looping enabled.

This proves the original battle scene chooses one of `battle1..battle4` independently with replacement. Repeats are therefore allowed; the Web port should not impose a no-repeat playlist rule.

## Web correction in this micro-batch
Previously the Web port shipped only `battle1.mp3` and hard-wired it as the sole looping battle track.

Now:
- original `battle2.mp3`, `battle3.mp3`, `battle4.mp3` are restored byte-for-byte from the APK;
- each newly opened battle scene chooses uniformly from the four original files, equivalent to `rand()%4 + 1`;
- leaving battle for Options and returning does not reroll, because the scene retains its selected track;
- restarting/opening/loading a battle constructs a new battle scene and therefore chooses again, matching the native scene-setup behavior;
- default battle/defeat music volume is aligned to original `BGVol=50` (0.5 in Web Audio volume units);
- all four battle tracks are Service Worker precached.

## Current status after later r14-39 controller work
- The original `form_option` separate background-music and sound-effect volume controls are now restored in the production controller; the earlier Web-toggle limitation recorded above is historical and no longer applies.
- The four original battle tracks remain the only battle-music baseline and are selected with native random-with-replacement semantics.
- No external/custom music replaces the original soundtrack.
