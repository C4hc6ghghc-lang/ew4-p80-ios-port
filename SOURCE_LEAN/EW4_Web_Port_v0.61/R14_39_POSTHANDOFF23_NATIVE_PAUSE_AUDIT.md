# R14-39 Post-Handoff 23 — Native Pause Form Audit

Date: 2026-09-10

## Baseline
Direct continuation from user-designated frozen P21. P22 Defense changes were selectively merged after source-level diff and regression verification; P21 campaign-upgrade core/data/save files remained byte-identical.

## P23 scope
- Preserve original `form_pause` 166x272 shell and four original button coordinates.
- Restore separate round word / round number positioning from `layout-568h.xml`: word x=50,y=35; number x=85,y=36,w=35,h=15.
- Restore original bottom `pattern_reoganizion.png` decoration with vertical flip.
- Keep existing save/options/restart/exit controller behavior unchanged.
- Add the restored pause asset to Service Worker precache and bump cache generation.

## Explicit non-claims
- This is layout/controller parity from original APK XML/assets, not yet true-device iPhone pixel/touch verification.
- No campaign technology, battle save, combat, AI, unit, general, item or economy rule was changed.
