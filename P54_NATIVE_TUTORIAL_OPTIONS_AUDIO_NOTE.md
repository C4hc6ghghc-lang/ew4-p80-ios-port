# P54 Native Tutorial / Options / Audio note

P54 closes the top-level Tutorial and Options placeholders and adds a real iOS audio controller without changing shipped assets.

## Landed
- Academy candidate info affordance using recovered `button_generalinfo_blue.png`, opening a read-only general detail overlay.
- Tavern no longer opens directly from facility tap. Player selects the recovered `extra == 3` facility, then uses the original 33x33 `button_bar.png` in the recovered `group_func` position (x=140, y=287), then the existing P53 Tavern form opens.
- `form_option`: 360x218 centered at (104,51), recovered close/OK offsets, two volume tracks, five speed bricks, ShowGrids checkbox; close cancels, OK commits profile settings.
- Optional Native hex-grid overlay uses the mature Web stroke contract and is hidden by default (`ShowGrids=false`).
- Audio controller reuses shipped `battle1..4.mp3`, `defeat_music.mp3`, `sfx_celebrate.wav`, `sfx_pop.wav`, etc. No audio files were added or modified.
- Tutorial menu launches `tutorials1.btl` / `tutorials2.btl` and reads the recovered 273-command catalog. The battle runner currently handles the universal tutorial primitives and known already-native UI aliases.

## Deliberate remaining gap
The original tutorials eventually wait on forms/actions not yet migrated natively (`btn_city`, recruit list, `btn_item`, item list, some window close/OK aliases). P54 stops at those waits rather than skipping them or faking completion. That is the primary P55 target.
