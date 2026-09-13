import Foundation

public enum NativeBattleConsumableCore {
    public static let usableIDs: Set<Int> = [11, 12, 13, 14, 15]
    public static let spiritFunction = 6
    public static let wineFunction = 7
    public static let medicalFunction = 8

    public static func eventMorale(unit: NativeBattleUnitState, round: Int) -> Int {
        NativeBattleEnvironmentCore.eventMoraleBase(base: unit.nativeMoraleBase, untilRound: unit.nativeMoraleUntilRound, round: round)
    }

    public static func canUse(item: NativeItemEffectDefinition, unit: NativeBattleUnitState, round: Int) -> Bool {
        guard usableIDs.contains(item.id), !unit.dead else { return false }
        switch item.function {
        case medicalFunction: return unit.hp < unit.maxHP
        case spiritFunction: return eventMorale(unit: unit, round: round) <= 0
        case wineFunction: return eventMorale(unit: unit, round: round) < 0
        default: return false
        }
    }

    @discardableResult
    public static func apply(item: NativeItemEffectDefinition, unit: inout NativeBattleUnitState, round: Int) -> Bool {
        guard canUse(item: item, unit: unit, round: round) else { return false }
        switch item.function {
        case medicalFunction:
            unit.hp = min(unit.maxHP, unit.hp + max(0, item.value))
        case spiritFunction:
            unit.nativeMoraleBase = 1
            unit.nativeMoraleUntilRound = max(1, round) + 3
        case wineFunction:
            unit.nativeMoraleBase = 0
            unit.nativeMoraleUntilRound = max(1, round) + 3
        default:
            return false
        }
        unit.moved = true
        unit.attacked = true
        return true
    }
}
