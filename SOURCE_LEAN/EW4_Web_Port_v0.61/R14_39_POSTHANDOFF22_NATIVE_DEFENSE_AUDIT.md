# R14-39 Post-Handoff 22 — Native Defense Form Audit

Date: 2026-09-10

## Scope
P22 completes the remaining Web-shaped interior of original `form_defense`. Pause, UnitInfo and UseItem were audited first and were already substantially aligned; they were not needlessly rewritten.

## Frozen behavior
- Original 300x184 `form_defense` shell.
- Original upper `lbox_defense` geometry: x=2, y=30, 298x65.
- Original lower description group: x=2, y=98, 296x84.
- Removed the Web-only standalone `defense-cost` strip; selected item now owns title/description while price/industry remain on the selectable item.
- Original selection box and defensive/build marker assets.
- Tutorial aliases `lbox_defense` / `winbtn_ok` preserved.
- Campaign fortress technology lock from P21 remains authoritative.
- All P22 defense assets are Service Worker precached.

## Verification
Independent Node suite: **98 / 98 PASS**.
Service Worker CORE: **239 / 239 files present**.
