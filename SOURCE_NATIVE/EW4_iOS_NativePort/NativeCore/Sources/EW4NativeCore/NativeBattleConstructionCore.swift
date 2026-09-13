import Foundation

public struct NativeRecruitDefinition: Decodable, Equatable, Sendable {
    public let name: String
    public let grade: Int

    enum CodingKeys: String, CodingKey { case name, grade }

    public init(name: String, grade: Int) { self.name = name; self.grade = max(0, grade) }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        if let value = try? c.decode(Int.self, forKey: .grade) { grade = max(0, value) }
        else { grade = max(0, Int((try? c.decode(String.self, forKey: .grade)) ?? "0") ?? 0) }
    }
}

public struct NativeRecruitCardDefinition: Decodable, Equatable, Sendable {
    public let id: Int
    public let army: String
    public let grade: Int
    public let price: Int
    public let industry: Int
    public let image: String?
    public let intro: String?
}
public typealias NativeRecruitCardCatalog = [String: NativeRecruitCardDefinition]

public struct NativeBuildCardDefinition: Decodable, Equatable, Sendable {
    public let name: String
    public let id: Int
    public let type: String
    public let price: Int
    public let industry: Int
    public let army: String?
    public let grade: Int
    public let buildround: Int?
    public let image: String?
    public let intro: String?

    enum CodingKeys: String, CodingKey { case name, id, type, price, industry, army, grade, buildround, image, intro }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decode(String.self, forKey: .name)
        id = try c.decode(Int.self, forKey: .id)
        type = try c.decode(String.self, forKey: .type)
        price = try c.decode(Int.self, forKey: .price)
        industry = try c.decode(Int.self, forKey: .industry)
        army = try c.decodeIfPresent(String.self, forKey: .army)
        if let value = try? c.decode(Int.self, forKey: .grade) { grade = max(0, value) }
        else { grade = max(0, Int((try? c.decode(String.self, forKey: .grade)) ?? "0") ?? 0) }
        buildround = try c.decodeIfPresent(Int.self, forKey: .buildround)
        image = try c.decodeIfPresent(String.self, forKey: .image)
        intro = try c.decodeIfPresent(String.self, forKey: .intro)
    }
}
public typealias NativeBuildCardCatalog = [String: NativeBuildCardDefinition]

public struct NativeConstructionUpgradeCost: Equatable, Sendable {
    public let money: Int
    public let industry: Int
    public let discounted: Bool
}

public enum NativeBattleConstructionCore {
    public static let baseUpgradeCosts: [String: (money: Int, industry: Int)] = [
        "city": (65, 0), "industry": (60, 20), "stable": (80, 5), "port": (75, 10), "farmland": (40, 0)
    ]

    public static func upgradeCost(type: String?, architecture: Bool) -> NativeConstructionUpgradeCost? {
        guard let type, let base = baseUpgradeCosts[type.lowercased()] else { return nil }
        let money = architecture ? base.money * 3 / 5 : base.money
        let industry = architecture ? base.industry * 3 / 5 : base.industry
        return .init(money: money, industry: industry, discounted: architecture)
    }

    public static func canUpgrade(object: NativeBattleObjectState, constructions: NativeConstructionCatalog) -> Bool {
        guard let type = object.constructionType?.lowercased(), let def = constructions[type] else { return false }
        return object.level < def.maxlevel
    }

    @discardableResult
    public static func upgrade(
        object: inout NativeBattleObjectState,
        resources: inout CountryResources,
        constructions: NativeConstructionCatalog,
        architecture: Bool
    ) -> NativeConstructionUpgradeCost? {
        guard canUpgrade(object: object, constructions: constructions),
              let cost = upgradeCost(type: object.constructionType, architecture: architecture),
              resources.money >= cost.money, resources.industry >= cost.industry else { return nil }
        resources.money -= cost.money
        resources.industry -= cost.industry
        object.level += 1
        return cost
    }

    public static func recruitDefinitions(object: NativeBattleObjectState, constructions: NativeConstructionCatalog) -> [NativeRecruitDefinition] {
        guard let type = object.constructionType?.lowercased(), let def = constructions[type], !def.levels.isEmpty else { return [] }
        let row = def.levels.first(where: { $0.idx == object.level }) ?? def.levels[max(0, min(def.levels.count - 1, object.level))]
        return row.recruit ?? []
    }

    public static func card(_ recruit: NativeRecruitDefinition, grade: Int, cards: NativeRecruitCardCatalog) -> NativeRecruitCardDefinition? {
        let clamped = max(0, min(recruit.grade, grade))
        return cards["\(recruit.name)|\(clamped)"]
    }
}
