# P52 Native Headquarters Shop / Military Academy binding

P52 continues P51 without rewriting Campaign, Conquest or battle rules.

## Landed

- `NativeHeadquartersCommerceCore.swift`
  - 28-slot Native item bank and mature stack limits.
  - HQ daily SceneShop persistence and stock generator.
  - original HQ buy/sell pricing contract with the user's infinite-medal modification preserved.
  - Military Academy 6/4/2 tier generation, `drawlots` eligibility, star bands, medal/badge alternatives, persistent purchase/refresh state.
  - purchased-out all-null tier pages remain stable instead of rerolling.
- `ResourceModels.swift`
  - Commander now decodes native `price` and `drawlots` fields required by SceneGetGeneral.
- `NativeRoundSettlementCore.swift`
  - item metadata now decodes `consumable`, preserving existing initializer compatibility.
- `NativeOriginalHQShopScene.swift`
  - recovered 425x259 HQ shop shell, 14-slot seller, scrollable 28-slot buyer bank, existing item icons, buy/sell persistence.
- `NativeOriginalAcademyScene.swift`
  - original-style 6/4/2 tabs and selected marker, 78x98 cards, price pair, refresh surface/decor, persistent acquisition, recovered 152x184 get-general confirmation shell.
- `EW4NativePortApp.swift`
  - HQ Shop and Military Academy placeholder handlers are replaced by real Native scene routes, both saving through the same `NativePlayerProfileStore`.

## Hard boundary

P52 does not modify `NativeBattleScene`, native map/camera/LOD, unit anchors, flags, HP arcs, battle HUD/text baselines, Campaign rules or Conquest rules. `SOURCE_LEAN` and Native runtime Resources remain frozen.

## Verification

- Native 183/183 PASS (174 Swift Testing + 9 XCTest).
- Mature JS 126/126 PASS.
- Native resource audit `errors=[]`.
- 116/116 project Swift syntax parse.
- IPA preflight 26/26 PASS.
- SOURCE_LEAN 6321/6321 frozen.
- 228/228 item icon names used by the Native shop resolve.

## Pending

Academy info-button to full general detail; DeployItem/equipment UI; regroup/dismissal; tavern/remaining HQ commerce; Tutorial/Options/audio closure; macOS Xcode iPhoneOS build and real-device acceptance.
