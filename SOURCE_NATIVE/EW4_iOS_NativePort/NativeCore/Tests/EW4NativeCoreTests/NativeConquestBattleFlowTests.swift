import Foundation
import Testing
@testable import EW4NativeCore

private func conquestFlowFixture(playerOwner: Int? = nil) throws -> (NativeBattleGameplayState, [Int: Commander]) {
    let battles = try ResourceLoader.decode(BattlesRuntimeFile.self, from: TestResourcePaths.data("battles_runtime.json"))
    let worlds = try ResourceLoader.decode(WorldMapsFile.self, from: TestResourcePaths.data("worldmaps.json"))
    let stats = try ResourceLoader.decode(ArmyStatsCatalog.self, from: TestResourcePaths.data("army_stats.json"))
    let rawCommanders = try ResourceLoader.decode([String: Commander].self, from: TestResourcePaths.data("commanders.json"))
    let commanders: [Int: Commander] = Dictionary(uniqueKeysWithValues: rawCommanders.values.map { ($0.id, $0) })
    let battle = try #require(battles.battles.first(where: { $0.file == "conquest1.btl" }))
    let world = try #require(worlds.worlds["europe"])
    let session = NativeBattleSession(battle: battle, worldName: "europe", world: world)
    let gameplay = NativeBattleGameplayState(
        session: session, terrainTypes: worlds.terrainTypes, armyStats: stats,
        commanders: commanders, mode: .conquest, playerOwner: playerOwner ?? battle.playerOwnerDefault
    )
    return (gameplay, commanders)
}

@Test func conquestBattleFlowDelegatesExactFrozenExtinctionRule() throws {
    let (gameplay, _) = try conquestFlowFixture()
    #expect(NativeConquestBattleFlowCore.outcome(gameplay: gameplay) == nil)
    let player = NativeConquestExtinctionCore.countryStatus(gameplay, owner: gameplay.playerOwner)
    #expect(!player.defeated)
}

@Test func conquestContinueRequiresFastWinChoiceOnlyWhenAsiaEligible() throws {
    let (gameplay, commanders) = try conquestFlowFixture()
    let profile = NativePlayerProfile.fresh()
    let resources = CountryResources(money: 5_000, industry: 2_000, food: 2_000)
    var fastGameplay = gameplay
    fastGameplay.restoreRuntimeState(
        round: 30, ended: false,
        restoredUnits: fastGameplay.unitOrder.compactMap { fastGameplay.units[$0] },
        restoredObjects: Array(fastGameplay.objects.values)
    )
    let prepared = NativeConquestBattleFlowCore.prepareVictory(
        gameplay: fastGameplay, map: "europe", resources: resources, profile: profile, commanders: commanders
    )
    #expect(prepared.asiaEligible)
    let next = NativeConquestBattleFlowCore.continueAfterVictory(profile: profile, prepared: prepared)
    guard case .challenge = next.route else { Issue.record("Expected Asia challenge"); return }
    let resolved = NativeConquestBattleFlowCore.resolveChallenge(profile: next.profile, prepared: prepared, chooseAsia: true)
    guard case .summary(let result) = resolved.route else { Issue.record("Expected summary"); return }
    #expect(result.kind == "asia")
    #expect(NativeConquestAchievementCore.storedValue(resolved.profile, key: "asia") == result.storedValue)
}

@Test func conquestSlowVictoryRecordsNormalContinentImmediately() throws {
    let (gameplay, commanders) = try conquestFlowFixture()
    let profile = NativePlayerProfile.fresh()
    var slow = gameplay
    slow.restoreRuntimeState(
        round: 80, ended: false,
        restoredUnits: slow.unitOrder.compactMap { slow.units[$0] },
        restoredObjects: Array(slow.objects.values)
    )
    let prepared = NativeConquestBattleFlowCore.prepareVictory(
        gameplay: slow, map: "europe", resources: .init(money: 0, industry: 0, food: 0),
        profile: profile, commanders: commanders
    )
    #expect(!prepared.asiaEligible)
    let next = NativeConquestBattleFlowCore.continueAfterVictory(profile: profile, prepared: prepared)
    guard case .summary(let result) = next.route else { Issue.record("Expected normal summary"); return }
    #expect(result.kind == "europe")
    #expect(NativeConquestAchievementCore.storedValue(next.profile, key: "europe") == result.storedValue)
}

@Test func conquestSceneSourceUsesSharedImpactBoundariesAndChallengeIsDeferredUntilContinue() throws {
    let source = try String(contentsOf: TestResourcePaths.projectRoot
        .appendingPathComponent("NativeCore/Sources/EW4NativeRenderer/NativeBattleScene.swift"), encoding: .utf8)
    #expect(source.contains("case .conquest: return evaluateNativeConquestOutcomeIfNeeded()"))
    #expect(source.contains("NativeConquestExtinctionCore.defeatedOwners(gameplay)"))
    #expect(source.contains("pendingConquestVictory = NativeConquestBattleFlowCore.prepareVictory"))
    #expect(source.contains("NativeConquestBattleFlowCore.continueAfterVictory"))
    #expect(source.contains("public func resolveNativeConquestChallenge(chooseAsia: Bool)"))
    #expect(source.contains("mode: BattleMode = .campaign"))
    #expect(source.contains("playerOwner explicitPlayerOwner: Int? = nil"))
}
