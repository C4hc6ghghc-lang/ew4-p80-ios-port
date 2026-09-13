import Foundation
import Testing
@testable import EW4NativeCore

private func originalResultGameplay(_ file: String = "campaign1_01.btl", round: Int = 8) throws -> NativeBattleGameplayState {
    let battles = try ResourceLoader.decode(BattlesRuntimeFile.self, from: TestResourcePaths.data("battles_runtime.json"))
    let worlds = try ResourceLoader.decode(WorldMapsFile.self, from: TestResourcePaths.data("worldmaps.json"))
    let stats = try ResourceLoader.decode(ArmyStatsCatalog.self, from: TestResourcePaths.data("army_stats.json"))
    let session = try NativeBattleLoader.session(file: file, battles: battles, worlds: worlds)
    var gameplay = NativeBattleGameplayState(
        session: session,
        terrainTypes: worlds.terrainTypes,
        armyStats: stats,
        commanders: [:],
        mode: .campaign,
        playerOwner: session.battle.playerOwnerDefault
    )
    gameplay.restoreRuntimeState(
        round: round,
        ended: false,
        restoredUnits: gameplay.unitOrder.compactMap { gameplay.units[$0] },
        restoredObjects: gameplay.objects.values.sorted { $0.index < $1.index }
    )
    return gameplay
}

@Test func nativeOriginalVictoryResultUsesExistingP39ScoreAndBattleState() throws {
    let gameplay = try originalResultGameplay(round: 8)
    let content = NativeOriginalBattleResultCore.content(
        kind: .victory,
        gameplay: gameplay,
        previousBestScore: 0,
        collectedMedal: 3
    )
    #expect(content.kind == .victory)
    #expect(content.battleFile == "campaign1_01.btl")
    #expect(content.battleName == "土伦港之战")
    #expect(content.round == 8)
    #expect(content.score == 5)
    #expect(content.awardMedal == 50)
    #expect(content.collectedMedal == 3)
    #expect(content.limits == NativeStageTurnLimits(valid: true, win: 22, best: 8))
    #expect(content.playerCountryCode == "fra")
    #expect(content.narrationKey == "desc_victory 1")
    #expect(content.generalIDs.count <= 6)
}

@Test func nativeOriginalDefeatResultUsesRecoveredFailureNarrationKeys() throws {
    let gameplay = try originalResultGameplay(round: 23)
    let combat = NativeOriginalBattleResultCore.content(kind: .defeat, reason: .combat, gameplay: gameplay)
    let timeout = NativeOriginalBattleResultCore.content(kind: .defeat, reason: .turnLimit, gameplay: gameplay)
    #expect(combat.narrationKey == "desc_failure 1")
    #expect(timeout.narrationKey == "desc_failure 2")
    #expect(timeout.score == 0)
    #expect(timeout.awardMedal == 0)
}

@Test func originalVictoryFailureAndVictoryTextGeometryCannotDrift() {
    #expect(NativeOriginalFormGeometryCore.Victory.screenFrame == NativeRect(x: 111, y: 55, width: 346, height: 210))
    #expect(NativeOriginalFormGeometryCore.Victory.awardLabel == NativeRect(x: 12, y: 70, width: 50, height: 15))
    #expect(NativeOriginalFormGeometryCore.Victory.gainMedal == NativeRect(x: 182, y: 69, width: 12, height: 12))
    #expect(NativeOriginalFormGeometryCore.Failure.frame == NativeRect(x: 0, y: 0, width: 151, height: 184))
    #expect(NativeOriginalFormGeometryCore.Failure.common == NativeRect(x: 33, y: 58, width: 85, height: 67))
    #expect(NativeOriginalFormGeometryCore.VictoryText.backdrop == NativeRect(x: 0, y: 104, width: 568, height: 70))
    #expect(NativeOriginalFormGeometryCore.VictoryText.word == NativeRect(x: 108, y: 130, width: 351, height: 61))
    #expect(NativeOriginalFormGeometryCore.VictoryText.durationMilliseconds == 4500)
}

@Test func originalResultActionHitboxesStayBoundToRecoveredButtons() {
    #expect(NativeOriginalBattleResultCore.action(kind: .victory, at: NativePoint(x: 50, y: 175)) == .continueBattle)
    #expect(NativeOriginalBattleResultCore.action(kind: .victory, at: NativePoint(x: 250, y: 175)) == .exit)
    #expect(NativeOriginalBattleResultCore.action(kind: .defeat, at: NativePoint(x: 75, y: 166)) == .restart)
    #expect(NativeOriginalBattleResultCore.action(kind: .victory, at: NativePoint(x: 170, y: 175)) == nil)
}
