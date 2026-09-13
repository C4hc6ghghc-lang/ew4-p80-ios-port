import Foundation

public struct NativeGeneralDeploymentResult: Equatable, Sendable {
    public let targetUnitIndex: Int
    public let commanderID: Int
    public let clearedUnitIndices: [Int]
    public let previousCommanderID: Int?
    public let previousHP: Int
    public let previousMaxHP: Int
    public let hp: Int
    public let maxHP: Int

    public init(targetUnitIndex: Int, commanderID: Int, clearedUnitIndices: [Int], previousCommanderID: Int?, previousHP: Int, previousMaxHP: Int, hp: Int, maxHP: Int) {
        self.targetUnitIndex = targetUnitIndex
        self.commanderID = commanderID
        self.clearedUnitIndices = clearedUnitIndices
        self.previousCommanderID = previousCommanderID
        self.previousHP = previousHP
        self.previousMaxHP = previousMaxHP
        self.hp = hp
        self.maxHP = maxHP
    }
}

/// DOM-free parity for the mature Web `general_deployment_core.js`.
public enum NativeGeneralDeploymentCore {
    public static func deployedIDs(units: [NativeBattleUnitState], playerOwner: Int, exceptUnitIndex: Int? = nil) -> Set<Int> {
        Set(units.compactMap { unit in
            guard !unit.dead,
                  unit.owner == playerOwner,
                  unit.index != exceptUnitIndex,
                  let commanderID = unit.commanderID,
                  commanderID > 0 else { return nil }
            return commanderID
        })
    }

    public static func eligibleCommanderIDs(
        ownedCommanderIDs: [Int],
        units: [NativeBattleUnitState],
        playerOwner: Int,
        targetUnitIndex: Int,
        include: Set<Int> = []
    ) -> [Int] {
        let occupied = deployedIDs(units: units, playerOwner: playerOwner, exceptUnitIndex: targetUnitIndex)
        return Array(Set(ownedCommanderIDs))
            .filter { $0 > 0 && (!occupied.contains($0) || include.contains($0)) }
            .sorted()
    }

    /// Rebuilds an immutable unit record while preserving damage taken exactly.
    public static func replacingCommander(_ unit: NativeBattleUnitState, commanderID: Int?, hpBonus: Int) -> NativeBattleUnitState {
        let oldBonus = max(0, unit.playerCommanderHPBonus)
        let baseMax = max(1, unit.maxHP - oldBonus)
        let damage = max(0, unit.maxHP - unit.hp)
        let newBonus = max(0, hpBonus)
        let newMax = baseMax + newBonus
        let newHP = max(0, min(newMax, newMax - damage))
        return NativeBattleUnitState(
            index: unit.index,
            armyID: unit.armyID,
            armyName: unit.armyName,
            grade: unit.grade,
            owner: unit.owner,
            commanderID: commanderID,
            q: unit.q,
            r: unit.r,
            hp: newHP,
            maxHP: newMax,
            moved: unit.moved,
            attacked: unit.attacked,
            embarked: unit.embarked,
            trainingLevel: unit.trainingLevel,
            trainingExp: unit.trainingExp,
            underConstruction: unit.underConstruction,
            constructionRoundsRemaining: unit.constructionRoundsRemaining,
            constructionTotalRounds: unit.constructionTotalRounds,
            playerCommanderHPBonus: newBonus,
            nativeMoraleBase: unit.nativeMoraleBase,
            nativeMoraleUntilRound: unit.nativeMoraleUntilRound
        )
    }

    /// Assigns only the requested player unit. A stale duplicate on another player
    /// unit is cleared, while enemy units carrying the same commander id are left alone.
    @discardableResult
    public static func assign(
        units: inout [Int: NativeBattleUnitState],
        targetUnitIndex: Int,
        commanderID: Int,
        playerOwner: Int,
        hpBonus: Int
    ) -> NativeGeneralDeploymentResult? {
        guard commanderID > 0,
              let target = units[targetUnitIndex],
              !target.dead,
              target.owner == playerOwner else { return nil }

        var cleared: [Int] = []
        for (index, unit) in units where index != targetUnitIndex && unit.owner == playerOwner && unit.commanderID == commanderID {
            units[index] = replacingCommander(unit, commanderID: nil, hpBonus: 0)
            cleared.append(index)
        }

        let replacement = replacingCommander(target, commanderID: commanderID, hpBonus: hpBonus)
        units[targetUnitIndex] = replacement
        return NativeGeneralDeploymentResult(
            targetUnitIndex: targetUnitIndex,
            commanderID: commanderID,
            clearedUnitIndices: cleared.sorted(),
            previousCommanderID: target.commanderID,
            previousHP: target.hp,
            previousMaxHP: target.maxHP,
            hp: replacement.hp,
            maxHP: replacement.maxHP
        )
    }
}
