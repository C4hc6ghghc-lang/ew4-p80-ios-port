import Foundation

public struct NativeBattleShopRecord: Equatable, Sendable {
    public let storeID: String
    public let objectIndex: Int
    public var slots: [NativeHQShopSlot?]

    public init(storeID: String, objectIndex: Int, slots: [NativeHQShopSlot?]) {
        self.storeID = storeID
        self.objectIndex = objectIndex
        self.slots = NativeBattleShopCore.normalize(slots)
    }
}

public enum NativeBattleShopCore {
    public static let sellerSize = 14
    public static let sellBasePercent = 60
    public static let commerceStepPercent = 4
    public static let sellMaxPercent = 80

    public static func initialState(catalog: NativeJSONValue?, battleFile: String) -> NativeJSONValue? {
        guard case .object(let root) = catalog,
              case .object(let battles) = root["battles"],
              case .object(let stores) = battles[battleFile] else { return nil }
        var out: [String: NativeJSONValue] = [:]
        for (storeID, raw) in stores {
            guard case .object(var store) = raw else { continue }
            let slots = decodeSlots(store["slots"])
            store["slots"] = encodeSlots(slots)
            out[storeID] = .object(store)
        }
        return .object(out)
    }

    public static func record(itemStores: NativeJSONValue?, objectIndex: Int) -> NativeBattleShopRecord? {
        guard case .object(let stores) = itemStores else { return nil }
        for (storeID, raw) in stores {
            guard case .object(let store) = raw,
                  integer(store["object_index"]) == objectIndex else { continue }
            return .init(storeID: storeID, objectIndex: objectIndex, slots: decodeSlots(store["slots"]))
        }
        return nil
    }

    public static func buyPrice(_ item: NativeItemEffectDefinition?, business: Int) -> Int {
        let base = max(0, item?.price ?? 0)
        let discount = NativeBattleCommerceCore.businessStars(business) * 4
        return max(0, base - (base * discount / 100))
    }

    public static func sellPercent(business: Int) -> Int {
        min(sellMaxPercent, sellBasePercent + NativeBattleCommerceCore.businessStars(business) * commerceStepPercent)
    }

    public static func sellPrice(_ item: NativeItemEffectDefinition?, business: Int) -> Int {
        let base = max(0, item?.price ?? 0)
        return max(1, base * sellPercent(business: business) / 100)
    }

    @discardableResult
    public static func buy(
        itemStores: inout NativeJSONValue?,
        objectIndex: Int,
        sellerIndex: Int,
        profile: inout NativePlayerProfile,
        items: NativeItemEffectCatalog
    ) -> Int? {
        guard var record = record(itemStores: itemStores, objectIndex: objectIndex),
              record.slots.indices.contains(sellerIndex),
              var slot = record.slots[sellerIndex], slot.active, slot.count > 0,
              item(items, id: slot.item) != nil else { return nil }
        let bank = NativeHQItemInventoryCore.decode(profile.document["itemInventory"])
        guard let nextBank = NativeHQItemInventoryCore.add(bank, itemID: slot.item, items: items) else { return nil }
        profile.document["itemInventory"] = NativeHQItemInventoryCore.encode(nextBank)
        slot.count -= 1
        record.slots[sellerIndex] = slot.count > 0 ? slot : nil
        itemStores = replace(record: record, in: itemStores)
        return slot.item
    }

    @discardableResult
    public static func sell(
        inventoryIndex: Int,
        profile: inout NativePlayerProfile
    ) -> Int? {
        let bank = NativeHQItemInventoryCore.decode(profile.document["itemInventory"])
        guard bank.slots.indices.contains(inventoryIndex), !bank.slots[inventoryIndex].isEmpty else { return nil }
        let itemID = bank.slots[inventoryIndex].item
        guard let next = NativeHQItemInventoryCore.remove(bank, slotIndex: inventoryIndex) else { return nil }
        profile.document["itemInventory"] = NativeHQItemInventoryCore.encode(next)
        return itemID
    }

    public static func item(_ items: NativeItemEffectCatalog, id: Int) -> NativeItemEffectDefinition? {
        items[String(id)] ?? items.values.first(where: { $0.id == id })
    }

    static func normalize(_ slots: [NativeHQShopSlot?]) -> [NativeHQShopSlot?] {
        var out = Array(slots.prefix(sellerSize))
        while out.count < sellerSize { out.append(nil) }
        return out
    }

    private static func decodeSlots(_ value: NativeJSONValue?) -> [NativeHQShopSlot?] {
        guard case .array(let rows) = value else { return normalize([]) }
        let slots: [NativeHQShopSlot?] = rows.prefix(sellerSize).map { row in
            guard case .object(let slot) = row,
                  let item = integer(slot["item"]), item >= 0 else { return nil }
            let count = max(0, integer(slot["count"]) ?? 1)
            let active: Bool
            if case .bool(let value) = slot["active"] { active = value } else { active = true }
            return count > 0 ? .init(item: item, count: count, active: active) : nil
        }
        return normalize(slots)
    }

    private static func encodeSlots(_ slots: [NativeHQShopSlot?]) -> NativeJSONValue {
        .array(normalize(slots).map { slot in
            guard let slot else { return .null }
            return .object(["item": .int(slot.item), "count": .int(slot.count), "active": .bool(slot.active)])
        })
    }

    private static func replace(record: NativeBattleShopRecord, in itemStores: NativeJSONValue?) -> NativeJSONValue? {
        guard case .object(var stores) = itemStores,
              case .object(var store) = stores[record.storeID] else { return itemStores }
        store["slots"] = encodeSlots(record.slots)
        stores[record.storeID] = .object(store)
        return .object(stores)
    }

    private static func integer(_ value: NativeJSONValue?) -> Int? {
        guard let value else { return nil }
        switch value {
        case .int(let value): return value
        case .double(let value): return Int(value)
        case .string(let value): return Int(value)
        default: return nil
        }
    }
}
