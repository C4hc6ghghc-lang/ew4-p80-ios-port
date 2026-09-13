import Foundation
import Testing
@testable import EW4NativeCore

private func p71CoreRoot() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
}

private func p71PackageRoot() -> URL {
    p71CoreRoot().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
}

private func p71Commander() throws -> Commander {
    let data = try Data(contentsOf: TestResourcePaths.data("commanders.json"))
    let rows = try JSONDecoder().decode([String: Commander].self, from: data)
    return try #require(rows.values.first(where: { !NativePlayerProfile.princessIDs.contains($0.id) }))
}

@Test func p71GeneralUpgradeCostMathMatchesMatureP39() {
    #expect(NativeGeneralUpgradeCore.nextMilitaryCost(rank: 0, progress: 0) == 4)
    #expect(NativeGeneralUpgradeCore.nextMilitaryCost(rank: 0, progress: 250) == 2)
    #expect(NativeGeneralUpgradeCore.nextMilitaryCost(rank: 14, progress: 0) == 0)
    #expect(NativeGeneralUpgradeCore.nextNobilityCost(level: 0, progress: 0) == 20)
    #expect(NativeGeneralUpgradeCore.nextNobilityCost(level: 0, progress: 50) == 10)
    #expect(NativeGeneralUpgradeCore.nextNobilityCost(level: 9, progress: 0) == 0)
    #expect(NativeGeneralUpgradeCore.allFullCost(rank: 0, militaryProgress: 0, nobility: 0, nobilityProgress: 0) == 3600)
    #expect(NativeGeneralUpgradeCore.allFullCost(rank: 14, militaryProgress: 0, nobility: 9, nobilityProgress: 0) == 0)
}

@Test func p71GeneralUpgradeAppliesGrowthWithoutSpendingMedals() throws {
    let commander = try p71Commander()
    var profile = NativePlayerProfile.fresh()
    profile.document["owned"] = .array([.int(commander.id)] + NativePlayerProfile.princessIDs.map(NativeJSONValue.int))
    profile.document["medals"] = .int(123)
    NativePlayerProfileCore.setIntMapValue(&profile, key: "rank", nestedKey: String(commander.id), value: 0)
    NativePlayerProfileCore.setIntMapValue(&profile, key: "rankProgress", nestedKey: String(commander.id), value: 250)
    NativePlayerProfileCore.setIntMapValue(&profile, key: "nobility", nestedKey: String(commander.id), value: 0)
    NativePlayerProfileCore.setIntMapValue(&profile, key: "nobilityProgress", nestedKey: String(commander.id), value: 50)
    #expect(NativeGeneralUpgradeCore.apply(profile: &profile, commander: commander, kind: .military))
    var growth = NativePlayerProfileCore.generalGrowthState(profile: profile, raw: commander)
    #expect(growth.rank == 1)
    #expect(growth.militaryProgress == 0)
    #expect(profile.document["medals"] == .int(123))
    #expect(NativeGeneralUpgradeCore.apply(profile: &profile, commander: commander, kind: .all))
    growth = NativePlayerProfileCore.generalGrowthState(profile: profile, raw: commander)
    #expect(growth.rank == 14)
    #expect(growth.nobility == 9)
    #expect(growth.militaryProgress == 0)
    #expect(growth.nobilityProgress == 0)
    #expect(profile.document["medals"] == .int(123))
}

@Test func p71GeneralUpgradeGeometryAndEntryMatchFrozenAuthority() throws {
    let G = NativeOriginalFormGeometryCore.GeneralUpgrade.self
    #expect(G.screenFrame == NativeRect(x: 121.5, y: 67.5, width: 325, height: 185))
    #expect(G.militaryGroup == NativeRect(x: 207.5, y: 100.5, width: 235, height: 47))
    #expect(G.nobilityGroup == NativeRect(x: 207.5, y: 150.5, width: 235, height: 47))
    #expect(G.fullGroup == NativeRect(x: 207.5, y: 200.5, width: 235, height: 47))
    #expect(NativeHeadquartersCore.upgradeHotspotRect(index: 0) == NativeRect(x: 88, y: 86, width: 19, height: 19))
    let xml = try String(contentsOf: p71PackageRoot().appendingPathComponent("SOURCE_LEAN/EW4_Web_Port_v0.61/assets/data/original_layout-568h.xml"), encoding: .utf8)
    for needle in [
        "<Layout id=\"form_generalupgrade\" type=\"user_window\" x=\"0\" y=\"0\" w=\"325\" h=\"185\"",
        "id=\"group_military\" type=\"groupbox\" x=\"86\" y=\"33\" w=\"235\" h=\"47\"",
        "id=\"group_nobility\" type=\"groupbox\" x=\"86\" y=\"83\" w=\"235\" h=\"47\"",
        "id=\"group_fullrank\" type=\"groupbox\" x=\"86\" y=\"133\" w=\"235\" h=\"47\"",
        "name=\"marker_max_2.png\"",
        "name=\"medals.png\""
    ] { #expect(xml.contains(needle), Comment(rawValue: needle)) }
}

@Test func p71NativeUpgradeRendererAndCoordinatorAreActuallyWired() throws {
    let sourceRoot = p71CoreRoot().appendingPathComponent("Sources/EW4NativeRenderer")
    let renderer = try String(contentsOf: sourceRoot.appendingPathComponent("NativeOriginalGeneralUpgradeScene.swift"), encoding: .utf8)
    let hq = try String(contentsOf: sourceRoot.appendingPathComponent("NativeOriginalHeadquartersScene.swift"), encoding: .utf8)
    let app = try String(contentsOf: p71CoreRoot().deletingLastPathComponent().appendingPathComponent("iOSApp/App/EW4NativePortApp.swift"), encoding: .utf8)
    for needle in ["NativeGeneralUpgradeCore.apply", "rank_14.png", "class_9.png", "marker_max_2.png", "medals.png", "sfx_lvup2.wav", "strings[\"title_upgrade\"]"] {
        #expect(renderer.contains(needle), Comment(rawValue: needle))
    }
    #expect(hq.contains("button_rank.png"))
    #expect(hq.contains("upgradeHandler?(generalIDs[index])"))
    #expect(app.contains("NativeOriginalGeneralUpgradeScene"))
    #expect(app.contains("hq.upgradeHandler"))
    #expect(app.contains("playFormOpen(\"form_generalupgrade\""))
    let ui = TestResourcePaths.resources.appendingPathComponent("Sprites/image_ui_hd")
    for file in ["button_rank.png","gray_board.png","arrow_reoganizion.png","marker_hp_dark.png","marker_recover_dark.png","medals.png","marker_max_2.png","btn_common_blue.png","btn_common_green.png"] {
        #expect(FileManager.default.fileExists(atPath: ui.appendingPathComponent(file).path), Comment(rawValue: file))
    }
}
