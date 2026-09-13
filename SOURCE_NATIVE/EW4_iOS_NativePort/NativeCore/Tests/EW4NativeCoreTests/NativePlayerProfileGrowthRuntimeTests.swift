import XCTest
@testable import EW4NativeCore

final class NativePlayerProfileGrowthRuntimeTests: XCTestCase {
    private func resources() throws -> (NativeResourceStoreFixture, [Int: Commander], NativeItemEffectCatalog, NativePlayerGeneralOverrides, NativePlayerPrincessOverrides) {
        let fixture = try NativeResourceStoreFixture()
        return (fixture, try fixture.commanders(), try fixture.items(), try fixture.generalOverrides(), try fixture.princessOverrides())
    }

    func testRuntimeProviderSeesRankGrowthImmediately() throws {
        let (_, commanders, items, generalOverrides, princessOverrides) = try resources()
        let napoleon = try XCTUnwrap(commanders[1] ?? commanders.values.first(where: { $0.name.lowercased().contains("napoleon") }))
        var profile = NativePlayerProfile.fresh()
        profile.document["owned"] = .array([.int(napoleon.id)] + NativePlayerProfile.princessIDs.map(NativeJSONValue.int))
        NativePlayerProfileCore.setIntMapValue(&profile, key: "rank", nestedKey: String(napoleon.id), value: 0)
        NativePlayerProfileCore.setIntMapValue(&profile, key: "rankProgress", nestedKey: String(napoleon.id), value: 499)
        let runtime = NativePlayerProfileRuntime(profile)
        let provider = NativePlayerProfileCore.makeRuntimeProvider(runtime: runtime, commanders: commanders, generalOverrides: generalOverrides, princessOverrides: princessOverrides)
        let before = try XCTUnwrap(provider(napoleon.id, true))
        let application = try XCTUnwrap(runtime.applyCombatGrowth(commander: napoleon, damage: 1, killed: false, victimGrade: 0, victimHasCommander: false, itemEffects: items, generalOverrides: generalOverrides, princessOverrides: princessOverrides))
        let after = try XCTUnwrap(provider(napoleon.id, true))
        XCTAssertEqual(application.award.after.rank, 1)
        XCTAssertGreaterThan(after.rankHPBonus, before.rankHPBonus)
        XCTAssertEqual(application.rankHPDelta, after.rankHPBonus - before.rankHPBonus)
    }

    func testUnownedCommanderDoesNotGainPlayerGrowth() throws {
        let (_, commanders, items, generalOverrides, princessOverrides) = try resources()
        let raw = try XCTUnwrap(commanders.values.first(where: { !NativePlayerProfile.princessIDs.contains($0.id) }))
        var profile = NativePlayerProfile.fresh()
        profile.document["owned"] = .array(NativePlayerProfile.princessIDs.map(NativeJSONValue.int))
        let before = profile
        let out = NativePlayerProfileCore.applyCombatGrowth(profile: &profile, commander: raw, damage: 999, killed: true, victimGrade: 5, victimHasCommander: true, itemEffects: items, generalOverrides: generalOverrides, princessOverrides: princessOverrides)
        XCTAssertNil(out)
        XCTAssertEqual(profile, before)
    }

    func testGrowthEquipmentOverridesSkillUsingRealItemCatalog() throws {
        let (_, commanders, items, generalOverrides, princessOverrides) = try resources()
        let raw = try XCTUnwrap(commanders.values.first)
        var profile = NativePlayerProfile.fresh()
        profile.document["owned"] = .array([.int(raw.id)] + NativePlayerProfile.princessIDs.map(NativeJSONValue.int))
        guard let growthItem = items.values.filter({ $0.function == 2 }).max(by: { $0.value < $1.value }) else {
            throw XCTSkip("No function=2 item in catalog")
        }
        profile.document["equipment"] = .object([String(raw.id): .array([.int(growthItem.id)])])
        NativePlayerProfileCore.setIntMapValue(&profile, key: "rank", nestedKey: String(raw.id), value: 0)
        NativePlayerProfileCore.setIntMapValue(&profile, key: "rankProgress", nestedKey: String(raw.id), value: 0)
        let before = NativePlayerProfileCore.generalGrowthState(profile: profile, raw: raw)
        let out = try XCTUnwrap(NativePlayerProfileCore.applyCombatGrowth(profile: &profile, commander: raw, damage: 10, killed: false, victimGrade: 0, victimHasCommander: false, itemEffects: items, generalOverrides: generalOverrides, princessOverrides: princessOverrides))
        XCTAssertEqual(out.award.militaryGain, Int(floor(20.0 * Double(growthItem.value) / 100.0)))
        XCTAssertNotEqual(out.award.after.militaryProgress, before.militaryProgress)
    }
}

private struct NativeResourceStoreFixture {
    let root: URL
    init() throws { root = TestResourcePaths.resources }
    func decode<T: Decodable>(_ type: T.Type, _ relative: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(contentsOf: root.appendingPathComponent(relative)))
    }
    func commanders() throws -> [Int: Commander] {
        let rows: [String: Commander] = try decode([String: Commander].self, "Data/commanders.json")
        return Dictionary(uniqueKeysWithValues: rows.values.map { ($0.id, $0) })
    }
    func items() throws -> NativeItemEffectCatalog { try decode(NativeItemEffectCatalog.self, "Data/items.json") }
    func generalOverrides() throws -> NativePlayerGeneralOverrides { try decode(NativePlayerGeneralOverrides.self, "Data/player_general_overrides.json") }
    func princessOverrides() throws -> NativePlayerPrincessOverrides { try decode(NativePlayerPrincessOverrides.self, "Data/player_princess_overrides.json") }
}
