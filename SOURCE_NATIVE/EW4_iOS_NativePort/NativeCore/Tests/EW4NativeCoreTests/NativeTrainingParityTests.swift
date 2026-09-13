import Testing
@testable import EW4NativeCore

@Test func nativeTrainingTablesMatchP39() {
    #expect(NativeTrainingParityCore.maxLevel == 5)
    #expect(NativeTrainingParityCore.goldCost == [30, 45, 70, 105, 160])
    #expect(NativeTrainingParityCore.levels.map(\.defense) == [0, 2, 4, 6, 8, 10])
    #expect(NativeTrainingParityCore.levels.map(\.roundHeal) == [0, 2, 3, 4, 5, 6])
    #expect(NativeTrainingParityCore.levels.map(\.levelUpHeal) == [0, 10, 20, 30, 40, 50])
    #expect(NativeTrainingParityCore.levels.map(\.baseExp) == [0, 100, 150, 220, 300, 400])
}

@Test func manualTrainingCostAndHealMatchP39() {
    var unit = NativeTrainingUnitState(trainingLevel: 3, trainingExp: 99, hp: 620, maxHP: 900, commanderID: 1)
    var resources = CountryResources(money: 1000, industry: 500, food: 100)
    #expect(NativeTrainingParityCore.manualCost(unit: NativeTrainingUnitState(trainingLevel: 0, hp: 50, maxHP: 100), consumption: 5) == CountryResources(money: 30, industry: 0, food: 15))
    #expect(NativeTrainingParityCore.manualCost(unit: NativeTrainingUnitState(trainingLevel: 4, hp: 50, maxHP: 100), consumption: 15) == CountryResources(money: 160, industry: 0, food: 45))
    let out = NativeTrainingParityCore.manualTrain(unit: &unit, commanderTraining: 5, consumption: 10, resources: &resources)
    #expect(out.ok)
    #expect(unit.trainingLevel == 4)
    #expect(unit.trainingExp == 99)
    #expect(unit.hp == 660)
    #expect(resources == CountryResources(money: 895, industry: 500, food: 70))
}

@Test func trainingExperienceThresholdsMatchP39() {
    var land = NativeTrainingUnitState(trainingLevel: 0, trainingExp: 0, hp: 80, maxHP: 100, commanderID: 1)
    #expect(NativeTrainingParityCore.nextExpThreshold(unit: land, unitType: "infantry") == 150)
    #expect(NativeTrainingParityCore.nextExpThreshold(unit: land, hasCommander: false, unitType: "infantry") == 100)
    #expect(NativeTrainingParityCore.nextExpThreshold(unit: land, unitType: "warship") == 300)
    let first = NativeTrainingParityCore.awardExp(unit: &land, amount: 149, unitType: "infantry")
    #expect(!first.leveled)
    let second = NativeTrainingParityCore.awardExp(unit: &land, amount: 1, unitType: "infantry")
    #expect(second.leveled)
    #expect(land.trainingLevel == 1)
    #expect(land.hp == 90)
    #expect(land.trainingExp == 0)
}

@Test func roundTrainingHealCapsAtMaxHP() {
    var unit = NativeTrainingUnitState(trainingLevel: 5, hp: 97, maxHP: 100)
    #expect(NativeTrainingParityCore.applyRoundHeal(&unit) == 3)
    #expect(unit.hp == 100)
    var dead = NativeTrainingUnitState(trainingLevel: 5, hp: 0, maxHP: 100, dead: true)
    #expect(NativeTrainingParityCore.applyRoundHeal(&dead) == 0)
}
