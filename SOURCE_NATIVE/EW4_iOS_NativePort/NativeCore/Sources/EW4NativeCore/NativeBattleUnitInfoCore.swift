import Foundation

public struct NativeBattleUnitInfoModel: Equatable, Sendable {
    public let armyName: String
    public let displayName: String
    public let description: String
    public let grade: Int
    public let hp: Int
    public let maxHP: Int
    public let attackMin: Int
    public let attackMax: Int
    public let consumption: Int
    public let minRange: Int
    public let maxRange: Int
    public let movement: Int
    public let moneyCost: Int
    public let industryCost: Int
    public let commanderID: Int?
    public let commanderName: String?

    public var formationCount: Int { max(1, min(3, grade + 1)) }

    public init(
        armyName: String, displayName: String, description: String,
        grade: Int, hp: Int, maxHP: Int,
        attackMin: Int, attackMax: Int, consumption: Int,
        minRange: Int, maxRange: Int, movement: Int,
        moneyCost: Int, industryCost: Int,
        commanderID: Int?, commanderName: String?
    ) {
        self.armyName = armyName
        self.displayName = displayName
        self.description = description
        self.grade = grade
        self.hp = hp
        self.maxHP = maxHP
        self.attackMin = attackMin
        self.attackMax = attackMax
        self.consumption = consumption
        self.minRange = minRange
        self.maxRange = maxRange
        self.movement = movement
        self.moneyCost = moneyCost
        self.industryCost = industryCost
        self.commanderID = commanderID
        self.commanderName = commanderName
    }
}

public enum NativeBattleUnitInfoCore {
    public static func model(
        unit: NativeBattleUnitState,
        stat: ArmyStatDefinition,
        effectiveCommander: NativeEffectiveCommander?,
        movement: Int,
        moneyCost: Int,
        industryCost: Int,
        isPlayer: Bool,
        commanderName: String?,
        strings: [String: String]
    ) -> NativeBattleUnitInfoModel {
        let commander = effectiveCommander?.combatCommander
        let intervalBonus = CombatCore.skillIntervalBonus(commander, statType: stat.type)
        let interval = CombatCore.effectiveAttackInterval(
            min: stat.minatk,
            max: stat.maxatk,
            isPlayer: isPlayer,
            lowerBonus: intervalBonus.lower,
            upperBonus: intervalBonus.upper
        )
        return NativeBattleUnitInfoModel(
            armyName: unit.armyName,
            displayName: strings["name_\(unit.armyName)"] ?? unit.armyName,
            description: strings["desc_\(unit.armyName)"] ?? "",
            grade: unit.grade,
            hp: max(0, unit.hp),
            maxHP: max(1, unit.maxHP),
            attackMin: interval.min,
            attackMax: interval.max,
            consumption: stat.consumption,
            minRange: stat.minatkrange,
            maxRange: stat.maxatkrange,
            movement: max(0, movement),
            moneyCost: max(0, moneyCost),
            industryCost: max(0, industryCost),
            commanderID: unit.commanderID,
            commanderName: commanderName
        )
    }
}
