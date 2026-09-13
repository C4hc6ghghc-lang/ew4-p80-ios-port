import Foundation

public struct NativeCommanderOverrideRecord: Decodable, Equatable, Sendable {
    public let name: String?
    public let stats: [String: Int]?
    public let addSkills: [Int]?
    public let rankHpBonusCap: Int?
    public let nobilityHealCap: Int?
}

public struct NativePlayerOverrideGlobal: Decodable, Equatable, Sendable {
    public let rankMaxLevel: Int
    public let nobilityMaxLevel: Int
    public let rankHpBonusCap: Int
    public let nobilityHealCap: Int
    public let movementOverridesMayExceedOriginalCap: Bool?
}

public struct NativePlayerGeneralOverrides: Decodable, Equatable, Sendable {
    public let version: Int
    public let scope: String
    public let global: NativePlayerOverrideGlobal
    public let generals: [String: NativeCommanderOverrideRecord]
}

public struct NativePrincessUnlockRule: Decodable, Equatable, Sendable {
    public let allPrincessesImmediatelyAvailable: Bool
    public let ids: [Int]
}

public struct NativePlayerPrincessOverrides: Decodable, Equatable, Sendable {
    public let version: Int
    public let scope: String
    public let unlock: NativePrincessUnlockRule
    public let princesses: [String: NativeCommanderOverrideRecord]
}

/// A lossless wrapper around the mature P39 global save document. Unknown fields
/// remain in `document`, so future HQ/Campaign migrations cannot accidentally
/// erase state merely because the Swift layer does not understand it yet.
public struct NativePlayerProfile: Equatable, Sendable {
    public static let version = 61
    public static let princessIDs = [201, 202, 203, 204, 205, 206, 207, 208]
    public var document: [String: NativeJSONValue]

    public init(document: [String: NativeJSONValue] = [:]) {
        self.document = NativePlayerProfileCore.normalize(document)
    }

    public static func fresh() -> NativePlayerProfile { NativePlayerProfile() }

    public var ownedCommanderIDs: [Int] {
        NativePlayerProfileCore.intArray(document["owned"])
    }

    public func intMap(_ key: String) -> [String: Int] {
        NativePlayerProfileCore.intMap(document[key])
    }

    public func equipmentSlots(commanderID: Int, base: [Int]) -> [Int] {
        guard case .object(let table) = document["equipment"],
              case .array(let row) = table[String(commanderID)] else {
            return base.filter { $0 >= 0 }
        }
        let slots = row.prefix(2).compactMap(NativePlayerProfileCore.intOrNil)
        return slots.filter { $0 >= 0 }
    }

    public func encoded(pretty: Bool = false) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = pretty ? [.prettyPrinted, .sortedKeys] : [.sortedKeys]
        return try encoder.encode(document)
    }

    public static func decode(_ data: Data) throws -> NativePlayerProfile {
        let raw = try JSONDecoder().decode([String: NativeJSONValue].self, from: data)
        let migrated = NativeCampaignSessionCore.normalizeDocument(state: raw, source: raw)
        return NativePlayerProfile(document: migrated)
    }
}

public struct NativeEffectiveCommander: Equatable, Sendable {
    public let id: Int
    public let infantry: Int
    public let cavalry: Int
    public let artillery: Int
    public let warship: Int
    public let fort: Int
    public let business: Int
    public let movement: Int
    public let training: Int
    public let skillIDs: Set<Int>
    public let equippedItemIDs: [Int]
    public let rankLevel: Int
    public let nobilityLevel: Int
    public let rankHPBonus: Int
    public let nobilityHealCap: Int

    public var combatCommander: CombatCommander {
        CombatCommander(
            infantry: infantry,
            cavalry: cavalry,
            artillery: artillery,
            warship: warship,
            fort: fort,
            skills: skillIDs
        )
    }

    public var roundProjection: NativeCommanderRoundProjection {
        NativeCommanderRoundProjection(
            skillIDs: skillIDs,
            equippedItemIDs: equippedItemIDs,
            nobilityLevel: nobilityLevel,
            nobilityHealCap: nobilityHealCap
        )
    }
}

public enum NativePlayerProfileCore {
    public static func normalize(_ source: [String: NativeJSONValue]) -> [String: NativeJSONValue] {
        var out = source
        out["version"] = .int(NativePlayerProfile.version)
        var owned = Set(intArray(out["owned"]))
        owned.formUnion(NativePlayerProfile.princessIDs)
        out["owned"] = .array(owned.sorted().map(NativeJSONValue.int))
        for key in ["rank", "nobility", "rankProgress", "nobilityProgress", "generalStats", "equipment", "campaignProgress", "campaignBestRating", "campaignSecretUnlocks", "campaignCompletedZones"] {
            if case .object = out[key] { } else { out[key] = .object([:]) }
        }
        if case .object = out["itemInventory"] { } else { out["itemInventory"] = emptyItemBank() }
        if case .object = out["hqShop"] { } else {
            out["hqShop"] = .object(["dateKey": .string(""), "slots": .array([])])
        }
        if out["academyPool"] == nil { out["academyPool"] = .string("6") }
        if case .object = out["academyCandidatesByPool"] { } else {
            out["academyCandidatesByPool"] = .object(["6": .array([]), "4": .array([]), "2": .array([])])
        }
        if out["music"] == nil { out["music"] = .bool(true) }
        if out["bgVol"] == nil { out["bgVol"] = .int(50) }
        if out["seVol"] == nil { out["seVol"] = .int(50) }
        if out["gameSpeed"] == nil { out["gameSpeed"] = .int(2) }
        if out["showGrids"] == nil { out["showGrids"] = .bool(false) }
        if out["campaignStars"] == nil { out["campaignStars"] = .int(0) }
        if out["warzoneTech"] == nil { out["warzoneTech"] = .null }
        if case .object = out["campaignCompletionEarned"] { } else {
            out["campaignCompletionEarned"] = .object(["medals": .int(0), "badges": .int(0), "score": .int(0)])
        }
        return out
    }

    public static func effectiveCommander(
        raw: Commander,
        playerControlled: Bool,
        profile: NativePlayerProfile,
        generalOverrides: NativePlayerGeneralOverrides,
        princessOverrides: NativePlayerPrincessOverrides
    ) -> NativeEffectiveCommander {
        let override: NativeCommanderOverrideRecord? = playerControlled
            ? (generalOverrides.generals[String(raw.id)] ?? princessOverrides.princesses[String(raw.id)])
            : nil
        let stats = override?.stats ?? [:]
        let persistedStats = playerControlled
            ? nestedIntMap(profile.document["generalStats"], key: String(raw.id))
            : [:]
        func stat(_ key: String, _ base: Int) -> Int {
            guard playerControlled else { return base }
            let overridden = stats[key] ?? base
            return max(overridden, persistedStats[key] ?? overridden)
        }
        var skills = raw.skillIDs
        if playerControlled { skills.formUnion(override?.addSkills ?? []) }
        let baseItems = [raw.item1, raw.item2].compactMap { value -> Int? in
            guard let value, value >= 0 else { return nil }
            return value
        }
        let equipment = playerControlled
            ? profile.equipmentSlots(commanderID: raw.id, base: baseItems)
            : baseItems
        let ranks = playerControlled ? profile.intMap("rank") : [:]
        let nobles = playerControlled ? profile.intMap("nobility") : [:]
        let rankMax = max(1, generalOverrides.global.rankMaxLevel)
        let nobilityMax = max(1, generalOverrides.global.nobilityMaxLevel)
        let rank = playerControlled
            ? max(0, min(rankMax, ranks[String(raw.id)] ?? raw.rank))
            : raw.rank
        let nobility = playerControlled
            ? max(0, min(nobilityMax, nobles[String(raw.id)] ?? raw.nobilityrank))
            : raw.nobilityrank
        let rankCap = playerControlled ? max(0, override?.rankHpBonusCap ?? generalOverrides.global.rankHpBonusCap) : 0
        let nobleCap = playerControlled ? max(0, override?.nobilityHealCap ?? generalOverrides.global.nobilityHealCap) : 0
        let rankHPBonus = playerControlled ? Int((Double(rankCap * rank) / Double(rankMax)).rounded()) : 0
        return NativeEffectiveCommander(
            id: raw.id,
            infantry: stat("infantry", raw.infantry),
            cavalry: stat("cavalry", raw.cavalry),
            artillery: stat("artillery", raw.artillery),
            warship: stat("warship", raw.warship),
            fort: stat("fort", raw.fort),
            business: stat("business", raw.business),
            movement: stat("movement", raw.movement),
            training: stat("training", raw.training),
            skillIDs: skills,
            equippedItemIDs: equipment,
            rankLevel: rank,
            nobilityLevel: nobility,
            rankHPBonus: rankHPBonus,
            nobilityHealCap: nobleCap
        )
    }

    public static func makeRuntimeProvider(
        profile: NativePlayerProfile,
        commanders: [Int: Commander],
        generalOverrides: NativePlayerGeneralOverrides,
        princessOverrides: NativePlayerPrincessOverrides
    ) -> @Sendable (Int, Bool) -> NativeEffectiveCommander? {
        { id, playerControlled in
            guard let raw = commanders[id] else { return nil }
            return effectiveCommander(
                raw: raw,
                playerControlled: playerControlled,
                profile: profile,
                generalOverrides: generalOverrides,
                princessOverrides: princessOverrides
            )
        }
    }

    static func emptyItemBank() -> NativeJSONValue {
        let emptySlot: NativeJSONValue = .object(["item": .int(-1), "count": .int(0)])
        return .object(["schema": .int(1), "slots": .array(Array(repeating: emptySlot, count: 28))])
    }

    static func intArray(_ value: NativeJSONValue?) -> [Int] {
        guard case .array(let values) = value else { return [] }
        return values.compactMap(intOrNil)
    }

    static func intMap(_ value: NativeJSONValue?) -> [String: Int] {
        guard case .object(let object) = value else { return [:] }
        return object.reduce(into: [:]) { result, pair in
            if let value = intOrNil(pair.value) { result[pair.key] = value }
        }
    }

    static func nestedIntMap(_ value: NativeJSONValue?, key: String) -> [String: Int] {
        guard case .object(let object) = value else { return [:] }
        return intMap(object[key])
    }

    static func intOrNil(_ value: NativeJSONValue) -> Int? {
        switch value {
        case .int(let value): return value
        case .double(let value): return Int(value)
        case .string(let value): return Int(value)
        default: return nil
        }
    }
}

public final class NativePlayerProfileStore: @unchecked Sendable {
    public let fileURL: URL

    public init(directory: URL, fileName: String = "player_profile_v61.json") {
        self.fileURL = directory.appendingPathComponent(fileName)
    }

    public func load() -> NativePlayerProfile {
        guard let data = try? Data(contentsOf: fileURL), let profile = try? NativePlayerProfile.decode(data) else {
            return .fresh()
        }
        return profile
    }

    public func save(_ profile: NativePlayerProfile) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try profile.encoded(pretty: false)
        let temporary = fileURL.appendingPathExtension("tmp")
        try data.write(to: temporary, options: .atomic)
        if FileManager.default.fileExists(atPath: fileURL.path) { try FileManager.default.removeItem(at: fileURL) }
        try FileManager.default.moveItem(at: temporary, to: fileURL)
    }
}

public struct NativeGeneralGrowthApplication: Equatable, Sendable {
    public let commanderID: Int
    public let award: NativeGeneralGrowthAward
    public let rankHPBonusBefore: Int
    public let rankHPBonusAfter: Int

    public var rankHPDelta: Int { max(0, rankHPBonusAfter - rankHPBonusBefore) }
}

public extension NativePlayerProfileCore {
    static func generalGrowthState(profile: NativePlayerProfile, raw: Commander) -> NativeGeneralGrowthState {
        let ranks = profile.intMap("rank")
        let nobles = profile.intMap("nobility")
        let rankProgress = profile.intMap("rankProgress")
        let nobilityProgress = profile.intMap("nobilityProgress")
        return NativeGeneralGrowthState(
            rank: ranks[String(raw.id)] ?? raw.rank,
            militaryProgress: rankProgress[String(raw.id)] ?? 0,
            nobility: nobles[String(raw.id)] ?? raw.nobilityrank,
            nobilityProgress: nobilityProgress[String(raw.id)] ?? 0
        )
    }

    static func setIntMapValue(_ profile: inout NativePlayerProfile, key: String, nestedKey: String, value: Int) {
        var map: [String: NativeJSONValue]
        if case .object(let existing) = profile.document[key] { map = existing } else { map = [:] }
        map[nestedKey] = .int(value)
        profile.document[key] = .object(map)
    }

    @discardableResult
    static func applyCombatGrowth(
        profile: inout NativePlayerProfile,
        commander raw: Commander,
        damage: Int,
        killed: Bool,
        victimGrade: Int,
        victimHasCommander: Bool,
        itemEffects: NativeItemEffectCatalog,
        generalOverrides: NativePlayerGeneralOverrides,
        princessOverrides: NativePlayerPrincessOverrides
    ) -> NativeGeneralGrowthApplication? {
        guard profile.ownedCommanderIDs.contains(raw.id) else { return nil }
        let beforeEffective = effectiveCommander(
            raw: raw, playerControlled: true, profile: profile,
            generalOverrides: generalOverrides, princessOverrides: princessOverrides
        )
        let context = NativeGeneralGrowthContext(
            skillIDs: beforeEffective.skillIDs,
            items: beforeEffective.equippedItemIDs.compactMap { itemEffects[String($0)] }
        )
        let before = generalGrowthState(profile: profile, raw: raw)
        let award = NativeGeneralGrowthCore.award(
            state: before,
            damage: damage,
            killed: killed,
            victimGrade: victimGrade,
            victimHasCommander: victimHasCommander,
            context: context
        )
        guard award.after != award.before else { return nil }
        let key = String(raw.id)
        setIntMapValue(&profile, key: "rank", nestedKey: key, value: award.after.rank)
        setIntMapValue(&profile, key: "rankProgress", nestedKey: key, value: award.after.militaryProgress)
        setIntMapValue(&profile, key: "nobility", nestedKey: key, value: award.after.nobility)
        setIntMapValue(&profile, key: "nobilityProgress", nestedKey: key, value: award.after.nobilityProgress)
        let afterEffective = effectiveCommander(
            raw: raw, playerControlled: true, profile: profile,
            generalOverrides: generalOverrides, princessOverrides: princessOverrides
        )
        return NativeGeneralGrowthApplication(
            commanderID: raw.id,
            award: award,
            rankHPBonusBefore: beforeEffective.rankHPBonus,
            rankHPBonusAfter: afterEffective.rankHPBonus
        )
    }
}

/// Shared value box used by a live battle. Effective-commander providers capture
/// this reference instead of a stale profile struct, so rank/nobility growth is
/// visible immediately to later attacks and round settlement.
public final class NativePlayerProfileRuntime: @unchecked Sendable {
    private let lock = NSLock()
    private var value: NativePlayerProfile

    public init(_ profile: NativePlayerProfile) { self.value = profile }

    public func snapshot() -> NativePlayerProfile {
        lock.lock(); defer { lock.unlock() }
        return value
    }

    public func replace(with profile: NativePlayerProfile) {
        lock.lock(); value = profile; lock.unlock()
    }

    @discardableResult
    public func applyCombatGrowth(
        commander: Commander,
        damage: Int,
        killed: Bool,
        victimGrade: Int,
        victimHasCommander: Bool,
        itemEffects: NativeItemEffectCatalog,
        generalOverrides: NativePlayerGeneralOverrides,
        princessOverrides: NativePlayerPrincessOverrides
    ) -> NativeGeneralGrowthApplication? {
        lock.lock(); defer { lock.unlock() }
        return NativePlayerProfileCore.applyCombatGrowth(
            profile: &value,
            commander: commander,
            damage: damage,
            killed: killed,
            victimGrade: victimGrade,
            victimHasCommander: victimHasCommander,
            itemEffects: itemEffects,
            generalOverrides: generalOverrides,
            princessOverrides: princessOverrides
        )
    }
}

public extension NativePlayerProfileCore {
    static func makeRuntimeProvider(
        runtime: NativePlayerProfileRuntime,
        commanders: [Int: Commander],
        generalOverrides: NativePlayerGeneralOverrides,
        princessOverrides: NativePlayerPrincessOverrides
    ) -> @Sendable (Int, Bool) -> NativeEffectiveCommander? {
        { id, playerControlled in
            guard let raw = commanders[id] else { return nil }
            return effectiveCommander(
                raw: raw,
                playerControlled: playerControlled,
                profile: runtime.snapshot(),
                generalOverrides: generalOverrides,
                princessOverrides: princessOverrides
            )
        }
    }
}
