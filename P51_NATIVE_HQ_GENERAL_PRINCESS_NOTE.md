# P51 Native Headquarters / General / Princess first binding batch

This checkpoint continues P50 without rewriting Campaign, Conquest or battle rules.

## Landed
- `NativeHeadquartersCore.swift`: recovered `form_deploygeneral` geometry, six-column card layout, scrolling bounds, hit routing, original princess order.
- `NativeOriginalHeadquartersScene.swift`: SpriteKit HQ shell on `campaign_wide`, original shortcut positions, profile-owned general cards, effective general details, 468x300 princess window.
- `EW4NativePortApp.swift`: main-menu Headquarters now routes into the Native HQ scene.
- `NativeResourceStore.swift`: portrait manifest access for Native HQ rendering.
- `NativeHeadquartersCoreTests.swift`: geometry/routing/order regression locks.

## Hard boundary
HQ context deliberately cannot run battle commander assignment. P51 does not touch `NativeBattleScene`, camera, map, flags, HP arcs, unit anchors, LOD, HUD baselines, or Campaign/Conquest rules.

## Verification
Native 178/178 PASS; mature JS 126/126 PASS; resource audit errors=[]; 112/112 Swift parse; preflight 26/26; SOURCE_LEAN frozen 6321/6321.

## Pending
HQ SceneShop and SceneGetGeneral/Military Academy are still the next Native bindings. Real-device visual/touch acceptance remains pending until an iPhoneOS build exists.
