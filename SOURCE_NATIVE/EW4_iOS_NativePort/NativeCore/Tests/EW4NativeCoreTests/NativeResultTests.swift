import Foundation
import Testing
@testable import EW4NativeCore

private func resultBattle(_ file: String) throws -> BattleRecord {
    let db = try ResourceLoader.decode(BattlesRuntimeFile.self, from: TestResourcePaths.data("battles_runtime.json"))
    return try #require(db.battles.first(where: { $0.file == file }))
}

@Test func nativeFiveGradeResultFormulaMatchesP39() throws {
    let battle = try resultBattle("campaign1_01.btl")
    #expect(NativeResultCore.stageTurnLimits(battle) == NativeStageTurnLimits(valid: true, win: 22, best: 8))
    #expect(NativeResultCore.victoryScore(round: 8, battle: battle) == 5)
    #expect(NativeResultCore.victoryScore(round: 9, battle: battle) == 4)
    #expect(NativeResultCore.victoryScore(round: 12, battle: battle) == 3)
    #expect(NativeResultCore.victoryScore(round: 16, battle: battle) == 2)
    #expect(NativeResultCore.victoryScore(round: 22, battle: battle) == 1)
    #expect(NativeResultCore.victoryGrade(round: 8, battle: battle) == 1)
}

@Test func nativeMedalDeltaAndDescriptionMatchP39() {
    #expect(NativeResultCore.medalTable == [0, 0, 5, 15, 25, 50])
    #expect(NativeResultCore.medalGain(score: 5, previousBestScore: 0) == 50)
    #expect(NativeResultCore.medalGain(score: 5, previousBestScore: 4) == 25)
    #expect(NativeResultCore.medalGain(score: 4, previousBestScore: 3) == 10)
    #expect(NativeResultCore.medalGain(score: 3, previousBestScore: 5) == 0)
    #expect(NativeResultCore.descriptionKey(score: 5, awardMedal: 50) == "desc_victory 1")
    #expect(NativeResultCore.descriptionKey(score: 5, awardMedal: 0) == "desc_victory 1 no award")
    #expect(NativeResultCore.descriptionKey(score: 1, awardMedal: 0) == "desc_victory 5")
}

@Test func allCampaignTurnLimitsProduceValidNativeScores() throws {
    let db = try ResourceLoader.decode(BattlesRuntimeFile.self, from: TestResourcePaths.data("battles_runtime.json"))
    let campaign = db.battles.filter { $0.file.range(of: #"^campaign\d+_\d+\.btl$"#, options: .regularExpression) != nil }
    #expect(campaign.count >= 80)
    for battle in campaign {
        let limits = NativeResultCore.stageTurnLimits(battle)
        #expect(limits.valid)
        if limits.valid {
            for round in 1...limits.win {
                let score = NativeResultCore.victoryScore(round: round, limits: limits)
                #expect((1...5).contains(score))
            }
        }
    }
}

@Test func campaignContinueRewardsAndMedalProcMatchP39() {
    let rows = [
        NativeCampaignRow(file: "campaign1_17.btl"),
        NativeCampaignRow(file: "campaign1_18.btl", hidden: true)
    ]
    #expect(NativeResultCore.campaignContinueDecision(rows: rows, currentFile: "campaign1_17.btl") == NativeCampaignContinueDecision(valid: true, complete: true, continueBattle: 0, index: 0, lastVisible: 0))
    #expect(NativeResultCore.campaignContinueDecision(rows: rows, currentFile: "campaign1_18.btl") == NativeCampaignContinueDecision(valid: true, complete: false, continueBattle: 0, index: 1, lastVisible: 0))
    #expect(NativeResultCore.campaignCompletionReward(zone: 2) == NativeCampaignCompletionReward(zone: 2, medal: 50, badge: 0, score: 1, image: "campaignend_coalitiont.png", firstTime: true))
    #expect(NativeResultCore.campaignCompletionReward(zone: 2, alreadyCompleted: true) == NativeCampaignCompletionReward(zone: 2, medal: 0, badge: 0, score: 0, image: "campaignend_coalitiont.png", firstTime: false))
    #expect(!NativeResultCore.collectMedalProc(damage: 20, roll: 95))
    #expect(NativeResultCore.collectMedalProc(damage: 20, roll: 96))
    #expect(NativeResultCore.collectMedalAdjustedRoll(90, nativeType: 1, nativeLevel: 3) == 99)
}
