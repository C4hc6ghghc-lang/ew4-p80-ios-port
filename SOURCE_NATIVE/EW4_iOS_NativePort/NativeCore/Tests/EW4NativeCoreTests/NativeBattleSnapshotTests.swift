import Foundation
import Testing
@testable import EW4NativeCore

private func snapshotResources() throws -> (BattlesRuntimeFile, WorldMapsFile, ArmyStatsCatalog, [Int: Commander]) {
    let battles = try ResourceLoader.decode(BattlesRuntimeFile.self, from: TestResourcePaths.data("battles_runtime.json"))
    let worlds = try ResourceLoader.decode(WorldMapsFile.self, from: TestResourcePaths.data("worldmaps.json"))
    let stats = try ResourceLoader.decode(ArmyStatsCatalog.self, from: TestResourcePaths.data("army_stats.json"))
    let raw = try ResourceLoader.decode([String: Commander].self, from: TestResourcePaths.data("commanders.json"))
    return (battles, worlds, stats, Dictionary(uniqueKeysWithValues: raw.values.map { ($0.id, $0) }))
}

@Test func nativeSnapshotRoundTripPreservesGameplayAndP39Sidecar() throws {
    let (battles, worlds, stats, commanders) = try snapshotResources()
    let battle = try #require(battles.battles.first(where: { $0.file == "campaign1_01.btl" }))
    let session = try NativeBattleLoader.session(file: battle.file, battles: battles, worlds: worlds)
    var gameplay = NativeBattleGameplayState(
        session: session,
        terrainTypes: worlds.terrainTypes,
        armyStats: stats,
        commanders: commanders,
        mode: .campaign,
        playerOwner: battle.playerOwnerDefault
    )
    let owner = gameplay.playerOwner
    let playerIndex = try #require(gameplay.unitOrder.first(where: { gameplay.units[$0]?.owner == owner }))
    var changedUnit = try #require(gameplay.units[playerIndex])
    changedUnit.hp = max(1, changedUnit.maxHP - 41)
    changedUnit.moved = true
    changedUnit.attacked = true
    let changedObjectIndex = try #require(gameplay.objects.keys.sorted().first)
    var changedObject = try #require(gameplay.objects[changedObjectIndex])
    changedObject.owner = owner
    gameplay.restoreRuntimeState(
        round: 8,
        ended: false,
        restoredUnits: gameplay.unitOrder.compactMap { index in index == playerIndex ? changedUnit : gameplay.units[index] },
        restoredObjects: gameplay.objects.keys.sorted().compactMap { index in index == changedObjectIndex ? changedObject : gameplay.objects[index] }
    )

    let context = NativeBattlePersistenceContext(
        resources: CountryResources(money: 700, industry: 80, food: 900),
        countryResources: [
            owner: CountryResources(money: 700, industry: 80, food: 900),
            1: CountryResources(money: 12, industry: 34, food: 56)
        ],
        ownership: [0, 1, 255],
        assignments: [playerIndex: 7],
        installations: [["q": .int(2), "r": .int(3), "type": .string("trench")]],
        fireCells: ["4,5"],
        nativeFiredEvents: ["1:10"],
        nativeAppliedEvents: ["2:20"],
        itemStores: .object(["99": .object(["count": .int(2)])]),
        taverns: .object(["99": .object(["commander": .int(3)])]),
        collectMedal: 9,
        campaignTech: Array(repeating: 2, count: 26),
        campaignTechZone: 4,
        ended: nil
    )
    let camera = NativeCameraState(x: 432.5, y: 222.25, zoom: 0.65)
    let payload = try NativeBattleSnapshotCore.makePayload(
        gameplay: gameplay,
        worldName: session.worldName,
        camera: camera,
        context: context,
        savedAt: 12345
    )
    let encoded = try NativeBattleSaveCore.encode(payload)
    let decoded = try NativeBattleSaveCore.decode(encoded)
    let restored = try NativeBattleRehydrationCore.rehydrate(
        decoded,
        battles: battles,
        worlds: worlds,
        terrainTypes: worlds.terrainTypes,
        armyStats: stats,
        commanders: commanders
    )

    #expect(restored.worldName == session.worldName)
    #expect(restored.gameplay.round == 8)
    #expect(restored.gameplay.units[playerIndex]?.hp == changedUnit.hp)
    #expect(restored.gameplay.units[playerIndex]?.maxHP == changedUnit.maxHP)
    #expect(restored.gameplay.units[playerIndex]?.moved == true)
    #expect(restored.gameplay.units[playerIndex]?.attacked == true)
    #expect(restored.gameplay.objects[changedObjectIndex]?.owner == owner)
    #expect(restored.camera == camera)
    #expect(restored.countryResources[owner]?.money == 700)
    #expect(restored.countryResources[1]?.food == 56)
    #expect(restored.assignments[playerIndex] == 7)
    #expect(restored.installations.count == 1)
    #expect(restored.fireCells == ["4,5"])
    #expect(restored.nativeFiredEvents == ["1:10"])
    #expect(restored.nativeAppliedEvents == ["2:20"])
    #expect(restored.collectMedal == 9)
    #expect(restored.campaignTechZone == 4)
    #expect(restored.campaignTech?.count == 26)
    #expect(restored.itemStores == context.itemStores)
    #expect(restored.taverns == context.taverns)
}

@Test func freshPersistenceContextUsesAuthoredLedgersAndDeployedCommanders() throws {
    let (battles, worlds, stats, commanders) = try snapshotResources()
    let battle = try #require(battles.battles.first(where: { $0.file == "campaign1_01.btl" }))
    let session = try NativeBattleLoader.session(file: battle.file, battles: battles, worlds: worlds)
    let gameplay = NativeBattleGameplayState(
        session: session,
        terrainTypes: worlds.terrainTypes,
        armyStats: stats,
        commanders: commanders,
        mode: .campaign,
        playerOwner: battle.playerOwnerDefault
    )
    let context = NativeBattlePersistenceContext.fresh(gameplay: gameplay)
    #expect(context.countryResources[gameplay.playerOwner] != nil)
    for unit in gameplay.units.values where unit.commanderID != nil {
        #expect(context.assignments[unit.index] == unit.commanderID)
    }
    #expect(context.ownership == (battle.ownership ?? []))
}

@Test func trainingAndConstructionRuntimeStateSurvivesNativeSaveRoundTrip() throws {
    let (battles, worlds, stats, commanders) = try snapshotResources()
    let battle = try #require(battles.battles.first(where: { $0.file == "campaign1_01.btl" }))
    let session = try NativeBattleLoader.session(file: battle.file, battles: battles, worlds: worlds)
    var gameplay = NativeBattleGameplayState(
        session: session,
        terrainTypes: worlds.terrainTypes,
        armyStats: stats,
        commanders: commanders,
        mode: .campaign,
        playerOwner: battle.playerOwnerDefault
    )
    let index = try #require(gameplay.unitOrder.first)
    var unit = try #require(gameplay.units[index])
    unit.trainingLevel = 4
    unit.trainingExp = 77
    unit.underConstruction = true
    unit.constructionRoundsRemaining = 2
    unit.constructionTotalRounds = 4
    unit.playerCommanderHPBonus = 60
    gameplay.restoreRuntimeState(
        round: 5,
        ended: false,
        restoredUnits: gameplay.unitOrder.compactMap { $0 == index ? unit : gameplay.units[$0] },
        restoredObjects: gameplay.objects.values.sorted { $0.index < $1.index }
    )
    let context = NativeBattlePersistenceContext.fresh(gameplay: gameplay)
    let payload = try NativeBattleSnapshotCore.makePayload(
        gameplay: gameplay,
        worldName: session.worldName,
        camera: NativeCameraState(x: 100, y: 100, zoom: 1),
        context: context,
        savedAt: 1
    )
    let restored = try NativeBattleRehydrationCore.rehydrate(
        try NativeBattleSaveCore.decode(NativeBattleSaveCore.encode(payload)),
        battles: battles,
        worlds: worlds,
        terrainTypes: worlds.terrainTypes,
        armyStats: stats,
        commanders: commanders
    )
    let roundTripped = try #require(restored.gameplay.units[index])
    #expect(roundTripped.trainingLevel == 4)
    #expect(roundTripped.trainingExp == 77)
    #expect(roundTripped.underConstruction)
    #expect(roundTripped.constructionRoundsRemaining == 2)
    #expect(roundTripped.constructionTotalRounds == 4)
    #expect(roundTripped.playerCommanderHPBonus == 60)
}

@Test func authoredBTLRawTrainingLevelFeedsFreshNativeUnitState() throws {
    let (battles, worlds, stats, commanders) = try snapshotResources()
    let battle = try #require(battles.battles.first(where: { $0.file == "campaign1_01.btl" }))
    let session = try NativeBattleLoader.session(file: battle.file, battles: battles, worlds: worlds)
    let gameplay = NativeBattleGameplayState(
        session: session,
        terrainTypes: worlds.terrainTypes,
        armyStats: stats,
        commanders: commanders,
        mode: .campaign,
        playerOwner: battle.playerOwnerDefault
    )
    for source in battle.units.prefix(12) {
        let expected = NativeTrainingParityCore.level(source.raw.flatMap { $0.indices.contains(20) ? $0[20] : nil } ?? 0)
        #expect(gameplay.units[source.index]?.trainingLevel == expected)
        #expect(gameplay.units[source.index]?.trainingExp == 0)
    }
}
