# P43 Codex -> unsigned IPA handoff contract

## Goal

Make the macOS/Xcode handoff boring: Codex should not need to rediscover the project architecture or rewrite game systems. It should run one gate, fix only Apple-platform compile/link/resource issues that the Linux environment cannot prove, rerun, and produce a verified unsigned IPA.

## One command

```bash
./BUILD_FROM_CODEX_MAC.sh
```

Expected pipeline:

1. native structural/noon-regression preflight;
2. Swift package tests (P43 target: 55/55);
3. real 101-battle/877-animation resource audit;
4. verify full Xcode + iPhoneOS SDK + XcodeGen;
5. generate Xcode project;
6. Release generic iOS / iphoneos build with signing disabled;
7. require arm64 executable;
8. reject WebKit/JavaScriptCore linkage;
9. require the `Resources/Data`, `Resources/Bile`, `Resources/Maps`, `Resources/Audio` hierarchy inside the built app;
10. reject flattened-resource sentinels;
11. reject `.html/.js/.mjs/.apk/.aab` from native Payload;
12. create IPA, CRC-test it, verify payload contract and emit SHA-256.

The output path is `SOURCE_NATIVE/EW4_iOS_NativePort/build/EW4NativePort-unsigned.ipa`.

## Why the resource-folder gate is non-negotiable

The native resource tree has 1751 files and currently 232 case-insensitive duplicate-basename groups. Files such as country flags can legitimately share names across strategic-map/building/UI/flag atlases. Flattening the tree can overwrite correct files without a Swift compiler error. Therefore the Xcode resource entry is intentionally a folder reference, not an ordinary group.

## What Codex may fix after a real Xcode failure

Codex may make the smallest evidence-backed change necessary for:

- Swift 6 / UIKit / SpriteKit API availability or actor-isolation diagnostics that occur under the actual Apple SDK;
- Xcode project-generation syntax/toolchain compatibility;
- bundle lookup details while preserving the exact resource hierarchy and resource hashes;
- signing-disabled build settings needed to obtain an unsigned `.app`/IPA;
- Apple-platform compiler/linker errors that cannot be reproduced on Linux.

Every such fix must keep the preflight, Swift tests and resource audit green.

## What Codex must NOT do

Do not:

- replace SpriteKit with WKWebView;
- execute the mature Web/PWA code inside the app;
- flatten/copy selected assets into a new ad-hoc catalog to make missing-resource errors disappear;
- resize/re-anchor units or change camera/LOD/touch constants to fix perceived blur;
- rewrite Campaign/HQ/shop/save/AI rules from memory when the P39 truth implementation/tests exist;
- delete tests/audits because they block the build;
- rename the mainline away from P43/P44 numbering;
- claim true-device visual/touch acceptance before an actual iPhone run.

## Release-startup change in P43

The expensive `NativeResourceAuditor.audit(...)` call is now DEBUG-only. Release still constructs `NativeResourceStore` and loads the native scene, but full integrity auditing happens during the build gate rather than on every player launch.

## Current limitation

The handoff/build path is hardened before all P39 subsystems have completed Swift parity. A successful P43 IPA proves the current native target builds and packages correctly; it does not magically mean every still-pending P39 subsystem has already been translated to Swift. Continue P44+ native parity work from the migration matrix without restarting or redesigning those systems.
