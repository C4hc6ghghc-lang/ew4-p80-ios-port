import Foundation
import Testing
@testable import EW4NativeCore

private struct EventFixture {
    let catalog: NativeBattleEventCatalogFile
    let targets: NativeTriggerTargetCatalogFile
    let battles: BattlesRuntimeFile
    let worlds: WorldMapsFile
    let stats: ArmyStatsCatalog
    let commanders: [Int: Commander]
    let constructions: NativeConstructionCatalog
    let installations: NativeInstallationCatalog

    static func load() throws -> EventFixture {
        let catalog = try ResourceLoader.decode(NativeBattleEventCatalogFile.self, from: TestResourcePaths.data("battle_native_triggers.json"))
        let targets = try ResourceLoader.decode(NativeTriggerTargetCatalogFile.self, from: TestResourcePaths.data("native_trigger_targets.json"))
        let battles = try ResourceLoader.decode(BattlesRuntimeFile.self, from: TestResourcePaths.data("battles_runtime.json"))
        let worlds = try ResourceLoader.decode(WorldMapsFile.self, from: TestResourcePaths.data("worldmaps.json"))
        let stats = try ResourceLoader.decode(ArmyStatsCatalog.self, from: TestResourcePaths.data("army_stats.json"))
        let raw = try ResourceLoader.decode([String: Commander].self, from: TestResourcePaths.data("commanders.json"))
        let commanders = Dictionary(uniqueKeysWithValues: raw.values.map { ($0.id, $0) })
        let constructions = try ResourceLoader.decode(NativeConstructionCatalog.self, from: TestResourcePaths.data("constructions.json"))
        let installations = try ResourceLoader.decode(NativeInstallationCatalog.self, from: TestResourcePaths.data("installations.json"))
        return EventFixture(catalog: catalog, targets: targets, battles: battles, worlds: worlds, stats: stats, commanders: commanders, constructions: constructions, installations: installations)
    }

    func gameplay(_ file: String) throws -> NativeBattleGameplayState {
        let session = try NativeBattleLoader.session(file: file, battles: battles, worlds: worlds)
        return NativeBattleGameplayState(
            session: session,
            terrainTypes: worlds.terrainTypes,
            armyStats: stats,
            commanders: commanders,
            constructions: constructions,
            installationCatalog: installations,
            mode: .campaign,
            playerOwner: session.battle.playerOwnerDefault
        )
    }
}

@Test func nativeEventCatalogMatchesRecoveredP39Coverage() throws {
    let fx = try EventFixture.load()
    let events = fx.catalog.battles.values.flatMap(\.events)
    #expect(fx.catalog.battles.count == 101)
    #expect(events.count == 360)
    #expect(events.filter { $0.dialogue?.text?.isEmpty == false }.count == 323)
    #expect(events.filter { $0.triggerType == 2 && $0.paramA == 5 }.count == 31)
    #expect(fx.targets.capture.values.reduce(0) { $0 + $1.count } == 31)
    #expect(fx.targets.death.values.reduce(0) { $0 + $1.count } == 23)
}

@Test func captureAndDeathBindingsResolveExactRecoveredTargets() throws {
    let fx = try EventFixture.load()
    let capture = NativeBattleEventCore.captureEvents(
        battleFile: "campaign1_01.btl", objectIndex: 32, catalog: fx.catalog, targets: fx.targets
    )
    #expect(capture.count == 1)
    #expect(capture.first?.eventID == 1014)
    #expect(capture.first?.triggerType == 0)

    let death = NativeBattleEventCore.deathEvents(
        battleFile: "campaign1_02.btl", unitIndex: 21, catalog: fx.catalog, targets: fx.targets
    )
    #expect(death.count == 1)
    #expect(death.first?.eventID == 1021)
    #expect(death.first?.triggerType == 1)
}

@Test func captureScriptEventAppliesMoraleAndDedupesDialogueAndEffect() throws {
    let fx = try EventFixture.load()
    var gameplay = try fx.gameplay("campaign1_01.btl")
    var context = NativeBattlePersistenceContext.fresh(gameplay: gameplay)
    let events = NativeBattleEventCore.captureEvents(
        battleFile: gameplay.battle.file, objectIndex: 32, catalog: fx.catalog, targets: fx.targets
    )
    let first = NativeBattleEventCore.applyScriptEvents(events, gameplay: &gameplay, context: &context)
    #expect(first.appliedEvents.count == 1)
    #expect(first.newlyQueuedDialogues.count == 1)
    #expect(first.moraleUnitCount > 0)
    #expect(context.nativeAppliedEvents.contains(events[0].eventKey))
    #expect(context.nativeFiredEvents.contains(events[0].dialogueKey))
    let french = gameplay.units.values.filter { !$0.dead && gameplay.countryCode(owner: $0.owner) == "fra" }
    #expect(!french.isEmpty)
    #expect(french.allSatisfy { $0.nativeMoraleBase == 1 && $0.nativeMoraleUntilRound == gameplay.round + 3 })

    let second = NativeBattleEventCore.applyScriptEvents(events, gameplay: &gameplay, context: &context)
    #expect(second.appliedEvents.isEmpty)
    #expect(second.newlyQueuedDialogues.isEmpty)
}

@Test func roundDialogueUsesFiredDedupeWithoutPollutingAppliedSet() throws {
    let fx = try EventFixture.load()
    var gameplay = try fx.gameplay("campaign1_01.btl")
    var context = NativeBattlePersistenceContext.fresh(gameplay: gameplay)
    let first = NativeBattleEventCore.applyRoundEvents(
        battleFile: gameplay.battle.file, round: 1, catalog: fx.catalog, gameplay: &gameplay, context: &context
    )
    #expect(first.newlyQueuedDialogues.contains { $0.eventID == 1011 })
    let talk = try #require(NativeBattleEventCore.roundEvents(battleFile: gameplay.battle.file, round: 1, catalog: fx.catalog).first { $0.eventID == 1011 })
    #expect(context.nativeFiredEvents.contains(talk.dialogueKey))
    #expect(!context.nativeAppliedEvents.contains(talk.eventKey))

    let second = NativeBattleEventCore.applyRoundEvents(
        battleFile: gameplay.battle.file, round: 1, catalog: fx.catalog, gameplay: &gameplay, context: &context
    )
    #expect(!second.newlyQueuedDialogues.contains { $0.eventID == 1011 })
}

@Test func recoveredRoundFireCellUsesNativeWorldWidthAndPersists() throws {
    let fx = try EventFixture.load()
    var gameplay = try fx.gameplay("campaign1_10.btl")
    var context = NativeBattlePersistenceContext.fresh(gameplay: gameplay)
    let fire = try #require(NativeBattleEventCore.roundEvents(battleFile: gameplay.battle.file, round: 1, catalog: fx.catalog).first { $0.paramA == 5 })
    let cell = try #require(NativeBattleEventCore.eventCell(fire, worldWidth: gameplay.world.width))
    #expect(cell == HexCell(q: 14, r: 44))
    let applied = NativeBattleEventCore.applyRoundEvents(
        battleFile: gameplay.battle.file, round: 1, catalog: fx.catalog, gameplay: &gameplay, context: &context
    )
    #expect(applied.fireApplied.contains(cell) || applied.fireBlocked.contains(cell))
    if applied.fireApplied.contains(cell) { #expect(context.fireCells.contains("14,44")) }
}

@Test func recoveredRoundMoraleLastsNThroughNPlusTwo() throws {
    let fx = try EventFixture.load()
    var gameplay = try fx.gameplay("campaign2_06.btl")
    gameplay.advanceRoundCounterForSettlement()
    var context = NativeBattlePersistenceContext.fresh(gameplay: gameplay)
    let applied = NativeBattleEventCore.applyRoundEvents(
        battleFile: gameplay.battle.file, round: 2, catalog: fx.catalog, gameplay: &gameplay, context: &context
    )
    #expect(applied.moraleUnitCount > 0)
    let british = gameplay.units.values.filter { !$0.dead && gameplay.countryCode(owner: $0.owner) == "gbr" }
    #expect(!british.isEmpty)
    #expect(british.allSatisfy { $0.nativeMoraleBase == 1 && $0.nativeMoraleUntilRound == 5 })
    #expect(NativeBattleEnvironmentCore.eventMoraleBase(base: 1, untilRound: 5, round: 4) == 1)
    #expect(NativeBattleEnvironmentCore.eventMoraleBase(base: 1, untilRound: 5, round: 5) == 0)
}

@Test func nativeAppliedAndFiredEventKeysSurviveSchema6Snapshot() throws {
    let fx = try EventFixture.load()
    var gameplay = try fx.gameplay("campaign1_01.btl")
    var context = NativeBattlePersistenceContext.fresh(gameplay: gameplay)
    let events = NativeBattleEventCore.captureEvents(
        battleFile: gameplay.battle.file, objectIndex: 32, catalog: fx.catalog, targets: fx.targets
    )
    _ = NativeBattleEventCore.applyScriptEvents(events, gameplay: &gameplay, context: &context)
    let payload = try NativeBattleSnapshotCore.makePayload(
        gameplay: gameplay, worldName: "europe", camera: NativeCameraState(x: 284, y: 160, zoom: 1), context: context, savedAt: 9
    )
    #expect(Set(payload.nativeAppliedEvents) == context.nativeAppliedEvents)
    #expect(Set(payload.nativeFiredEvents) == context.nativeFiredEvents)
}

@Test func fireproofCommanderBlocksNativeFireAndClearsExistingCell() throws {
    let fx = try EventFixture.load()
    var gameplay = try fx.gameplay("campaign1_05.btl")
    let savary = try #require(gameplay.units[18])
    #expect(savary.commanderID == 50)
    #expect(gameplay.isFireproof(at: savary.cell))
    var context = NativeBattlePersistenceContext.fresh(gameplay: gameplay)
    let key = "\(savary.q),\(savary.r)"
    context.fireCells.insert(key)
    let pos = savary.r * gameplay.world.width + savary.q
    let event = NativeBattleScriptEvent(
        sequence: 99, triggerType: 2, paramA: 5, paramB: gameplay.round, eventID: 99999,
        paramC: pos, country: "", paramD: 0, paramE: 0, paramF: 0, dialogue: nil
    )
    let result = NativeBattleEventCore.applyScriptEvents([event], gameplay: &gameplay, context: &context)
    #expect(result.fireApplied.isEmpty)
    #expect(result.fireBlocked == [savary.cell])
    #expect(!context.fireCells.contains(key))
}
