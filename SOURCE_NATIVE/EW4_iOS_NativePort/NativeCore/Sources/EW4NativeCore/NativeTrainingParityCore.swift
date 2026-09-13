import Foundation

public struct NativeTrainingLevelRow: Equatable, Sendable {
    public let level: Int
    public let defense: Int
    public let roundHeal: Int
    public let levelUpHeal: Int
    public let baseExp: Int

    public init(level: Int, defense: Int, roundHeal: Int, levelUpHeal: Int, baseExp: Int) {
        self.level = level
        self.defense = defense
        self.roundHeal = roundHeal
        self.levelUpHeal = levelUpHeal
        self.baseExp = baseExp
    }
}

public struct NativeTrainingUnitState: Equatable, Sendable {
    public var trainingLevel: Int
    public var trainingExp: Int
    public var hp: Int
    public var maxHP: Int
    public var dead: Bool
    public var commanderID: Int?

    public init(trainingLevel: Int, trainingExp: Int = 0, hp: Int, maxHP: Int, dead: Bool = false, commanderID: Int? = nil) {
        self.trainingLevel = trainingLevel
        self.trainingExp = trainingExp
        self.hp = hp
        self.maxHP = maxHP
        self.dead = dead
        self.commanderID = commanderID
    }
}

public struct NativeTrainingActionResult: Equatable, Sendable {
    public let ok: Bool
    public let reason: String?
    public let moneyCost: Int
    public let industryCost: Int
    public let foodCost: Int
    public let before: Int?
    public let after: Int?
    public let heal: Int
    public let defense: Int?
    public let roundHeal: Int?

    public init(ok: Bool, reason: String? = nil, moneyCost: Int = 0, industryCost: Int = 0, foodCost: Int = 0, before: Int? = nil, after: Int? = nil, heal: Int = 0, defense: Int? = nil, roundHeal: Int? = nil) {
        self.ok = ok
        self.reason = reason
        self.moneyCost = moneyCost
        self.industryCost = industryCost
        self.foodCost = foodCost
        self.before = before
        self.after = after
        self.heal = heal
        self.defense = defense
        self.roundHeal = roundHeal
    }
}

public struct NativeTrainingExpResult: Equatable, Sendable {
    public let awarded: Int
    public let leveled: Bool
    public let need: Int?
    public let exp: Int
    public let before: Int?
    public let after: Int?
    public let heal: Int

    public init(awarded: Int, leveled: Bool, need: Int?, exp: Int, before: Int? = nil, after: Int? = nil, heal: Int = 0) {
        self.awarded = awarded
        self.leveled = leveled
        self.need = need
        self.exp = exp
        self.before = before
        self.after = after
        self.heal = heal
    }
}

public enum NativeTrainingParityCore {
    public static let maxLevel = 5
    public static let levels: [NativeTrainingLevelRow] = [
        .init(level: 0, defense: 0, roundHeal: 0, levelUpHeal: 0, baseExp: 0),
        .init(level: 1, defense: 2, roundHeal: 2, levelUpHeal: 10, baseExp: 100),
        .init(level: 2, defense: 4, roundHeal: 3, levelUpHeal: 20, baseExp: 150),
        .init(level: 3, defense: 6, roundHeal: 4, levelUpHeal: 30, baseExp: 220),
        .init(level: 4, defense: 8, roundHeal: 5, levelUpHeal: 40, baseExp: 300),
        .init(level: 5, defense: 10, roundHeal: 6, levelUpHeal: 50, baseExp: 400)
    ]
    public static let goldCost = [30, 45, 70, 105, 160]

    public static func level(_ value: Int) -> Int {
        max(0, min(maxLevel, value))
    }

    public static func row(_ value: Int) -> NativeTrainingLevelRow {
        levels[level(value)]
    }

    public static func canManualTrain(unit: NativeTrainingUnitState, commanderTraining: Int?) -> Bool {
        guard !unit.dead, let commanderTraining else { return false }
        let current = level(unit.trainingLevel)
        return current < maxLevel && max(0, commanderTraining) > current
    }

    public static func manualCost(unit: NativeTrainingUnitState, consumption: Int) -> CountryResources? {
        let current = level(unit.trainingLevel)
        guard current < maxLevel else { return nil }
        return CountryResources(money: goldCost[current], industry: 0, food: max(0, consumption) * 3)
    }

    public static func canAfford(resources: CountryResources, cost: CountryResources?) -> Bool {
        guard let cost else { return false }
        return resources.money >= cost.money && resources.industry >= cost.industry && resources.food >= cost.food
    }

    @discardableResult
    public static func levelUp(_ unit: inout NativeTrainingUnitState) -> NativeTrainingActionResult? {
        let before = level(unit.trainingLevel)
        guard before < maxLevel else { return nil }
        let after = before + 1
        let levelRow = levels[after]
        let oldHP = max(0, unit.hp)
        unit.trainingLevel = after
        unit.hp = min(max(0, unit.maxHP), oldHP + levelRow.levelUpHeal)
        return NativeTrainingActionResult(
            ok: true,
            before: before,
            after: after,
            heal: unit.hp - oldHP,
            defense: levelRow.defense,
            roundHeal: levelRow.roundHeal
        )
    }

    public static func manualTrain(
        unit: inout NativeTrainingUnitState,
        commanderTraining: Int?,
        consumption: Int,
        resources: inout CountryResources
    ) -> NativeTrainingActionResult {
        guard canManualTrain(unit: unit, commanderTraining: commanderTraining) else {
            return NativeTrainingActionResult(ok: false, reason: "ineligible")
        }
        guard let cost = manualCost(unit: unit, consumption: consumption) else {
            return NativeTrainingActionResult(ok: false, reason: "ineligible")
        }
        guard canAfford(resources: resources, cost: cost) else {
            return NativeTrainingActionResult(
                ok: false,
                reason: "resources",
                moneyCost: cost.money,
                industryCost: cost.industry,
                foodCost: cost.food
            )
        }
        resources.money -= cost.money
        resources.industry -= cost.industry
        resources.food -= cost.food
        let result = levelUp(&unit)!
        return NativeTrainingActionResult(
            ok: true,
            moneyCost: cost.money,
            industryCost: cost.industry,
            foodCost: cost.food,
            before: result.before,
            after: result.after,
            heal: result.heal,
            defense: result.defense,
            roundHeal: result.roundHeal
        )
    }

    public static func defenseBonus(_ unit: NativeTrainingUnitState) -> Int {
        row(unit.trainingLevel).defense
    }

    public static func roundHeal(_ unit: NativeTrainingUnitState) -> Int {
        row(unit.trainingLevel).roundHeal
    }

    public static func levelUpHealFor(_ levelAfter: Int) -> Int {
        row(levelAfter).levelUpHeal
    }

    public static func baseExpForLevel(_ value: Int) -> Int {
        row(value).baseExp
    }

    public static func nextExpThreshold(
        unit: NativeTrainingUnitState,
        hasCommander: Bool? = nil,
        unitType: String? = nil
    ) -> Int? {
        let current = level(unit.trainingLevel)
        guard current < maxLevel else { return nil }
        var need = levels[current + 1].baseExp
        if hasCommander ?? (unit.commanderID != nil) {
            need = Int(Double(need) * 1.5)
        }
        if unitType == "warship" {
            need *= 2
        }
        return need
    }

    public static func awardExp(
        unit: inout NativeTrainingUnitState,
        amount: Int,
        hasCommander: Bool? = nil,
        unitType: String? = nil
    ) -> NativeTrainingExpResult {
        let awarded = max(0, amount)
        unit.trainingExp = max(0, unit.trainingExp) + awarded
        let need = nextExpThreshold(unit: unit, hasCommander: hasCommander, unitType: unitType)
        guard let need, unit.trainingExp >= need else {
            return NativeTrainingExpResult(awarded: awarded, leveled: false, need: need, exp: unit.trainingExp)
        }
        unit.trainingExp -= need
        let up = levelUp(&unit)
        return NativeTrainingExpResult(
            awarded: awarded,
            leveled: up != nil,
            need: need,
            exp: unit.trainingExp,
            before: up?.before,
            after: up?.after,
            heal: up?.heal ?? 0
        )
    }

    @discardableResult
    public static func applyRoundHeal(_ unit: inout NativeTrainingUnitState) -> Int {
        guard !unit.dead else { return 0 }
        let heal = roundHeal(unit)
        guard heal > 0 else { return 0 }
        let before = max(0, unit.hp)
        unit.hp = min(max(0, unit.maxHP), before + heal)
        return unit.hp - before
    }
}
