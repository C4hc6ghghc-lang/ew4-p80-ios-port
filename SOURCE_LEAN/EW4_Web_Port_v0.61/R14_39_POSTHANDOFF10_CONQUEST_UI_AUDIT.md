# r14-39 Post-Handoff 10 — Native Conquest UI Audit

## Native evidence
- `layout-568h.xml/form_selconquest`: six conquest cards at 222x83 with `lbox_country_1..6` horizontal country lists.
- `layout-568h.xml/form_conquestlist`: right list background x=442 in native form coordinates, `lbox_battles` x=410 y=23 w=160 h=275 itemh=45, confirm x=468 y=298 w=80 h=22.
- x86_64 `libeuropean-war-4.so` SceneSelConquest event path sets `SelConquest=0..5` then transitions into `SceneSelBattle`.
- `SceneSelBattle` GameMode==2 formats `conquest %d`, resolves the selected entry, writes `PlayerCountryID`, and proceeds; it does not call `form_selcountry`.
- `SceneSelBattle` GameMode==3 formats `multiplay %d` and is the branch that calls the two-country `form_selcountry` controller. This corrects the earlier single-player interpretation.

## Web integration
- Single-player conquest now presents a map + right vertical country list rather than the old four-column Web wall.
- Each row maps directly to the decoded BTL country `index`, preserving existing battle owner semantics.
- Main conquest cards display native-style flag strips.
- Map marker placement is data-driven from BTL ownership and native odd-row geometry.

## Still unresolved
- Exact native scroll easing / overscroll of the listbox is not claimed.
- Exact native country marker choice when a nation owns multiple same-level cities is not proven; Web uses highest-level owned city, then first owned unit as deterministic fallback.
