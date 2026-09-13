import Foundation

public enum NativeJSONValue: Codable, Equatable, Sendable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([NativeJSONValue])
    case object([String: NativeJSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null; return }
        if let value = try? container.decode(Bool.self) { self = .bool(value); return }
        if let value = try? container.decode(Int.self) { self = .int(value); return }
        if let value = try? container.decode(Double.self) { self = .double(value); return }
        if let value = try? container.decode(String.self) { self = .string(value); return }
        if let value = try? container.decode([NativeJSONValue].self) { self = .array(value); return }
        if let value = try? container.decode([String: NativeJSONValue].self) { self = .object(value); return }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "unsupported JSON value")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }
}

public struct NativeSaveCamera: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var zoom: Double

    public init(x: Double, y: Double, zoom: Double) {
        self.x = x
        self.y = y
        self.zoom = zoom
    }
}

public struct NativeBattleSaveState: Equatable, Sendable {
    public var battleFile: String
    public var battleTitle: String
    public var map: String
    public var mode: String
    public var playerOwner: Int
    public var round: Int
    public var resources: CountryResources
    public var countryResources: [String: CountryResources]
    public var camera: NativeSaveCamera
    public var cameraGeometry: String?
    public var units: [[String: NativeJSONValue]]
    public var objects: [[String: NativeJSONValue]]
    public var ownership: [Int]
    public var assignments: [[Int]]
    public var installations: [[String: NativeJSONValue]]
    public var fireCells: [String]
    public var nativeFiredEvents: [String]
    public var nativeAppliedEvents: [String]
    public var itemStores: NativeJSONValue?
    public var taverns: NativeJSONValue?
    public var collectMedal: Int
    public var campaignTech: [Int]?
    public var campaignTechZone: Int
    public var ended: NativeJSONValue?

    public init(
        battleFile: String,
        battleTitle: String,
        map: String,
        mode: String,
        playerOwner: Int,
        round: Int,
        resources: CountryResources,
        countryResources: [String: CountryResources] = [:],
        camera: NativeSaveCamera,
        cameraGeometry: String? = nil,
        units: [[String: NativeJSONValue]] = [],
        objects: [[String: NativeJSONValue]] = [],
        ownership: [Int] = [],
        assignments: [[Int]] = [],
        installations: [[String: NativeJSONValue]] = [],
        fireCells: [String] = [],
        nativeFiredEvents: [String] = [],
        nativeAppliedEvents: [String] = [],
        itemStores: NativeJSONValue? = nil,
        taverns: NativeJSONValue? = nil,
        collectMedal: Int = 0,
        campaignTech: [Int]? = nil,
        campaignTechZone: Int = 0,
        ended: NativeJSONValue? = nil
    ) {
        self.battleFile = battleFile
        self.battleTitle = battleTitle
        self.map = map
        self.mode = mode
        self.playerOwner = playerOwner
        self.round = round
        self.resources = resources
        self.countryResources = countryResources
        self.camera = camera
        self.cameraGeometry = cameraGeometry
        self.units = units
        self.objects = objects
        self.ownership = ownership
        self.assignments = assignments
        self.installations = installations
        self.fireCells = fireCells
        self.nativeFiredEvents = nativeFiredEvents
        self.nativeAppliedEvents = nativeAppliedEvents
        self.itemStores = itemStores
        self.taverns = taverns
        self.collectMedal = collectMedal
        self.campaignTech = campaignTech
        self.campaignTechZone = campaignTechZone
        self.ended = ended
    }
}

public struct NativeBattleSavePayload: Codable, Equatable, Sendable {
    public var schema: Int
    public var gameVersion: Int
    public var savedAt: Int64
    public var battleFile: String
    public var battleTitle: String
    public var map: String
    public var mode: String
    public var playerOwner: Int
    public var round: Int
    public var resources: CountryResources
    public var countryResources: [String: CountryResources]?
    public var camera: NativeSaveCamera
    public var cameraGeometry: String?
    public var units: [[String: NativeJSONValue]]
    public var objects: [[String: NativeJSONValue]]
    public var ownership: [Int]
    public var assignments: [[Int]]
    public var installations: [[String: NativeJSONValue]]
    public var fireCells: [String]
    public var nativeFiredEvents: [String]
    public var nativeAppliedEvents: [String]
    public var itemStores: NativeJSONValue?
    public var taverns: NativeJSONValue?
    public var collectMedal: Int?
    public var campaignTech: [Int]?
    public var campaignTechZone: Int?
    public var ended: NativeJSONValue?
}

public enum NativeBattleSaveError: Error, Equatable, Sendable {
    case noActiveBattle
    case invalidBattleSave
}

public enum NativeBattleSaveCore {
    public static let schema = 6
    public static let gameVersion = 61
    public static let acceptedSchemas: Set<Int> = [1, 2, 3, 4, 5, 6]
    public static let transientUnitKeys: Set<String> = ["moveAnim", "attackAnimStart", "attackPoseUntil"]

    public static func makePayload(
        from state: NativeBattleSaveState,
        savedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) throws -> NativeBattleSavePayload {
        guard !state.battleFile.isEmpty else { throw NativeBattleSaveError.noActiveBattle }
        return NativeBattleSavePayload(
            schema: schema,
            gameVersion: gameVersion,
            savedAt: savedAt,
            battleFile: state.battleFile,
            battleTitle: state.battleTitle.isEmpty ? state.battleFile : state.battleTitle,
            map: state.map,
            mode: state.mode,
            playerOwner: state.playerOwner,
            round: state.round == 0 ? 1 : state.round,
            resources: state.resources,
            countryResources: cleanCountryResources(state.countryResources),
            camera: state.camera,
            cameraGeometry: state.cameraGeometry,
            units: state.units.map(stripTransientUnitFields),
            objects: state.objects,
            ownership: state.ownership,
            assignments: state.assignments,
            installations: state.installations,
            fireCells: state.fireCells,
            nativeFiredEvents: state.nativeFiredEvents,
            nativeAppliedEvents: state.nativeAppliedEvents,
            itemStores: state.itemStores,
            taverns: state.taverns,
            collectMedal: max(0, state.collectMedal),
            campaignTech: normalizeCampaignTech(state.campaignTech),
            campaignTechZone: max(0, min(6, state.campaignTechZone)),
            ended: state.ended
        )
    }

    public static func validate(_ payload: NativeBattleSavePayload) -> Bool {
        acceptedSchemas.contains(payload.schema)
            && !payload.battleFile.isEmpty
    }

    public static func normalize(_ payload: NativeBattleSavePayload) throws -> NativeBattleSavePayload {
        guard validate(payload) else { throw NativeBattleSaveError.invalidBattleSave }
        var normalized = payload
        normalized.playerOwner = payload.playerOwner
        normalized.round = max(1, payload.round)
        normalized.resources = CountryResources(
            money: payload.resources.money,
            industry: payload.resources.industry,
            food: payload.resources.food
        )
        if let countryResources = payload.countryResources {
            normalized.countryResources = cleanCountryResources(countryResources)
        } else {
            normalized.countryResources = nil
        }
        normalized.camera = NativeSaveCamera(
            x: payload.camera.x,
            y: payload.camera.y,
            zoom: max(0.2, min(1.0, payload.camera.zoom))
        )
        normalized.collectMedal = max(0, payload.collectMedal ?? 0)
        normalized.campaignTech = normalizeCampaignTech(payload.campaignTech)
        normalized.campaignTechZone = max(0, min(6, payload.campaignTechZone ?? 0))
        return normalized
    }

    public static func encode(_ payload: NativeBattleSavePayload, pretty: Bool = false) throws -> Data {
        let encoder = JSONEncoder()
        if pretty { encoder.outputFormatting = [.prettyPrinted, .sortedKeys] }
        return try encoder.encode(payload)
    }

    public static func decode(_ data: Data) throws -> NativeBattleSavePayload {
        let payload = try JSONDecoder().decode(NativeBattleSavePayload.self, from: data)
        return try normalize(payload)
    }

    private static func stripTransientUnitFields(_ unit: [String: NativeJSONValue]) -> [String: NativeJSONValue] {
        unit.filter { !transientUnitKeys.contains($0.key) }
    }

    private static func cleanCountryResources(_ input: [String: CountryResources]) -> [String: CountryResources] {
        var output: [String: CountryResources] = [:]
        for (key, value) in input {
            let canonicalKey = Int(key).map(String.init) ?? key
            output[canonicalKey] = CountryResources(money: value.money, industry: value.industry, food: value.food)
        }
        return output
    }

    private static func normalizeCampaignTech(_ values: [Int]?) -> [Int]? {
        guard let values else { return nil }
        return values.prefix(26).map { max(-1, min(3, $0)) }
    }
}
