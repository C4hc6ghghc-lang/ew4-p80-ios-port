# HANDOFF P67

Authoritative checkpoint: **EW4 R14-39 P67 Native Play Notice Scroll Audited**, 2026-09-12.

Continue from P67; do not redo P50-P66. P67 is a narrow original-XML behavior/content recovery for `form_playnotice`.

## Landed
- Recovered original 400x225 play-notice form and 390x186 framed HtmlBox viewport.
- Frozen `html_notice` is rendered as all **24/24** help lines; removed the old `prefix(11)` truncation.
- Added `NativeOriginalPlayNoticeCore` for line parsing, 20px row spacing, scroll clamping, and scrollbar thumb metrics.
- Restored original `scrollbar_gray.png` track and `scrollbar_darkgray.png` thumb.
- Restored clipped vertical scrolling: content drag and scrollbar drag both reach the full 294px scroll range.
- Corrected dismissal behavior: content/scrollbar touches no longer close the overlay; only the original close button does.
- Tutorial battle launch routing remains unchanged.
- Added `P67PlayNoticeScrollFidelityTests.swift` to lock XML bindings, 24-item frozen content, geometry, scroll metrics, assets, and close-only dismissal.
- No combat/economy/AI/save semantics, recruitment, shop, items/defense rules, map/LOD/unit art, flags, HP/HUD, camera, P33 timing, Native Resources, or SOURCE_LEAN content changed.

## Verification
- Native **253/253 PASS** = 244 Swift Testing + 9 XCTest.
- Mature JS **126/126 PASS**.
- NativeCore Sources+Tests **173/173 parse PASS**; entire native Swift tree **175/175 PASS**.
- SOURCE_LEAN **6321/6321 unchanged**.
- Native Resources **1751/1751 byte-provenanced**.
- Runtime resource audit `errors=[]`: 101 battles, 7407/7407 unit visuals, 5482/5482 eligible building sprites, 877 animation units / 3519 motions, BILE 12/12.
- IPA preflight **26/26 PASS**; script syntax PASS; cross-project scope guard PASS.

## P66 -> P67 scope
- Product Swift: **1 added / 2 modified / 0 deleted**.
- Test Swift: **1 added / 0 modified / 0 deleted**.
- Native Resources: **0/0/0**.
- SOURCE_LEAN: **0/0/0**.

## Next isolated work
Highest-priority remaining proven form gap is the interior of `form_regroupconfirm`: P66 restored title/text/button/board geometry and correct hitboxes, but original XML also contains the source `tmp_commander` plus a 132x98 equipment group. Recover those preview internals only if the frozen/original resource and controller evidence closes cleanly; do not alter regroup gameplay semantics.

Continue evidence-led Release-visible auditing after that. Do not reopen frozen map/LOD/unit/HUD/camera/AI systems without a proven defect.

## Still not verified
Apple SDK/Xcode/iPhoneOS compilation and real-device SpriteKit font metrics, clipping, scrollbar feel, touch behavior, and final Release configuration. Linux/SwiftPM verification cannot substitute for device acceptance.
