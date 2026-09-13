import Foundation

public struct WorldMapsFile: Decodable, Sendable {
    public let terrains: [TerrainDefinition]
    public let terrainTypes: [String: TerrainTypeDefinition]
    public let worlds: [String: WorldDefinition]
    enum CodingKeys: String, CodingKey { case terrains, terrainTypes = "terrain_types", worlds }
}
public struct TerrainDefinition: Decodable, Sendable { public let id: Int; public let name: String; public let type: String }
public struct TerrainTypeDefinition: Decodable, Equatable, Sendable {
    public let type: String
    public let movementcost: Int?
    public let penaltyInfantry: Int?
    public let penaltyCavalry: Int?
    public let penaltyArtillery: Int?
    public let penaltyWarship: Int?
    public let penaltyFort: Int?
    enum CodingKeys: String, CodingKey {
        case type, movementcost
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
public struct WorldDefinition: Decodable, Sendable {
    public let mapID: Int; public let width: Int; public let height: Int; public let magic: String; public let version: Int; public let cells: [WorldCell]
    enum CodingKeys: String, CodingKey { case mapID = "map_id", width, height, magic, version, cells }
}
public struct WorldCell: Decodable, Sendable {
    public let terrainID: Int; public let variant: Int; public let type: String
    enum CodingKeys: String, CodingKey { case terrainID = "terrain_id", variant, type }
}

public struct BattlesRuntimeFile: Decodable, Sendable {
    public let format: String; public let count: Int; public let battles: [BattleRecord]
}
public struct BattleRecord: Decodable, Sendable {
    public let file: String
    public let nameKey: String
    public let nameCN: String
    public let titleCN: String
    public let descCN: String?
    public let meta: BattleMeta?
    public let header: BattleHeader
    public let countries: [BattleCountry]
    public let relationGroups: [String: Int]?
    public let units: [BattleUnit]
    public let objects: [BattleObject]
    public let ownership: [Int]?
    public let playerOwnerDefault: Int?
    public let ownerIndexBias: Int?

    enum CodingKeys: String, CodingKey {
        case file
        case nameKey = "name_key"
        case nameCN = "name_cn"
        case titleCN = "title_cn"
        case descCN = "desc_cn"
        case meta
        case header
        case countries
        case relationGroups = "relation_groups"
        case units
        case objects
        case ownership
        case playerOwnerDefault = "player_owner_default"
        case ownerIndexBias = "owner_index_bias"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        file = try container.decode(String.self, forKey: .file)
        nameKey = try container.decode(String.self, forKey: .nameKey)
        nameCN = try container.decode(String.self, forKey: .nameCN)
        titleCN = try container.decode(String.self, forKey: .titleCN)
        descCN = try container.decodeIfPresent(String.self, forKey: .descCN)
        meta = try container.decodeIfPresent(BattleMeta.self, forKey: .meta)
        header = try container.decode(BattleHeader.self, forKey: .header)
        countries = try container.decode([BattleCountry].self, forKey: .countries)
        units = try container.decode([BattleUnit].self, forKey: .units)
        objects = try container.decode([BattleObject].self, forKey: .objects)
        ownership = try container.decodeIfPresent([Int].self, forKey: .ownership)
        playerOwnerDefault = try container.decodeIfPresent(Int.self, forKey: .playerOwnerDefault)
        ownerIndexBias = try container.decodeIfPresent(Int.self, forKey: .ownerIndexBias)

        let rawGroups = try container.decodeIfPresent([String: Int?].self, forKey: .relationGroups)
        relationGroups = rawGroups?.compactMapValues { $0 }
    }
}

public struct BattleMeta: Decodable, Sendable {
    public let name: String?
    public let file: String?
    public let file2: String?
    public let pairedFrom: String?
    public let countries: String?
    public let map: String?
    public let hide: String?
    public let commander: String?
    public let centerx: String?
    public let centery: String?
    public let age: String?

    enum CodingKeys: String, CodingKey {
        case name, file, file2, countries, map, hide, commander, centerx, centery, age
        case pairedFrom = "paired_from"
    }
}

public struct BattleCountry: Decodable, Sendable {
    public let index: Int
    public let code: String
    public let nameCN: String?
    public let relationHint: Int?
    public let rawResources: [UInt64]?
    enum CodingKeys: String, CodingKey { case index, code, nameCN = "name_cn", relationHint = "relation_hint", rawResources = "raw_u32_36_180" }
}

public struct BattleHeader: Decodable, Sendable {
    public let version: Int; public let mapID: Int; public let originX: Int; public let originY: Int; public let width: Int; public let height: Int; public let countryCount: Int; public let objectCount: Int; public let unitCount: Int; public let raw: [UInt64]?
    enum CodingKeys: String, CodingKey { case version, mapID = "map_id", originX = "origin_x", originY = "origin_y", width, height, countryCount = "country_count", objectCount = "object_count", unitCount = "unit_count", raw }
}
public struct BattleUnit: Decodable, Sendable {
    public let index: Int; public let q: Int; public let r: Int; public let armyID: Int; public let armyName: String; public let grade: Int; public let hp: Int; public let maxHP: Int; public let commanderID: Int?; public let owner: Int; public let raw: [Int]?
    enum CodingKeys: String, CodingKey { case index, q, r, armyID = "army_id", armyName = "army_name", grade, hp, maxHP = "max_hp", commanderID = "commander_id", owner, raw }

    public init(index: Int, q: Int, r: Int, armyID: Int, armyName: String, grade: Int, hp: Int, maxHP: Int, commanderID: Int?, owner: Int, raw: [Int]? = nil) {
        self.index = index; self.q = q; self.r = r; self.armyID = armyID; self.armyName = armyName; self.grade = grade; self.hp = hp; self.maxHP = maxHP; self.commanderID = commanderID; self.owner = owner; self.raw = raw
    }
}
public struct BattleObject: Decodable, Sendable {
    public let index: Int; public let q: Int; public let r: Int; public let constructionID: Int; public let constructionType: String?; public let level: Int; public let extra: Int; public let owner: Int
    enum CodingKeys: String, CodingKey { case index, q, r, constructionID = "construction_id", constructionType = "construction_type", level, extra, owner }
}

public struct NativeAnimationManifest: Decodable, Sendable {
    public let format: String; public let unitCount: Int; public let uniqueAssetCount: Int; public let fps: Int; public let units: [String: NativeAnimationUnit]; public let assets: [String: NativeAnimationAsset]; public let motionCount: Int
    enum CodingKeys: String, CodingKey { case format, unitCount = "unit_count", uniqueAssetCount = "unique_asset_count", fps, units, assets, motionCount = "motion_count" }
}
public struct NativeAnchor: Decodable, Equatable, Sendable { public let x: Double; public let y: Double }
public struct NativeAnimationUnit: Decodable, Sendable { public let resource: String; public let nativeAnchor: NativeAnchor; public let dir: String?; public let motions: [NativeMotionRef]; enum CodingKeys: String, CodingKey { case resource, nativeAnchor = "native_anchor", dir, motions } }
public struct NativeMotionRef: Decodable, Sendable { public let type: String; public let index: Int; public let direction: String; public let asset: String; public let speed: Double; public let effect: String? }
public struct NativeAnimationAsset: Decodable, Sendable {
    public let resource: String; public let motionName: String; public let motionType: String; public let motionIndex: Int; public let direction: String; public let frameCount: Int; public let fps: Int; public let motionSpeedAttr: Double; public let representativeUnit: String; public let compactOnly: Bool
    enum CodingKeys: String, CodingKey { case resource, motionName = "motion_name", motionType = "motion_type", motionIndex = "motion_index", direction, frameCount = "frame_count", fps, motionSpeedAttr = "motion_speed_attr", representativeUnit = "representative_unit", compactOnly = "compact_only" }
}

public struct Commander: Decodable, Sendable {
    public let id: Int
    public let name: String
    public let country: String
    public let rank: Int
    public let nobilityrank: Int
    public let star: Int
    public let infantry: Int
    public let cavalry: Int
    public let artillery: Int
    public let warship: Int
    public let fort: Int
    public let business: Int
    public let movement: Int
    public let training: Int
    public let skill1: Int?
    public let skill2: Int?
    public let skill3: Int?
    public let skill4: Int?
    public let item1: Int?
    public let item2: Int?
    public let price: Int?
    public let drawlots: Int?

    public var skillIDs: Set<Int> {
        Set([skill1, skill2, skill3, skill4].compactMap { value in
            guard let value, value >= 0 else { return nil }
            return value
        })
    }
}

public struct ArmyStatDefinition: Decodable, Equatable, Sendable {
    public let name: String
    public let grade: Int
    public let type: String
    public let strength: Int
    public let movement: Int
    public let minatk: Int
    public let maxatk: Int
    public let weapon: String
    public let minatkrange: Int
    public let maxatkrange: Int
    public let consumption: Int
}

public typealias ArmyStatsCatalog = [String: [String: ArmyStatDefinition]]

public enum ResourceLoader {
    public static func decode<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }
}


public struct SpriteManifestEntry: Decodable, Sendable {
    public let file: String
    public let w: Double
    public let h: Double
    public let refx: Double
    public let refy: Double
    public let atlas: String?
}
