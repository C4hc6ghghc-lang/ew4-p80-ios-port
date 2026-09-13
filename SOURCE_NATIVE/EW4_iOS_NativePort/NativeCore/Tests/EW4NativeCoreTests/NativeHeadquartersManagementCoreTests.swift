import Foundation
import Testing
@testable import EW4NativeCore

struct NativeHeadquartersManagementCoreTests {
    private func commander(_ id: Int, skills: [Int] = [], items: [Int?] = [nil,nil], rank: Int = 0, noble: Int = 0) -> Commander {
        let json: [String: Any] = [
            "id": id, "name": "G\(id)", "country": "fra", "rank": rank, "nobilityrank": noble, "star": 4,
            "infantry": 3, "cavalry": 2, "artillery": 1, "warship": 0, "fort": 0, "business": 1, "movement": 3, "training": 2,
            "skill1": skills.indices.contains(0) ? skills[0] : -1, "skill2": skills.indices.contains(1) ? skills[1] : -1,
            "skill3": skills.indices.contains(2) ? skills[2] : -1, "skill4": skills.indices.contains(3) ? skills[3] : -1,
            "item1": items[0] ?? -1, "item2": items[1] ?? -1, "price": 100, "drawlots": 1
        ]
        return try! JSONDecoder().decode(Commander.self, from: JSONSerialization.data(withJSONObject: json))
    }

    private let globals = NativePlayerGeneralOverrides(version: 1, scope: "player", global: .init(rankMaxLevel: 14, nobilityMaxLevel: 9, rankHpBonusCap: 500, nobilityHealCap: 25, movementOverridesMayExceedOriginalCap: true), generals: [:])
    private let princess = NativePlayerPrincessOverrides(version: 1, scope: "player", unlock: .init(allPrincessesImmediatelyAvailable: true, ids: NativePlayerProfile.princessIDs), princesses: [:])

    @Test func equipmentSwapReturnsOldItemAndConsumesSelectedInventorySlot() {
        let c = commander(9001, items: [10,nil])
        let items: NativeItemEffectCatalog = ["10": .init(name:"Old",id:10,function:11,value:1), "11": .init(name:"New",id:11,function:11,value:2)]
        var p = NativePlayerProfile(document: ["owned": .array([.int(9001)]), "itemInventory": NativeHQItemInventoryCore.encode(.init(slots:[.init(item:11,count:1)]))])
        let r = NativeHeadquartersManagementCore.equip(profile:&p, commander:c, slot:0, inventoryIndex:0, items:items, generalOverrides:globals, princessOverrides:princess)
        #expect(r.ok)
        #expect(NativeHeadquartersManagementCore.equipmentPair(profile:p, commander:c) == [11,nil])
        let bank = NativeHQItemInventoryCore.decode(p.document["itemInventory"])
        #expect(bank.count(itemID: 10) == 1)
        #expect(bank.count(itemID: 11) == 0)
    }

    @Test func consumableAndFlagLockAreRejectedWithoutMutation() {
        let c = commander(9002)
        let items: NativeItemEffectCatalog = [
            "20": .init(name:"Med",id:20,function:0,value:1,consumable:"1"),
            "21": .init(name:"Flag",id:21,function:13,value:1,flag:"1")
        ]
        let initial = NativeHQItemInventoryCore.encode(.init(slots:[.init(item:20,count:2),.init(item:21,count:1)]))
        var p = NativePlayerProfile(document:["owned":.array([.int(9002)]),"itemInventory":initial])
        let a = NativeHeadquartersManagementCore.equip(profile:&p, commander:c, slot:0, inventoryIndex:0, items:items, generalOverrides:globals, princessOverrides:princess)
        #expect(a.reason == .consumable)
        let b = NativeHeadquartersManagementCore.equip(profile:&p, commander:c, slot:0, inventoryIndex:1, items:items, generalOverrides:globals, princessOverrides:princess)
        #expect(b.reason == .flagSkill)
        #expect(NativeHQItemInventoryCore.decode(p.document["itemInventory"]).count(itemID: 21) == 1)
    }

    @Test func dismissReturnsEquipmentButRegroupDeletesSourceEquipment() {
        let target = commander(9101)
        let source = commander(9102, skills:[33], items:[31,32], rank:2, noble:1)
        let items: NativeItemEffectCatalog = ["31":.init(name:"A",id:31,function:11,value:1),"32":.init(name:"B",id:32,function:11,value:1)]
        var dismissed = NativePlayerProfile(document:["owned":.array([.int(9101),.int(9102)])])
        let dr = NativeHeadquartersManagementCore.dismiss(profile:&dismissed, commander:source, items:items)
        #expect(dr.ok)
        #expect(!dismissed.ownedCommanderIDs.contains(9102))
        #expect(NativeHQItemInventoryCore.decode(dismissed.document["itemInventory"]).count(itemID:31) == 1)

        var regrouped = NativePlayerProfile(document:["owned":.array([.int(9101),.int(9102)])])
        let rr = NativeHeadquartersManagementCore.regroup(profile:&regrouped, target:target, source:source, generalOverrides:globals, princessOverrides:princess)
        #expect(rr.ok)
        #expect(!regrouped.ownedCommanderIDs.contains(9102))
        #expect(NativeHQItemInventoryCore.decode(regrouped.document["itemInventory"]).count(itemID:31) == 0)
        #expect(regrouped.intMap("generalStats")["9101"] == nil) // nested stat map is intentionally not flattened
        if case .object(let gs) = regrouped.document["generalStats"], case .object(let row) = gs["9101"] {
            #expect(row["infantry"] == .int(4))
        } else { Issue.record("missing regroup target stats") }
    }

    @Test func transferTablesMatchMatureControllerContract() {
        #expect(NativeHeadquartersManagementCore.militaryTransfer(rank:0, progress:0) == 300)
        #expect(NativeHeadquartersManagementCore.nobilityTransfer(level:0, progress:0) == 60)
        #expect(NativeHeadquartersManagementCore.militaryTransfer(rank:1, progress:100) == 873)
        #expect(NativeHeadquartersManagementCore.nobilityTransfer(level:1, progress:20) == 172)
    }
    @Test func dismissalBlocksAtomicallyWhenReturnedEquipmentCannotFit() {
        let source = commander(9202, items: [41, 42])
        let items: NativeItemEffectCatalog = [
            "41": .init(name:"A",id:41,function:11,value:1),
            "42": .init(name:"B",id:42,function:11,value:1),
            "99": .init(name:"Filler",id:99,function:11,value:1)
        ]
        var slots = Array(repeating: NativeItemInventorySlot(item: 99, count: 1), count: 27)
        slots.append(.init())
        var profile = NativePlayerProfile(document:["owned":.array([.int(9202)]), "itemInventory":NativeHQItemInventoryCore.encode(.init(slots:slots))])
        let before = profile
        let result = NativeHeadquartersManagementCore.dismiss(profile:&profile, commander:source, items:items)
        #expect(result.reason == .full)
        #expect(profile == before)
        #expect(profile.ownedCommanderIDs.contains(9202))
    }

}
