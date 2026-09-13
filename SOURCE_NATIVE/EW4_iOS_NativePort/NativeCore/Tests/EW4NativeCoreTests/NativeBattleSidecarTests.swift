import Testing
@testable import EW4NativeCore

@Test func attackSidecarAddsCollectedMedalsExactlyOnce() {
    let bounds = DamageBounds(min: 1, max: 1, attackMin: 1, attackMax: 1, mastery: 0, coefficient: 1, masteryCoefficient: 1, fixedBonus: 0, skillLower: 0, skillUpper: 0)
    let hit = DamageResult(bounds: bounds, value: 1, attackTactic: false, defenseTactic: false, totalReduction: 0, notes: [])
    let result = NativeBattleAttackResult(
        attackerIndex: 1, defenderIndex: 2, damage: 1, counterDamage: nil,
        defenderKilled: false, attackerKilled: false, cavalryExtraAction: false,
        hit: hit, counter: nil, collectedMedals: 2
    )
    var context = NativeBattlePersistenceContext(
        resources: CountryResources(money: 0, industry: 0, food: 0), countryResources: [:], collectMedal: 4
    )
    #expect(NativeBattleSidecarCore.applyAttackResult(result, context: &context) == 2)
    #expect(context.collectMedal == 6)
}
