import Foundation
import Testing
@testable import EW4NativeCore

private func p46RealBattleState(
    profile: NativePlayerProfile
) throws -> NativeBattleGameplayState {
    let battles = try ResourceLoader.decode(BattlesRuntimeFile.self, from: TestResourcePaths.data("battles_runtime.json"))
    let worlds = try ResourceLoader.decode(WorldMapsFile.self, from: TestResourcePaths.data("worldmaps.json"))
    let stats = try ResourceLoader.decode(ArmyStatsCatalog.self, from: TestResourcePaths.data("army_stats.json"))
    let items = try ResourceLoader.decode(NativeItemEffectCatalog.self, from: TestResourcePaths.data("items.json"))
    let rawCommanders = try ResourceLoader.decode([String: Commander].self, from: TestResourcePaths.data("commanders.json"))
    let commanders = Dictionary(uniqueKeysWithValues: rawCommanders.values.map { ($0.id, $0) })
    let generalOverrides = try ResourceLoader.decode(NativePlayerGeneralOverrides.self, from: TestResourcePaths.data("player_general_overrides.json"))
    let princessOverrides = try ResourceLoader.decode(NativePlayerPrincessOverrides.self, from: TestResourcePaths.data("player_princess_overrides.json"))
    let provider = NativePlayerProfileCore.makeRuntimeProvider(
        profile: profile,
        commanders: commanders,
        generalOverrides: generalOverrides,
        princessOverrides: princessOverrides
    )
    let session = try NativeBattleLoader.session(
        file: "campaign1_01.btl",
        battles: battles,
        worlds: worlds
    )
    return NativeBattleGameplayState(
        session: session,
        terrainTypes: worlds.terrainTypes,
        armyStats: stats,
        commanders: commanders,
        itemEffects: items,
        effectiveCommanderProvider: provider,
        mode: .campaign,
        playerOwner: 0
    )
}

@Test func playerMovementEquipmentFunction9MatchesP39TargetRule() throws {
    let baseline = try p46RealBattleState(profile: .fresh())
    let equipped = try p46RealBattleState(profile: NativePlayerProfile(document: [
        "equipment": .object(["94": .array([.int(16), .int(-1)])])
    ]))
    let baselineUnit = try #require(baseline.units[9]) // Claude on Grenadier, owner 0
    let equippedUnit = try #require(equipped.units[9])
    #expect(baselineUnit.commanderID == 94)
    #expect(equippedUnit.armyName == "Grenadier")
    #expect(equipped.effectiveMovement(for: equippedUnit) == baseline.effectiveMovement(for: baselineUnit) + 2)
}

@Test func playerProfileEquipmentNeverLeaksIntoAICommanderMovement() throws {
    let profile = NativePlayerProfile(document: [
        "equipment": .object(["188": .array([.int(24), .int(-1)])]),
        "generalStats": .object(["188": .object(["movement": .int(8)])])
    ])
    let baseline = try p46RealBattleState(profile: .fresh())
    let modified = try p46RealBattleState(profile: profile)
    let baselineAI = try #require(baseline.units[2]) // owner 4, commander 188
    let modifiedAI = try #require(modified.units[2])
    #expect(modifiedAI.owner != modified.playerOwner)
    #expect(modified.effectiveMovement(for: modifiedAI) == baseline.effectiveMovement(for: baselineAI))
}

@Test func equipmentFunction0PreservesP39TerrainIgnoreSemantics() throws {
    let state = try p46RealBattleState(profile: NativePlayerProfile(document: [
        "equipment": .object(["94": .array([.int(0), .int(-1)])])
    ]))
    let unit = try #require(state.units[9])
    #expect(state.hasEquipmentFunction(unit, function: 0))

    // P39 moveCost gives geography/function-0 equipment the same complex-terrain
    // override as Light Infantry / Geography skill: fixed movement cost 3.
    let authoredCell = HexCell(q: 18, r: 35)
    #expect(state.movementCost(for: unit, entering: authoredCell) == 3)
}
