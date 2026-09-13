import Foundation

public enum NativeHQManagementFailure: String, Equatable, Sendable {
    case commander
    case slot
    case inventory
    case insufficient
    case full
    case consumable
    case flagSkill
    case princess
    case sameCommander
}

public struct NativeHQManagementResult: Equatable, Sendable {
    public let ok: Bool
    public let reason: NativeHQManagementFailure?
    public let itemID: Int?
    public init(ok: Bool, reason: NativeHQManagementFailure? = nil, itemID: Int? = nil) {
        self.ok = ok; self.reason = reason; self.itemID = itemID
    }
}

public struct NativeHQRegroupPreview: Equatable, Sendable {
    public let rank: Int
    public let militaryProgress: Int
    public let nobility: Int
    public let nobilityProgress: Int
    public let stats: [String: Int]
    public let militaryGain: Int
    public let nobilityGain: Int
    public let teachingBonuses: [String: Int]
}

public struct NativeHQDismissPreview: Equatable, Sendable {
    public let ok: Bool
    public let reason: NativeHQManagementFailure?
    public let returnedItemIDs: [Int]
    public let inventory: NativeItemInventoryBank
}

public enum NativeHeadquartersManagementCore {
    public static let militaryRetention = [100, 97, 94, 91, 88, 85, 82, 79, 76, 73, 70, 67, 64, 61, 58]
    public static let nobilityRetention = [100, 96, 92, 88, 84, 80, 76, 72, 68, 64]
    public static let teachingSkills: [Int: String] = [
        33: "infantry", 34: "cavalry", 35: "artillery", 36: "warship",
        37: "fort", 38: "business", 39: "movement"
    ]

    public static func equipmentPair(profile: NativePlayerProfile, commander: Commander) -> [Int?] {
        let base: [Int?] = [validItem(commander.item1), validItem(commander.item2)]
        guard case .object(let table) = profile.document["equipment"],
              case .array(let row) = table[String(commander.id)] else { return base }
        var out: [Int?] = []
        for i in 0..<2 {
            guard row.indices.contains(i) else { out.append(nil); continue }
            out.append(jsonInt(row[i]).flatMap { $0 >= 0 ? $0 : nil })
        }
        return out
    }

    public static func equip(
        profile: inout NativePlayerProfile,
        commander: Commander,
        slot: Int,
        inventoryIndex: Int?,
        items: NativeItemEffectCatalog,
        generalOverrides: NativePlayerGeneralOverrides,
        princessOverrides: NativePlayerPrincessOverrides
    ) -> NativeHQManagementResult {
        guard profile.ownedCommanderIDs.contains(commander.id) else { return .init(ok: false, reason: .commander) }
        guard slot == 0 || slot == 1 else { return .init(ok: false, reason: .slot) }
        var bank = NativeHQItemInventoryCore.decode(profile.document["itemInventory"])
        let slots = equipmentPair(profile: profile, commander: commander)
        let current = slots[slot]
        var requested: Int?
        if let inventoryIndex {
            guard bank.slots.indices.contains(inventoryIndex) else { return .init(ok: false, reason: .inventory) }
            let source = bank.slots[inventoryIndex]
            guard !source.isEmpty else { requested = nil; return changeEquipment(profile: &profile, bank: bank, slots: slots, commanderID: commander.id, slot: slot, requested: nil, sourceIndex: nil, current: current, items: items) }
            requested = source.item
            guard let item = items[String(source.item)] ?? items.values.first(where: { $0.id == source.item }) else { return .init(ok: false, reason: .inventory) }
            if NativeHQItemInventoryCore.isConsumable(item) { return .init(ok: false, reason: .consumable) }
            let effective = NativePlayerProfileCore.effectiveCommander(raw: commander, playerControlled: true, profile: profile, generalOverrides: generalOverrides, princessOverrides: princessOverrides)
            if item.flag != nil && !effective.skillIDs.contains(0) { return .init(ok: false, reason: .flagSkill) }
            if current == requested { return .init(ok: true, itemID: requested) }
            guard let removed = NativeHQItemInventoryCore.remove(bank, slotIndex: inventoryIndex) else { return .init(ok: false, reason: .insufficient) }
            bank = removed
            return changeEquipment(profile: &profile, bank: bank, slots: slots, commanderID: commander.id, slot: slot, requested: requested, sourceIndex: inventoryIndex, current: current, items: items)
        }
        requested = nil
        return changeEquipment(profile: &profile, bank: bank, slots: slots, commanderID: commander.id, slot: slot, requested: nil, sourceIndex: nil, current: current, items: items)
    }

    private static func changeEquipment(
        profile: inout NativePlayerProfile,
        bank: NativeItemInventoryBank,
        slots: [Int?],
        commanderID: Int,
        slot: Int,
        requested: Int?,
        sourceIndex: Int?,
        current: Int?,
        items: NativeItemEffectCatalog
    ) -> NativeHQManagementResult {
        if current == requested { return .init(ok: true, itemID: requested) }
        var nextBank = bank
        if let current {
            guard let returned = NativeHQItemInventoryCore.add(nextBank, itemID: current, items: items) else {
                return .init(ok: false, reason: .full)
            }
            nextBank = returned
        }
        var nextSlots = slots
        nextSlots[slot] = requested
        profile.document["itemInventory"] = NativeHQItemInventoryCore.encode(nextBank)
        setEquipment(profile: &profile, commanderID: commanderID, slots: nextSlots)
        return .init(ok: true, itemID: requested)
    }

    public static func dismissalPreview(profile: NativePlayerProfile, commander: Commander, items: NativeItemEffectCatalog) -> NativeHQDismissPreview {
        if NativePlayerProfile.princessIDs.contains(commander.id) {
            return .init(ok: false, reason: .princess, returnedItemIDs: [], inventory: NativeHQItemInventoryCore.decode(profile.document["itemInventory"]))
        }
        guard profile.ownedCommanderIDs.contains(commander.id) else {
            return .init(ok: false, reason: .commander, returnedItemIDs: [], inventory: NativeHQItemInventoryCore.decode(profile.document["itemInventory"]))
        }
        var bank = NativeHQItemInventoryCore.decode(profile.document["itemInventory"])
        var returned: [Int] = []
        for id in equipmentPair(profile: profile, commander: commander).compactMap({ $0 }) {
            guard let next = NativeHQItemInventoryCore.add(bank, itemID: id, items: items) else {
                return .init(ok: false, reason: .full, returnedItemIDs: returned, inventory: bank)
            }
            bank = next; returned.append(id)
        }
        return .init(ok: true, reason: nil, returnedItemIDs: returned, inventory: bank)
    }

    @discardableResult
    public static func dismiss(profile: inout NativePlayerProfile, commander: Commander, items: NativeItemEffectCatalog) -> NativeHQManagementResult {
        let preview = dismissalPreview(profile: profile, commander: commander, items: items)
        guard preview.ok else { return .init(ok: false, reason: preview.reason) }
        profile.document["itemInventory"] = NativeHQItemInventoryCore.encode(preview.inventory)
        removeCommanderState(profile: &profile, commanderID: commander.id)
        return .init(ok: true)
    }

    public static func regroupPreview(
        profile: NativePlayerProfile,
        target: Commander,
        source: Commander,
        generalOverrides: NativePlayerGeneralOverrides,
        princessOverrides: NativePlayerPrincessOverrides
    ) -> NativeHQRegroupPreview? {
        guard target.id != source.id,
              profile.ownedCommanderIDs.contains(target.id),
              profile.ownedCommanderIDs.contains(source.id),
              !NativePlayerProfile.princessIDs.contains(source.id) else { return nil }
        let targetEffective = NativePlayerProfileCore.effectiveCommander(raw: target, playerControlled: true, profile: profile, generalOverrides: generalOverrides, princessOverrides: princessOverrides)
        let sourceEffective = NativePlayerProfileCore.effectiveCommander(raw: source, playerControlled: true, profile: profile, generalOverrides: generalOverrides, princessOverrides: princessOverrides)
        let targetGrowth = NativePlayerProfileCore.generalGrowthState(profile: profile, raw: target)
        let sourceGrowth = NativePlayerProfileCore.generalGrowthState(profile: profile, raw: source)
        let militaryGain = militaryTransfer(rank: sourceGrowth.rank, progress: sourceGrowth.militaryProgress)
        let nobleGain = nobilityTransfer(level: sourceGrowth.nobility, progress: sourceGrowth.nobilityProgress)
        let m = NativeGeneralGrowthCore.addMilitaryProgress(rank: targetGrowth.rank, progress: targetGrowth.militaryProgress, amount: militaryGain)
        let n = NativeGeneralGrowthCore.addNobilityProgress(level: targetGrowth.nobility, progress: targetGrowth.nobilityProgress, amount: nobleGain)
        let bonuses = teachingBonuses(skillIDs: sourceEffective.skillIDs)
        var stats = [
            "infantry": targetEffective.infantry, "cavalry": targetEffective.cavalry,
            "artillery": targetEffective.artillery, "warship": targetEffective.warship,
            "fort": targetEffective.fort, "business": targetEffective.business,
            "movement": targetEffective.movement, "training": targetEffective.training
        ]
        for (key, value) in bonuses where (stats[key] ?? 0) < 5 { stats[key] = min(5, (stats[key] ?? 0) + value) }
        return .init(rank: m.level, militaryProgress: m.progress, nobility: n.level, nobilityProgress: n.progress, stats: stats, militaryGain: militaryGain, nobilityGain: nobleGain, teachingBonuses: bonuses)
    }

    @discardableResult
    public static func regroup(
        profile: inout NativePlayerProfile,
        target: Commander,
        source: Commander,
        generalOverrides: NativePlayerGeneralOverrides,
        princessOverrides: NativePlayerPrincessOverrides
    ) -> NativeHQManagementResult {
        guard let preview = regroupPreview(profile: profile, target: target, source: source, generalOverrides: generalOverrides, princessOverrides: princessOverrides) else {
            return .init(ok: false, reason: target.id == source.id ? .sameCommander : .commander)
        }
        let key = String(target.id)
        NativePlayerProfileCore.setIntMapValue(&profile, key: "rank", nestedKey: key, value: preview.rank)
        NativePlayerProfileCore.setIntMapValue(&profile, key: "rankProgress", nestedKey: key, value: preview.militaryProgress)
        NativePlayerProfileCore.setIntMapValue(&profile, key: "nobility", nestedKey: key, value: preview.nobility)
        NativePlayerProfileCore.setIntMapValue(&profile, key: "nobilityProgress", nestedKey: key, value: preview.nobilityProgress)
        setObjectMapValue(profile: &profile, key: "generalStats", nestedKey: key, value: .object(Dictionary(uniqueKeysWithValues: preview.stats.map { ($0.key, .int($0.value)) })))
        // Original Regroup deletes source and its equipped items instead of returning them.
        removeCommanderState(profile: &profile, commanderID: source.id)
        return .init(ok: true)
    }

    public static func militaryTransfer(rank: Int, progress: Int) -> Int {
        let level = max(0, min(NativeGeneralGrowthCore.militaryMax, rank))
        let pct = militaryRetention[min(level, militaryRetention.count - 1)]
        var total = 300 + max(0, progress)
        if level > 0 { for i in 0..<level { total += NativeGeneralGrowthCore.militaryThresholds[i] } }
        return Int(floor(Double(total * pct) / 100.0))
    }

    public static func nobilityTransfer(level: Int, progress: Int) -> Int {
        let level = max(0, min(NativeGeneralGrowthCore.nobilityMax, level))
        let pct = nobilityRetention[min(level, nobilityRetention.count - 1)]
        var total = 60 + max(0, progress)
        if level > 0 { for i in 0..<level { total += NativeGeneralGrowthCore.nobilityThresholds[i] } }
        return Int(floor(Double(total * pct) / 100.0))
    }

    public static func teachingBonuses(skillIDs: Set<Int>) -> [String: Int] {
        var out: [String: Int] = [:]
        for id in skillIDs { if let key = teachingSkills[id] { out[key, default: 0] += 1 } }
        return out
    }

    private static func setEquipment(profile: inout NativePlayerProfile, commanderID: Int, slots: [Int?]) {
        var table: [String: NativeJSONValue] = [:]
        if case .object(let existing) = profile.document["equipment"] { table = existing }
        table[String(commanderID)] = .array(Array(slots.prefix(2)).map { $0.map(NativeJSONValue.int) ?? .null })
        profile.document["equipment"] = .object(table)
    }

    private static func removeCommanderState(profile: inout NativePlayerProfile, commanderID: Int) {
        var owned = Set(profile.ownedCommanderIDs); owned.remove(commanderID)
        profile.document["owned"] = .array(owned.sorted().map(NativeJSONValue.int))
        let key = String(commanderID)
        for tableKey in ["rank", "nobility", "rankProgress", "nobilityProgress", "generalStats"] {
            if case .object(var table) = profile.document[tableKey] { table.removeValue(forKey: key); profile.document[tableKey] = .object(table) }
        }
        setEquipment(profile: &profile, commanderID: commanderID, slots: [nil, nil])
    }

    private static func setObjectMapValue(profile: inout NativePlayerProfile, key: String, nestedKey: String, value: NativeJSONValue) {
        var table: [String: NativeJSONValue] = [:]
        if case .object(let existing) = profile.document[key] { table = existing }
        table[nestedKey] = value; profile.document[key] = .object(table)
    }

    private static func validItem(_ value: Int?) -> Int? { guard let value, value >= 0 else { return nil }; return value }
    private static func jsonInt(_ value: NativeJSONValue) -> Int? {
        switch value { case .int(let n): return n; case .double(let n): return Int(n); case .string(let s): return Int(s); default: return nil }
    }
}
