import Foundation
import Testing
@testable import EW4NativeCore

private func envUnit(_ index: Int, _ owner: Int, _ q: Int, _ r: Int, morale: Int = 0, until: Int = 0) -> NativeBattleUnitState {
    NativeBattleUnitState(
        index: index, armyID: 1, armyName: "Line Infantry", grade: 0, owner: owner,
        commanderID: nil, q: q, r: r, hp: 100, maxHP: 100,
        moved: false, attacked: false, embarked: false,
        nativeMoraleBase: morale, nativeMoraleUntilRound: until
    )
}

@Test func realTerrainPenaltiesDecodeFromRecoveredWorldData() throws {
    let worlds = try ResourceLoader.decode(WorldMapsFile.self, from: TestResourcePaths.data("worldmaps.json"))
    let forest = try #require(worlds.terrainTypes["forest"])
    #expect(forest.penalty(against: "infantry") == 0)
    #expect(forest.penalty(against: "cavalry") == 20)
    #expect(forest.penalty(against: "artillery") == 10)
    let mountain = try #require(worlds.terrainTypes["mountain"])
    #expect(mountain.penalty(against: "artillery") == 20)
}

@Test func realInstallationPenaltiesMatchP39Catalog() throws {
    let catalog = try ResourceLoader.decode(NativeInstallationCatalog.self, from: TestResourcePaths.data("installations.json"))
    #expect(catalog["trench"]?.penalty(against: "infantry") == 20)
    #expect(catalog["fence"]?.penalty(against: "cavalry") == 25)
    #expect(catalog["bunker"]?.penalty(against: "artillery") == 30)
}

@Test func constructionPresenceOverridesTerrainEvenWhenAvoidIsZero() throws {
    let constructions = try ResourceLoader.decode(NativeConstructionCatalog.self, from: TestResourcePaths.data("constructions.json"))
    let farmland = NativeBattleObjectState(index: 1, q: 4, r: 5, constructionID: 1, constructionType: "farmland", level: 0, extra: 0, owner: 0)
    let out = NativeBattleEnvironmentCore.buildingReduction(
        defenderCell: HexCell(q: 4, r: 5), objects: [1: farmland], constructions: constructions
    )
    #expect(out.hasConstruction)
    #expect(out.value == 0)
}

@Test func eventMoraleLastsExactlyThreeRoundsAndLeadershipClearsNegative() {
    #expect(NativeBattleEnvironmentCore.eventMoraleBase(base: -2, untilRound: 7, round: 4) == -2)
    #expect(NativeBattleEnvironmentCore.eventMoraleBase(base: -2, untilRound: 7, round: 6) == -2)
    #expect(NativeBattleEnvironmentCore.eventMoraleBase(base: -2, untilRound: 7, round: 7) == 0)
    #expect(NativeBattleEnvironmentCore.combinedMorale(eventBase: -2, flankPenalty: -1, leadership: false) == -3)
    #expect(NativeBattleEnvironmentCore.combinedMorale(eventBase: -2, flankPenalty: -1, leadership: true) == 0)
}

@Test func oppositeFlankIsMinusOneAndFullSurroundIsMinusTwo() {
    let defender = envUnit(0, 0, 10, 10)
    let n = NativeHexGeometry.neighbors(of: defender.cell)
    var units: [Int: NativeBattleUnitState] = [0: defender]
    units[1] = envUnit(1, 1, n[0].q, n[0].r)
    units[2] = envUnit(2, 1, n[3].q, n[3].r)
    let hostile: (Int, Int) -> CountryRelation = { a, b in a == b ? .ally : .hostile }
    #expect(NativeBattleEnvironmentCore.flankPenalty(defender: defender, units: units, relation: hostile) == -1)
    for i in 0..<6 { units[10 + i] = envUnit(10 + i, 1, n[i].q, n[i].r) }
    #expect(NativeBattleEnvironmentCore.flankPenalty(defender: defender, units: units, relation: hostile) == -2)
}

@Test func moraleAndInstallationsSurviveSchema6Rehydration() throws {
    let battles = try ResourceLoader.decode(BattlesRuntimeFile.self, from: TestResourcePaths.data("battles_runtime.json"))
    let worlds = try ResourceLoader.decode(WorldMapsFile.self, from: TestResourcePaths.data("worldmaps.json"))
    let stats = try ResourceLoader.decode(ArmyStatsCatalog.self, from: TestResourcePaths.data("army_stats.json"))
    let raw = try ResourceLoader.decode([String: Commander].self, from: TestResourcePaths.data("commanders.json"))
    let commanders = Dictionary(uniqueKeysWithValues: raw.values.map { ($0.id, $0) })
    let constructions = try ResourceLoader.decode(NativeConstructionCatalog.self, from: TestResourcePaths.data("constructions.json"))
    let installationCatalog = try ResourceLoader.decode(NativeInstallationCatalog.self, from: TestResourcePaths.data("installations.json"))
    let battle = try #require(battles.battles.first(where: { $0.file == "campaign1_01.btl" }))
    let first = try #require(battle.units.first)
    let record: [String: NativeJSONValue] = [
        "index": .int(first.index), "q": .int(first.q), "r": .int(first.r),
        "army_id": .int(first.armyID), "army_name": .string(first.armyName), "grade": .int(first.grade),
        "hp": .int(first.hp), "max_hp": .int(first.maxHP), "owner": .int(first.owner),
        "commander_id": first.commanderID.map(NativeJSONValue.int) ?? .null,
        "nativeMoraleBase": .int(-2), "nativeMoraleUntilRound": .int(8)
    ]
    let payload = NativeBattleSavePayload(
        schema: 6, gameVersion: 61, savedAt: 1, battleFile: battle.file, battleTitle: battle.titleCN,
        map: "europe", mode: "campaign", playerOwner: battle.playerOwnerDefault ?? 0, round: 6,
        resources: CountryResources(money: 1, industry: 2, food: 3), countryResources: nil,
        camera: NativeSaveCamera(x: 1, y: 2, zoom: 0.8), cameraGeometry: NativeHexGeometry.geometryID,
        units: [record], objects: [], ownership: [], assignments: [],
        installations: [["q": .int(first.q), "r": .int(first.r), "type": .string("trench"), "owner": .int(first.owner)]],
        fireCells: [], nativeFiredEvents: [], nativeAppliedEvents: [], itemStores: nil, taverns: nil,
        collectMedal: 0, campaignTech: nil, campaignTechZone: 0, ended: nil
    )
    let restored = try NativeBattleRehydrationCore.rehydrate(
        payload, battles: battles, worlds: worlds, terrainTypes: worlds.terrainTypes,
        armyStats: stats, commanders: commanders, constructions: constructions, installationCatalog: installationCatalog
    )
    let unit = try #require(restored.gameplay.units[first.index])
    #expect(unit.nativeMoraleBase == -2)
    #expect(unit.nativeMoraleUntilRound == 8)
    #expect(restored.gameplay.installations == [NativeBattleInstallationState(q: first.q, r: first.r, type: "trench", owner: first.owner)])
}
