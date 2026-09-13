import Foundation
import Testing
@testable import EW4NativeCore

private func driverGameplay() throws -> NativeBattleGameplayState {
    let battles = try ResourceLoader.decode(BattlesRuntimeFile.self, from: TestResourcePaths.data("battles_runtime.json"))
    let worlds = try ResourceLoader.decode(WorldMapsFile.self, from: TestResourcePaths.data("worldmaps.json"))
    let stats = try ResourceLoader.decode(ArmyStatsCatalog.self, from: TestResourcePaths.data("army_stats.json"))
    let raw = try ResourceLoader.decode([String: Commander].self, from: TestResourcePaths.data("commanders.json"))
    let commanders = Dictionary(uniqueKeysWithValues: raw.values.map { ($0.id, $0) })
    let session = try NativeBattleLoader.session(file: "campaign1_01.btl", battles: battles, worlds: worlds)
    return NativeBattleGameplayState(
        session: session, terrainTypes: worlds.terrainTypes, armyStats: stats,
        commanders: commanders, mode: .campaign, playerOwner: session.battle.playerOwnerDefault
    )
}

@Test func incrementalAIDriverMatchesHeadlessRoundFinalState() throws {
    var headless = try driverGameplay()
    var incremental = headless
    _ = try NativeAIRoundSimulationCore.runOneRound(gameplay: &headless, rng: { 0.5 })

    var driver = NativeAIPresentationDriver()
    var events = 0
    while !driver.finished {
        let action = try driver.next(gameplay: &incremental, rng: { 0.5 })
        events += 1
        if case .countryEnded = action {
            try driver.advanceAfterCountryEnd(gameplay: &incremental)
        } else if case .roundReadyToSettle = action {
            _ = try driver.completeRoundAfterSettlement(gameplay: &incremental)
        }
        #expect(events < 20_000)
    }
    #expect(incremental.units == headless.units)
    #expect(incremental.objects == headless.objects)
    #expect(incremental.round == headless.round)
    #expect(incremental.phase == headless.phase)
    #expect(incremental.activeOwner == headless.activeOwner)
}

@Test func incrementalAIDriverYieldsVisibleMovesInsteadOfCollapsingWholeRound() throws {
    var gameplay = try driverGameplay()
    var driver = NativeAIPresentationDriver()
    var sawCountry = false
    var sawMove = false
    var sawAttack = false
    var steps = 0
    while !driver.finished && steps < 5_000 {
        let action = try driver.next(gameplay: &gameplay, rng: { 0.5 })
        steps += 1
        switch action {
        case .countryBegan(let owner):
            sawCountry = true
            #expect(owner == gameplay.activeOwner)
        case .move(let move):
            sawMove = true
            #expect(move.path.count > 1)
            #expect(move.owner == gameplay.activeOwner)
        case .attack(let attack):
            sawAttack = true
            #expect(attack.owner == gameplay.activeOwner)
            #expect(attack.result.damage > 0)
        case .countryEnded:
            try driver.advanceAfterCountryEnd(gameplay: &gameplay)
        case .roundReadyToSettle:
            _ = try driver.completeRoundAfterSettlement(gameplay: &gameplay)
        case .roundCompleted:
            break
        }
    }
    #expect(sawCountry)
    #expect(sawMove)
    #expect(sawAttack)
    #expect(gameplay.phase == .player)
    #expect(gameplay.round == 2)
}
