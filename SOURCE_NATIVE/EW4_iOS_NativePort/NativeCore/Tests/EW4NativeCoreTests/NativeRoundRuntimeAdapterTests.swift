import Foundation
import Testing
@testable import EW4NativeCore

private func p45Gameplay() throws -> NativeBattleGameplayState {
    let battles = try ResourceLoader.decode(BattlesRuntimeFile.self, from: TestResourcePaths.data("battles_runtime.json"))
    let worlds = try ResourceLoader.decode(WorldMapsFile.self, from: TestResourcePaths.data("worldmaps.json"))
    let stats = try ResourceLoader.decode(ArmyStatsCatalog.self, from: TestResourcePaths.data("army_stats.json"))
    let raw = try ResourceLoader.decode([String: Commander].self, from: TestResourcePaths.data("commanders.json"))
    let commanders = Dictionary(uniqueKeysWithValues: raw.values.map { ($0.id, $0) })
    let session = try NativeBattleLoader.session(file: "campaign1_01.btl", battles: battles, worlds: worlds)
    return NativeBattleGameplayState(
        session: session,
        terrainTypes: worlds.terrainTypes,
        armyStats: stats,
        commanders: commanders,
        mode: .campaign,
        playerOwner: session.battle.playerOwnerDefault
    )
}

private func p45SettlementData() throws -> (NativeConstructionCatalog, NativeItemEffectCatalog) {
    (
        try ResourceLoader.decode(NativeConstructionCatalog.self, from: TestResourcePaths.data("constructions.json")),
        try ResourceLoader.decode(NativeItemEffectCatalog.self, from: TestResourcePaths.data("items.json"))
    )
}

@Test func liveRoundSettlementUsesPreviousAttackedFlagBeforeReset() throws {
    var gameplay = try p45Gameplay()
    let (constructions, items) = try p45SettlementData()
    let player = gameplay.playerOwner
    let base = try #require(gameplay.unitOrder.compactMap { gameplay.units[$0] }.first { $0.owner == player })
    let wounded = NativeBattleUnitState(
        index: base.index,
        armyID: base.armyID,
        armyName: base.armyName,
        grade: base.grade,
        owner: base.owner,
        commanderID: 1,
        q: base.q,
        r: base.r,
        hp: 50,
        maxHP: 100,
        moved: true,
        attacked: false,
        embarked: base.embarked,
        trainingLevel: 0
    )
    gameplay.restoreRuntimeState(round: 1, ended: false, restoredUnits: [wounded], restoredObjects: [])
    var context = NativeBattlePersistenceContext(
        resources: CountryResources(money: 0, industry: 0, food: 100),
        countryResources: [player: CountryResources(money: 0, industry: 0, food: 100)]
    )
    var driver = NativeAIPresentationDriver()
    let boundary = try driver.next(gameplay: &gameplay, rng: { 0.5 })
    guard case .roundReadyToSettle(let before, let after) = boundary else {
        Issue.record("expected settlement barrier")
        return
    }
    #expect(before == 1)
    #expect(after == 2)
    #expect(gameplay.units[base.index]?.attacked == false)

    let settlement = NativeRoundRuntimeAdapter.settlePlayerRound(
        gameplay: &gameplay,
        context: &context,
        constructions: constructions,
        items: items,
        projectionProvider: { id, controlled in
            guard id == 1, controlled else { return nil }
            return NativeCommanderRoundProjection(
                skillIDs: [],
                equippedItemIDs: [10],
                nobilityLevel: 0,
                nobilityHealCap: 25
            )
        }
    )
    #expect(settlement.playerSpecialHealed == 6)
    #expect(gameplay.units[base.index]?.hp == 56)
    _ = try driver.completeRoundAfterSettlement(gameplay: &gameplay)
    #expect(gameplay.phase == .player)
    #expect(gameplay.units[base.index]?.attacked == false)
    #expect(gameplay.units[base.index]?.moved == false)
}

@Test func liveRoundSettlementBlocksTentWhenUnitAttackedLastRound() throws {
    var gameplay = try p45Gameplay()
    let (constructions, items) = try p45SettlementData()
    let player = gameplay.playerOwner
    let base = try #require(gameplay.unitOrder.compactMap { gameplay.units[$0] }.first { $0.owner == player })
    let wounded = NativeBattleUnitState(
        index: base.index,
        armyID: base.armyID,
        armyName: base.armyName,
        grade: base.grade,
        owner: base.owner,
        commanderID: 1,
        q: base.q,
        r: base.r,
        hp: 50,
        maxHP: 100,
        moved: true,
        attacked: true,
        embarked: base.embarked
    )
    gameplay.restoreRuntimeState(round: 1, ended: false, restoredUnits: [wounded], restoredObjects: [])
    var context = NativeBattlePersistenceContext(
        resources: CountryResources(money: 0, industry: 0, food: 100),
        countryResources: [player: CountryResources(money: 0, industry: 0, food: 100)]
    )
    var driver = NativeAIPresentationDriver()
    _ = try driver.next(gameplay: &gameplay, rng: { 0.5 })
    let result = NativeRoundRuntimeAdapter.settlePlayerRound(
        gameplay: &gameplay,
        context: &context,
        constructions: constructions,
        items: items,
        projectionProvider: { _, _ in NativeCommanderRoundProjection(equippedItemIDs: [10]) }
    )
    #expect(result.playerSpecialHealed == 0)
    #expect(gameplay.units[base.index]?.hp == 50)
}

@Test func constructionAdvancesAfterGlobalActionResetLikeP39() throws {
    var gameplay = try p45Gameplay()
    let player = gameplay.playerOwner
    let base = try #require(gameplay.unitOrder.compactMap { gameplay.units[$0] }.first { $0.owner == player })
    let building = NativeBattleUnitState(
        index: base.index,
        armyID: base.armyID,
        armyName: "Small Fortress",
        grade: 0,
        owner: player,
        commanderID: nil,
        q: base.q,
        r: base.r,
        hp: 100,
        maxHP: 100,
        moved: true,
        attacked: true,
        embarked: false,
        underConstruction: true,
        constructionRoundsRemaining: 2,
        constructionTotalRounds: 2
    )
    gameplay.restoreRuntimeState(round: 1, ended: false, restoredUnits: [building], restoredObjects: [])
    _ = try gameplay.endPlayerTurn()
    gameplay.advanceRoundCounterForSettlement()
    let completed1 = gameplay.enterPlayerPhaseAfterRoundSettlement()
    #expect(completed1.isEmpty)
    #expect(gameplay.units[base.index]?.constructionRoundsRemaining == 1)
    #expect(gameplay.units[base.index]?.underConstruction == true)
    #expect(gameplay.units[base.index]?.moved == true)
    #expect(gameplay.units[base.index]?.attacked == true)

    _ = try gameplay.endPlayerTurn()
    gameplay.advanceRoundCounterForSettlement()
    let completed2 = gameplay.enterPlayerPhaseAfterRoundSettlement()
    #expect(completed2 == [base.index])
    #expect(gameplay.units[base.index]?.underConstruction == false)
    #expect(gameplay.units[base.index]?.moved == false)
    #expect(gameplay.units[base.index]?.attacked == false)
}

@Test func aiCountryEconomyWritesBackToPersistenceLedger() throws {
    let gameplay = try p45Gameplay()
    let (constructions, items) = try p45SettlementData()
    let aiOwner = try #require(gameplay.battle.countries.map(\.index).first { $0 != gameplay.playerOwner })
    var context = NativeBattlePersistenceContext.fresh(gameplay: gameplay)
    let before = context.countryResources[aiOwner] ?? CountryResources(money: 0, industry: 0, food: 0)
    let result = NativeRoundRuntimeAdapter.settleCountryEconomy(
        owner: aiOwner,
        gameplay: gameplay,
        context: &context,
        constructions: constructions,
        items: items
    )
    #expect(context.countryResources[aiOwner] == result.resources)
    #expect(result.resources.money >= before.money)
    #expect(result.resources.industry >= before.industry)
}
