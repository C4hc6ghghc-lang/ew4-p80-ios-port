import Testing
@testable import EW4NativeCore

@Test func originalCampaignAndConquestSelectionGeometryMatches568hXML() {
    #expect(NativeOriginalOuterShellCore.CampaignSelect.zoneButtons.count == 6)
    #expect(NativeOriginalOuterShellCore.CampaignSelect.zoneButtons[0] == NativeRect(x: 300, y: 118, width: 54, height: 62))
    #expect(NativeOriginalOuterShellCore.CampaignSelect.zoneButtons[5] == NativeRect(x: 265, y: 38, width: 54, height: 62))
    #expect(NativeOriginalOuterShellCore.ConquestSelect.cards.count == 6)
    #expect(NativeOriginalOuterShellCore.ConquestSelect.cards[0] == NativeRect(x: 52, y: 37, width: 222, height: 83))
    #expect(NativeOriginalOuterShellCore.ConquestSelect.cards[5] == NativeRect(x: 292, y: 227, width: 222, height: 83))
}

@Test func originalCountrySelectorAndBattleListsCannotDrift() {
    #expect(NativeOriginalOuterShellCore.CountrySelect.screenFrame == NativeRect(x: 167, y: 85, width: 234, height: 150))
    #expect(NativeOriginalOuterShellCore.CountrySelect.left == NativeRect(x: 17, y: 36, width: 85, height: 67))
    #expect(NativeOriginalOuterShellCore.CountrySelect.right == NativeRect(x: 132, y: 36, width: 85, height: 67))
    #expect(NativeOriginalOuterShellCore.CampaignList.list == NativeRect(x: 410, y: 23, width: 160, height: 275))
    #expect(NativeOriginalOuterShellCore.ConquestList.listBack == NativeRect(x: 442, y: 23, width: 160, height: 297))
}

@Test func originalCompleteChallengeSummaryUseSame346By190Form() {
    #expect(NativeOriginalOuterShellCore.Complete.frame == NativeRect(x: 0, y: 0, width: 346, height: 190))
    #expect(NativeOriginalOuterShellCore.Complete.screenFrame == NativeRect(x: 111, y: 65, width: 346, height: 190))
    #expect(NativeOriginalOuterShellCore.Complete.Campaign.ok == NativeRect(x: 317, y: 136, width: 31, height: 31))
    #expect(NativeOriginalOuterShellCore.Complete.Challenge.asia == NativeRect(x: 40, y: 142, width: 100, height: 35))
    #expect(NativeOriginalOuterShellCore.Complete.Challenge.home == NativeRect(x: 205, y: 142, width: 100, height: 35))
    #expect(NativeOriginalOuterShellCore.Complete.Conquest.ok == NativeRect(x: 317, y: 161, width: 31, height: 31))
}

@Test func conquestScenarioMetadataMatchesP39SixScenarioShell() {
    let all = NativeOriginalOuterShellCore.conquestScenarios
    #expect(all.count == 6)
    #expect(all[0] == NativeOriginalConquestScenario(index: 1, textureYear: "1793", location: "europe", displayYear: "1798", map: "europe"))
    #expect(all[1].map == "america")
    #expect(all[4].displayYear == "1812")
    #expect(NativeOriginalOuterShellCore.conquestScenario(file: "conquest6.btl")?.textureYear == "1815")
    #expect(NativeOriginalOuterShellCore.conquestScenario(file: "campaign1_01.btl") == nil)
}

@Test func conquestChallengeUsesOriginalHomeButtonByMap() {
    let components = NativeConquestScoreComponents(resource: 0, hq: 0, stage: 0, round: 0)
    let normal = NativeConquestAchievementResult(kind: "europe", value: 500, normalized: 50, total: 0, components: components)
    let asia = NativeConquestAchievementResult(kind: "asia", value: 450, normalized: 55, total: 0, components: components)
    let prepared = NativeConquestVictoryPrepared(normal: normal, asiaEligible: true, asia: asia)
    #expect(NativeOriginalOuterShellCore.conquestChallenge(prepared, map: "europe").homeButtonStringKey == "btn_chal_euro")
    #expect(NativeOriginalOuterShellCore.conquestChallenge(prepared, map: "america").homeButtonStringKey == "btn_chal_amer")
}

@Test func originalCompleteHitboxesUseRecoveredButtonPositions() {
    #expect(NativeOriginalOuterShellCore.campaignCompleteAction(at: NativePoint(x: 332, y: 151)) == .campaignOK)
    #expect(NativeOriginalOuterShellCore.conquestChallengeAction(at: NativePoint(x: 90, y: 158)) == .challengeAsia)
    #expect(NativeOriginalOuterShellCore.conquestChallengeAction(at: NativePoint(x: 255, y: 158)) == .challengeHome)
    #expect(NativeOriginalOuterShellCore.conquestSummaryAction(at: NativePoint(x: 332, y: 176)) == .conquestOK)
    #expect(NativeOriginalOuterShellCore.conquestChallengeAction(at: NativePoint(x: 170, y: 158)) == nil)
}

@Test func originalOuterSelectionHitboxesMatchRecoveredShell() {
    #expect(NativeOriginalOuterShellCore.campaignSelectionAction(at: NativePoint(x: 327, y: 149)) == .campaignZone(1))
    #expect(NativeOriginalOuterShellCore.campaignSelectionAction(at: NativePoint(x: 292, y: 69)) == .campaignZone(6))
    #expect(NativeOriginalOuterShellCore.conquestSelectionAction(at: NativePoint(x: 160, y: 78)) == .conquestScenario(1))
    #expect(NativeOriginalOuterShellCore.conquestSelectionAction(at: NativePoint(x: 400, y: 268)) == .conquestScenario(6))
    #expect(NativeOriginalOuterShellCore.countrySelectionAction(at: NativePoint(x: 200, y: 145)) == .countryLeft)
    #expect(NativeOriginalOuterShellCore.countrySelectionAction(at: NativePoint(x: 331, y: 145)) == .countryRight)
    #expect(NativeOriginalOuterShellCore.countrySelectionAction(at: NativePoint(x: 391, y: 86)) == .countryClose)
    #expect(NativeOriginalOuterShellCore.countrySelectionAction(at: NativePoint(x: 390, y: 226)) == .countryConfirm)
}

@Test func originalOuterListHitboxesHonorVisibleWindowOffset() {
    let p = NativePoint(x: 450, y: 23 + 47 * 2 + 20)
    #expect(NativeOriginalOuterShellCore.campaignListAction(at: p, firstVisibleRow: 4, rowCount: 12) == .listRow(6))
    #expect(NativeOriginalOuterShellCore.conquestListAction(at: p, firstVisibleRow: 3, rowCount: 20) == .listRow(5))
    #expect(NativeOriginalOuterShellCore.campaignListAction(at: NativePoint(x: 500, y: 308), firstVisibleRow: 0, rowCount: 10) == .listConfirm)
}
