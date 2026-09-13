# Apply EW4 r14-39 Post-Handoff 6

Required base: cumulative Post-Handoff 5 tree.

This delta corrects fresh-battle camera framing and adds the proven native programmatic camera motor without adding manual fling.

Changed runtime files:
- `app.js`
- `native_camera_core.js`
- `native_hex_core.js`
- `sw.js`

Regression/audit additions are included. After overlay, run every `test_*.js` from the project root. Expected result is all green. Service Worker cache target: `ew4-port-v061-r14-39-posthandoff6-nativecamera`.
