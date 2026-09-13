import Foundation
import Testing
@testable import EW4NativeCore

private func impactManifest() throws -> NativeAnimationManifest {
    try ResourceLoader.decode(NativeAnimationManifest.self, from: TestResourcePaths.data("native_animation_core877.json"))
}


private func fakeDamage(_ value: Int) -> DamageResult {
    let b = DamageBounds(min: value, max: value, attackMin: value, attackMax: value, mastery: 0, coefficient: 0, masteryCoefficient: 0, fixedBonus: 0, skillLower: 0, skillUpper: 0)
    return DamageResult(bounds: b, value: value, attackTactic: false, defenseTactic: false, totalReduction: 0, notes: [])
}

private func impactUnit(_ index: Int, hp: Int, maxHP: Int = 100, owner: Int = 0) -> NativeBattleUnitState {
    NativeBattleUnitState(
        index: index, armyID: 0, armyName: "Militia", grade: 0, owner: owner,
        commanderID: nil, q: index, r: 1, hp: hp, maxHP: maxHP,
        moved: false, attacked: false, embarked: false
    )
}

@Test func authoredImpactUsesEndOfAttackPhaseNotFullReloadFinishChain() throws {
    let manifest = try impactManifest()
    let unitName = try #require(manifest.units.keys.first(where: { name in
        guard let u = manifest.units[name] else { return false }
        return NativeAnimationSequenceCore.hasMotion(unit: u, type: "attack", index: 0)
            && NativeAnimationSequenceCore.hasMotion(unit: u, type: "reload", index: 0)
            && NativeAnimationSequenceCore.hasMotion(unit: u, type: "finish", index: 0)
    }))
    let sequence = try NativeAnimationSequenceCore.buildAttackSequence(manifest: manifest, unitName: unitName)
    let attack = try #require(sequence.phases.first(where: { $0.kind == "attack" }))
    let asset = try #require(manifest.assets[attack.assetID])
    let impact = NativeImpactPresentationCore.attackImpactDelay(sequence: sequence, manifest: manifest)
    #expect(abs(impact - NativeAnimationTiming.rawDurationMilliseconds(asset)) < 0.001)
    #expect(impact < sequence.activeDurationMilliseconds)
}

@Test func pendingKilledUnitRemainsVisibleUntilImpactThenCommitsHP() {
    let event = NativeDamagePresentationEvent(
        targetIndex: 2, beforeHP: 30, afterHP: 0, damage: 30, killed: true, delayMilliseconds: 400
    )
    let plan = NativeAttackPresentationPlan(
        primaryImpactMilliseconds: 400,
        counterImpactMilliseconds: nil,
        actionDurationMilliseconds: 900,
        resultCheckDelayMilliseconds: 420,
        events: [event]
    )
    var queue = NativeDamagePresentationQueue()
    queue.enqueue(plan: plan, nowMilliseconds: 1000)
    #expect(queue.displayedHP(unitIndex: 2, logicalHP: 0) == 30)
    #expect(queue.isVisible(unitIndex: 2, logicalDead: true))
    #expect(queue.drain(nowMilliseconds: 1399).isEmpty)
    let applied = queue.drain(nowMilliseconds: 1400)
    #expect(applied == [event])
    #expect(queue.displayedHP(unitIndex: 2, logicalHP: 0) == 0)
    #expect(!queue.isVisible(unitIndex: 2, logicalDead: true))
}

@Test func counterDamageGetsIndependentAuthoredImpact() throws {
    let manifest = try impactManifest()
    let name = try #require(manifest.units.keys.first(where: { name in
        guard let unit = manifest.units[name] else { return false }
        return NativeAnimationSequenceCore.hasMotion(unit: unit, type: "attack", index: 0)
    }))
    let seq = try NativeAnimationSequenceCore.buildAttackSequence(manifest: manifest, unitName: name)
    let beforeA = impactUnit(1, hp: 90)
    let afterA = impactUnit(1, hp: 80)
    let beforeD = impactUnit(2, hp: 50, owner: 1)
    let afterD = impactUnit(2, hp: 20, owner: 1)
    let damage = fakeDamage(30)
    let result = NativeBattleAttackResult(
        attackerIndex: 1, defenderIndex: 2, damage: 30, counterDamage: 10,
        defenderKilled: false, attackerKilled: false, cavalryExtraAction: false,
        hit: damage, counter: fakeDamage(15)
    )
    let plan = NativeImpactPresentationCore.plan(
        beforeAttacker: beforeA, afterAttacker: afterA,
        beforeDefender: beforeD, afterDefender: afterD,
        result: result, attackerSequence: seq, counterSequence: seq, manifest: manifest
    )
    #expect(plan.events.count == 2)
    #expect(plan.events[0].targetIndex == 2)
    #expect(plan.events[1].targetIndex == 1)
    #expect(plan.resultCheckDelayMilliseconds == max(plan.primaryImpactMilliseconds, plan.counterImpactMilliseconds ?? 0) + 20)
}

@Test func fastAIPresentationCapsAuthoredImpactAtNinetyMilliseconds() {
    let event = NativeDamagePresentationEvent(
        targetIndex: 2, beforeHP: 100, afterHP: 70, damage: 30, killed: false, delayMilliseconds: 400
    )
    let plan = NativeAttackPresentationPlan(
        primaryImpactMilliseconds: 400,
        counterImpactMilliseconds: nil,
        actionDurationMilliseconds: 900,
        resultCheckDelayMilliseconds: 420,
        events: [event]
    )
    let fast = NativeImpactPresentationCore.fastAI(plan)
    #expect(abs(fast.primaryImpactMilliseconds - 90) < 0.001)
    #expect(fast.counterImpactMilliseconds == nil)
    #expect(abs(fast.events[0].delayMilliseconds - 90) < 0.001)
    #expect(fast.actionDurationMilliseconds <= 90)
    #expect(abs(fast.resultCheckDelayMilliseconds - 110) < 0.001)
}

@Test func fastAIPresentationPreservesAlreadyShortImpact() {
    let event = NativeDamagePresentationEvent(
        targetIndex: 2, beforeHP: 100, afterHP: 95, damage: 5, killed: false, delayMilliseconds: 60
    )
    let plan = NativeAttackPresentationPlan(
        primaryImpactMilliseconds: 60,
        counterImpactMilliseconds: nil,
        actionDurationMilliseconds: 80,
        resultCheckDelayMilliseconds: 80,
        events: [event]
    )
    #expect(NativeImpactPresentationCore.fastAI(plan) == plan)
}
