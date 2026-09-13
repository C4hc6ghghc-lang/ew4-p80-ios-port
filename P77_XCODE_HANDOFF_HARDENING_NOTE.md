# P77 Xcode Handoff Hardening Note

P77 does **not** add or change gameplay. It hardens the already-frozen P76/P75 product for the first real macOS/Xcode/iPhoneOS build.

## Product freeze
Byte comparison against the original P76 package proves:
- Native package product Swift: **106/106 unchanged**.
- iOS app entry Swift: **1/1 unchanged**.
- Native Resources: **1751/1751 unchanged**.
- SOURCE_LEAN: **6321/6321 unchanged**.

P77 therefore remains the exact P76/P75 gameplay product, with handoff tooling/docs only.

## What P77 hardens
1. Updates the Native build contract from stale P43/55-test assumptions to the current P76 baseline: **274 Swift Testing + 9 XCTest = 283**.
2. Requires **Xcode 16+ / Swift 6+** because `Package.swift` uses `swift-tools-version: 6.0` and the Xcode target uses Swift 6 language mode.
3. Adds a Linux/macOS static Xcode-candidate gate for:
   - local Swift package wiring;
   - app entry imports/boot contract;
   - preserved `Resources` folder reference;
   - bundle identifier, iOS 15 target and landscape-only config;
   - no WebKit/JavaScriptCore runtime shortcut.
4. Before building on Mac, the hardened pipeline now records Apple toolchain versions, dumps/resolves the XcodeGen spec, confirms the generated target/scheme, and resolves local package dependencies.
5. After build, it validates Info.plist, bundle identifier/orientation, arm64, forbidden WebKit/JavaScriptCore linkage, exact resource hierarchy, forbidden Web/APK/AAB payload and unsigned IPA integrity.
6. Adds `Docs/XCODE_FIRST_BUILD_RUNBOOK.md` with the exact first-build and first-device smoke order.

## Why this is the correct next checkpoint
P76's 57-form census found no newly proven high-value offline single-player route break. The primary remaining uncertainty is Apple-SDK-only type compilation and real-device rendering/touch behavior. P77 therefore improves the handoff gate rather than inventing more Linux-side parity work.

## Current Linux-side evidence
- Native: **283/283 PASS** = 274 Swift Testing + 9 XCTest.
- Mature Web: **126/126 PASS**.
- Native Resources: **1751/1751**.
- SOURCE_LEAN: **6321/6321**.
- Product Swift vs P76: **107/107 unchanged** across package sources + app entry.

## Next hard milestone
**Xcode Build Succeeded** on a real Mac using `./BUILD_FROM_CODEX_MAC.sh`.
