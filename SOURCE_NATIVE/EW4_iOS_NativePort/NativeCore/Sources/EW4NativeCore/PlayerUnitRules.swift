import Foundation

public enum PlayerUnitRules {
    public static let baseHPBonus = 120
    public static let movementBonus = 2

    public static func effectiveBaseHP(strength: Int, isPlayer: Bool) -> Int {
        max(1, strength) + (isPlayer ? baseHPBonus : 0)
    }

    public static func effectiveMovement(_ movement: Int, type: String, isPlayer: Bool) -> Int {
        max(0, movement) + (isPlayer && type != "fort" ? movementBonus : 0)
    }

    public static func migratedHP(hp: Int, maxHP: Int, previousAppliedBonus: Int?, isPlayer: Bool) -> (hp: Int, maxHP: Int, appliedBonus: Int?) {
        guard isPlayer else { return (hp, maxHP, previousAppliedBonus) }
        let previous = max(0, previousAppliedBonus ?? 0)
        let delta = baseHPBonus - previous
        let newMax = max(1, maxHP + delta)
        let newHP = min(newMax, max(0, hp + delta))
        return (newHP, newMax, baseHPBonus)
    }
}
