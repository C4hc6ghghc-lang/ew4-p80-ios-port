# P37 Native HUD De-Web — WIP checkpoint

Date: 2026-09-10

This pass continues strictly from P36. It does **not** reopen map geometry, unit native refs/scales, 568x320 logical coordinates, HiDPI backing, touch inversion, combat timing, or gameplay cores.

## Landed in P37

1. Removed browser-added `drop-shadow`, active `scale()` and 0.96 opacity from the native battle HUD corner buttons. The original button PNGs remain the sole authored presentation.
2. Removed browser-added `drop-shadow` / active scale from the bottom native action buttons. Disabled-state grayscale is retained; geometry stays 33x33 at native y=-22.
3. Removed extra CSS text shadows from the top resource strip and original AI-action strip without moving any P36 anchors.
4. Corrected the original `group_funcres` second row to the asymmetric XML anchors: secondary icon x=15,y=29; secondary text x=32,y=28. This fixes the prior shared-Web-row 1px baseline error.
5. Advanced only the Service Worker cache generation so changed CSS is not masked by an older P36 cache.

## Verification

- Full JS regression: **124/124 PASS**.
- P35 map/unit asset-integrity contract remains PASS.
- P36 native HUD geometry/hextend contract remains PASS.
- New `test_p37_native_hud_deweb.js` PASS.
- Protected campaign/save/upgrade/warzone cores remain byte-identical (see P37 audit).
- PORT_ONLY binary scan remains zero APK/AAB, including nested ZIPs (see P37 audit).

## Still not claimed

This is a **WIP visual checkpoint**, not true-device final acceptance. Sub-pixel font rasterization, WebKit compositing and physical touch feel remain iPhone A/B items.

## Next

Continue only evidence-backed battle HUD cleanup. Do not enlarge units, change native refpoints, alter map coordinates, or introduce modern Web hover/press effects to chase clarity.
