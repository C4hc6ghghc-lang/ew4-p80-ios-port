# P41 Native Result / Conquest / Save Parity — WIP checkpoint

P41 continues the single unified lineage **P39 → P40 → P41**. It does not fork a new Native project and does not delete or overwrite the mature `SOURCE_LEAN` single-player truth source.

## Native parity landed

1. `NativeResultCore.swift`
   - exact five-grade campaign turn formula;
   - cumulative medal table `0/0/5/15/25/50`;
   - replay award is positive delta only;
   - victory description key behavior;
   - hidden-stage Continue/Complete decision contract;
   - six-zone completion reward table;
   - recovered collect-medal probability thresholds and class/level roll adjustment.

2. `NativeConquestExtinctionCore.swift`
   - player-locked national extinction rule is now Swift: infantry/cavalry/artillery gone + non-port land facilities lost + ports lost;
   - surviving navy or fort alone does not preserve a country;
   - neutral/ally nations do not become hostile victory requirements.

3. `NativeBattleSaveCore.swift`
   - schema 6 envelope is Swift/Codable;
   - legacy schema 1..6 accepted;
   - camera normalization clamps zoom to 0.2..1.0;
   - transient Web presentation keys (`moveAnim`, `attackAnimStart`, `attackPoseUntil`) are excluded;
   - country resources, camera geometry, assignments, installations, fire/native events, ItemStore, tavern, CollectMedal, CampaignTech, CampaignTechZone and ended state are retained in the schema.

**Important:** this does not yet claim full SpriteKit scene rehydration from a save. The serialization/compatibility contract is landed; runtime reconstruction remains a later Native step.

## Verification

- Native Swift 6.2.1 tests: **43/43 PASS**.
- Mature `SOURCE_LEAN` JS regression: **126/126 PASS**.
- Native full resource audit: **101 battles; 7407/7407 unit visuals; 5482/5482 eligible building visuals; 877 animation units; 1272 animation assets; 3519 motions; compact BILE 12/12; errors=[]**.
- iOS Swift parse sanity: PASS.
- Xcode/iPhoneOS arm64 build is not claimed in this Linux environment.

## Next Native target

Round settlement is next, but it must migrate the real P39 chain: facility income, upkeep, training round-heal, facility supply, campaign economic tech bonuses and player special healing. No simplified fake settlement should replace that contract.
