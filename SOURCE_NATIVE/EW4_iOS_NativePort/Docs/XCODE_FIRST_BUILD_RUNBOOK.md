# EW4 Native P80 — First Xcode/iPhoneOS Build Runbook

## Status
- P80 is the Xcode handoff candidate after closing current-code dynamic battle presentation omissions: **P78 transport ships + P79 flags/commander bubble/morale + P80 fire cells**.
- Native Resources and SOURCE_LEAN were not modified for P80.
- This handoff has **not** yet been compiled by Apple SDK/Xcode in this environment.
- First hard milestone: **`xcodebuild ... build` succeeds for Release + generic iOS device**.

## Required Mac toolchain
1. Full Xcode **16+** selected by `xcode-select`.
2. Swift **6+** from selected Xcode.
3. XcodeGen installed (recommended `brew install xcodegen`).
4. Python 3 and standard macOS archive/plist tools.

## One-command path
From package root:

```bash
./BUILD_FROM_CODEX_MAC.sh
```

Root wrapper runs:
1. SOURCE_LEAN freeze/scope verification.
2. Mature SOURCE_LEAN **126/126** regression.
3. **P80 map/unit/dynamic-state audit**.
4. Native Mac pipeline.

Native Mac pipeline runs:
1. 26-check IPA preflight.
2. P80 Xcode-candidate static gate.
3. Apple toolchain/version checks.
4. Native regression floor: **286 Swift Testing + 9 XCTest = 295 total**.
5. Full 1751-resource runtime audit.
6. XcodeGen dump/generate and target/scheme validation.
7. Local Swift-package dependency resolution.
8. Unsigned Release / iphoneos / generic-device build.
9. Info.plist/orientation/bundle-ID checks.
10. arm64/framework checks; WebKit/JavaScriptCore forbidden.
11. exact resource hierarchy checks; flattened resources forbidden.
12. unsigned IPA creation and payload verification.

## Presentation evidence that must remain frozen unless real device evidence proves a defect
- 101 battles: **84 Europe / 17 America**.
- Europe/America map PNGs byte-identical to SOURCE_LEAN.
- **7407/7407** battle units resolve across **22 families**.
- animation layer: **877 units / 3519 motions / 1272 assets**.
- BILE: **12/12** decoded and frozen-identical triplets.
- native unit scale **0.5**; native anchors consumed.
- LOD: detail **0.5**, unit min **0.76**, max **1.18**, exponent **0.46**.
- P78 transport closure: normal `transportship1`, function-12 `transportship2`, immediate embark refresh, path-facing mirror, disembark restore.
- P79 dynamic overlays:
  - flagpole + 4-frame country cloth, **120ms** frame contract;
  - legacy flag-only aliases `gb→gbr`, `de→pru`, `fr→fra`;
  - commander `board_smallgenerals.png` + real mini portrait;
  - dynamic morale up/down1/down2/down3;
  - hierarchy: flag behind model -> model -> status/HP/marker -> commander -> morale.
- P80 dynamic fire cells: frozen-identical `anim_fire_hd.png`, six source frames at 160ms, 42px logical height, alpha 0.86, live `fireCells` add/remove/rehydration sync, layered below units.

Do **not** broadly refactor map/unit resolver, anchor math, LOD, status hierarchy or overlay selection to fix an unrelated compiler error. Fix the narrow Apple-SDK error first.

## First-device smoke order after build
1. Main menu boot.
2. Campaign and Conquest entry + battle.
3. Map drag/pinch and LOD transitions.
4. Infantry/cavalry/artillery/navy/fort visuals.
5. Ordinary transport embark/move/disembark.
6. Armored Carrier transport if available.
7. Country flag animation and correct legacy-country flags.
8. Commander bubble + mini portrait.
9. Morale up/down markers and HP/relation/unit-class layering.
10. Movement/attack/AI focus and fast-forward.
11. Save, terminate, relaunch, reload.
12. UI font/scroll/touch checks.

## If first Xcode build fails
Triage in this order: renderer/App Apple-SDK type errors; Swift 6 actor/concurrency; XcodeGen/SPM linkage; resource bundle/path; plist/target; only after successful build, device rendering/touch issues.

## Deliberately deferred/non-blocking
Old platform leaderboard/service flows, advertising/IAP/customer-service/multiplayer forms, and `form_loading` visual parity pending real boot observation.
