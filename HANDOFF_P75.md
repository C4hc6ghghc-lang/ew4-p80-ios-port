# HANDOFF P75

Authoritative checkpoint: **EW4 R14-39 P75 Native DeployGeneral Princess Audited**, 2026-09-12.

Continue from P75; do not redo P50-P74.

## Landed
- Restored battle-context original `form_deploygeneral` outer flow and six-column scroll geometry.
- Restored battle `form_princess` child flow for all eight unlocked princesses.
- Removed the Native-only princess eligibility filter that previously made newly deployed princesses impossible.
- Military Academy now round-trips to the same live battle scene and refreshes acquired generals into deployment.
- Battle-context Shop remains disabled per mature P39/Web evidence.

## Verification
- Native **283/283 PASS** = 274 Swift Testing + 9 XCTest.
- Mature Web **126/126 PASS**.
- NativeCore Sources+Tests **185/185 parse PASS**; entire Native Swift tree **187/187 PASS**.
- SOURCE_LEAN **6321/6321 unchanged**.
- Native Resources **1751/1751 byte-provenanced**.
- Runtime resource audit `errors=[]`: 101 battles, 7407/7407 unit visuals, 5482/5482 building sprites, 877 animation units / 3519 motions, BILE 12/12.

## P74 -> P75 scope
- Product Swift: **0 added / 3 modified / 0 deleted**.
- Test Swift: **1 added / 0 modified / 0 deleted**.
- Native Resources: **0/0/0**.
- SOURCE_LEAN: **0/0/0**.

## Progress judgement
Single-player mainline is now in late-stage parity cleanup rather than system construction. Most remaining value is in sparse missing routes/forms plus Xcode/iPhoneOS real-device validation.

## Still not verified
Apple SDK/Xcode/iPhoneOS compilation and real-device SpriteKit/UIKit type checking, pressed states, font metrics, clipping and touch feel.

## Next
Continue the XML-form-to-Native-route census. Exclude ads, legacy services, multiplayer/platform-only flows, and purchase/IAP surfaces unless they are required for offline single-player behavior. Prefer proven missing route layers over cosmetic over-tuning.
