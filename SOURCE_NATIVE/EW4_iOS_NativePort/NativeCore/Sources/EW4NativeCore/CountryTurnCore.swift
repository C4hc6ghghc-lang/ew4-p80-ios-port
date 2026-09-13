import Foundation

public struct CountryResources: Equatable, Codable, Sendable {
    public var money: Int
    public var industry: Int
    public var food: Int

    public init(money: Int, industry: Int, food: Int) {
        self.money = money
        self.industry = industry
        self.food = food
    }
}

public enum BattleMode: String, Sendable {
    case campaign
    case conquest
    case tutorial
}

public enum CountryRelation: String, Sendable {
    case ally
    case hostile
    case neutral
}

public enum CountryTurnCore {
    public static let sentinel: UInt64 = 0xffff_ffff

    public static func cleanResource(_ value: UInt64?, fallback: Int = 0) -> Int {
        guard let value,
              value != sentinel,
              value <= 10_000_000 else {
            return max(0, fallback)
        }
        return Int(value)
    }

    public static func headerResources(_ battle: BattleRecord) -> CountryResources {
        let raw = battle.header.raw ?? []
        func value(at index: Int) -> UInt64? {
            index < raw.count ? raw[index] : nil
        }

        return CountryResources(
            money: cleanResource(value(at: 18), fallback: 800),
            industry: cleanResource(value(at: 19), fallback: 300),
            food: cleanResource(value(at: 20), fallback: 500)
        )
    }

    public static func countryResources(
        _ country: BattleCountry,
        fallback: CountryResources = CountryResources(money: 0, industry: 0, food: 0)
    ) -> CountryResources {
        let raw = country.rawResources ?? []
        func value(at index: Int) -> UInt64? {
            index < raw.count ? raw[index] : nil
        }

        return CountryResources(
            money: cleanResource(value(at: 30), fallback: fallback.money),
            industry: cleanResource(value(at: 31), fallback: fallback.industry),
            food: cleanResource(value(at: 32), fallback: fallback.food)
        )
    }

    public static func buildLedgers(
        _ battle: BattleRecord,
        mode: BattleMode = .campaign,
        playerOwner: Int = 0,
        restored: [Int: CountryResources]? = nil
    ) -> [Int: CountryResources] {
        if let restored {
            return restored.mapValues {
                CountryResources(
                    money: max(0, $0.money),
                    industry: max(0, $0.industry),
                    food: max(0, $0.food)
                )
            }
        }

        let header = headerResources(battle)
        var ledgers: [Int: CountryResources] = [:]

        for country in battle.countries {
            ledgers[country.index] = countryResources(
                country,
                fallback: CountryResources(money: 0, industry: 0, food: header.food)
            )
        }

        if mode != .conquest {
            ledgers[playerOwner] = header
        }

        return ledgers
    }

    public static func hint(_ battle: BattleRecord, owner: Int?) -> Int? {
        guard let owner, owner != 255 else {
            return 4
        }

        if let group = battle.relationGroups?[String(owner)] {
            return group
        }

        return battle.countries.first(where: { $0.index == owner })?.relationHint
    }

    public static func relation(
        _ battle: BattleRecord,
        _ a: Int,
        _ b: Int,
        mode: BattleMode = .campaign,
        playerOwner: Int = 0
    ) -> CountryRelation {
        if a == b {
            return .ally
        }

        if a == 255 || b == 255 {
            return .neutral
        }

        if mode != .conquest {
            return (a == playerOwner || b == playerOwner) ? .hostile : .ally
        }

        let aHint = hint(battle, owner: a)
        let bHint = hint(battle, owner: b)

        if aHint == 4 || bHint == 4 {
            return .neutral
        }

        if let aHint,
           let bHint,
           (aHint == 1 || aHint == 2),
           (bHint == 1 || bHint == 2) {
            return aHint == bHint ? .ally : .hostile
        }

        return .hostile
    }

    public static func aiTurnOrder(
        _ battle: BattleRecord,
        livingOwners: Set<Int>,
        playerOwner: Int,
        mode: BattleMode = .campaign
    ) -> [Int] {
        var order: [Int] = []

        // Preserve the authored country order from the BTL record first.
        for country in battle.countries {
            let owner = country.index
            if owner == playerOwner || !livingOwners.contains(owner) {
                continue
            }
            if mode == .conquest && hint(battle, owner: owner) == 4 {
                continue
            }
            order.append(owner)
        }

        // Keep any live owner omitted from the country table deterministic.
        for owner in livingOwners.sorted() {
            if owner == playerOwner || order.contains(owner) {
                continue
            }
            if mode == .conquest && hint(battle, owner: owner) == 4 {
                continue
            }
            order.append(owner)
        }

        return order
    }
}
