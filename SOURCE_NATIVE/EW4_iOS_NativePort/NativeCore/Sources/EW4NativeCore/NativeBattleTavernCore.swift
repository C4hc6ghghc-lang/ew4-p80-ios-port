import Foundation

public struct NativeBattleTavernSlot: Equatable, Sendable {
    public var commander: Int
    public var money: Int
    public var industry: Int
    public var medal: Int
    public var round: Int
    public init(commander: Int, money: Int, industry: Int, medal: Int, round: Int) {
        self.commander = commander; self.money = max(0, money); self.industry = max(0, industry); self.medal = max(0, medal); self.round = max(0, round)
    }
}

public struct NativeBattleTavernRecord: Equatable, Sendable {
    public var key: String
    public var objectIndex: Int
    public var count: Int
    public var slots: [NativeBattleTavernSlot?]
    public init(key: String, objectIndex: Int, count: Int, slots: [NativeBattleTavernSlot?]) {
        self.key = key; self.objectIndex = objectIndex; self.count = max(0, min(5, count))
        var values = Array(slots.prefix(5)); while values.count < 5 { values.append(nil) }; self.slots = values
    }
}

public enum NativeBattleTavernAvailability: String, Equatable, Sendable {
    case available, missing, owned, roundLocked, resources
}

public struct NativeBattleTavernRecruitResult: Equatable, Sendable {
    public var ok: Bool
    public var availability: NativeBattleTavernAvailability
    public var commanderID: Int?
    public init(ok: Bool, availability: NativeBattleTavernAvailability, commanderID: Int? = nil) {
        self.ok = ok; self.availability = availability; self.commanderID = commanderID
    }
}

public enum NativeBattleTavernCore {
    public static let visibleCandidateCount = 4
    public static let storedSlotCount = 5

    public static func initialState(catalog: NativeJSONValue, battleFile: String) -> NativeJSONValue? {
        guard case .object(let root) = catalog,
              case .object(let battles) = root["battles"],
              case .object(let group) = battles[battleFile] else { return nil }
        var out: [String: NativeJSONValue] = [:]
        for (key, value) in group {
            guard case .object(let object) = value else { continue }
            let objectIndex = integer(object["object_index"]) ?? -1
            let fileOffset = integer(object["file_offset"]) ?? 0
            let count = max(0, min(5, integer(object["count"]) ?? 0))
            var rows: [NativeJSONValue] = []
            if case .array(let source) = object["slots"] {
                for row in source.prefix(storedSlotCount) { rows.append(normalizedSlot(row)) }
            }
            while rows.count < storedSlotCount { rows.append(.null) }
            out[key] = .object([
                "object_index": .int(objectIndex), "file_offset": .int(fileOffset), "count": .int(count), "slots": .array(rows)
            ])
        }
        return .object(out)
    }

    public static func record(taverns: NativeJSONValue?, objectIndex: Int) -> NativeBattleTavernRecord? {
        guard case .object(let group) = taverns else { return nil }
        for key in group.keys.sorted() {
            guard case .object(let object) = group[key], integer(object["object_index"]) == objectIndex else { continue }
            let count = max(0, min(storedSlotCount, integer(object["count"]) ?? 0))
            var slots: [NativeBattleTavernSlot?] = []
            if case .array(let rows) = object["slots"] {
                for row in rows.prefix(storedSlotCount) { slots.append(decodeSlot(row)) }
            }
            while slots.count < storedSlotCount { slots.append(nil) }
            return .init(key: key, objectIndex: objectIndex, count: count, slots: slots)
        }
        return nil
    }

    public static func availability(
        slot: NativeBattleTavernSlot?, round: Int, resources: CountryResources,
        ownedCommanderIDs: Set<Int>, commanders: [Int: Commander]
    ) -> NativeBattleTavernAvailability {
        guard let slot, slot.commander > 0, commanders[slot.commander] != nil else { return .missing }
        if ownedCommanderIDs.contains(slot.commander) { return .owned }
        if round < slot.round { return .roundLocked }
        if resources.money < slot.money || resources.industry < slot.industry { return .resources }
        return .available
    }

    @discardableResult
    public static func recruit(
        taverns: inout NativeJSONValue?, objectIndex: Int, candidateIndex: Int,
        round: Int, resources: inout CountryResources, profile: inout NativePlayerProfile,
        commanders: [Int: Commander]
    ) -> NativeBattleTavernRecruitResult {
        guard var record = record(taverns: taverns, objectIndex: objectIndex),
              candidateIndex >= 0, candidateIndex < min(visibleCandidateCount, record.count),
              record.slots.indices.contains(candidateIndex) else {
            return .init(ok: false, availability: .missing)
        }
        let slot = record.slots[candidateIndex]
        let state = availability(slot: slot, round: round, resources: resources, ownedCommanderIDs: Set(profile.ownedCommanderIDs), commanders: commanders)
        guard state == .available, let slot else { return .init(ok: false, availability: state, commanderID: slot?.commander) }

        resources.money -= slot.money
        resources.industry -= slot.industry
        var owned = Set(profile.ownedCommanderIDs); owned.insert(slot.commander)
        profile.document["owned"] = .array(owned.sorted().map(NativeJSONValue.int))
        for index in candidateIndex..<visibleCandidateCount { record.slots[index] = record.slots[index + 1] }
        record.slots[storedSlotCount - 1] = nil
        record.count = max(0, record.count - 1)
        taverns = replace(record: record, in: taverns)
        return .init(ok: true, availability: .available, commanderID: slot.commander)
    }

    public static func encode(_ record: NativeBattleTavernRecord) -> NativeJSONValue {
        .object([
            "object_index": .int(record.objectIndex), "count": .int(record.count),
            "slots": .array(record.slots.prefix(storedSlotCount).map { slot in
                guard let slot else { return .null }
                return .object([
                    "commander": .int(slot.commander), "money": .int(slot.money), "industry": .int(slot.industry),
                    "medal": .int(slot.medal), "round": .int(slot.round)
                ])
            })
        ])
    }

    private static func replace(record: NativeBattleTavernRecord, in taverns: NativeJSONValue?) -> NativeJSONValue {
        var group: [String: NativeJSONValue] = [:]
        if case .object(let current) = taverns { group = current }
        var object: [String: NativeJSONValue] = [:]
        if case .object(let old) = group[record.key] { object = old }
        object["object_index"] = .int(record.objectIndex)
        object["count"] = .int(record.count)
        object["slots"] = .array(record.slots.prefix(storedSlotCount).map { slot in
            guard let slot else { return .null }
            return .object(["commander":.int(slot.commander),"money":.int(slot.money),"industry":.int(slot.industry),"medal":.int(slot.medal),"round":.int(slot.round)])
        })
        group[record.key] = .object(object)
        return .object(group)
    }

    private static func normalizedSlot(_ value: NativeJSONValue) -> NativeJSONValue {
        guard let slot = decodeSlot(value), slot.commander > 0 else { return .null }
        return .object(["commander":.int(slot.commander),"money":.int(slot.money),"industry":.int(slot.industry),"medal":.int(slot.medal),"round":.int(slot.round)])
    }

    private static func decodeSlot(_ value: NativeJSONValue) -> NativeBattleTavernSlot? {
        guard case .object(let row) = value, let commander = integer(row["commander"]), commander > 0 else { return nil }
        return .init(commander: commander, money: integer(row["money"]) ?? 0, industry: integer(row["industry"]) ?? 0, medal: integer(row["medal"]) ?? 0, round: integer(row["round"]) ?? 0)
    }

    private static func integer(_ value: NativeJSONValue?) -> Int? {
        guard let value else { return nil }
        switch value { case .int(let n): return n; case .double(let n): return Int(n); case .string(let s): return Int(s); default: return nil }
    }
}
