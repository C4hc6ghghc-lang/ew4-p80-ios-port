import Testing
@testable import EW4NativeCore

@Suite("Native battle unit info core")
struct NativeBattleUnitInfoCoreTests {
    @Test("player interval includes global +4 and matching skill bonuses")
    func playerInterval() {
        let unit = NativeBattleUnitState(index: 1, armyID: 1, armyName: "Line Infantry", grade: 1, owner: 0, commanderID: 7, q: 1, r: 2, hp: 120, maxHP: 180, moved: false, attacked: false, embarked: false)
        let stat = ArmyStatDefinition(name: "Line Infantry", grade: 1, type: "infantry", strength: 140, movement: 7, minatk: 5, maxatk: 9, weapon: "rifle", minatkrange: 1, maxatkrange: 1, consumption: 4)
        let commander = NativeEffectiveCommander(id: 7, infantry: 4, cavalry: 0, artillery: 0, warship: 0, fort: 0, business: 0, movement: 1, training: 0, skillIDs: [12, 13], equippedItemIDs: [], rankLevel: 0, nobilityLevel: 0, rankHPBonus: 0, nobilityHealCap: 25)
        let model = NativeBattleUnitInfoCore.model(unit: unit, stat: stat, effectiveCommander: commander, movement: 10, moneyCost: 90, industryCost: 5, isPlayer: true, commanderName: "Davout", strings: ["name_Line Infantry":"线列步兵", "desc_Line Infantry":"主力部队"])
        #expect(model.attackMin == 10)
        #expect(model.attackMax == 14)
        #expect(model.formationCount == 2)
        #expect(model.displayName == "线列步兵")
        #expect(model.commanderName == "Davout")
    }

    @Test("enemy interval does not get player bonus")
    func enemyInterval() {
        let unit = NativeBattleUnitState(index: 2, armyID: 0, armyName: "Militia", grade: 0, owner: 1, commanderID: nil, q: 0, r: 0, hp: 50, maxHP: 50, moved: false, attacked: false, embarked: false)
        let stat = ArmyStatDefinition(name: "Militia", grade: 0, type: "infantry", strength: 50, movement: 5, minatk: 2, maxatk: 4, weapon: "musket", minatkrange: 1, maxatkrange: 1, consumption: 2)
        let model = NativeBattleUnitInfoCore.model(unit: unit, stat: stat, effectiveCommander: nil, movement: 5, moneyCost: 40, industryCost: 0, isPlayer: false, commanderName: nil, strings: [:])
        #expect(model.attackMin == 2)
        #expect(model.attackMax == 4)
        #expect(model.formationCount == 1)
    }
}
