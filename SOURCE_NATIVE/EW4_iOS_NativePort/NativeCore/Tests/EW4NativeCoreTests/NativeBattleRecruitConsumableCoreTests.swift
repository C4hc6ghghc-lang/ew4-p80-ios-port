import Testing
@testable import EW4NativeCore

@Test func nativeRecruitArmyIdsAndCampaignTrainingStayOnRecoveredMapping() {
    #expect(NativeBattleRecruitCore.armyID("Militia") == 0)
    #expect(NativeBattleRecruitCore.armyID("Rocket") == 13)
    #expect(NativeBattleRecruitCore.armyID("Ironclad") == 17)
    #expect(NativeBattleRecruitCore.armyID("Coastal Fort") == 21)
    var tech = Array(repeating: -1, count: 22)
    tech[3] = 2
    #expect(NativeBattleRecruitCore.initialTrainingLevel(name: "Grenadier", mode: .campaign, campaignTech: tech) == 2)
    #expect(NativeBattleRecruitCore.initialTrainingLevel(name: "Militia", mode: .campaign, campaignTech: tech) == nil)
    #expect(NativeBattleRecruitCore.initialTrainingLevel(name: "Militia", mode: .tutorial, campaignTech: tech) == 0)
    #expect(NativeBattleRecruitCore.initialTrainingLevel(name: "Militia", mode: .campaign, campaignTech: nil) == 0)
}

@Test func nativeBattleConsumablesMatchRecoveredUseRulesAndRemainStateOnly() {
    var unit = NativeBattleUnitState(index: 1, armyID: 1, armyName: "Line Infantry", grade: 0, owner: 0, commanderID: nil, q: 1, r: 1, hp: 100, maxHP: 200, moved: false, attacked: false, embarked: false)
    let small = NativeItemEffectDefinition(name: "Medikit", id: 13, function: 8, value: 65)
    #expect(NativeBattleConsumableCore.apply(item: small, unit: &unit, round: 2))
    #expect(unit.hp == 165)
    #expect(unit.moved && unit.attacked)

    var morale = NativeBattleUnitState(index: 2, armyID: 1, armyName: "Line Infantry", grade: 0, owner: 0, commanderID: nil, q: 1, r: 1, hp: 200, maxHP: 200, moved: false, attacked: false, embarked: false, nativeMoraleBase: -1, nativeMoraleUntilRound: 5)
    let wine = NativeItemEffectDefinition(name: "Wine", id: 11, function: 7, value: 0)
    #expect(NativeBattleConsumableCore.apply(item: wine, unit: &morale, round: 2))
    #expect(morale.nativeMoraleBase == 0)
    #expect(morale.nativeMoraleUntilRound == 5)
    let spirit = NativeItemEffectDefinition(name: "Spirit", id: 12, function: 6, value: 0)
    #expect(NativeBattleConsumableCore.apply(item: spirit, unit: &morale, round: 2))
    #expect(morale.nativeMoraleBase == 1)
    #expect(morale.nativeMoraleUntilRound == 5)
}
