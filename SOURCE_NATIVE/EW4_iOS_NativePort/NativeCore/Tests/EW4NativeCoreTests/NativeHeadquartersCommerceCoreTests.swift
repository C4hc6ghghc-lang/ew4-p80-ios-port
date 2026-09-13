import Foundation
import Testing
@testable import EW4NativeCore

private func item(_ id: Int, price: Int, consumable: Bool = false) -> NativeItemEffectDefinition {
    let extra = consumable ? ",\"consumable\":\"1\"" : ""
    let json = "{\"name\":\"I\(id)\",\"id\":\(id),\"function\":0,\"value\":0,\"target\":\"all\",\"price\":\(price)\(extra)}"
    return try! JSONDecoder().decode(NativeItemEffectDefinition.self, from: Data(json.utf8))
}

private func commander(_ id: Int, star: Int, price: Int = 100, drawlots: Int = 1) -> Commander {
    let json = "{\"id\":\(id),\"name\":\"C\(id)\",\"country\":\"fra\",\"rank\":1,\"nobilityrank\":1,\"star\":\(star),\"infantry\":1,\"cavalry\":1,\"artillery\":1,\"warship\":1,\"fort\":1,\"business\":1,\"movement\":1,\"training\":1,\"skill1\":-1,\"skill2\":-1,\"skill3\":-1,\"skill4\":-1,\"item1\":-1,\"item2\":-1,\"price\":\(price),\"drawlots\":\(drawlots)}"
    return try! JSONDecoder().decode(Commander.self, from: Data(json.utf8))
}

@Test func headquartersItemBankUsesNativeStackRules() {
    let items = ["11": item(11, price: 5, consumable: true), "1": item(1, price: 100)]
    var bank = NativeItemInventoryBank()
    bank = NativeHQItemInventoryCore.add(bank, itemID: 11, amount: 120, items: items)!
    #expect(bank.slots[0] == NativeItemInventorySlot(item: 11, count: 120))
    bank = NativeHQItemInventoryCore.add(bank, itemID: 1, amount: 2, items: items)!
    #expect(bank.count(itemID: 1) == 2)
    #expect(NativeHQItemInventoryCore.decode(NativeHQItemInventoryCore.encode(bank)) == bank)
}

@Test func headquartersShopDailyStockAndPurchasePersist() {
    let items = [
        "11": item(11, price: 5, consumable: true),
        "12": item(12, price: 10, consumable: true),
        "1": item(1, price: 100), "2": item(2, price: 200), "3": item(3, price: 300)
    ]
    var profile = NativePlayerProfile.fresh()
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let store = NativeHQShopCore.ensureStore(profile: &profile, items: items, date: date, timeZone: TimeZone(secondsFromGMT: 0)!, random: { 0 })
    #expect(store.slots.count == 14)
    #expect(store.slots[0]?.item == 11)
    #expect(store.slots[6]?.item == 1)
    #expect(store.slots[7]?.item == 2)
    #expect(NativeHQShopCore.buy(profile: &profile, sellerIndex: 0, items: items) == 11)
    #expect(NativeHQItemInventoryCore.decode(profile.document["itemInventory"]).count(itemID: 11) == 1)
}

@Test func academyKeepsNativeSixFourTwoTiersAndInfiniteCurrencyPurchase() {
    var commanders: [Int: Commander] = [:]
    var id = 1
    for star in 1...8 {
        for _ in 0..<6 { commanders[id] = commander(id, star: star, price: 100 + id); id += 1 }
    }
    var profile = NativePlayerProfile.fresh()
    let pools = NativeAcademyCore.ensurePools(profile: &profile, commanders: commanders, random: { 0 })
    #expect(pools["6"]?.count == 6)
    #expect(pools["4"]?.count == 4)
    #expect(pools["2"]?.count == 2)
    guard let row = pools["2"], let target = row.compactMap({ $0 }).first else { Issue.record("missing tier-2 candidate"); return }
    #expect(NativeAcademyCore.acquire(profile: &profile, commanders: commanders, tier: "2", commanderID: target, currency: "medal"))
    #expect(profile.ownedCommanderIDs.contains(target))
    #expect(NativeAcademyCore.decodePools(profile.document["academyCandidatesByPool"])["2"]?.contains(where: { $0 == target }) == false)
}

@Test func academyPurchasedOutFixedNullPoolsStayPersistedInsteadOfRerolling() {
    var commanders: [Int: Commander] = [:]
    var id = 1
    for star in 1...8 {
        for _ in 0..<6 { commanders[id] = commander(id, star: star, price: 100 + id); id += 1 }
    }
    var profile = NativePlayerProfile.fresh()
    profile.document["academyCandidatesByPool"] = .object([
        "6": .array(Array(repeating: .null, count: 6)),
        "4": .array(Array(repeating: .null, count: 4)),
        "2": .array(Array(repeating: .null, count: 2))
    ])
    let pools = NativeAcademyCore.ensurePools(profile: &profile, commanders: commanders, random: { 0 })
    #expect(pools["6"] == Array<Int?>(repeating: nil, count: 6))
    #expect(pools["4"] == Array<Int?>(repeating: nil, count: 4))
    #expect(pools["2"] == Array<Int?>(repeating: nil, count: 2))
}
