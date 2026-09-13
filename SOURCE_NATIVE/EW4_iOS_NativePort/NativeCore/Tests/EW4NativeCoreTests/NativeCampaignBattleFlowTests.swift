import Foundation
import Testing
@testable import EW4NativeCore

private func campaignFlowFixture(_ file: String) throws -> (BattlesRuntimeFile, WorldMapsFile, ArmyStatsCatalog, NativeCampaignTargetManifestFile, BattleRecord, NativeBattleGameplayState) {
    let battles = try ResourceLoader.decode(BattlesRuntimeFile.self, from: TestResourcePaths.data("battles_runtime.json"))
    let worlds = try ResourceLoader.decode(WorldMapsFile.self, from: TestResourcePaths.data("worldmaps.json"))
    let stats = try ResourceLoader.decode(ArmyStatsCatalog.self, from: TestResourcePaths.data("army_stats.json"))
    let manifest = try ResourceLoader.decode(NativeCampaignTargetManifestFile.self, from: TestResourcePaths.data("native_campaign_targets.json"))
    let battle = try #require(battles.battles.first(where: { $0.file == file }))
    let worldName = battle.header.mapID == 2 ? "america" : "europe"
    let world = try #require(worlds.worlds[worldName])
    let session = NativeBattleSession(battle: battle, worldName: worldName, world: world)
    let gameplay = NativeBattleGameplayState(
        session: session,
        terrainTypes: worlds.terrainTypes,
        armyStats: stats,
        commanders: [:],
        mode: .campaign,
        playerOwner: battle.playerOwnerDefault
    )
    return (battles, worlds, stats, manifest, battle, gameplay)
}

@Test func campaignBattleFlowUsesPristineObjectiveSnapshotAndDetectsCapturedObjectiveVictory() throws {
    let (_, _, _, manifest, battle, base) = try campaignFlowFixture("campaign1_01.btl")
    let initial = NativeCampaignCore.authoredInitialTargetSnapshot(battle: battle, manifest: manifest)
    #expect(initial.type1.hostile > 0)
    var gameplay = base
    let spec = try #require(manifest.battles[battle.file])
    let hostileTargets = spec.mapTargets.filter { target in
        target.type == 1 && battle.objects.first(where: { $0.q == target.q && $0.r == target.r }).map {
            NativeCampaignCore.relation(spec, gameplay.playerOwner, $0.owner) == .hostile
        } == true
    }
    #expect(!hostileTargets.isEmpty)
    var restoredObjects = gameplay.objects.values.map { object -> NativeBattleObjectState in
        var value = object
        if hostileTargets.contains(where: { $0.q == object.q && $0.r == object.r }) { value.owner = gameplay.playerOwner }
        return value
    }
    restoredObjects.sort { $0.index < $1.index }
    gameplay.restoreRuntimeState(
        round: gameplay.round,
        ended: false,
        restoredUnits: gameplay.unitOrder.compactMap { gameplay.units[$0] },
        restoredObjects: restoredObjects
    )
    #expect(NativeCampaignBattleFlowCore.outcome(gameplay: gameplay, manifest: manifest, initial: initial)?.kind == .victory)
}

@Test func campaignBattleFlowTurnLimitIsStrictlyAfterWinRound() throws {
    let (_, _, _, manifest, battle, base) = try campaignFlowFixture("campaign1_01.btl")
    let limits = NativeResultCore.stageTurnLimits(battle)
    #expect(limits.valid)
    let initial = NativeCampaignCore.authoredInitialTargetSnapshot(battle: battle, manifest: manifest)
    var atLimit = base
    atLimit.restoreRuntimeState(
        round: limits.win,
        ended: false,
        restoredUnits: atLimit.unitOrder.compactMap { atLimit.units[$0] },
        restoredObjects: Array(atLimit.objects.values)
    )
    #expect(NativeCampaignBattleFlowCore.outcome(gameplay: atLimit, manifest: manifest, initial: initial) == nil)
    var over = base
    over.restoreRuntimeState(
        round: limits.win + 1,
        ended: false,
        restoredUnits: over.unitOrder.compactMap { over.units[$0] },
        restoredObjects: Array(over.objects.values)
    )
    #expect(NativeCampaignBattleFlowCore.outcome(gameplay: over, manifest: manifest, initial: initial)?.reason == .turnLimit)
}

@Test func campaignVictoryCommitAwardsOnlyRatingDeltaAndUnlocksSecretOnlyOnce() throws {
    let (battles, _, _, manifest, battle, gameplay) = try campaignFlowFixture("campaign1_17.btl")
    var profile = NativePlayerProfile.fresh()
    let first = NativeCampaignBattleFlowCore.commitVictory(
        profile: profile, gameplay: gameplay, manifest: manifest, battles: battles.battles
    )
    #expect(first.result.score > 0)
    #expect(NativeCampaignSessionCore.bestRating(first.profile.document, file: first.canonicalFile) == first.result.score)
    profile = first.profile
    let second = NativeCampaignBattleFlowCore.commitVictory(
        profile: profile, gameplay: gameplay, manifest: manifest, battles: battles.battles
    )
    #expect(second.result.awardMedal == 0)
    #expect(second.profile.document["campaignStars"] == first.profile.document["campaignStars"])
}

@Test func campaignContinueCompletionRewardIsOneShot() throws {
    let (battles, _, _, _, _, _) = try campaignFlowFixture("campaign1_01.btl")
    let rows = NativeCampaignCore.rows(zone: 1, battles: battles.battles)
    let finalVisible = try #require(rows.last(where: { !NativeCampaignCore.originalHide($0) }))
    let profile = NativePlayerProfile.fresh()
    let first = NativeCampaignBattleFlowCore.continueAfterVictory(profile: profile, battle: finalVisible, battles: battles.battles)
    guard case .zoneComplete(let zone, let reward, let firstTime) = first.route else {
        Issue.record("Expected zone completion")
        return
    }
    #expect(zone == 1)
    #expect(firstTime)
    #expect(reward.firstTime)
    let second = NativeCampaignBattleFlowCore.continueAfterVictory(profile: first.profile, battle: finalVisible, battles: battles.battles)
    guard case .zoneComplete(_, let replayReward, let replayFirstTime) = second.route else {
        Issue.record("Expected replay zone completion")
        return
    }
    #expect(!replayFirstTime)
    #expect(replayReward.medal == 0 && replayReward.badge == 0 && replayReward.score == 0)
}

@Test func campaignYellowObjectiveUnlockPersistsAndDoesNotDuplicate() throws {
    let (battles, _, _, manifest, battle, base) = try campaignFlowFixture("campaign1_17.btl")
    let spec = try #require(manifest.battles[battle.file])
    let yellow = try #require(spec.mapTargets.first(where: { $0.type == 2 }))
    var gameplay = base
    var objects = gameplay.objects.values.map { object -> NativeBattleObjectState in
        var value = object
        if object.q == yellow.q && object.r == yellow.r { value.owner = gameplay.playerOwner }
        return value
    }
    objects.sort { $0.index < $1.index }
    gameplay.restoreRuntimeState(
        round: gameplay.round,
        ended: false,
        restoredUnits: gameplay.unitOrder.compactMap { gameplay.units[$0] },
        restoredObjects: objects
    )
    #expect(NativeCampaignCore.yellowSecretCleared(gameplay: gameplay, manifest: manifest))
    let first = NativeCampaignBattleFlowCore.commitVictory(
        profile: .fresh(), gameplay: gameplay, manifest: manifest, battles: battles.battles
    )
    #expect(!first.unlockedSecretFiles.isEmpty)
    let second = NativeCampaignBattleFlowCore.commitVictory(
        profile: first.profile, gameplay: gameplay, manifest: manifest, battles: battles.battles
    )
    #expect(second.unlockedSecretFiles.isEmpty)
}

@Test func campaignSceneSourceLocksAuthoredImpactAndSettlementBeforeResultPresentation() throws {
    let source = try String(contentsOf: TestResourcePaths.projectRoot
        .appendingPathComponent("NativeCore/Sources/EW4NativeRenderer/NativeBattleScene.swift"), encoding: .utf8)

    let impact = try #require(source.range(of: "if damagePresentationQueue.isEmpty { _ = evaluateNativeBattleOutcomeIfNeeded() }"))
    let dispatcher = try #require(source.range(of: "private func evaluateNativeBattleOutcomeIfNeeded()"))
    let evaluate = try #require(source.range(of: "private func evaluateNativeCampaignOutcomeIfNeeded()", range: dispatcher.upperBound..<source.endIndex))
    let mark = try #require(source.range(of: "gameplay.markEnded()", range: evaluate.upperBound..<source.endIndex))
    let present = try #require(source.range(of: "presentNativeBattleResult(kind: resultKind", range: mark.upperBound..<source.endIndex))
    #expect(impact.lowerBound < dispatcher.lowerBound)
    #expect(dispatcher.lowerBound < evaluate.lowerBound)
    #expect(evaluate.lowerBound < mark.lowerBound)
    #expect(mark.lowerBound < present.lowerBound)

    let settle = try #require(source.range(of: "case .roundReadyToSettle:"))
    let complete = try #require(source.range(of: "completeRoundAfterSettlement", range: settle.lowerBound..<source.endIndex))
    let outcome = try #require(source.range(of: "_ = evaluateNativeBattleOutcomeIfNeeded()", range: complete.upperBound..<source.endIndex))
    let roundTurn = try #require(source.range(of: "presentNativeRoundTurn(content)", range: outcome.upperBound..<source.endIndex))
    #expect(complete.lowerBound < outcome.lowerBound)
    #expect(outcome.lowerBound < roundTurn.lowerBound)
    #expect(source.contains("!gameplay.ended else { return }"))
}
