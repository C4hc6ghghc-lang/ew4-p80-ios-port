import Foundation
import Testing
@testable import EW4NativeCore

@Test func conquestAchievementRoundAndResourceFormulasMatchRecoveredP39() {
    #expect(NativeConquestAchievementCore.resourceContribution(.init(money: 100, industry: 50, food: 20)) == 42)
    #expect(NativeConquestAchievementCore.normalRoundContribution(31) == 23_330)
    #expect(NativeConquestAchievementCore.normalRoundContribution(100) == 0)
    #expect(NativeConquestAchievementCore.asiaRoundContribution(20, map: "europe") == 21_000)
    #expect(NativeConquestAchievementCore.asiaEligible(round: 65, map: "europe"))
    #expect(!NativeConquestAchievementCore.asiaEligible(round: 66, map: "europe"))
    #expect(NativeConquestAchievementCore.asiaEligible(round: 55, map: "america"))
    #expect(!NativeConquestAchievementCore.asiaEligible(round: 56, map: "america"))
}

@Test func conquestAchievementUsesAllOwnedGeneralLevelsAndCampaignStageRatings() throws {
    let raw = try ResourceLoader.decode([String: Commander].self, from: TestResourcePaths.data("commanders.json"))
    let commanders: [Int: Commander] = Dictionary(uniqueKeysWithValues: raw.values.map { ($0.id, $0) })
    var profile = NativePlayerProfile.fresh()
    NativePlayerProfileCore.setIntMapValue(&profile, key: "rank", nestedKey: "1", value: 14)
    NativePlayerProfileCore.setIntMapValue(&profile, key: "nobility", nestedKey: "1", value: 9)
    var progress: [String: NativeJSONValue] = [:]
    var best: [String: NativeJSONValue] = [:]
    progress["campaign1_01.btl"] = .int(1)
    best["campaign1_01.btl"] = .int(5)
    profile.document["campaignProgress"] = .object(progress)
    profile.document["campaignBestRating"] = .object(best)
    #expect(NativeConquestAchievementCore.generalLevelContribution(profile: profile, commanders: commanders) > 0)
    #expect(NativeConquestAchievementCore.campaignStageStars(profile) == 5)
}

@Test func conquestAchievementPrepareVictoryOffersAsiaOnlyWithinRecoveredFastWinThreshold() throws {
    let raw = try ResourceLoader.decode([String: Commander].self, from: TestResourcePaths.data("commanders.json"))
    let commanders: [Int: Commander] = Dictionary(uniqueKeysWithValues: raw.values.map { ($0.id, $0) })
    let profile = NativePlayerProfile.fresh()
    let resources = CountryResources(money: 5_000, industry: 2_000, food: 3_000)
    let fast = NativeConquestAchievementCore.prepareVictory(round: 30, map: "europe", resources: resources, profile: profile, commanders: commanders)
    #expect(fast.normal.kind == "europe")
    #expect(fast.asiaEligible)
    #expect(fast.asia?.kind == "asia")
    let slow = NativeConquestAchievementCore.prepareVictory(round: 80, map: "europe", resources: resources, profile: profile, commanders: commanders)
    #expect(!slow.asiaEligible)
    #expect(slow.asia == nil)
}

@Test func conquestAchievementRecordKeepsBestStoredValueOnly() {
    let profile = NativePlayerProfile.fresh()
    let components = NativeConquestScoreComponents(resource: 0, hq: 0, stage: 0, round: 0)
    let high = NativeConquestAchievementResult(kind: "europe", value: 500, normalized: 50, total: 1, components: components)
    let first = NativeConquestAchievementCore.recordResult(profile: profile, result: high)
    #expect(first.changed)
    #expect(first.result.storedValue == 500)
    let low = NativeConquestAchievementResult(kind: "europe", value: 200, normalized: 20, total: 1, components: components)
    let second = NativeConquestAchievementCore.recordResult(profile: first.profile, result: low)
    #expect(!second.changed)
    #expect(second.result.storedValue == 500)
}
