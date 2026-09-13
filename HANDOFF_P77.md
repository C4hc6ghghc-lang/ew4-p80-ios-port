# HANDOFF P77 — Xcode Handoff Hardened

Authoritative checkpoint: **EW4 R14-39 P77 Xcode Handoff Hardened**, 2026-09-12.

Continue from P77. Do not redo P50-P76 and do not add Linux-only parity work unless a new hard source proves an actual offline single-player route break.

## Product state
P77 changes **no gameplay/product Swift and no game resources**. The product is byte-identical to P76/P75:
- NativeCore/Renderer product Swift 106/106 unchanged;
- iOS App Swift 1/1 unchanged;
- Native Resources 1751/1751 unchanged;
- SOURCE_LEAN 6321/6321 unchanged.

## P77 purpose
P77 hardens the first Mac/Xcode handoff:
- current 283-test floor instead of stale P43 55-test floor;
- Xcode 16+/Swift 6+ fail-fast gate;
- XcodeGen resolved-spec dump and generated target/scheme verification;
- local Swift-package dependency resolution before build;
- built Info.plist/bundle-ID/orientation checks;
- arm64/linkage/resource-hierarchy/Web-payload/IPA verification;
- explicit first-build + first-device runbook.

## Current verification
- Native **283/283 PASS** = 274 Swift Testing + 9 XCTest.
- Mature Web **126/126 PASS**.
- P77 Xcode-candidate static gate **6/6 PASS**.
- P76→P77 product zero-diff audit **PASS**.
- Native Resources **1751/1751** unchanged.
- SOURCE_LEAN **6321/6321** unchanged.

## Mac entrypoint
From the package root on macOS:

```bash
./BUILD_FROM_CODEX_MAC.sh
```

This runs the frozen mature-source gate and then the hardened Native pipeline. XcodeGen intentionally generates the `.xcodeproj` on the Mac from `iOSApp/project.yml`; the project file is not treated as source truth.

Read `SOURCE_NATIVE/EW4_iOS_NativePort/Docs/XCODE_FIRST_BUILD_RUNBOOK.md` before modifying anything after the first build failure.

## Next checkpoint rule
The next checkpoint must be driven by concrete Xcode/iPhoneOS or real-device evidence. Do not create P78 merely for cosmetic/Linux-side form coverage.

Primary milestone: **Xcode Build Succeeded**.
