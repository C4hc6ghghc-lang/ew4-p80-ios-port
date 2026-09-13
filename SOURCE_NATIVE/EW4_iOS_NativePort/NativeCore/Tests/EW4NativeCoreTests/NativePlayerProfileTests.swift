import Foundation
import Testing
@testable import EW4NativeCore

private func p46ProfileResources() throws -> (
    [Int: Commander],
    NativePlayerGeneralOverrides,
    NativePlayerPrincessOverrides
) {
    let raw = try ResourceLoader.decode([String: Commander].self, from: TestResourcePaths.data("commanders.json"))
    let commanders = Dictionary(uniqueKeysWithValues: raw.values.map { ($0.id, $0) })
    let generalOverrides = try ResourceLoader.decode(NativePlayerGeneralOverrides.self, from: TestResourcePaths.data("player_general_overrides.json"))
    let princessOverrides = try ResourceLoader.decode(NativePlayerPrincessOverrides.self, from: TestResourcePaths.data("player_princess_overrides.json"))
    return (commanders, generalOverrides, princessOverrides)
}

@Test func freshProfileMatchesP39CoreDefaultsAndUnlocksAllPrincesses() throws {
    let p = NativePlayerProfile.fresh()
    #expect(Set(NativePlayerProfile.princessIDs).isSubset(of: Set(p.ownedCommanderIDs)))
    #expect(p.document["version"] == .int(61))
    #expect(p.document["academyPool"] == .string("6"))
    #expect(p.document["music"] == .bool(true))
    #expect(p.document["bgVol"] == .int(50))
    #expect(p.document["seVol"] == .int(50))
    #expect(p.document["gameSpeed"] == .int(2))
    #expect(p.document["showGrids"] == .bool(false))
    #expect(p.document["campaignStars"] == .int(0))
    #expect(p.document["warzoneTech"] == .null)
    guard case .object(let bank) = p.document["itemInventory"],
          case .array(let slots) = bank["slots"] else {
        Issue.record("missing P39 itemInventory")
        return
    }
    #expect(bank["schema"] == .int(1))
    #expect(slots.count == 28)
    guard case .object(let pools) = p.document["academyCandidatesByPool"] else {
        Issue.record("missing academy pools")
        return
    }
    #expect(pools["6"] == .array([]))
    #expect(pools["4"] == .array([]))
    #expect(pools["2"] == .array([]))
}

@Test func profileUnknownFieldsSurviveLosslessRoundTrip() throws {
    let source = NativePlayerProfile(document: [
        "owned": .array([.int(99)]),
        "futureNativeField": .object(["nested": .array([.string("keep"), .int(7)])])
    ])
    let decoded = try NativePlayerProfile.decode(source.encoded())
    #expect(decoded.document["futureNativeField"] == .object(["nested": .array([.string("keep"), .int(7)])]))
    #expect(decoded.ownedCommanderIDs.contains(99))
    #expect(Set(NativePlayerProfile.princessIDs).isSubset(of: Set(decoded.ownedCommanderIDs)))
}

@Test func napoleonPlayerEffectiveCommanderMatchesP39OverrideUnion() throws {
    let (commanders, generalOverrides, princessOverrides) = try p46ProfileResources()
    let raw = try #require(commanders[1])
    let effective = NativePlayerProfileCore.effectiveCommander(
        raw: raw,
        playerControlled: true,
        profile: .fresh(),
        generalOverrides: generalOverrides,
        princessOverrides: princessOverrides
    )
    #expect(effective.infantry == 5)
    #expect(effective.movement == 7)
    #expect(effective.artillery == raw.artillery)
    #expect(effective.skillIDs == raw.skillIDs.union([8, 1, 31, 5, 7, 32, 4, 3]))
    #expect(effective.rankLevel == 8)
    #expect(effective.nobilityLevel == 4)
    #expect(effective.rankHPBonus == 571) // round(1000 * 8 / 14)
    #expect(effective.nobilityHealCap == 100)
}

@Test func persistedPlayerGrowthAndEquipmentOverrideEffectiveCommander() throws {
    let (commanders, generalOverrides, princessOverrides) = try p46ProfileResources()
    let raw = try #require(commanders[1])
    let profile = NativePlayerProfile(document: [
        "rank": .object(["1": .int(14)]),
        "nobility": .object(["1": .int(9)]),
        "generalStats": .object(["1": .object(["infantry": .int(6), "movement": .int(8)])]),
        "equipment": .object(["1": .array([.int(10), .int(46)])])
    ])
    let effective = NativePlayerProfileCore.effectiveCommander(
        raw: raw,
        playerControlled: true,
        profile: profile,
        generalOverrides: generalOverrides,
        princessOverrides: princessOverrides
    )
    #expect(effective.infantry == 6)
    #expect(effective.movement == 8)
    #expect(effective.equippedItemIDs == [10, 46])
    #expect(effective.rankLevel == 14)
    #expect(effective.nobilityLevel == 9)
    #expect(effective.rankHPBonus == 1000)
    #expect(effective.nobilityHealCap == 100)
}

@Test func aiCommanderNeverConsumesPlayerProfileOrOverrides() throws {
    let (commanders, generalOverrides, princessOverrides) = try p46ProfileResources()
    let raw = try #require(commanders[1])
    let profile = NativePlayerProfile(document: [
        "rank": .object(["1": .int(14)]),
        "nobility": .object(["1": .int(9)]),
        "generalStats": .object(["1": .object(["infantry": .int(8), "movement": .int(8)])]),
        "equipment": .object(["1": .array([.int(10), .int(46)])])
    ])
    let effective = NativePlayerProfileCore.effectiveCommander(
        raw: raw,
        playerControlled: false,
        profile: profile,
        generalOverrides: generalOverrides,
        princessOverrides: princessOverrides
    )
    #expect(effective.infantry == raw.infantry)
    #expect(effective.movement == raw.movement)
    #expect(effective.skillIDs == raw.skillIDs)
    #expect(effective.equippedItemIDs.isEmpty)
    #expect(effective.rankLevel == raw.rank)
    #expect(effective.nobilityLevel == raw.nobilityrank)
    #expect(effective.rankHPBonus == 0)
    #expect(effective.nobilityHealCap == 0)
}

@Test func princessOverridesAffectOnlySpecifiedThreePrincesses() throws {
    let (commanders, generalOverrides, princessOverrides) = try p46ProfileResources()
    #expect(Set(princessOverrides.princesses.keys) == Set(["204", "205", "208"]))

    let lanRaw = try #require(commanders[208])
    let lan = NativePlayerProfileCore.effectiveCommander(raw: lanRaw, playerControlled: true, profile: .fresh(), generalOverrides: generalOverrides, princessOverrides: princessOverrides)
    #expect(lan.infantry == 5)
    #expect(lan.cavalry == 5)
    #expect(lan.movement == 7)
    #expect(lan.skillIDs.isSuperset(of: [11, 34, 12, 13, 14, 15, 33, 32, 4]))

    let mariaRaw = try #require(commanders[201])
    let maria = NativePlayerProfileCore.effectiveCommander(raw: mariaRaw, playerControlled: true, profile: .fresh(), generalOverrides: generalOverrides, princessOverrides: princessOverrides)
    #expect(maria.infantry == mariaRaw.infantry)
    #expect(maria.cavalry == mariaRaw.cavalry)
    #expect(maria.movement == mariaRaw.movement)
    #expect(maria.skillIDs == mariaRaw.skillIDs)
}

@Test func playerProfileStoreAtomicRoundTripAndCorruptFallback() throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("ew4-profile-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = NativePlayerProfileStore(directory: directory)
    let profile = NativePlayerProfile(document: ["owned": .array([.int(1)]), "future": .string("preserve")])
    try store.save(profile)
    let loaded = store.load()
    #expect(loaded.document["future"] == .string("preserve"))
    #expect(loaded.ownedCommanderIDs.contains(1))
    #expect(Set(NativePlayerProfile.princessIDs).isSubset(of: Set(loaded.ownedCommanderIDs)))

    try Data("{ definitely corrupt".utf8).write(to: store.fileURL)
    let fallback = store.load()
    #expect(Set(NativePlayerProfile.princessIDs).isSubset(of: Set(fallback.ownedCommanderIDs)))
    #expect(fallback.document["version"] == .int(61))
}
