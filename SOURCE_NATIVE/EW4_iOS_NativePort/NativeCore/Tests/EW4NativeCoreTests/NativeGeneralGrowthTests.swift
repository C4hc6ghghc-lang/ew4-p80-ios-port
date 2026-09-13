import XCTest
@testable import EW4NativeCore

final class NativeGeneralGrowthTests: XCTestCase {
    private func item(_ id: Int, function: Int, value: Int) -> NativeItemEffectDefinition {
        .init(name: "x", id: id, function: function, value: value, target: nil, price: nil, flag: nil)
    }

    func testMilitaryDamageGainMatchesP39() {
        XCTAssertEqual(NativeGeneralGrowthCore.battleMilitaryGain(damage: 10), 20)
        XCTAssertEqual(NativeGeneralGrowthCore.battleMilitaryGain(damage: 10, context: .init(skillIDs: [20])), 28)
        XCTAssertEqual(NativeGeneralGrowthCore.battleMilitaryGain(damage: 10, context: .init(skillIDs: [21])), 36)
        XCTAssertEqual(NativeGeneralGrowthCore.battleMilitaryGain(damage: 10, context: .init(skillIDs: [20, 21])), 36)
    }

    func testEquipmentOverridesSkillMultiplierAndBestWins() {
        let context = NativeGeneralGrowthContext(skillIDs: [21], items: [item(1, function: 2, value: 200)])
        XCTAssertEqual(NativeGeneralGrowthCore.battleMilitaryGain(damage: 10, context: context), 40)
        let best = NativeGeneralGrowthContext(items: [item(1, function: 2, value: 200), item(2, function: 2, value: 300)])
        XCTAssertEqual(NativeGeneralGrowthCore.battleMilitaryGain(damage: 10, context: best), 60)
    }

    func testNobilityGainOnlyUsesKillInputs() {
        XCTAssertEqual(NativeGeneralGrowthCore.battleNobilityGain(victimGrade: 0, victimHasCommander: false), 1)
        XCTAssertEqual(NativeGeneralGrowthCore.battleNobilityGain(victimGrade: 2, victimHasCommander: true), 6)
        XCTAssertEqual(NativeGeneralGrowthCore.battleNobilityGain(victimGrade: 2, victimHasCommander: true, context: .init(skillIDs: [19])), 9)
    }

    func testProgressMayCrossMultipleThresholdsExactlyLikeP39() {
        let out = NativeGeneralGrowthCore.addMilitaryProgress(rank: 0, progress: 490, amount: 820)
        XCTAssertEqual(out.level, 2)
        XCTAssertEqual(out.progress, 10)
        let noble = NativeGeneralGrowthCore.addNobilityProgress(level: 0, progress: 95, amount: 210)
        XCTAssertEqual(noble.level, 2)
        XCTAssertEqual(noble.progress, 5)
    }

    func testMaxLevelClearsProgress() {
        let m = NativeGeneralGrowthCore.addMilitaryProgress(rank: 13, progress: 199_999, amount: 1)
        XCTAssertEqual(m.level, 14)
        XCTAssertEqual(m.progress, 0)
        let n = NativeGeneralGrowthCore.addNobilityProgress(level: 8, progress: 3_374, amount: 1)
        XCTAssertEqual(n.level, 9)
        XCTAssertEqual(n.progress, 0)
    }

    func testAwardSeparatesMilitaryHitFromKillNobility() {
        let state = NativeGeneralGrowthState(rank: 0, militaryProgress: 490, nobility: 0, nobilityProgress: 99)
        let hitOnly = NativeGeneralGrowthCore.award(state: state, damage: 5, killed: false, victimGrade: 5, victimHasCommander: true)
        XCTAssertEqual(hitOnly.after.rank, 1)
        XCTAssertEqual(hitOnly.after.nobility, 0)
        let kill = NativeGeneralGrowthCore.award(state: state, damage: 5, killed: true, victimGrade: 0, victimHasCommander: false)
        XCTAssertEqual(kill.after.rank, 1)
        XCTAssertEqual(kill.after.nobility, 1)
    }
}
