import Testing
@testable import EW4NativeCore

@Suite("Native battle shop parity")
struct NativeBattleShopCoreTests {
    private func catalog() -> NativeJSONValue {
        .object(["battles": .object(["tutorials1.btl": .object(["777": .object([
            "object_index": .int(4),
            "slots": .array([
                .object(["item": .int(11), "count": .int(2)]),
                .object(["item": .int(53), "count": .int(1)])
            ])
        ])])])])
    }

    @Test func initialStateFindsStoreByObjectIndexAndConsumesSellerSlot() throws {
        var state = NativeBattleShopCore.initialState(catalog: catalog(), battleFile: "tutorials1.btl")
        #expect(NativeBattleShopCore.record(itemStores: state, objectIndex: 4)?.storeID == "777")
        var profile = NativePlayerProfile.fresh()
        let items: NativeItemEffectCatalog = [
            "11": .init(name: "Wine", id: 11, function: 7, value: 0, price: 20, consumable: "1"),
            "53": .init(name: "Flag", id: 53, function: 0, value: 0, price: 100, consumable: "0")
        ]
        #expect(NativeBattleShopCore.buy(itemStores: &state, objectIndex: 4, sellerIndex: 0, profile: &profile, items: items) == 11)
        #expect(NativeBattleShopCore.record(itemStores: state, objectIndex: 4)?.slots[0]?.count == 1)
        #expect(NativeHQItemInventoryCore.decode(profile.document["itemInventory"]).count(itemID: 11) == 1)
    }

    @Test func recoveredBusinessPricingMatchesMatureTruth() {
        let item = NativeItemEffectDefinition(name: "x", id: 1, function: 0, value: 0, price: 101)
        #expect(NativeBattleShopCore.buyPrice(item, business: 0) == 101)
        #expect(NativeBattleShopCore.buyPrice(item, business: 5) == 81)
        #expect(NativeBattleShopCore.sellPrice(item, business: 0) == 60)
        #expect(NativeBattleShopCore.sellPrice(item, business: 5) == 80)
    }
}
