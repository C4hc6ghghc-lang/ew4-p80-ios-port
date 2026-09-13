# EW4 Web Port r14-39 — native result/UI audio audit

Authority: original APK `assets/layout-568h.xml` and x86_64 `libeuropean-war-4.so`.

## Proven result audio behavior

- `form_victorytext` is a separate native victory-banner window (`board_victory.png` + `tex_victory.png`).
- Its native constructor path at x86_64 `0x4ab40` resolves `AudioSystem` and immediately plays `sfx_celebrate.wav` (string at `0x1ad5ed`).
- The same object initializes a ~4.5 s display timer (`0x40900000`) before its transition path.
- The native battle-result path references `form_victory` and, on the failure branch, stops/replaces battle audio with `defeat_music.mp3` (string at `0x1ad548`).
- The APK contains no `victory_music.mp3`; victory uses the celebrate SFX rather than a separate victory BGM asset.

Web integration in this micro-batch:
- battle result always stops the current battle BGM;
- victory plays native `sfx_celebrate.wav` through SEVol;
- defeat plays native `defeat_music.mp3` through BGVol;
- stale defeat music is stopped before either result path.

The current Web visual result panel is still not a claim of full native `form_victory` / `form_victorytext` controller parity.

## Proven form-open sounds from layout-568h.xml

- `form_generalinfo` -> `sfx_pop.wav`
- `form_option` -> `sfx_pop.wav`
- `form_save` -> `sfx_pop.wav`
- `form_upgrade` -> `sfx_pop.wav`
- `form_princess` -> `sfx_pop.wav`
- `form_complete` -> `sfx_pop.wav`
- `form_getgeneraltips` -> `sfx_lvup2.wav`

Current Web paths now use the proven sound for forms that are already live: general-info, option, and save. Upgrade/princess/complete/get-general-tips remain mapped in `native_ui_audio_core.js` for use when their original controller paths are restored; no fake controller was added just to make a sound play.

## Important non-claim

This pass restores proven audio behavior only. It does not claim the current battle-result DOM is a pixel/controller-perfect reconstruction of the original result windows.
