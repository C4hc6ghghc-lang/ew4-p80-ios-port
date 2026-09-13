# P76 Xcode Candidate Readiness Note

P76 is the point where Linux-side feature/parity construction should stop by default.

## Why
- The original-layout census has no newly proven high-value offline single-player route break after P75.
- Product Swift, Native Resources and SOURCE_LEAN are byte-identical to P75.
- Full Native, mature Web, resource, provenance, scope and IPA-preflight gates remain green.
- Remaining uncertainty is disproportionately Apple-SDK/runtime specific rather than missing game systems.

## Known pre-Xcode items that are not blockers
1. `form_loading`: startup-only original tips/loading presentation. Native currently shows a black placeholder until boot reaches Main Menu. This should be judged on Xcode/device rather than forcing another Linux-side gameplay checkpoint.
2. `form_messagebox`: generic confirm/cancel shell with no proven mature local trigger.
3. `form_claim`: visual component restored, trigger deliberately not invented.
4. Platform/multiplayer/IAP/ad/service layouts are out of PORT_ONLY scope.

## Xcode acceptance order
1. Open/build the iOS target with the Apple SDK.
2. Fix compile/type errors inside SpriteKit/UIKit guarded renderer code.
3. Verify Bundle resource paths and app-support save paths.
4. Launch to Main Menu.
5. Smoke-test Campaign selection → CampaignInfo → list → battle → victory/complete.
6. Smoke-test Conquest selection → country → battle → completion/challenge/summary.
7. Smoke-test HQ → GeneralInfo → Upgrade / DeployItem / Regroup / Dismiss / Shop / Academy.
8. Smoke-test Achievement and Tutorial/PlayNotice.
9. Smoke-test battle Recruit / Shop / Tavern / Defense / UseItem / DeployGeneral / 8 Princesses / save-load / pause / AI fast-forward.
10. Only create the next checkpoint from concrete Xcode or device evidence.
