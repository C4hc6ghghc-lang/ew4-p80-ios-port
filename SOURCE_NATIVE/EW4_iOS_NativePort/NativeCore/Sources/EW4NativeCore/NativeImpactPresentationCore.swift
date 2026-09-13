import Foundation

public struct NativeDamagePresentationEvent: Equatable, Sendable {
    public let targetIndex: Int
    public let beforeHP: Int
    public let afterHP: Int
    public let damage: Int
    public let killed: Bool
    public let delayMilliseconds: Double

    public init(targetIndex: Int, beforeHP: Int, afterHP: Int, damage: Int, killed: Bool, delayMilliseconds: Double) {
        self.targetIndex = targetIndex
        self.beforeHP = beforeHP
        self.afterHP = afterHP
        self.damage = damage
        self.killed = killed
        self.delayMilliseconds = max(0, delayMilliseconds)
    }
}

public struct NativeAttackPresentationPlan: Equatable, Sendable {
    public let primaryImpactMilliseconds: Double
    public let counterImpactMilliseconds: Double?
    public let actionDurationMilliseconds: Double
    public let resultCheckDelayMilliseconds: Double
    public let events: [NativeDamagePresentationEvent]

    public init(
        primaryImpactMilliseconds: Double,
        counterImpactMilliseconds: Double?,
        actionDurationMilliseconds: Double,
        resultCheckDelayMilliseconds: Double,
        events: [NativeDamagePresentationEvent]
    ) {
        self.primaryImpactMilliseconds = primaryImpactMilliseconds
        self.counterImpactMilliseconds = counterImpactMilliseconds
        self.actionDurationMilliseconds = actionDurationMilliseconds
        self.resultCheckDelayMilliseconds = resultCheckDelayMilliseconds
        self.events = events
    }
}

public struct NativePendingDamagePresentation: Equatable, Sendable {
    public let event: NativeDamagePresentationEvent
    public let dueMilliseconds: Double

    public init(event: NativeDamagePresentationEvent, dueMilliseconds: Double) {
        self.event = event
        self.dueMilliseconds = dueMilliseconds
    }
}

public struct NativeDamagePresentationQueue: Equatable, Sendable {
    public private(set) var presentationHP: [Int: Int] = [:]
    public private(set) var pending: [NativePendingDamagePresentation] = []

    public init() {}

    public mutating func enqueue(plan: NativeAttackPresentationPlan, nowMilliseconds: Double) {
        for event in plan.events {
            if presentationHP[event.targetIndex] == nil {
                presentationHP[event.targetIndex] = event.beforeHP
            }
            pending.append(
                NativePendingDamagePresentation(
                    event: event,
                    dueMilliseconds: nowMilliseconds + event.delayMilliseconds
                )
            )
        }
        pending.sort {
            if $0.dueMilliseconds != $1.dueMilliseconds { return $0.dueMilliseconds < $1.dueMilliseconds }
            return $0.event.targetIndex < $1.event.targetIndex
        }
    }

    @discardableResult
    public mutating func drain(nowMilliseconds: Double) -> [NativeDamagePresentationEvent] {
        var applied: [NativeDamagePresentationEvent] = []
        var remaining: [NativePendingDamagePresentation] = []
        for item in pending {
            if item.dueMilliseconds <= nowMilliseconds {
                presentationHP[item.event.targetIndex] = item.event.afterHP
                applied.append(item.event)
            } else {
                remaining.append(item)
            }
        }
        pending = remaining
        let stillPending = Set(pending.map { $0.event.targetIndex })
        for event in applied where !stillPending.contains(event.targetIndex) {
            presentationHP[event.targetIndex] = nil
        }
        return applied
    }

    public func displayedHP(unitIndex: Int, logicalHP: Int) -> Int {
        presentationHP[unitIndex] ?? logicalHP
    }

    public func isVisible(unitIndex: Int, logicalDead: Bool) -> Bool {
        !logicalDead || pending.contains(where: { $0.event.targetIndex == unitIndex })
    }

    public var isEmpty: Bool { pending.isEmpty }
}

public enum NativeImpactPresentationCore {
    public static let victoryPresentationTailMilliseconds = 20.0

    public static let fastAIMaximumImpactMilliseconds = 90.0

    public static func fastAI(_ plan: NativeAttackPresentationPlan) -> NativeAttackPresentationPlan {
        let presentationEnd = max(plan.primaryImpactMilliseconds, plan.counterImpactMilliseconds ?? 0)
        guard presentationEnd > fastAIMaximumImpactMilliseconds else { return plan }
        let scale = fastAIMaximumImpactMilliseconds / presentationEnd
        let events = plan.events.map { event in
            NativeDamagePresentationEvent(
                targetIndex: event.targetIndex,
                beforeHP: event.beforeHP,
                afterHP: event.afterHP,
                damage: event.damage,
                killed: event.killed,
                delayMilliseconds: max(1, event.delayMilliseconds * scale)
            )
        }
        let primary = max(1, plan.primaryImpactMilliseconds * scale)
        let counter = plan.counterImpactMilliseconds.map { max(1, $0 * scale) }
        let actionDuration = max(1, min(plan.actionDurationMilliseconds * scale, fastAIMaximumImpactMilliseconds))
        let resultDelay = max(primary, counter ?? 0) + victoryPresentationTailMilliseconds
        return NativeAttackPresentationPlan(
            primaryImpactMilliseconds: primary,
            counterImpactMilliseconds: counter,
            actionDurationMilliseconds: actionDuration,
            resultCheckDelayMilliseconds: resultDelay,
            events: events
        )
    }

    public static func attackImpactDelay(
        sequence: NativeAnimationSequence?,
        manifest: NativeAnimationManifest
    ) -> Double {
        guard let sequence else { return 1 }
        guard let attackIndex = sequence.phases.firstIndex(where: { $0.kind == "attack" }) else {
            return max(1, sequence.activeDurationMilliseconds)
        }
        let phase = sequence.phases[attackIndex]
        guard let asset = manifest.assets[phase.assetID] else {
            return max(1, sequence.activeDurationMilliseconds)
        }
        return max(
            1,
            sequence.phaseStartsMilliseconds[attackIndex] + NativeAnimationTiming.rawDurationMilliseconds(asset)
        )
    }

    public static func plan(
        beforeAttacker: NativeBattleUnitState,
        afterAttacker: NativeBattleUnitState,
        beforeDefender: NativeBattleUnitState,
        afterDefender: NativeBattleUnitState,
        result: NativeBattleAttackResult,
        attackerSequence: NativeAnimationSequence?,
        counterSequence: NativeAnimationSequence?,
        manifest: NativeAnimationManifest
    ) -> NativeAttackPresentationPlan {
        let primaryImpact = attackImpactDelay(sequence: attackerSequence, manifest: manifest)
        let counterImpact: Double? = result.counterDamage == nil
            ? nil
            : attackImpactDelay(sequence: counterSequence, manifest: manifest)
        let actionDuration = max(
            attackerSequence?.activeDurationMilliseconds ?? primaryImpact,
            counterSequence?.activeDurationMilliseconds ?? counterImpact ?? 0
        )
        let presentationEnd = max(primaryImpact, counterImpact ?? 0)
        var events: [NativeDamagePresentationEvent] = [
            NativeDamagePresentationEvent(
                targetIndex: beforeDefender.index,
                beforeHP: beforeDefender.hp,
                afterHP: afterDefender.hp,
                damage: result.damage,
                killed: result.defenderKilled,
                delayMilliseconds: primaryImpact
            )
        ]
        if let counterDamage = result.counterDamage {
            events.append(
                NativeDamagePresentationEvent(
                    targetIndex: beforeAttacker.index,
                    beforeHP: beforeAttacker.hp,
                    afterHP: afterAttacker.hp,
                    damage: counterDamage,
                    killed: result.attackerKilled,
                    delayMilliseconds: counterImpact ?? 1
                )
            )
        }
        return NativeAttackPresentationPlan(
            primaryImpactMilliseconds: primaryImpact,
            counterImpactMilliseconds: counterImpact,
            actionDurationMilliseconds: max(1, actionDuration),
            resultCheckDelayMilliseconds: presentationEnd + victoryPresentationTailMilliseconds,
            events: events
        )
    }
}
