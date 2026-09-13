import Foundation
import Testing
@testable import EW4NativeCore

private func p39SaveFixture() -> NativeBattleSaveState {
    NativeBattleSaveState(
        battleFile: "campaign1_01.btl",
        battleTitle: "土伦港之战",
        map: "europe",
        mode: "campaign",
        playerOwner: 0,
        round: 7,
        resources: CountryResources(money: 123, industry: 45, food: 67),
        countryResources: [
            "0": CountryResources(money: 123, industry: 45, food: 67),
            "1": CountryResources(money: 88, industry: 99, food: 111)
        ],
        camera: NativeSaveCamera(x: 100, y: 200, zoom: 1.3),
        cameraGeometry: "native-odd-r-64x54-v1",
        units: [[
            "index": .int(1), "q": .int(2), "r": .int(3), "hp": .int(88),
            "max_hp": .int(120), "owner": .int(0), "dead": .bool(false),
            "moved": .bool(true), "attacked": .bool(false),
            "moveAnim": .object(["x": .int(1)]), "attackPoseUntil": .int(999)
        ]],
        objects: [["pos": .int(99), "q": .int(2), "r": .int(3), "owner": .int(0), "construction_type": .string("city")]],
        ownership: [0, 1, 255],
        assignments: [[1, 7]],
        installations: [["q": .int(2), "r": .int(3), "type": .string("trench"), "owner": .int(0)]],
        fireCells: ["4,5"],
        nativeFiredEvents: ["1:10"],
        nativeAppliedEvents: ["2:20"],
        itemStores: .object(["99": .object(["slots": .array([.object(["item": .int(1), "count": .int(1), "active": .bool(true)])])])]),
        taverns: .object(["99": .object(["count": .int(1), "slots": .array([.object(["commander": .int(3), "money": .int(1), "industry": .int(1), "medal": .int(0), "round": .int(1)])])])]),
        collectMedal: 7,
        campaignTech: Array(-3...30),
        campaignTechZone: 9,
        ended: nil
    )
}

@Test func battleSaveSchema6EnvelopeMatchesP39Contract() throws {
    let payload = try NativeBattleSaveCore.makePayload(from: p39SaveFixture(), savedAt: 123456)
    #expect(payload.schema == 6)
    #expect(payload.gameVersion == 61)
    #expect(payload.savedAt == 123456)
    #expect(payload.cameraGeometry == "native-odd-r-64x54-v1")
    #expect(payload.units[0]["moveAnim"] == nil)
    #expect(payload.units[0]["attackPoseUntil"] == nil)
    #expect(payload.collectMedal == 7)
    #expect(payload.campaignTech?.count == 26)
    #expect(payload.campaignTech?.first == -1)
    #expect(payload.campaignTech?.last == 3)
    #expect(payload.campaignTechZone == 6)
}

@Test func battleSaveRoundTripClampsCameraAndPreservesExtendedState() throws {
    let payload = try NativeBattleSaveCore.makePayload(from: p39SaveFixture(), savedAt: 1)
    let data = try NativeBattleSaveCore.encode(payload)
    let normalized = try NativeBattleSaveCore.decode(data)
    #expect(normalized.round == 7)
    #expect(normalized.camera.zoom == 1)
    #expect(normalized.assignments == [[1, 7]])
    #expect(normalized.fireCells.contains("4,5"))
    #expect(normalized.countryResources?["1"]?.industry == 99)
    #expect(normalized.nativeFiredEvents.contains("1:10"))
    #expect(normalized.nativeAppliedEvents.contains("2:20"))
    if case .object(let taverns)? = normalized.taverns,
       case .object(let tavern)? = taverns["99"],
       case .array(let slots)? = tavern["slots"],
       case .object(let first)? = slots.first {
        #expect(first["commander"] == .int(3))
    } else {
        Issue.record("tavern state was not preserved")
    }
}

@Test func battleSaveAcceptsLegacySchema1Through6AndDefaultsNewFields() throws {
    let current = try NativeBattleSaveCore.makePayload(from: p39SaveFixture(), savedAt: 1)
    for schema in 1...6 {
        var legacy = current
        legacy.schema = schema
        if schema < 5 { legacy.collectMedal = nil }
        if schema < 6 { legacy.campaignTech = nil; legacy.campaignTechZone = nil }
        #expect(NativeBattleSaveCore.validate(legacy))
        let normalized = try NativeBattleSaveCore.normalize(legacy)
        #expect(normalized.collectMedal == (schema < 5 ? 0 : 7))
        #expect(normalized.campaignTechZone == (schema < 6 ? 0 : 6))
    }
    var invalid = current
    invalid.schema = 7
    #expect(!NativeBattleSaveCore.validate(invalid))
}
