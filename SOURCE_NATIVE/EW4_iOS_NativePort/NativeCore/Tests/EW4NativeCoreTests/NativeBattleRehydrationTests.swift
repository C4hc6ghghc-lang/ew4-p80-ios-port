import Foundation
import Testing
@testable import EW4NativeCore

private func loadRehydrationResources() throws -> (
    BattlesRuntimeFile,
    WorldMapsFile,
    ArmyStatsCatalog,
    [Int: Commander]
) {
    let battles = try ResourceLoader.decode(BattlesRuntimeFile.self, from: TestResourcePaths.data("battles_runtime.json"))
    let worlds = try ResourceLoader.decode(WorldMapsFile.self, from: TestResourcePaths.data("worldmaps.json"))
    let stats = try ResourceLoader.decode(ArmyStatsCatalog.self, from: TestResourcePaths.data("army_stats.json"))
    let raw = try ResourceLoader.decode([String: Commander].self, from: TestResourcePaths.data("commanders.json"))
    let commanders = Dictionary(uniqueKeysWithValues: raw.values.map { ($0.id, $0) })
    return (battles, worlds, stats, commanders)
}

private func saveRecord(for unit: BattleUnit, hp: Int, maxHP: Int, moved: Bool = false, attacked: Bool = false, embarked: Bool = false) -> [String: NativeJSONValue] {
    [
        "index": .int(unit.index),
        "q": .int(unit.q),
        "r": .int(unit.r),
        "army_id": .int(unit.armyID),
        "army_name": .string(unit.armyName),
        "grade": .int(unit.grade),
        "hp": .int(hp),
        "max_hp": .int(maxHP),
        "commander_id": unit.commanderID.map(NativeJSONValue.int) ?? .null,
        "owner": .int(unit.owner),
        "dead": .bool(hp <= 0),
        "moved": .bool(moved),
        "attacked": .bool(attacked),
        "embarked": .bool(embarked)
    ]
}

private func saveRecord(for object: BattleObject, owner: Int? = nil) -> [String: NativeJSONValue] {
    [
        "index": .int(object.index),
        "q": .int(object.q),
        "r": .int(object.r),
        "construction_id": .int(object.constructionID),
        "construction_type": object.constructionType.map(NativeJSONValue.string) ?? .null,
        "level": .int(object.level),
        "extra": .int(object.extra),
        "owner": .int(owner ?? object.owner)
    ]
}

@Test func saveRehydrationDoesNotApplyPlayerHPBonusTwice() throws {
    let (battles, worlds, stats, commanders) = try loadRehydrationResources()
    let battle = try #require(battles.battles.first(where: { $0.file == "campaign1_01.btl" }))
    let playerOwner = battle.playerOwnerDefault ?? 0
    let player = try #require(battle.units.first(where: { $0.owner == playerOwner }))
    let savedMax = player.maxHP + PlayerUnitRules.baseHPBonus
    let savedHP = max(1, savedMax - 37)
    let payload = NativeBattleSavePayload(
        schema: 6,
        gameVersion: 61,
        savedAt: 1,
        battleFile: battle.file,
        battleTitle: battle.titleCN,
        map: "europe",
        mode: "campaign",
        playerOwner: playerOwner,
        round: 9,
        resources: CountryResources(money: 321, industry: 123, food: 456),
        countryResources: nil,
        camera: NativeSaveCamera(x: 111, y: 222, zoom: 0.75),
        cameraGeometry: NativeHexGeometry.geometryID,
        units: battle.units.map { u in
            u.index == player.index
                ? saveRecord(for: u, hp: savedHP, maxHP: savedMax, moved: true, attacked: true)
                : saveRecord(for: u, hp: u.hp, maxHP: u.maxHP)
        },
        objects: battle.objects.map { saveRecord(for: $0) },
        ownership: battle.ownership ?? [],
        assignments: [],
        installations: [],
        fireCells: ["4,5"],
        nativeFiredEvents: ["1:10"],
        nativeAppliedEvents: ["2:20"],
        itemStores: nil,
        taverns: nil,
        collectMedal: 3,
        campaignTech: Array(repeating: 1, count: 26),
        campaignTechZone: 2,
        ended: nil
    )
    let runtime = try NativeBattleRehydrationCore.rehydrate(
        payload,
        battles: battles,
        worlds: worlds,
        terrainTypes: worlds.terrainTypes,
        armyStats: stats,
        commanders: commanders
    )
    let restored = try #require(runtime.gameplay.units[player.index])
    #expect(restored.maxHP == savedMax)
    #expect(restored.hp == savedHP)
    #expect(restored.moved)
    #expect(restored.attacked)
    #expect(runtime.gameplay.round == 9)
    #expect(runtime.resources == payload.resources)
    #expect(runtime.camera == NativeCameraState(x: 111, y: 222, zoom: 0.75))
    #expect(runtime.fireCells.contains("4,5"))
    #expect(runtime.collectMedal == 3)
}

@Test func saveRehydrationRestoresCapturedFacilityAndEndedPhase() throws {
    let (battles, worlds, stats, commanders) = try loadRehydrationResources()
    let battle = try #require(battles.battles.first(where: { $0.file == "campaign1_01.btl" }))
    let object = try #require(battle.objects.first)
    let owner = battle.playerOwnerDefault ?? 0
    let payload = NativeBattleSavePayload(
        schema: 6,
        gameVersion: 61,
        savedAt: 1,
        battleFile: battle.file,
        battleTitle: battle.titleCN,
        map: "europe",
        mode: "campaign",
        playerOwner: owner,
        round: 4,
        resources: CountryResources(money: 1, industry: 2, food: 3),
        countryResources: [String(owner): CountryResources(money: 11, industry: 22, food: 33)],
        camera: NativeSaveCamera(x: 0, y: 0, zoom: 1),
        cameraGeometry: NativeHexGeometry.geometryID,
        units: battle.units.map { saveRecord(for: $0, hp: $0.hp, maxHP: $0.maxHP) },
        objects: battle.objects.map { $0.index == object.index ? saveRecord(for: $0, owner: owner) : saveRecord(for: $0) },
        ownership: battle.ownership ?? [],
        assignments: [[battle.units[0].index, 1]],
        installations: [["q": .int(1), "r": .int(2), "type": .string("trench")]],
        fireCells: [],
        nativeFiredEvents: [],
        nativeAppliedEvents: [],
        itemStores: .object(["x": .int(1)]),
        taverns: .object(["y": .int(2)]),
        collectMedal: 0,
        campaignTech: nil,
        campaignTechZone: 0,
        ended: .string("victory")
    )
    let runtime = try NativeBattleRehydrationCore.rehydrate(
        payload,
        battles: battles,
        worlds: worlds,
        terrainTypes: worlds.terrainTypes,
        armyStats: stats,
        commanders: commanders
    )
    #expect(runtime.gameplay.objects[object.index]?.owner == owner)
    #expect(runtime.gameplay.phase == .ended)
    #expect(runtime.countryResources[owner] == CountryResources(money: 11, industry: 22, food: 33))
    #expect(runtime.assignments[battle.units[0].index] == 1)
    #expect(runtime.installations.count == 1)
}

@Test func legacyCameraGeometryFallsBackToPlayerOpeningFocusButKeepsZoom() throws {
    let (battles, worlds, stats, commanders) = try loadRehydrationResources()
    let battle = try #require(battles.battles.first(where: { $0.file == "campaign1_01.btl" }))
    let owner = battle.playerOwnerDefault ?? 0
    let own = battle.units.filter { $0.owner == owner }
    let expected = own.first(where: { ($0.commanderID ?? 0) > 0 }) ?? own.first!
    let payload = NativeBattleSavePayload(
        schema: 5,
        gameVersion: 61,
        savedAt: 1,
        battleFile: battle.file,
        battleTitle: battle.titleCN,
        map: "europe",
        mode: "campaign",
        playerOwner: owner,
        round: 2,
        resources: CountryResources(money: 1, industry: 2, food: 3),
        countryResources: nil,
        camera: NativeSaveCamera(x: 99999, y: 99999, zoom: 0.6),
        cameraGeometry: nil,
        units: battle.units.map { saveRecord(for: $0, hp: $0.hp, maxHP: $0.maxHP) },
        objects: battle.objects.map { saveRecord(for: $0) },
        ownership: battle.ownership ?? [],
        assignments: [], installations: [], fireCells: [], nativeFiredEvents: [], nativeAppliedEvents: [],
        itemStores: nil, taverns: nil, collectMedal: nil, campaignTech: nil, campaignTechZone: nil, ended: nil
    )
    let runtime = try NativeBattleRehydrationCore.rehydrate(
        payload,
        battles: battles,
        worlds: worlds,
        terrainTypes: worlds.terrainTypes,
        armyStats: stats,
        commanders: commanders
    )
    let p = NativeHexGeometry.cellCenter(HexCell(q: expected.q, r: expected.r))
    #expect(runtime.camera == NativeCameraState(x: p.x, y: p.y, zoom: 0.6))
}
