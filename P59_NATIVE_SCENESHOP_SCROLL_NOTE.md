# P59 — Native SceneShop 28-slot scroll / hitbox closure

Base: audited P58 Native AI fast-forward checkpoint.

## Proven defect
`NativeOriginalBattleShopRenderer` rendered the 28-slot player ItemBank as four compressed 45x23 rows with no vertical scroll path. This contradicted both recovered `original_layout-568h.xml form_shop` (7 columns, rowh 45, 4px spacing) and mature P39 `.shop-buyer-grid` behavior (full-size 45x45 cells, vertical scrolling). It also left no modal drag route in `NativeBattleScene`.

## Landed
- Added `NativeShopFormCore` as the shared SceneShop grid/scroll/hit-test truth.
- Battlefield buyer bank uses a clipped crop, 45x45 cells, 4px spacing and clamped vertical scrolling across all 28 slots.
- Battle shop drags are routed to the modal and never pan the world camera.
- Buyer hit-testing is clipped to the visible viewport, so invisible rows cannot be selected outside the shop grid.
- HQ Shop now consumes the same shared geometry/scroll core; its existing behavior remains unchanged.
- Existing seller stock, prices, business-star math, infinite-medal override, selection -> info -> confirm flow, persistence/autosave, and all battle simulation rules remain unchanged.

## Verification
- Native clean-cache: **228/228 PASS** = 219 Swift Testing + 9 XCTest.
- New SceneShop grid/scroll suite: **4/4 PASS**.
- Mature JS: **126/126 PASS**.
- Native resource audit: `errors=[]`; 101 battles; 7407/7407 unit visuals; 5482/5482 building sprites; 877 units / 3519 motions; BILE 12/12.
- SOURCE_LEAN: **6321/6321 unchanged**.
- Native Resources: **1751/1751 byte-provenanced**.

## Safety boundary
No runtime resource, SOURCE_LEAN file, AI planner, combat formula, RNG, economy settlement, map/LOD/unit geometry, flags, HP arcs, HUD baseline or camera rule was changed.

## Still pending
Apple SDK/Xcode/iPhoneOS compile/link and real-device touch/scroll feel remain unverified.
## Final package gates
- P58 -> P59 product Swift delta: **1 added / 3 changed / 0 deleted**.
- Test Swift delta: **1 added / 0 changed / 0 deleted**.
- Native Resources: **0 added / 0 changed / 0 deleted**.
- SOURCE_LEAN: **0 added / 0 changed / 0 deleted**.
- IPA preflight: **26/26 PASS**.
- Cross-project contamination gate: **PASS**.
- Direct APK/AAB: **0**; nested ZIP APK/AAB hits: **0**.
- Build cache directories: **0**.

