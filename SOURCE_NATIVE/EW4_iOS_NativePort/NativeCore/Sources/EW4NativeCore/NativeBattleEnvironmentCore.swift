import Foundation

public struct NativeInstallationDefinition: Decodable, Equatable, Sendable {
    public let type: String
    public let image: String?
    public let penaltyInfantry: Int?
    public let penaltyCavalry: Int?
    public let penaltyArtillery: Int?
    public let penaltyWarship: Int?
    public let penaltyFort: Int?

    enum CodingKeys: String, CodingKey {
        case type, image
        case penaltyInfantry = "penalty_infantry"
        case penaltyCavalry = "penalty_cavalry"
        case penaltyArtillery = "penalty_artillery"
        case penaltyWarship = "penalty_warship"
        case penaltyFort = "penalty_fort"
    }

    public func penalty(against attackerType: String) -> Int {
        switch attackerType {
        case "infantry": return max(0, penaltyInfantry ?? 0)
        case "cavalry": return max(0, penaltyCavalry ?? 0)
        case "artillery": return max(0, penaltyArtillery ?? 0)
        case "warship": return max(0, penaltyWarship ?? 0)
        case "fort": return max(0, penaltyFort ?? 0)
        default: return 0
        }
    }
}

public typealias NativeInstallationCatalog = [String: NativeInstallationDefinition]

public struct NativeBattleInstallationState: Equatable, Sendable {
    public let q: Int
    public let r: Int
    public let type: String
    public let owner: Int

    public init(q: Int, r: Int, type: String, owner: Int) {
        self.q = q
        self.r = r
        self.type = type
        self.owner = owner
    }

    public var cell: HexCell { HexCell(q: q, r: r) }
}

public enum NativeBattleEnvironmentCore {
    public static func eventMoraleBase(base: Int, untilRound: Int, round: Int) -> Int {
        guard untilRound > round else { return 0 }
        return max(-3, min(1, base))
    }

    public static func combinedMorale(eventBase: Int, flankPenalty: Int, leadership: Bool) -> Int {
        var morale = max(-3, min(1, eventBase + flankPenalty))
        if leadership && morale < 0 { morale = 0 }
        return morale
    }

    public static func flankPenalty(
        defender: NativeBattleUnitState,
        units: [Int: NativeBattleUnitState],
        relation: (Int, Int) -> CountryRelation
    ) -> Int {
        let hostile = NativeHexGeometry.neighbors(of: defender.cell).map { neighbor -> Bool in
            units.values.contains {
                !$0.dead && $0.cell == neighbor && relation(defender.owner, $0.owner) == .hostile
            }
        }
        if hostile.allSatisfy({ $0 }) { return -2 }
        if (hostile[0] && hostile[3]) || (hostile[1] && hostile[4]) || (hostile[2] && hostile[5]) { return -1 }
        return 0
    }

    public static func terrainReduction(
        attackerType: String,
        defenderCell: HexCell,
        world: WorldDefinition,
        terrainTypes: [String: TerrainTypeDefinition]
    ) -> Int {
        guard defenderCell.q >= 0, defenderCell.r >= 0,
              defenderCell.q < world.width, defenderCell.r < world.height else { return 0 }
        let index = defenderCell.r * world.width + defenderCell.q
        guard world.cells.indices.contains(index) else { return 0 }
        let terrainType = world.cells[index].type
        return terrainTypes[terrainType]?.penalty(against: attackerType) ?? 0
    }

    public static func installationReduction(
        attackerType: String,
        defenderCell: HexCell,
        installations: [NativeBattleInstallationState],
        catalog: NativeInstallationCatalog
    ) -> Int {
        guard let installation = installations.first(where: { $0.cell == defenderCell }),
              let definition = catalog[installation.type] else { return 0 }
        return definition.penalty(against: attackerType)
    }

    public static func buildingReduction(
        defenderCell: HexCell,
        objects: [Int: NativeBattleObjectState],
        constructions: NativeConstructionCatalog
    ) -> (value: Int, hasConstruction: Bool) {
        guard let object = objects.values.first(where: { $0.cell == defenderCell && $0.constructionType != nil }) else {
            return (0, false)
        }
        guard let type = object.constructionType,
              let definition = constructions[type],
              !definition.levels.isEmpty else {
            return (0, true)
        }
        let level = definition.levels.first(where: { $0.idx == object.level })
            ?? definition.levels[max(0, min(definition.levels.count - 1, object.level))]
        return (max(0, level.avoid ?? 0), true)
    }
}
