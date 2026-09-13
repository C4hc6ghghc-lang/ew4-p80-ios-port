# P40 Merge Report

- Parent: P39 Noon-Regression Lock / complete PORT_ONLY single-player mainline.
- Integration: the temporary Swift/SpriteKit native work was merged back under `SOURCE_NATIVE/EW4_iOS_NativePort` instead of continuing as a separate project.
- P39 preservation audit before metadata additions: **6485/6485 existing files byte-identical; 0 missing; 0 changed**.
- P39 root JS regression from the fresh P40 tree: **126/126 PASS**.
- Native Swift 6.2.1 tests after removing old absolute test paths: **33/33 PASS**.
- Native full resource audit: **101 battles; 2 worlds; 7407/7407 battle units; 5482/5482 eligible buildings; 877 animation units; 1272 assets; 3519 motions; 24 FPS; BILE 12/12; errors=[]**.
- iOS/renderer Swift syntax parse: PASS.
- Native test fixtures now resolve `Resources` relative to the P40 source tree; no `/mnt/data/EW4_NATIVE_PORT_v0.1` dependency remains.
- No claim of Xcode/iPhoneOS arm64 build: this Linux environment has no Apple SDK.

This checkpoint is intentionally a **lineage recovery + native integration** checkpoint. It does not delete or supersede P39 single-player functionality. Future native work must replace P39 contracts module-by-module with parity tests.
