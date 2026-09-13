# HANDOFF P76 — Xcode Candidate Readiness

Authoritative checkpoint: **EW4 R14-39 P76 Xcode Candidate Readiness Audited**, 2026-09-12.

Continue from P76. Do not redo P50-P75.

## What P76 changes
P76 is deliberately **non-product-code**. It adds no gameplay system and modifies no product Swift or Native Resources. It closes the pre-Xcode audit loop:

- completed a 58-declaration / 57-unique-form XML → Native route census;
- confirmed no newly proven high-value Release-visible offline single-player route break after P75;
- classified debug/platform/multiplayer/IAP/ad/service forms as deliberate PORT_ONLY exclusions rather than missing work;
- recorded `form_loading` as a startup-only visual parity item, not a gameplay blocker;
- recorded `form_messagebox` as generic/evidence-limited rather than inventing a trigger;
- kept `form_claim` restored but intentionally unbound without local trigger evidence;
- synchronized stale status documentation to the current checkpoint.

## Product baseline carried forward unchanged
P75 remains the gameplay baseline: battle `form_deploygeneral` + `form_princess`, all-eight princess deployability, academy round-trip, and every prior P50-P74 system/parity fix.

## Verification
- Native **283/283 PASS** = 274 Swift Testing + 9 XCTest.
- Mature Web **126/126 PASS**.
- NativeCore Sources+Tests **185/185 parse PASS**; entire Native Swift tree **187/187 PASS**.
- Runtime resource audit `errors=[]`: 101 battles; 7407/7407 unit visuals; 5482/5482 building sprites; 877 animation units / 3519 motions; BILE 12/12.
- SOURCE_LEAN **6321/6321 unchanged**.
- Native Resources **1751/1751 byte-provenanced**.
- IPA preflight **26/26 PASS**; scope guard PASS.
- P75→P76 byte audit: **187/187 product Swift unchanged, 1751/1751 Native Resources unchanged, 6321/6321 SOURCE_LEAN unchanged**.

## Form-census result
- 58 Layout declarations / 57 unique form IDs.
- **39** covered/equivalent offline single-player forms.
- **15** deliberate PORT_ONLY exclusions (debug/platform/multiplayer/IAP/ad/service).
- **2** deferred non-blocking forms (`form_loading`, `form_messagebox`).
- **1** restored but intentionally unbound shell (`form_claim`).

## Next milestone
**Do not chase P77 for cosmetic coverage by default.** The next primary milestone is:

1. open the P76 candidate in macOS/Xcode;
2. perform real Apple SDK/iPhoneOS type compilation;
3. fix only concrete compiler/resource/signing errors;
4. launch on simulator/device;
5. smoke-test Main Menu → Campaign → Battle → save/load, Conquest, Headquarters, Academy/Shop/Regroup/DeployItem/Upgrade, Achievement, Tutorial and 8-princess deployment;
6. only then create the next checkpoint from evidence produced by Xcode or the device.

The biggest unverified boundary remains Apple SDK/SpriteKit/UIKit compilation and real-device font, clipping, pressed-state, touch/scroll behavior.
