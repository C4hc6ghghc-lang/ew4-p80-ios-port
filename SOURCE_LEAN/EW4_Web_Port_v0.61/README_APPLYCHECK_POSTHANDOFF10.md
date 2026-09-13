# EW4 r14-39 Post-Handoff Patch 10 — Native Single-Player Conquest Selection

Baseline: cumulative r14-39 + Post-Handoff P1 through P9.

This patch replaces the Web-style single-player conquest country wall with the native single-player conquest selection flow evidenced from the original APK/controller path.

Key corrections:
- Single-player conquest no longer uses `form_selcountry`; that two-country form is the multiplayer (`GameMode == 3`) path.
- Conquest cards keep the original six-card screen and now show horizontal nation flag strips corresponding to native `lbox_country_1..6` presentation.
- Selecting a conquest enters a `form_conquestlist`-style view: left campaign map preview, right 160x297 vertical nation list, bottom native confirm button.
- Confirm writes the selected BTL country owner index into the existing `PlayerCountryID`/`playerOwner` battle path.
- Europe/America marker positions are derived from real BTL ownership and the restored native odd-row 64x54 battlefield geometry.
- P10 Service Worker cache includes the conquest list background and confirm-button source assets.

Known unresolved detail:
- Exact native decorative map-marker anchor choice when a nation owns multiple cities/units is not yet proven. Current deterministic rule chooses the highest-level owned city, then falls back to the first owned unit. This does not affect selected country/gameplay ownership.

Verification at freeze:
- Full JS regression: 74/74 PASS
- compact BILE: 1076/1076 PASS
- Machine Gun Finish corrected set: 18/18 PASS
- `node -c` passes for changed JS files
