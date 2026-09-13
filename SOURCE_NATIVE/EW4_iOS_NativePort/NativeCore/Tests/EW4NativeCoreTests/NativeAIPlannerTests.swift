import Foundation
import Testing
@testable import EW4NativeCore

private func aiGameplay() throws -> NativeBattleGameplayState {
    let resources = TestResourcePaths.resources
    let battles = try ResourceLoader.decode(BattlesRuntimeFile.self, from: resources.appendingPathComponent("Data/battles_runtime.json"))
    let worlds = try ResourceLoader.decode(WorldMapsFile.self, from: resources.appendingPathComponent("Data/worldmaps.json"))
    let stats = try ResourceLoader.decode(ArmyStatsCatalog.self, from: resources.appendingPathComponent("Data/army_stats.json"))
    let rawCommanders = try ResourceLoader.decode([String: Commander].self, from: resources.appendingPathComponent("Data/commanders.json"))
    let commanders = Dictionary(uniqueKeysWithValues: rawCommanders.values.map { ($0.id, $0) })
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

@Test func aiPlannerTargetsOnlyHostiles() throws {
    let gameplay = try aiGameplay()
    let ai = try #require(gameplay.units.values.first(where: { $0.owner != gameplay.playerOwner && !$0.dead }))
    let targets = NativeAIPlannerCore.targets(for: ai, gameplay: gameplay)
    #expect(!targets.isEmpty)
    #expect(targets.allSatisfy { gameplay.relation(ai.owner, $0.owner) == .hostile })
}

@Test func aiPlannerPrefersLegalFiringCellWhenAvailable() throws {
    let gameplay = try aiGameplay()
    var found = false
    for index in gameplay.unitOrder {
        guard let unit = gameplay.units[index], unit.owner != gameplay.playerOwner, !unit.dead else { continue }
        let targets = NativeAIPlannerCore.targets(for: unit, gameplay: gameplay)
        guard !targets.isEmpty else { continue }
        let plan = NativeAIPlannerCore.chooseDestination(for: unit, targets: targets, gameplay: gameplay)
        let attackable = NativeAIPlannerCore.attackable(by: unit, from: plan.destination, targets: targets, gameplay: gameplay)
        let anyReachableFiringCell = ([unit.cell] + Array(gameplay.reachableCells(for: unit).keys)).contains { cell in
            !NativeAIPlannerCore.attackable(by: unit, from: cell, targets: targets, gameplay: gameplay).isEmpty
        }
        if anyReachableFiringCell {
            #expect(!attackable.isEmpty)
            found = true
            break
        }
    }
    #expect(found)
}

@Test func aiPlannerIsDeterministicForSameState() throws {
    let gameplay = try aiGameplay()
    let unit = try #require(gameplay.unitOrder.compactMap { gameplay.units[$0] }.first(where: { $0.owner != gameplay.playerOwner && !$0.dead }))
    let targets = NativeAIPlannerCore.targets(for: unit, gameplay: gameplay)
    let first = NativeAIPlannerCore.chooseDestination(for: unit, targets: targets, gameplay: gameplay)
    let second = NativeAIPlannerCore.chooseDestination(for: unit, targets: targets, gameplay: gameplay)
    #expect(first == second)
}

@Test func aiExecutionMovesAndAttacksUnderNativePhaseRules() throws {
    var gameplay = try aiGameplay()
    let order = try gameplay.endPlayerTurn()
    let owner = try #require(order.first)
    try gameplay.beginAITurn(owner: owner)
    let candidate = try #require(gameplay.unitOrder.compactMap { gameplay.units[$0] }.first(where: { $0.owner == owner && !$0.dead }))
    let targets = NativeAIPlannerCore.targets(for: candidate, gameplay: gameplay)
    let plan = NativeAIPlannerCore.chooseDestination(for: candidate, targets: targets, gameplay: gameplay)
    let move = try gameplay.moveAIUnit(candidate.index, to: plan.destination)
    #expect(move.unitIndex == candidate.index)
    #expect(gameplay.units[candidate.index]?.moved == true)

    guard let movedUnit = gameplay.units[candidate.index] else { return }
    let postTargets = NativeAIPlannerCore.targets(for: movedUnit, gameplay: gameplay)
    let attackable = NativeAIPlannerCore.attackable(by: movedUnit, from: movedUnit.cell, targets: postTargets, gameplay: gameplay)
        .sorted { $0.hp == $1.hp ? $0.index < $1.index : $0.hp < $1.hp }
    if let target = attackable.first {
        let result = try gameplay.attackAIUnit(attacker: movedUnit.index, target: target.index, rng: { 0.5 })
        #expect(result.damage > 0)
        #expect(gameplay.units[movedUnit.index]?.attacked == true || result.cavalryExtraAction)
    }
}

@Test func fullNativeAIRoundReturnsControlToPlayerDeterministically() throws {
    var first = try aiGameplay()
    var second = try aiGameplay()
    let a = try NativeAIRoundSimulationCore.runOneRound(gameplay: &first, rng: { 0.5 })
    let b = try NativeAIRoundSimulationCore.runOneRound(gameplay: &second, rng: { 0.5 })
    #expect(a == b)
    #expect(first.phase == .player)
    #expect(first.activeOwner == first.playerOwner)
    #expect(first.round == 2)
    #expect(first.units == second.units)
    #expect(a.owners == b.owners)
}
