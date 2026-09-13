import Foundation
import Testing
@testable import EW4NativeCore

private func settlementData() throws -> (NativeConstructionCatalog, NativeItemEffectCatalog) {
    let constructions = try ResourceLoader.decode(NativeConstructionCatalog.self, from: TestResourcePaths.data("constructions.json"))
    let items = try ResourceLoader.decode(NativeItemEffectCatalog.self, from: TestResourcePaths.data("items.json"))
    return (constructions, items)
}

private func roundUnit(
    index: Int,
    owner: Int = 0,
    q: Int,
    r: Int,
    commanderID: Int? = nil,
    skills: Set<Int> = [],
    items: [Int] = [],
    nobilityLevel: Int = 0,
    nobilityHealCap: Int = 25,
    trainingLevel: Int = 0,
    consumption: Int = 5,
    attacked: Bool = false,
    hp: Int = 50,
    maxHP: Int = 100
) -> NativeRoundUnitContext {
    NativeRoundUnitContext(
        index: index,
        owner: owner,
        q: q,
        r: r,
        armyName: "Line Infantry",
        grade: 0,
        commanderID: commanderID,
        commanderSkillIDs: skills,
        equippedItemIDs: items,
        nobilityLevel: nobilityLevel,
        nobilityHealCap: nobilityHealCap,
        trainingLevel: trainingLevel,
        consumption: consumption,
        attacked: attacked,
        hp: hp,
        maxHP: maxHP
    )
}

@Test func facilityIncomeAndUpkeepMatchP39() throws {
    let (constructions, items) = try settlementData()
    let objects = [NativeRoundObjectContext(index: 1, owner: 0, q: 4, r: 4, constructionType: "city", level: 3)]
    let base = roundUnit(index: 1, q: 4, r: 4, commanderID: 1, skills: [23], consumption: 5)
    let income = NativeRoundSettlementCore.facilityIncome(owner: 0, units: [base], objects: objects, constructions: constructions, items: items)
    #expect(income == CountryResources(money: 28, industry: 2, food: 0))
    #expect(NativeRoundSettlementCore.upkeep(owner: 0, units: [base]) == 5)
    let zeroFood = roundUnit(index: 2, q: 5, r: 4, commanderID: 2, skills: [22], consumption: 15)
    #expect(NativeRoundSettlementCore.upkeep(owner: 0, units: [base, zeroFood]) == 5)
}

@Test func facilityIncomeEquipmentUsesMaxMultiplierNotAddition() throws {
    let (constructions, items) = try settlementData()
    let objects = [NativeRoundObjectContext(index: 1, owner: 0, q: 2, r: 2, constructionType: "city", level: 3)]
    let encyclopedia = roundUnit(index: 1, q: 2, r: 2, commanderID: 1, skills: [23], items: [5])
    let code = roundUnit(index: 2, q: 2, r: 2, commanderID: 1, skills: [24], items: [6])
    #expect(NativeRoundSettlementCore.facilityIncome(owner: 0, units: [encyclopedia], objects: objects, constructions: constructions, items: items).money == 30)
    #expect(NativeRoundSettlementCore.facilityIncome(owner: 0, units: [code], objects: objects, constructions: constructions, items: items).money == 40)
}

@Test func campaignEconomicBonusesMatchP39UpgradeTable() throws {
    let (constructions, items) = try settlementData()
    var tech = Array(repeating: 0, count: 26)
    tech[22] = 3
    tech[23] = 2
    tech[24] = 1
    let out = NativeRoundSettlementCore.settleCountryEconomy(
        owner: 0,
        resources: CountryResources(money: 100, industry: 20, food: 50),
        units: [],
        objects: [],
        constructions: constructions,
        items: items,
        mode: .campaign,
        playerOwner: 0,
        campaignTechLevels: tech
    )
    #expect(out.income == CountryResources(money: 40, industry: 10, food: 30))
    #expect(out.resources == CountryResources(money: 140, industry: 30, food: 80))
}

@Test func trainingThenFacilitySupplyApplyToAllOwners() throws {
    let (constructions, _) = try settlementData()
    let objects = [
        NativeRoundObjectContext(index: 1, owner: 0, q: 1, r: 1, constructionType: "city", level: 2),
        NativeRoundObjectContext(index: 2, owner: 1, q: 3, r: 3, constructionType: "city", level: 1)
    ]
    var units = [
        roundUnit(index: 1, owner: 0, q: 1, r: 1, trainingLevel: 2, hp: 50, maxHP: 100),
        roundUnit(index: 2, owner: 1, q: 3, r: 3, trainingLevel: 1, hp: 50, maxHP: 100)
    ]
    #expect(NativeRoundSettlementCore.applyTrainingRecoveryAll(&units) == 5)
    #expect(units[0].hp == 53)
    #expect(units[1].hp == 52)
    let supply = NativeRoundSettlementCore.applyFacilitySupplyAll(&units, objects: objects, constructions: constructions)
    #expect(supply[0] == 4)
    #expect(supply[1] == 2)
    #expect(units[0].hp == 57)
    #expect(units[1].hp == 54)
}

@Test func playerNobilityFlagAndTentHealingMatchP39Ordering() throws {
    let (constructions, items) = try settlementData()
    let target = roundUnit(index: 1, q: 4, r: 4, commanderID: 1, items: [10], nobilityLevel: 9, nobilityHealCap: 25, trainingLevel: 0, attacked: false, hp: 50, maxHP: 100)
    let flagSource = roundUnit(index: 2, q: 5, r: 4, commanderID: 2, items: [46], hp: 100, maxHP: 100)
    let enemyFlag = roundUnit(index: 3, owner: 1, q: 4, r: 5, commanderID: 3, items: [46], hp: 100, maxHP: 100)
    let relation: (Int, Int) -> CountryRelation = { $0 == $1 ? .ally : .hostile }
    let out = NativeRoundSettlementCore.settlePlayerRound(
        playerOwner: 0,
        resources: CountryResources(money: 0, industry: 0, food: 20),
        units: [target, flagSource, enemyFlag],
        objects: [],
        constructions: constructions,
        items: items,
        mode: .campaign,
        relation: relation
    )
    let healedTarget = try #require(out.units.first(where: { $0.index == 1 }))
    #expect(out.playerSpecialHealed == 33)
    #expect(healedTarget.hp == 83)
}

@Test func tentDoesNotHealAfterAttackOrInsideConstruction() throws {
    let (constructions, items) = try settlementData()
    let relation: (Int, Int) -> CountryRelation = { $0 == $1 ? .ally : .hostile }
    var attackedUnits = [roundUnit(index: 1, q: 1, r: 1, items: [10], attacked: true, hp: 50, maxHP: 100)]
    #expect(NativeRoundSettlementCore.applyPlayerSpecialRecovery(&attackedUnits, playerOwner: 0, objects: [], items: items, relation: relation) == 0)
    var insideUnits = [roundUnit(index: 2, q: 2, r: 2, items: [10], attacked: false, hp: 50, maxHP: 100)]
    let object = NativeRoundObjectContext(index: 9, owner: 1, q: 2, r: 2, constructionType: "city", level: 0)
    #expect(NativeRoundSettlementCore.applyPlayerSpecialRecovery(&insideUnits, playerOwner: 0, objects: [object], items: items, relation: relation) == 0)
    _ = constructions
}

@Test func fullPlayerRoundSettlementMatchesP39Sequence() throws {
    let (constructions, items) = try settlementData()
    let objects = [NativeRoundObjectContext(index: 1, owner: 0, q: 1, r: 1, constructionType: "city", level: 2)]
    var tech = Array(repeating: 0, count: 26)
    tech[22] = 1
    tech[23] = 1
    tech[24] = 1
    let units = [
        roundUnit(index: 1, q: 1, r: 1, commanderID: 1, skills: [23], trainingLevel: 2, consumption: 5, hp: 50, maxHP: 100),
        roundUnit(index: 2, q: 2, r: 1, commanderID: 2, skills: [22], items: [46], consumption: 15, hp: 100, maxHP: 100)
    ]
    let relation: (Int, Int) -> CountryRelation = { $0 == $1 ? .ally : .hostile }
    let out = NativeRoundSettlementCore.settlePlayerRound(
        playerOwner: 0,
        resources: CountryResources(money: 100, industry: 20, food: 50),
        units: units,
        objects: objects,
        constructions: constructions,
        items: items,
        mode: .campaign,
        campaignTechLevels: tech,
        relation: relation
    )
    #expect(out.money == 36)
    #expect(out.industry == 10)
    #expect(out.foodAdd == 10)
    #expect(out.foodDel == 5)
    #expect(out.trainingHealed == 3)
    #expect(out.facilityHealed == 4)
    #expect(out.playerSpecialHealed == 2)
    #expect(out.healed == 9)
    #expect(out.resources == CountryResources(money: 136, industry: 30, food: 55))
    let first = try #require(out.units.first(where: { $0.index == 1 }))
    #expect(first.hp == 59)
}
