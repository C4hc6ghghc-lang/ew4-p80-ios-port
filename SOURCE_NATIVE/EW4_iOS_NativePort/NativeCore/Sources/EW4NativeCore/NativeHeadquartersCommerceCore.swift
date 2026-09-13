import Foundation

public struct NativeItemInventorySlot: Equatable, Sendable {
    public var item: Int
    public var count: Int
    public init(item: Int = -1, count: Int = 0) { self.item = item; self.count = count }
    public var isEmpty: Bool { item < 0 || count <= 0 }
}

public struct NativeItemInventoryBank: Equatable, Sendable {
    public static let size = 28
    public static let slot0StackMax = 999
    public static let normalStackMax = 99
    public var slots: [NativeItemInventorySlot]

    public init(slots: [NativeItemInventorySlot] = []) {
        var values = Array(slots.prefix(Self.size))
        while values.count < Self.size { values.append(.init()) }
        self.slots = values.map { $0.isEmpty ? .init() : .init(item: $0.item, count: max(1, $0.count)) }
    }

    public func count(itemID: Int) -> Int { slots.reduce(0) { $0 + ($1.item == itemID ? $1.count : 0) } }
}

public struct NativeHQShopSlot: Equatable, Sendable {
    public var item: Int
    public var count: Int
    public var active: Bool
    public init(item: Int, count: Int = 1, active: Bool = true) { self.item = item; self.count = count; self.active = active }
}

public struct NativeHQShopStore: Equatable, Sendable {
    public var dateKey: String
    public var slots: [NativeHQShopSlot?]
    public init(dateKey: String = "", slots: [NativeHQShopSlot?] = []) {
        self.dateKey = dateKey
        self.slots = Array(slots.prefix(NativeHQShopCore.sellerSize))
        while self.slots.count < NativeHQShopCore.sellerSize { self.slots.append(nil) }
    }
}

public enum NativeHQItemInventoryCore {
    public static func isConsumable(_ item: NativeItemEffectDefinition?) -> Bool {
        guard let value = item?.consumable?.lowercased() else { return false }
        return value == "1" || value == "true" || value == "yes"
    }

    public static func decode(_ value: NativeJSONValue?) -> NativeItemInventoryBank {
        guard case .object(let object) = value, case .array(let raw) = object["slots"] else { return .init() }
        return NativeItemInventoryBank(slots: raw.prefix(NativeItemInventoryBank.size).map { row in
            guard case .object(let slot) = row else { return .init() }
            let item = integer(slot["item"]) ?? integer(slot["itemId"]) ?? integer(slot["id"]) ?? -1
            let count = integer(slot["count"]) ?? 0
            return item >= 0 && count > 0 ? .init(item: item, count: count) : .init()
        })
    }

    public static func encode(_ bank: NativeItemInventoryBank) -> NativeJSONValue {
        .object([
            "schema": .int(1),
            "slots": .array(bank.slots.map { .object(["item": .int($0.isEmpty ? -1 : $0.item), "count": .int($0.isEmpty ? 0 : $0.count)]) })
        ])
    }

    public static func canAdd(_ bank: NativeItemInventoryBank, itemID: Int, amount: Int = 1, items: NativeItemEffectCatalog) -> Bool {
        guard itemID >= 0, amount > 0 else { return false }
        if isConsumable(items[String(itemID)]) {
            var room = 0
            for (index, slot) in bank.slots.enumerated() {
                let cap = index == 0 ? NativeItemInventoryBank.slot0StackMax : NativeItemInventoryBank.normalStackMax
                if slot.item == itemID { room += max(0, cap - slot.count) }
                else if slot.isEmpty { room += cap }
                if room >= amount { return true }
            }
            return false
        }
        return bank.slots.filter(\.isEmpty).count >= amount
    }

    public static func add(_ bank: NativeItemInventoryBank, itemID: Int, amount: Int = 1, items: NativeItemEffectCatalog) -> NativeItemInventoryBank? {
        guard canAdd(bank, itemID: itemID, amount: amount, items: items) else { return nil }
        var out = bank
        var left = amount
        if isConsumable(items[String(itemID)]) {
            for index in out.slots.indices where left > 0 && out.slots[index].item == itemID {
                let cap = index == 0 ? NativeItemInventoryBank.slot0StackMax : NativeItemInventoryBank.normalStackMax
                let take = min(left, max(0, cap - out.slots[index].count))
                out.slots[index].count += take; left -= take
            }
            for index in out.slots.indices where left > 0 && out.slots[index].isEmpty {
                let cap = index == 0 ? NativeItemInventoryBank.slot0StackMax : NativeItemInventoryBank.normalStackMax
                let take = min(left, cap)
                out.slots[index] = .init(item: itemID, count: take); left -= take
            }
        } else {
            while left > 0, let index = out.slots.firstIndex(where: \.isEmpty) {
                out.slots[index] = .init(item: itemID, count: 1); left -= 1
            }
        }
        return out
    }

    public static func remove(_ bank: NativeItemInventoryBank, slotIndex: Int, amount: Int = 1) -> NativeItemInventoryBank? {
        guard bank.slots.indices.contains(slotIndex), amount > 0 else { return nil }
        var out = bank
        guard !out.slots[slotIndex].isEmpty, out.slots[slotIndex].count >= amount else { return nil }
        out.slots[slotIndex].count -= amount
        if out.slots[slotIndex].count <= 0 { out.slots[slotIndex] = .init() }
        return out
    }

    private static func integer(_ value: NativeJSONValue?) -> Int? {
        guard let value else { return nil }
        switch value {
        case .int(let n): return n
        case .double(let n): return Int(n)
        case .string(let n): return Int(n)
        default: return nil
        }
    }
}

public enum NativeHQShopCore {
    public static let sellerSize = 14
    public static let consumableSlots = 5
    public static let uniqueSlots = [6, 7]
    public static let sellBasePercent = 60

    public static func buyPrice(_ item: NativeItemEffectDefinition?) -> Int { max(0, item?.price ?? 0) }
    public static func sellPrice(_ item: NativeItemEffectDefinition?) -> Int { max(1, Int(Double(max(0, item?.price ?? 0)) * 0.60)) }

    public static func dateKey(_ date: Date = Date(), timeZone: TimeZone = .current) -> String {
        let f = DateFormatter(); f.calendar = Calendar(identifier: .gregorian); f.locale = Locale(identifier: "en_US_POSIX"); f.timeZone = timeZone; f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    public static func decodeStore(_ value: NativeJSONValue?) -> NativeHQShopStore {
        guard case .object(let object) = value else { return .init() }
        let key: String
        if case .string(let s) = object["dateKey"] { key = s } else { key = "" }
        guard case .array(let rows) = object["slots"] else { return .init(dateKey: key) }
        let slots: [NativeHQShopSlot?] = rows.prefix(sellerSize).map { row in
            guard case .object(let slot) = row else { return nil }
            guard let id = integer(slot["item"]), id >= 0 else { return nil }
            let count = max(0, integer(slot["count"]) ?? 1)
            let active: Bool
            if case .bool(let b) = slot["active"] { active = b } else { active = true }
            return count > 0 ? .init(item: id, count: count, active: active) : nil
        }
        return .init(dateKey: key, slots: slots)
    }

    public static func encodeStore(_ store: NativeHQShopStore) -> NativeJSONValue {
        .object(["dateKey": .string(store.dateKey), "slots": .array(store.slots.map { slot in
            guard let slot else { return .null }
            return .object(["item": .int(slot.item), "count": .int(slot.count), "active": .bool(slot.active)])
        })])
    }

    public static func directOwnedItemIDs(profile: NativePlayerProfile) -> Set<Int> {
        var out = Set(NativeHQItemInventoryCore.decode(profile.document["itemInventory"]).slots.filter { !$0.isEmpty }.map(\.item))
        if case .object(let equipment) = profile.document["equipment"] {
            for row in equipment.values {
                guard case .array(let values) = row else { continue }
                for value in values { if let id = integer(value), id >= 0 { out.insert(id) } }
            }
        }
        return out
    }

    public static func makeDailyStock(items: NativeItemEffectCatalog, ownedIDs: Set<Int>, random: () -> Double = { Double.random(in: 0..<1) }) -> [NativeHQShopSlot?] {
        var slots = Array<NativeHQShopSlot?>(repeating: nil, count: sellerSize)
        let values = items.values.filter { $0.id >= 0 }
        let consumables = values.filter { NativeHQItemInventoryCore.isConsumable($0) }.sorted { $0.id < $1.id }
        var uniques = values.filter { !NativeHQItemInventoryCore.isConsumable($0) && !ownedIDs.contains($0.id) }.sorted { $0.id < $1.id }
        func pick<T>(_ array: [T]) -> T? {
            guard !array.isEmpty else { return nil }
            let r = max(0, min(0.999999999, random()))
            return array[Int(Double(array.count) * r)]
        }
        for index in 0..<consumableSlots { if let item = pick(consumables) { slots[index] = .init(item: item.id) } }
        for index in uniqueSlots {
            guard let item = pick(uniques) else { break }
            slots[index] = .init(item: item.id)
            uniques.removeAll { $0.id == item.id }
        }
        return slots
    }

    @discardableResult
    public static func ensureStore(profile: inout NativePlayerProfile, items: NativeItemEffectCatalog, date: Date = Date(), timeZone: TimeZone = .current, random: () -> Double = { Double.random(in: 0..<1) }) -> NativeHQShopStore {
        let key = dateKey(date, timeZone: timeZone)
        let current = decodeStore(profile.document["hqShop"])
        if current.dateKey == key, current.slots.count == sellerSize { return current }
        let next = NativeHQShopStore(dateKey: key, slots: makeDailyStock(items: items, ownedIDs: directOwnedItemIDs(profile: profile), random: random))
        profile.document["hqShop"] = encodeStore(next)
        return next
    }

    @discardableResult
    public static func buy(profile: inout NativePlayerProfile, sellerIndex: Int, items: NativeItemEffectCatalog) -> Int? {
        var store = decodeStore(profile.document["hqShop"])
        guard store.slots.indices.contains(sellerIndex), var slot = store.slots[sellerIndex], slot.active, slot.count > 0 else { return nil }
        let bank = NativeHQItemInventoryCore.decode(profile.document["itemInventory"])
        guard let nextBank = NativeHQItemInventoryCore.add(bank, itemID: slot.item, items: items) else { return nil }
        profile.document["itemInventory"] = NativeHQItemInventoryCore.encode(nextBank)
        slot.count -= 1; store.slots[sellerIndex] = slot.count > 0 ? slot : nil
        profile.document["hqShop"] = encodeStore(store)
        return slot.item
    }

    @discardableResult
    public static func sell(profile: inout NativePlayerProfile, inventoryIndex: Int) -> Int? {
        let bank = NativeHQItemInventoryCore.decode(profile.document["itemInventory"])
        guard bank.slots.indices.contains(inventoryIndex), !bank.slots[inventoryIndex].isEmpty else { return nil }
        let item = bank.slots[inventoryIndex].item
        guard let next = NativeHQItemInventoryCore.remove(bank, slotIndex: inventoryIndex) else { return nil }
        profile.document["itemInventory"] = NativeHQItemInventoryCore.encode(next)
        return item
    }

    private static func integer(_ value: NativeJSONValue?) -> Int? {
        guard let value else { return nil }
        switch value { case .int(let n): return n; case .double(let n): return Int(n); case .string(let n): return Int(n); default: return nil }
    }
}

public struct NativeAcademyTier: Equatable, Sendable {
    public let key: String; public let count: Int; public let minStar: Int; public let maxStar: Int
}

public enum NativeAcademyCore {
    public static let tierOrder = ["6", "4", "2"]
    public static let tiers: [String: NativeAcademyTier] = [
        "6": .init(key: "6", count: 6, minStar: 1, maxStar: 3),
        "4": .init(key: "4", count: 4, minStar: 4, maxStar: 6),
        "2": .init(key: "2", count: 2, minStar: 7, maxStar: 9)
    ]
    public static let badgePriceByStar = [0, 0, 0, 0, 3, 3, 4, 6, 8]

    public static func tier(_ key: String) -> NativeAcademyTier { tiers[key] ?? tiers["6"]! }
    public static func medalPrice(_ commander: Commander) -> Int { max(0, commander.price ?? 0) }
    public static func badgePrice(_ commander: Commander) -> Int {
        let star = commander.star
        return badgePriceByStar.indices.contains(star) ? badgePriceByStar[star] : 0
    }

    public static func decodePools(_ value: NativeJSONValue?) -> [String: [Int?]] {
        var out: [String: [Int?]] = [:]
        let object: [String: NativeJSONValue]
        if case .object(let source) = value { object = source } else { object = [:] }
        for key in tierOrder {
            let cfg = tier(key)
            let source: [NativeJSONValue]
            if case .array(let values) = object[key] { source = Array(values.prefix(cfg.count)) } else { source = [] }
            var row = source.map { integer($0).flatMap { $0 > 0 ? $0 : nil } }
            while row.count < cfg.count { row.append(nil) }
            out[key] = row
        }
        return out
    }

    public static func encodePools(_ pools: [String: [Int?]]) -> NativeJSONValue {
        .object(Dictionary(uniqueKeysWithValues: tierOrder.map { key in
            let cfg = tier(key), row = Array((pools[key] ?? []).prefix(cfg.count)) + Array(repeating: nil, count: max(0, cfg.count - (pools[key]?.count ?? 0)))
            return (key, .array(row.prefix(cfg.count).map { $0.map(NativeJSONValue.int) ?? .null }))
        }))
    }

    public static func structurallyValid(_ pools: [String: [Int?]], commanders: [Int: Commander]) -> Bool {
        var seen = Set<Int>()
        for key in tierOrder {
            let cfg = tier(key), row = pools[key] ?? []
            guard row.count == cfg.count else { return false }
            for maybeID in row {
                guard let id = maybeID else { continue }
                guard !seen.contains(id), let commander = commanders[id], (commander.drawlots ?? 0) != 0, commander.star >= cfg.minStar, commander.star <= cfg.maxStar else { return false }
                seen.insert(id)
            }
        }
        return true
    }

    public static func refreshTier(commanders: [Int: Commander], owned: Set<Int>, pools: [String: [Int?]], tier key: String, random: () -> Double = { Double.random(in: 0..<1) }) -> [String: [Int?]] {
        let cfg = tier(key)
        var next = decodePools(encodePools(pools))
        var excluded = Set(next.values.flatMap { $0.compactMap { $0 } })
        var picked: [Int?] = []
        for _ in 0..<cfg.count {
            let eligible = commanders.values.filter {
                $0.id > 0 && ($0.drawlots ?? 0) != 0 && !owned.contains($0.id) && !excluded.contains($0.id) && $0.star >= cfg.minStar && $0.star <= cfg.maxStar
            }.sorted { $0.id < $1.id }
            guard !eligible.isEmpty else { picked.append(nil); continue }
            let r = max(0, min(0.999999999, random()))
            let id = eligible[Int(Double(eligible.count) * r)].id
            picked.append(id); excluded.insert(id)
        }
        next[key] = picked
        return next
    }

    public static func initializePools(commanders: [Int: Commander], owned: Set<Int>, random: () -> Double = { Double.random(in: 0..<1) }) -> [String: [Int?]] {
        var pools = ["6": Array<Int?>(repeating: nil, count: 6), "4": Array<Int?>(repeating: nil, count: 4), "2": Array<Int?>(repeating: nil, count: 2)]
        for key in tierOrder { pools = refreshTier(commanders: commanders, owned: owned, pools: pools, tier: key, random: random) }
        return pools
    }

    @discardableResult
    public static func ensurePools(profile: inout NativePlayerProfile, commanders: [Int: Commander], random: () -> Double = { Double.random(in: 0..<1) }) -> [String: [Int?]] {
        let raw = profile.document["academyCandidatesByPool"]
        let decoded = decodePools(raw)
        // The mature controller treats fresh [] tier arrays as uninitialized, but a
        // purchased-out tier with fixed-length null holes is a valid persisted page.
        // Inspect the raw array lengths before decodePads so the two states do not collapse.
        let hasNativeShape: Bool = {
            guard case .object(let object) = raw else { return false }
            for key in tierOrder {
                guard case .array(let row) = object[key], row.count == tier(key).count else { return false }
            }
            return true
        }()
        let next = (hasNativeShape && structurallyValid(decoded, commanders: commanders)) ? decoded : initializePools(commanders: commanders, owned: Set(profile.ownedCommanderIDs), random: random)
        profile.document["academyCandidatesByPool"] = encodePools(next)
        return next
    }

    @discardableResult
    public static func refresh(profile: inout NativePlayerProfile, commanders: [Int: Commander], tier key: String, random: () -> Double = { Double.random(in: 0..<1) }) -> [String: [Int?]] {
        let current = ensurePools(profile: &profile, commanders: commanders, random: random)
        let next = refreshTier(commanders: commanders, owned: Set(profile.ownedCommanderIDs), pools: current, tier: key, random: random)
        profile.document["academyPool"] = .string(key)
        profile.document["academyCandidatesByPool"] = encodePools(next)
        return next
    }

    @discardableResult
    public static func acquire(profile: inout NativePlayerProfile, commanders: [Int: Commander], tier key: String, commanderID: Int, currency: String) -> Bool {
        guard !profile.ownedCommanderIDs.contains(commanderID), let commander = commanders[commanderID] else { return false }
        let validCurrency = currency == "medal" ? medalPrice(commander) > 0 : currency == "badge" ? badgePrice(commander) > 0 : false
        guard validCurrency else { return false }
        var pools = decodePools(profile.document["academyCandidatesByPool"])
        guard (pools[key] ?? []).contains(where: { $0 == commanderID }) else { return false }
        var owned = Set(profile.ownedCommanderIDs); owned.insert(commanderID)
        profile.document["owned"] = .array(owned.sorted().map(NativeJSONValue.int))
        pools[key] = (pools[key] ?? []).map { $0 == commanderID ? nil : $0 }
        profile.document["academyPool"] = .string(key)
        profile.document["academyCandidatesByPool"] = encodePools(pools)
        return true
    }

    private static func integer(_ value: NativeJSONValue) -> Int? {
        switch value { case .int(let n): return n; case .double(let n): return Int(n); case .string(let n): return Int(n); default: return nil }
    }
}
