import Foundation

public struct NativeConstructionLevelDefinition: Decodable, Equatable, Sendable {
    public let idx: Int
    public let image: String?
    public let tax: Int
    public let industry: Int
    public let food: Int
    public let supply: Int
    public let avoid: Int?
    public let recruit: [NativeRecruitDefinition]?
}

public struct NativeConstructionDefinition: Decodable, Equatable, Sendable {
    public let maxlevel: Int
    public let levels: [NativeConstructionLevelDefinition]
}

public typealias NativeConstructionCatalog = [String: NativeConstructionDefinition]

public struct NativeItemEffectDefinition: Decodable, Equatable, Sendable {
    public let name: String
    public let id: Int
    public let function: Int
    public let value: Int
    public let target: String?
    public let price: Int?
    public let flag: String?
    public let consumable: String?

    public init(name: String, id: Int, function: Int, value: Int, target: String? = nil, price: Int? = nil, flag: String? = nil, consumable: String? = nil) {
        self.name = name; self.id = id; self.function = function; self.value = value
        self.target = target; self.price = price; self.flag = flag; self.consumable = consumable
    }
}

public typealias NativeItemEffectCatalog = [String: NativeItemEffectDefinition]

public struct NativeRoundUnitContext: Equatable, Sendable {
    public let index: Int
    public let owner: Int
    public let q: Int
    public let r: Int
    public let armyName: String
    public let grade: Int
    public let commanderID: Int?
    public let commanderSkillIDs: Set<Int>
    public let equippedItemIDs: [Int]
    public let nobilityLevel: Int
    public let nobilityHealCap: Int
    public let trainingLevel: Int
    public let consumption: Int
    public let attacked: Bool
    public var hp: Int
    public let maxHP: Int

    public var dead: Bool { hp <= 0 }
    public var cell: HexCell { HexCell(q: q, r: r) }

    public init(
        index: Int,
        owner: Int,
        q: Int,
        r: Int,
        armyName: String,
        grade: Int,
        commanderID: Int? = nil,
        commanderSkillIDs: Set<Int> = [],
        equippedItemIDs: [Int] = [],
        nobilityLevel: Int = 0,
        nobilityHealCap: Int = 25,
        trainingLevel: Int = 0,
        consumption: Int,
        attacked: Bool = false,
        hp: Int,
        maxHP: Int
    ) {
        self.index = index
        self.owner = owner
        self.q = q
        self.r = r
        self.armyName = armyName
        self.grade = grade
        self.commanderID = commanderID
        self.commanderSkillIDs = commanderSkillIDs
        self.equippedItemIDs = equippedItemIDs
        self.nobilityLevel = nobilityLevel
        self.nobilityHealCap = nobilityHealCap
        self.trainingLevel = trainingLevel
        self.consumption = consumption
        self.attacked = attacked
        self.hp = hp
        self.maxHP = maxHP
    }
}

public struct NativeRoundObjectContext: Equatable, Sendable {
    public let index: Int
    public let owner: Int
    public let q: Int
    public let r: Int
    public let constructionType: String?
    public let level: Int

    public var cell: HexCell { HexCell(q: q, r: r) }

    public init(index: Int, owner: Int, q: Int, r: Int, constructionType: String?, level: Int) {
        self.index = index
        self.owner = owner
        self.q = q
        self.r = r
        self.constructionType = constructionType
        self.level = level
    }
}

public struct NativeCountryEconomySettlement: Equatable, Sendable {
    public let income: CountryResources
    public let foodCost: Int
    public let resources: CountryResources
}

public struct NativePlayerRoundSettlement: Equatable, Sendable {
    public let money: Int
    public let industry: Int
    public let foodAdd: Int
    public let foodDel: Int
    public let healed: Int
    public let trainingHealed: Int
    public let facilityHealed: Int
    public let playerSpecialHealed: Int
    public let resources: CountryResources
    public let units: [NativeRoundUnitContext]
}

public enum NativeRoundSettlementCore {
    public static let nobilityMaxLevel = 9

    public static func constructionLevel(
        object: NativeRoundObjectContext,
        constructions: NativeConstructionCatalog
    ) -> NativeConstructionLevelDefinition? {
        guard let type = object.constructionType,
              let definition = constructions[type],
              !definition.levels.isEmpty else {
            return nil
        }
        if let exact = definition.levels.first(where: { $0.idx == object.level }) {
            return exact
        }
        let index = max(0, min(definition.levels.count - 1, object.level))
        return definition.levels[index]
    }

    public static func itemFunctionValue(
        unit: NativeRoundUnitContext,
        function: Int,
        items: NativeItemEffectCatalog
    ) -> Int {
        unit.equippedItemIDs.reduce(0) { total, itemID in
            guard let item = items[String(itemID)], item.function == function else { return total }
            return total + item.value
        }
    }

    public static func facilityIncomeMultiplier(
        unit: NativeRoundUnitContext?,
        items: NativeItemEffectCatalog
    ) -> Double {
        guard let unit, !unit.dead, unit.commanderID != nil else { return 1.0 }
        var multiplier = 1.0
        if unit.commanderSkillIDs.contains(24) {
            multiplier = max(multiplier, 1.8)
        } else if unit.commanderSkillIDs.contains(23) {
            multiplier = max(multiplier, 1.4)
        }
        for itemID in unit.equippedItemIDs {
            guard let item = items[String(itemID)], item.function == 3 else { continue }
            multiplier = max(multiplier, Double(item.value) / 100.0)
        }
        return multiplier
    }

    public static func facilityIncome(
        owner: Int,
        units: [NativeRoundUnitContext],
        objects: [NativeRoundObjectContext],
        constructions: NativeConstructionCatalog,
        items: NativeItemEffectCatalog
    ) -> CountryResources {
        var money = 0
        var industry = 0
        var food = 0
        for object in objects where object.owner == owner {
            guard let level = constructionLevel(object: object, constructions: constructions) else { continue }
            let stationed = units.first { !$0.dead && $0.owner == owner && $0.q == object.q && $0.r == object.r }
            let multiplier = facilityIncomeMultiplier(unit: stationed, items: items)
            money += Int(floor(Double(level.tax) * multiplier))
            industry += Int(floor(Double(level.industry) * multiplier))
            food += Int(floor(Double(level.food) * multiplier))
        }
        return CountryResources(money: money, industry: industry, food: food)
    }

    public static func upkeep(owner: Int, units: [NativeRoundUnitContext]) -> Int {
        units.reduce(0) { total, unit in
            guard !unit.dead, unit.owner == owner else { return total }
            return total + (unit.commanderSkillIDs.contains(22) ? 0 : max(0, unit.consumption))
        }
    }

    public static func economicBonus(level: Int, kind: String) -> Int {
        let clamped = max(0, min(3, level))
        switch kind {
        case "money": return [0, 20, 40, 60][clamped]
        case "industry", "food": return [0, 10, 20, 30][clamped]
        default: return 0
        }
    }

    public static func settleCountryEconomy(
        owner: Int,
        resources: CountryResources,
        units: [NativeRoundUnitContext],
        objects: [NativeRoundObjectContext],
        constructions: NativeConstructionCatalog,
        items: NativeItemEffectCatalog,
        mode: BattleMode,
        playerOwner: Int,
        campaignTechLevels: [Int]? = nil
    ) -> NativeCountryEconomySettlement {
        var income = facilityIncome(owner: owner, units: units, objects: objects, constructions: constructions, items: items)
        let foodCost = upkeep(owner: owner, units: units)
        if mode == .campaign && owner == playerOwner {
            let levels = campaignTechLevels ?? []
            func tech(_ id: Int) -> Int { id < levels.count ? levels[id] : 0 }
            income.food += economicBonus(level: tech(22), kind: "food")
            income.money += economicBonus(level: tech(23), kind: "money")
            income.industry += economicBonus(level: tech(24), kind: "industry")
        }
        let settled = CountryResources(
            money: resources.money + income.money,
            industry: resources.industry + income.industry,
            food: max(0, resources.food + income.food - foodCost)
        )
        return NativeCountryEconomySettlement(income: income, foodCost: foodCost, resources: settled)
    }

    public static func facilitySupply(
        for unit: NativeRoundUnitContext,
        objects: [NativeRoundObjectContext],
        constructions: NativeConstructionCatalog
    ) -> Int {
        guard let object = objects.first(where: {
            $0.q == unit.q && $0.r == unit.r && $0.constructionType != nil
        }), object.owner == unit.owner,
        let level = constructionLevel(object: object, constructions: constructions) else {
            return 0
        }
        return max(0, level.supply)
    }

    public static func nobilityHeal(level: Int, cap: Int, maxLevel: Int = nobilityMaxLevel) -> Int {
        guard maxLevel > 0 else { return 0 }
        let clampedLevel = max(0, min(maxLevel, level))
        return Int((Double(max(0, cap) * clampedLevel) / Double(maxLevel)).rounded())
    }

    public static func auraValueAround(
        target: NativeRoundUnitContext,
        units: [NativeRoundUnitContext],
        function: Int,
        items: NativeItemEffectCatalog,
        relation: (Int, Int) -> CountryRelation
    ) -> Int {
        var total = 0
        for source in units {
            guard source.index != target.index,
                  !source.dead,
                  NativeHexGeometry.distance(source.cell, target.cell) == 1,
                  relation(source.owner, target.owner) == .ally else {
                continue
            }
            total += itemFunctionValue(unit: source, function: function, items: items)
        }
        return total
    }

    public static func applyTrainingRecoveryAll(_ units: inout [NativeRoundUnitContext]) -> Int {
        var total = 0
        for index in units.indices {
            guard !units[index].dead else { continue }
            let heal = NativeTrainingParityCore.row(units[index].trainingLevel).roundHeal
            guard heal > 0 else { continue }
            let before = max(0, units[index].hp)
            units[index].hp = min(max(0, units[index].maxHP), before + heal)
            total += units[index].hp - before
        }
        return total
    }

    public static func applyFacilitySupplyAll(
        _ units: inout [NativeRoundUnitContext],
        objects: [NativeRoundObjectContext],
        constructions: NativeConstructionCatalog
    ) -> [Int: Int] {
        var totals: [Int: Int] = [:]
        for index in units.indices {
            guard !units[index].dead, units[index].hp < units[index].maxHP else { continue }
            let supply = facilitySupply(for: units[index], objects: objects, constructions: constructions)
            guard supply > 0 else { continue }
            let before = units[index].hp
            units[index].hp = min(units[index].maxHP, units[index].hp + supply)
            let got = units[index].hp - before
            if got > 0 {
                totals[units[index].owner, default: 0] += got
            }
        }
        return totals
    }

    public static func applyPlayerSpecialRecovery(
        _ units: inout [NativeRoundUnitContext],
        playerOwner: Int,
        objects: [NativeRoundObjectContext],
        items: NativeItemEffectCatalog,
        relation: (Int, Int) -> CountryRelation
    ) -> Int {
        let snapshot = units
        var total = 0
        for index in units.indices {
            guard !units[index].dead,
                  units[index].owner == playerOwner,
                  units[index].hp < units[index].maxHP else {
                continue
            }
            let source = snapshot[index]
            let noble = source.commanderID == nil ? 0 : nobilityHeal(level: source.nobilityLevel, cap: source.nobilityHealCap)
            let flag = auraValueAround(target: source, units: snapshot, function: 13, items: items, relation: relation)
            let outside = !objects.contains { $0.q == source.q && $0.r == source.r && $0.constructionType != nil }
            let tent = (!source.attacked && outside) ? itemFunctionValue(unit: source, function: 5, items: items) : 0
            let heal = noble + flag + tent
            guard heal > 0 else { continue }
            let before = units[index].hp
            units[index].hp = min(units[index].maxHP, units[index].hp + heal)
            total += units[index].hp - before
        }
        return total
    }

    public static func settlePlayerRound(
        playerOwner: Int,
        resources: CountryResources,
        units inputUnits: [NativeRoundUnitContext],
        objects: [NativeRoundObjectContext],
        constructions: NativeConstructionCatalog,
        items: NativeItemEffectCatalog,
        mode: BattleMode,
        campaignTechLevels: [Int]? = nil,
        relation: (Int, Int) -> CountryRelation
    ) -> NativePlayerRoundSettlement {
        let economy = settleCountryEconomy(
            owner: playerOwner,
            resources: resources,
            units: inputUnits,
            objects: objects,
            constructions: constructions,
            items: items,
            mode: mode,
            playerOwner: playerOwner,
            campaignTechLevels: campaignTechLevels
        )
        var units = inputUnits
        let trainingHealed = applyTrainingRecoveryAll(&units)
        let supplyTotals = applyFacilitySupplyAll(&units, objects: objects, constructions: constructions)
        let facilityHealed = supplyTotals[playerOwner] ?? 0
        let playerSpecialHealed = applyPlayerSpecialRecovery(&units, playerOwner: playerOwner, objects: objects, items: items, relation: relation)
        return NativePlayerRoundSettlement(
            money: economy.income.money,
            industry: economy.income.industry,
            foodAdd: economy.income.food,
            foodDel: economy.foodCost,
            healed: trainingHealed + facilityHealed + playerSpecialHealed,
            trainingHealed: trainingHealed,
            facilityHealed: facilityHealed,
            playerSpecialHealed: playerSpecialHealed,
            resources: economy.resources,
            units: units
        )
    }
}
