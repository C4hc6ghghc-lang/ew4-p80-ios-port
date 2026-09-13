import Foundation

public struct NativeAIDestinationPlan: Equatable, Sendable {
    public let destination: HexCell
    public let path: [HexCell]
    public let targetUnitIndex: Int?
    public let score: Int

    public init(destination: HexCell, path: [HexCell], targetUnitIndex: Int?, score: Int) {
        self.destination = destination
        self.path = path
        self.targetUnitIndex = targetUnitIndex
        self.score = score
    }
}

public enum NativeAIPlannerCore {
    public static func targets(
        for unit: NativeBattleUnitState,
        gameplay: NativeBattleGameplayState
    ) -> [NativeBattleUnitState] {
        gameplay.unitOrder.compactMap { gameplay.units[$0] }.filter {
            !$0.dead && gameplay.relation(unit.owner, $0.owner) == .hostile
        }
    }

    public static func attackable(
        by unit: NativeBattleUnitState,
        from cell: HexCell,
        targets: [NativeBattleUnitState],
        gameplay: NativeBattleGameplayState
    ) -> [NativeBattleUnitState] {
        guard let stat = gameplay.stat(for: unit) else { return [] }
        return targets.filter { target in
            let distance = NativeHexGeometry.distance(cell, target.cell)
            return distance >= stat.minatkrange && distance <= stat.maxatkrange
        }
    }

    public static func chooseDestination(
        for unit: NativeBattleUnitState,
        targets: [NativeBattleUnitState],
        gameplay: NativeBattleGameplayState
    ) -> NativeAIDestinationPlan {
        if ArmyStatsCore.isFort(armyName: unit.armyName) || unit.moved {
            return NativeAIDestinationPlan(
                destination: unit.cell,
                path: [unit.cell],
                targetUnitIndex: nil,
                score: 0
            )
        }

        let reachable = gameplay.reachableCells(for: unit)
        let cells = [unit.cell] + reachable.keys.sorted {
            if $0.r == $1.r { return $0.q < $1.q }
            return $0.r < $1.r
        }
        var best: NativeAIDestinationPlan?

        for cell in cells {
            let attackableTargets = attackable(by: unit, from: cell, targets: targets, gameplay: gameplay)
                .sorted { lhs, rhs in
                    if lhs.hp != rhs.hp { return lhs.hp < rhs.hp }
                    let ld = NativeHexGeometry.distance(cell, lhs.cell)
                    let rd = NativeHexGeometry.distance(cell, rhs.cell)
                    if ld != rd { return ld < rd }
                    return lhs.index < rhs.index
                }
            let nearest = targets.map { NativeHexGeometry.distance(cell, $0.cell) }.min() ?? 9999
            let spentMovement = reachable[cell] ?? 0
            let score = (attackableTargets.isEmpty ? 0 : 100_000 - attackableTargets[0].hp * 4)
                - nearest * 100
                - spentMovement
            let path: [HexCell]
            if cell == unit.cell {
                path = [unit.cell]
            } else {
                path = NativeMovementCore.path(
                    start: unit.cell,
                    goal: cell,
                    maxCost: gameplay.effectiveMovement(for: unit),
                    canEnter: { gameplay.isPassable(unit, entering: $0) },
                    stepCost: { gameplay.movementCost(for: unit, entering: $0) }
                )
            }
            let candidate = NativeAIDestinationPlan(
                destination: cell,
                path: path,
                targetUnitIndex: attackableTargets.first?.index,
                score: score
            )
            if best == nil || candidate.score > best!.score {
                best = candidate
            }
        }

        return best ?? NativeAIDestinationPlan(
            destination: unit.cell,
            path: [unit.cell],
            targetUnitIndex: nil,
            score: 0
        )
    }
}
