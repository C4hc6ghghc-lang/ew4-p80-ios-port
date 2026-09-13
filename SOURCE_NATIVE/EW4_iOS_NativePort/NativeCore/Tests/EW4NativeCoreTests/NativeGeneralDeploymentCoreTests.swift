import Testing
@testable import EW4NativeCore

private func deployUnit(_ index: Int, owner: Int, hp: Int = 80, maxHP: Int = 100, commander: Int? = nil, hpBonus: Int = 0) -> NativeBattleUnitState {
    NativeBattleUnitState(index: index, armyID: index, armyName: "Line Infantry", grade: 0, owner: owner, commanderID: commander, q: index, r: 0, hp: hp, maxHP: maxHP, moved: false, attacked: false, embarked: false, playerCommanderHPBonus: hpBonus)
}

struct NativeGeneralDeploymentCoreTests {
    @Test func preservesAbsoluteDamageWhenCommanderChanges() {
        let old = deployUnit(1, owner: 0, hp: 80, maxHP: 100, commander: 11, hpBonus: 20)
        let next = NativeGeneralDeploymentCore.replacingCommander(old, commanderID: 22, hpBonus: 40)
        #expect(next.commanderID == 22)
        #expect(next.maxHP == 120)
        #expect(next.hp == 100)
        #expect(next.playerCommanderHPBonus == 40)
    }

    @Test func duplicatePlayerCarrierIsClearedEnemyCarrierIsUntouched() {
        var units: [Int: NativeBattleUnitState] = [
            1: deployUnit(1, owner: 0, hp: 70, maxHP: 100, commander: 7),
            2: deployUnit(2, owner: 0, hp: 90, maxHP: 100),
            3: deployUnit(3, owner: 1, hp: 100, maxHP: 100, commander: 7)
        ]
        let out = NativeGeneralDeploymentCore.assign(units: &units, targetUnitIndex: 2, commanderID: 7, playerOwner: 0, hpBonus: 30)
        #expect(out?.clearedUnitIndices == [1])
        #expect(units[1]?.commanderID == nil)
        #expect(units[2]?.commanderID == 7)
        #expect(units[2]?.maxHP == 130)
        #expect(units[2]?.hp == 120)
        #expect(units[3]?.commanderID == 7)
    }

    @Test func occupiedCommandersAreExcludedFromTargetGrid() {
        let units = [deployUnit(4, owner: 0, commander: 10), deployUnit(5, owner: 0, commander: 20), deployUnit(6, owner: 1, commander: 30)]
        #expect(NativeGeneralDeploymentCore.deployedIDs(units: units, playerOwner: 0) == Set([10, 20]))
        #expect(NativeGeneralDeploymentCore.eligibleCommanderIDs(ownedCommanderIDs: [10,20,30,40], units: units, playerOwner: 0, targetUnitIndex: 4) == [10,30,40])
    }
}
