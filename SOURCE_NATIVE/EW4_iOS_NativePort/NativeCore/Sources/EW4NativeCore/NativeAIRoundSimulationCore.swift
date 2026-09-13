import Foundation

public struct NativeAICountrySimulationSummary: Equatable, Sendable {
    public let owner: Int
    public let moves: Int
    public let attacks: Int
    public let captures: Int
    public let kills: Int
    public let extraActions: Int
}

public struct NativeAIRoundSimulationSummary: Equatable, Sendable {
    public let roundBefore: Int
    public let owners: [Int]
    public let countries: [NativeAICountrySimulationSummary]
}

public enum NativeAIRoundSimulationCore {
    @discardableResult
    public static func runOneRound(
        gameplay: inout NativeBattleGameplayState,
        rng: () -> Double = { Double.random(in: 0..<1) }
    ) throws -> NativeAIRoundSimulationSummary {
        let roundBefore = gameplay.round
        let owners = try gameplay.endPlayerTurn()
        var summaries: [NativeAICountrySimulationSummary] = []
        for owner in owners {
            try gameplay.beginAITurn(owner: owner)
            summaries.append(try runCountry(owner: owner, gameplay: &gameplay, rng: rng))
        }
        gameplay.beginNextPlayerRound()
        return NativeAIRoundSimulationSummary(
            roundBefore: roundBefore,
            owners: owners,
            countries: summaries
        )
    }

    private static func runCountry(
        owner: Int,
        gameplay: inout NativeBattleGameplayState,
        rng: () -> Double
    ) throws -> NativeAICountrySimulationSummary {
        let unitOrder = gameplay.unitOrder.filter { gameplay.units[$0]?.owner == owner }
        var cursor = 0
        var moves = 0
        var attacks = 0
        var captures = 0
        var kills = 0
        var extraActions = 0

        while cursor < unitOrder.count {
            let unitIndex = unitOrder[cursor]
            cursor += 1
            guard let unit = gameplay.units[unitIndex], !unit.dead else { continue }
            var targets = NativeAIPlannerCore.targets(for: unit, gameplay: gameplay)
            if targets.isEmpty { continue }
            targets.sort { lhs, rhs in
                let ld = NativeHexGeometry.distance(unit.cell, lhs.cell)
                let rd = NativeHexGeometry.distance(unit.cell, rhs.cell)
                if ld != rd { return ld < rd }
                return lhs.index < rhs.index
            }

            if let nearest = targets.first, gameplay.canAttack(unit, nearest) {
                let result = try gameplay.attackAIUnit(attacker: unit.index, target: nearest.index, rng: rng)
                attacks += 1
                if result.defenderKilled { kills += 1 }
                if result.cavalryExtraAction {
                    extraActions += 1
                    cursor -= 1
                }
                continue
            }

            let plan = NativeAIPlannerCore.chooseDestination(for: unit, targets: targets, gameplay: gameplay)
            let move = try gameplay.moveAIUnit(unit.index, to: plan.destination)
            if move.path.count > 1 { moves += 1 }
            captures += move.capturedObjectIndices.count

            guard let movedUnit = gameplay.units[unit.index], !movedUnit.dead else { continue }
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
            if let target = attackable.first, !movedUnit.attacked {
                let result = try gameplay.attackAIUnit(attacker: movedUnit.index, target: target.index, rng: rng)
                attacks += 1
                if result.defenderKilled { kills += 1 }
                if result.cavalryExtraAction {
                    extraActions += 1
                    cursor -= 1
                }
            }
        }

        return NativeAICountrySimulationSummary(
            owner: owner,
            moves: moves,
            attacks: attacks,
            captures: captures,
            kills: kills,
            extraActions: extraActions
        )
    }
}
