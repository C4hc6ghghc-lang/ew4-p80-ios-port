import Foundation
import Testing
@testable import EW4NativeCore

struct NativeBattleTavernCoreTests {
    private func commander(_ id: Int) -> Commander {
        let j:[String:Any] = ["id":id,"name":"G\(id)","country":"fra","rank":0,"nobilityrank":0,"star":4,"infantry":1,"cavalry":1,"artillery":1,"warship":1,"fort":1,"business":1,"movement":1,"training":1,"skill1":-1,"skill2":-1,"skill3":-1,"skill4":-1,"item1":-1,"item2":-1,"price":1,"drawlots":1]
        return try! JSONDecoder().decode(Commander.self, from: JSONSerialization.data(withJSONObject:j))
    }
    private var catalog: NativeJSONValue { .object(["battles":.object(["x.btl":.object(["3101":.object(["object_index":.int(21),"file_offset":.int(9),"count":.int(5),"slots":.array([
        .object(["commander":.int(3),"money":.int(10),"industry":.int(5),"medal":.int(2),"round":.int(1)]),
        .object(["commander":.int(5),"money":.int(20),"industry":.int(6),"medal":.int(3),"round":.int(2)]),
        .object(["commander":.int(7),"money":.int(30),"industry":.int(7),"medal":.int(4),"round":.int(3)]),
        .object(["commander":.int(9),"money":.int(40),"industry":.int(8),"medal":.int(5),"round":.int(4)]),
        .object(["commander":.int(4),"money":.int(50),"industry":.int(9),"medal":.int(6),"round":.int(5)])])])])])]) }

    @Test func initialCatalogNormalizesAndFindsByObjectIndex() {
        let state = NativeBattleTavernCore.initialState(catalog: catalog, battleFile: "x.btl")
        let rec = NativeBattleTavernCore.record(taverns: state, objectIndex: 21)
        #expect(rec?.key == "3101"); #expect(rec?.count == 5); #expect(rec?.slots[0]?.commander == 3); #expect(rec?.slots[4]?.round == 5)
    }

    @Test func recruitmentUsesMoneyAndIndustryButDoesNotDeductMedalAndShiftsQueue() {
        var state = NativeBattleTavernCore.initialState(catalog: catalog, battleFile: "x.btl")
        var resources = CountryResources(money: 100, industry: 50, food: 9)
        var profile = NativePlayerProfile(document:["owned":.array([])])
        let commanders = [3:commander(3),5:commander(5),7:commander(7),9:commander(9),4:commander(4)]
        let result = NativeBattleTavernCore.recruit(taverns:&state, objectIndex:21, candidateIndex:0, round:3, resources:&resources, profile:&profile, commanders:commanders)
        #expect(result.ok); #expect(result.commanderID == 3); #expect(resources.money == 90); #expect(resources.industry == 45); #expect(resources.food == 9)
        #expect(profile.ownedCommanderIDs.contains(3))
        let after = NativeBattleTavernCore.record(taverns: state, objectIndex: 21)
        #expect(after?.count == 4); #expect(after?.slots[0]?.commander == 5); #expect(after?.slots[3]?.commander == 4); #expect(after?.slots[4] == nil)
    }

    @Test func recruitmentHonorsRoundOwnedAndResourceLocksWithoutMutation() {
        let commanders = [3:commander(3),5:commander(5),7:commander(7),9:commander(9),4:commander(4)]
        var state = NativeBattleTavernCore.initialState(catalog: catalog, battleFile: "x.btl")
        var resources = CountryResources(money: 100, industry: 50, food: 9)
        var profile = NativePlayerProfile(document:["owned":.array([])])
        let roundLock = NativeBattleTavernCore.recruit(taverns:&state, objectIndex:21, candidateIndex:2, round:1, resources:&resources, profile:&profile, commanders:commanders)
        #expect(roundLock.availability == .roundLocked); #expect(resources.money == 100)
        profile.document["owned"] = .array([.int(3)])
        let owned = NativeBattleTavernCore.recruit(taverns:&state, objectIndex:21, candidateIndex:0, round:9, resources:&resources, profile:&profile, commanders:commanders)
        #expect(owned.availability == .owned)
        profile.document["owned"] = .array([]); resources.money = 0
        let poor = NativeBattleTavernCore.recruit(taverns:&state, objectIndex:21, candidateIndex:0, round:9, resources:&resources, profile:&profile, commanders:commanders)
        #expect(poor.availability == .resources)
    }
}
