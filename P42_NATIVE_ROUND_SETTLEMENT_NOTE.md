# P42 Native Round Settlement — unified mainline

P42 continues **P39 -> P40 -> P41 -> P42**. It does not restart or redesign Campaign content. The mature P39 `SOURCE_LEAN` remains the authoritative functional truth source while verified rules are translated into Swift under `SOURCE_NATIVE`.

## What landed in Swift

1. `NativeTrainingParityCore.swift`
   - native training levels 0..5;
   - defense / round-heal / level-up-heal / base-exp tables;
   - manual training money + 3x unit-consumption food cost;
   - commander-training eligibility;
   - commander and warship experience-threshold multipliers;
   - round heal and level-up heal.

2. `NativeRoundSettlementCore.swift`
   - per-facility tax / industry / food outputs from `constructions.json`;
   - stationed commander economy multiplier: skill 24 -> 1.8x, else skill 23 -> 1.4x;
   - equipment function 3 uses the strongest multiplier rather than additive stacking;
   - unit food upkeep, with skill 22 zero-consumption behavior;
   - Campaign tech 22/23/24 economic bonuses exactly matching P39 tables;
   - training recovery for every living side;
   - owned-facility supply for every living side;
   - player-only nobility + adjacent friendly flag (function 13) + outside/non-attacked tent (function 5) healing, in the same order as P39.

## Explicitly not redone

No `native_campaign_*` source, Campaign BTL, target manifest, hidden-stage mapping, six-zone progression, Campaign session persistence, result UI, HQ, shop, or battle data was rewritten in P42. P41's existing source remains byte-identical.

## Verification

- Native Swift: **54/54 PASS**.
- Mature P39/P41 JS regression: **126/126 PASS** when run from the authoritative project root.
- Full Native resource audit: 101 battles, 7407/7407 battle-unit visuals, 5482/5482 drawable buildings, 877 animation units, 3519 motions, compact BILE 12/12, `errors=[]`.
- iOS Swift parse: 0 failures.
- P41 `SOURCE_LEAN`: 6321/6321 existing files byte-identical.
- P41 `SOURCE_NATIVE`: 1801/1801 existing files byte-identical.
- Only four new Native files were added in this checkpoint.

## Not yet claimed

The settlement math is native and parity-tested, but full runtime binding from every HQ/equipment/nobility save-state field into `NativeRoundUnitContext`, and writing the settled HP/resources back into a live SpriteKit battle scene, is not yet claimed. Those are integration steps, not missing Campaign rules.
