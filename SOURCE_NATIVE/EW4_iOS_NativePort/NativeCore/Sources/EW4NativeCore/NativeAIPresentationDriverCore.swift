import Foundation

public struct NativeAIMovePresentationAction: Equatable, Sendable {
    public let owner: Int
    public let unitIndex: Int
    public let from: HexCell
    public let to: HexCell
    public let path: [HexCell]
    public let capturedObjectIndices: [Int]
}

public struct NativeAIAttackPresentationAction: Sendable {
    public let owner: Int
    public let beforeAttacker: NativeBattleUnitState
    public let beforeDefender: NativeBattleUnitState
    public let afterAttacker: NativeBattleUnitState
    public let afterDefender: NativeBattleUnitState
    public let result: NativeBattleAttackResult
}

public enum NativeAIPresentationAction: Sendable {
    case countryBegan(owner: Int)
    case move(NativeAIMovePresentationAction)
    case attack(NativeAIAttackPresentationAction)
    case countryEnded(owner: Int)
    case roundReadyToSettle(roundBefore: Int, roundAfter: Int)
    case roundCompleted(roundBefore: Int, roundAfter: Int)
}

public enum NativeAIPresentationDriverError: Error, Equatable, Sendable {
    case alreadyFinished
}

/// Incremental form of NativeAIRoundSimulationCore. It consumes the exact same
/// planner/gameplay functions but yields at presentation boundaries so SpriteKit
/// can finish one move/attack before the next AI action is committed visually.
public struct NativeAIPresentationDriver: Sendable {
    public private(set) var owners: [Int] = []
    public private(set) var currentOwner: Int?
    public private(set) var finished = false

    private var started = false
    private var roundBefore = 0
    private var ownerCursor = 0
    private var unitOrder: [Int] = []
    private var unitCursor = 0
    private var pendingPostMoveUnitIndex: Int?
    private var countryBeganEmitted = false
    private var awaitingRoundFinalization = false

    public init() {}

    public mutating func next(
        gameplay: inout NativeBattleGameplayState,
        rng: () -> Double = { Double.random(in: 0..<1) }
    ) throws -> NativeAIPresentationAction {
        if finished { throw NativeAIPresentationDriverError.alreadyFinished }
        if !started {
            roundBefore = gameplay.round
            owners = try gameplay.endPlayerTurn()
            started = true
            ownerCursor = 0
            if owners.isEmpty {
                gameplay.advanceRoundCounterForSettlement()
                awaitingRoundFinalization = true
                return .roundReadyToSettle(roundBefore: roundBefore, roundAfter: gameplay.round)
            }
            try beginCurrentCountry(gameplay: &gameplay)
        }

        while true {
            guard let owner = currentOwner else {
                gameplay.advanceRoundCounterForSettlement()
                awaitingRoundFinalization = true
                return .roundReadyToSettle(roundBefore: roundBefore, roundAfter: gameplay.round)
            }

            if !countryBeganEmitted {
                countryBeganEmitted = true
                return .countryBegan(owner: owner)
            }

            if let pendingIndex = pendingPostMoveUnitIndex {
                pendingPostMoveUnitIndex = nil
                if let action = try postMoveAttackIfAvailable(unitIndex: pendingIndex, owner: owner, gameplay: &gameplay, rng: rng) {
                    return .attack(action)
                }
                continue
            }

            if unitCursor >= unitOrder.count {
                currentOwner = nil
                let endedOwner = owner
                ownerCursor += 1
                return .countryEnded(owner: endedOwner)
            }

            let unitIndex = unitOrder[unitCursor]
            unitCursor += 1
            guard let unit = gameplay.units[unitIndex], !unit.dead else { continue }
            let targets = NativeAIPlannerCore.targets(for: unit, gameplay: gameplay)
            if targets.isEmpty { continue }

            let sortedTargets = targets.sorted { lhs, rhs in
                let ld = NativeHexGeometry.distance(unit.cell, lhs.cell)
                let rd = NativeHexGeometry.distance(unit.cell, rhs.cell)
                if ld != rd { return ld < rd }
                return lhs.index < rhs.index
            }
            if let nearest = sortedTargets.first, gameplay.canAttack(unit, nearest) {
                let beforeAttacker = unit
                let beforeDefender = nearest
                let result = try gameplay.attackAIUnit(attacker: unit.index, target: nearest.index, rng: rng)
                let afterAttacker = gameplay.units[unit.index] ?? beforeAttacker
                let afterDefender = gameplay.units[nearest.index] ?? beforeDefender
                if result.cavalryExtraAction { unitCursor -= 1 }
                return .attack(
                    NativeAIAttackPresentationAction(
                        owner: owner,
                        beforeAttacker: beforeAttacker,
                        beforeDefender: beforeDefender,
                        afterAttacker: afterAttacker,
                        afterDefender: afterDefender,
                        result: result
                    )
                )
            }

            let plan = NativeAIPlannerCore.chooseDestination(for: unit, targets: targets, gameplay: gameplay)
            let from = unit.cell
            let move = try gameplay.moveAIUnit(unit.index, to: plan.destination)
            pendingPostMoveUnitIndex = unit.index
            if move.path.count > 1 {
                return .move(
                    NativeAIMovePresentationAction(
                        owner: owner,
                        unitIndex: unit.index,
                        from: from,
                        to: plan.destination,
                        path: move.path,
                        capturedObjectIndices: move.capturedObjectIndices
                    )
                )
            }
        }
    }


    /// Completes the round only after the caller has applied P39 settlement while
    /// previous-round action flags were still intact.
    public mutating func completeRoundAfterSettlement(
        gameplay: inout NativeBattleGameplayState
    ) throws -> NativeAIPresentationAction {
        guard !finished, awaitingRoundFinalization else {
            throw NativeAIPresentationDriverError.alreadyFinished
        }
        _ = gameplay.enterPlayerPhaseAfterRoundSettlement()
        awaitingRoundFinalization = false
        finished = true
        return .roundCompleted(roundBefore: roundBefore, roundAfter: gameplay.round)
    }

    /// Call after a countryEnded event before requesting the next visible action.
    /// Kept explicit so a renderer can leave the authored country strip on-screen
    /// for its own presentation delay without mutating game state in the meantime.
    public mutating func advanceAfterCountryEnd(gameplay: inout NativeBattleGameplayState) throws {
        guard !finished, currentOwner == nil else { return }
        if ownerCursor >= owners.count { return }
        try beginCurrentCountry(gameplay: &gameplay)
    }

    private mutating func beginCurrentCountry(gameplay: inout NativeBattleGameplayState) throws {
        guard ownerCursor < owners.count else {
            currentOwner = nil
            return
        }
        let owner = owners[ownerCursor]
        try gameplay.beginAITurn(owner: owner)
        currentOwner = owner
        unitOrder = gameplay.unitOrder.filter { gameplay.units[$0]?.owner == owner }
        unitCursor = 0
        pendingPostMoveUnitIndex = nil
        countryBeganEmitted = false
    }

    private mutating func postMoveAttackIfAvailable(
        unitIndex: Int,
        owner: Int,
        gameplay: inout NativeBattleGameplayState,
        rng: () -> Double
    ) throws -> NativeAIAttackPresentationAction? {
        guard let movedUnit = gameplay.units[unitIndex], !movedUnit.dead else { return nil }
        let postTargets = NativeAIPlannerCore.targets(for: movedUnit, gameplay: gameplay)
        let attackable = NativeAIPlannerCore.attackable(
            by: movedUnit,
            from: movedUnit.cell,
            targets: postTargets,
            gameplay: gameplay
        ).sorted { lhs, rhs in
            if lhs.hp != rhs.hp { return lhs.hp < rhs.hp }
            let ld = NativeHexGeometry.distance(movedUnit.cell, lhs.cell)
            let rd = NativeHexGeometry.distance(movedUnit.cell, rhs.cell)
            if ld != rd { return ld < rd }
            return lhs.index < rhs.index
        }
        guard let target = attackable.first, !movedUnit.attacked else { return nil }
        let beforeAttacker = movedUnit
        let beforeDefender = target
        let result = try gameplay.attackAIUnit(attacker: movedUnit.index, target: target.index, rng: rng)
        let afterAttacker = gameplay.units[movedUnit.index] ?? beforeAttacker
        let afterDefender = gameplay.units[target.index] ?? beforeDefender
        if result.cavalryExtraAction { unitCursor -= 1 }
        return NativeAIAttackPresentationAction(
            owner: owner,
            beforeAttacker: beforeAttacker,
            beforeDefender: beforeDefender,
            afterAttacker: afterAttacker,
            afterDefender: afterDefender,
            result: result
        )
    }
}
