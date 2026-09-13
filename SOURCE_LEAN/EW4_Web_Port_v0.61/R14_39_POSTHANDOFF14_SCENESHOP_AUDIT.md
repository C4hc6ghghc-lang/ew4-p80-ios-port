# r14-39 Post-Handoff 14 — native shared SceneShop audit

## Frozen scope
P12 SceneShop is now landed in production rather than existing only as reverse-engineering notes.

### Shared form/controller
- One shared `#commerce-panel` / `form_shop` shell is used by both Headquarters and battlefield shop contexts.
- `native_scene_shop_core.js` is DOM-free and owns the shared seller/buyer rules.
- Seller inventory is 14 slots.
- Player ItemBank remains the original 28-slot bank and the lower grid scrolls instead of truncating to 14.

### Headquarters store
- HQ shop is accessible from the Headquarters deploy-general scene.
- HQ daily stock persists in `saveState.hqShop` and refreshes only when the local calendar date changes.
- Daily layout: slots 1-5 are random native consumables (duplicates allowed), slot 6 empty, slots 7-8 are two distinct non-consumables not already in ItemBank/equipment, remaining slots empty.
- HQ buy price is original base price.
- HQ sell price is `max(1, floor(basePrice * 0.60))`.
- Infinite player medals remain a mechanical override only; the UI does not display FREE/∞/MOD labels.

### Battlefield store
- Seller source remains the decoded per-battle Map/ItemStore data (151 stores, 14 slots each).
- Commerce stars discount buy price by 4 percentage points per star.
- Sell rate is `60% + 4% * businessStars`, capped at 80%.
- Buying and selling both persist through the existing save paths.

### Item semantics
- Consumable sale removes one unit.
- Unique equipment sale removes the owned ItemBank copy, making it eligible for later HQ stock refresh if otherwise unowned/unequipped.

## Cache / packaging
- Service Worker cache advanced to `ew4-port-v061-r14-39-posthandoff14-sceneshop`.
- Old tests that hard-coded P11's exact cache name were relaxed to verify the post-handoff cache family rather than a stale version string.

## Regression
- Current JS suites: **78 / 78 PASS**.
- New core test: `test_native_scene_shop_core.js`.
- Updated integration contract: `test_shop_itemstore_contract.js`.
