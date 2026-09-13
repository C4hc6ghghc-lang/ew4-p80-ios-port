# EW4 r14-39 Post-Handoff Patch 5 — Native Hex + Strategic Status

Required baseline: **r14-39 frozen handoff + Patch 1 + Patch 2 + Patch 3 + Patch 4**, in that order.

Merge the contained `EW4_Web_Port_v0.61/` directory over that cumulative tree, replacing same-path files.

This patch is foundational and intentionally contains no naval/torpedo additions.

Main changes:
- replaces historical Web odd-column 64/53/26.5 approximation with recovered native odd-row 64/54 geometry;
- exact native world-to-cell corner hit-test;
- native odd-row neighbors / hex distance / pointy hex outline;
- native battle-rectangle camera origin;
- low-zoom relation ring + exact HP arc/color + `mark_unit_0..21` composition;
- legacy battle-save camera recentering and native camera-geometry marker;
- fixes stale battle-save zoom clamp;
- precaches `native_hex_core.js` and `native_lowzoom_core.js`.

Validation target after apply:
- full `test_*.js`: **65/65 PASS**
- compact BILE parity: **1076/1076 PASS**
- BTL native-geometry roundtrip: **101 battles / 7407 units / 8001 objects / 0 mismatches**
- `node --check app.js`, `native_hex_core.js`, `native_lowzoom_core.js`, `battle_save_core.js`, `sw.js`: PASS

Known remaining fidelity caveats are documented in `R14_39_POSTHANDOFF5_NATIVE_HEX_LOWZOOM_AUDIT.md`.
