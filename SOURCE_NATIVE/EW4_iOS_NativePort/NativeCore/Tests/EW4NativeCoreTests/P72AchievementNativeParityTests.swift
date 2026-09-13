import Foundation
import Testing
@testable import EW4NativeCore

private func p72CoreRoot() -> URL {
    URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
}
private func p72PackageRoot() -> URL { p72CoreRoot().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent() }
private func p72Commander() throws -> Commander {
    let data = try Data(contentsOf: TestResourcePaths.data("commanders.json"))
    let rows = try JSONDecoder().decode([String: Commander].self, from: data)
    return try #require(rows.values.first(where: { $0.id >= 1 && $0.id <= 200 && !NativePlayerProfile.princessIDs.contains($0.id) }))
}

@Test func p72AchievementExactP28MathIsNativeParity() throws {
    #expect(NativeAchievementCore.maxStageStars == 420)
    #expect(NativeAchievementCore.aggregateLevel(total: 99, cutoff: 99, first: 121, multiplier: 1.214) == 1)
    #expect(NativeAchievementCore.aggregateLevel(total: 100, cutoff: 99, first: 121, multiplier: 1.214) == 2)
    #expect(NativeAchievementCore.aggregateLevel(total: 49, cutoff: 49, first: 56, multiplier: 1.125) == 1)
    #expect(NativeAchievementCore.ruleDigits(0) == [0])
    #expect(NativeAchievementCore.ruleDigits(42) == [4,2])
    #expect(NativeAchievementCore.ruleDigits(1000) == [9,9,9])

    let commander = try p72Commander()
    var profile = NativePlayerProfile.fresh()
    profile.document["owned"] = .array([.int(commander.id)])
    NativePlayerProfileCore.setIntMapValue(&profile, key: "rank", nestedKey: String(commander.id), value: 0)
    NativePlayerProfileCore.setIntMapValue(&profile, key: "rankProgress", nestedKey: String(commander.id), value: 0)
    NativePlayerProfileCore.setIntMapValue(&profile, key: "nobility", nestedKey: String(commander.id), value: 0)
    NativePlayerProfileCore.setIntMapValue(&profile, key: "nobilityProgress", nestedKey: String(commander.id), value: 0)
    let summary = NativeAchievementCore.globalSummary(profile: profile, commanders: [commander.id: commander])
    #expect(summary.military.raw == 300)
    #expect(summary.military.score == 30)
    #expect(summary.nobility.raw == 60)
    #expect(summary.nobility.score == 240)
}

@Test func p72AchievementCampaignStarsAndContinentPersistenceMatchP28() {
    var profile = NativePlayerProfile.fresh()
    profile.document["campaignBestRating"] = .object(["campaign1_01.btl": .int(5)])
    profile.document["campaignProgress"] = .object(["campaign1_02.btl": .int(1)])
    let stars = NativeAchievementCore.campaignStageStars(profile: profile)
    #expect(stars.earned == 6)
    #expect(stars.max == 420)
    profile.document["achievementConquests"] = .object([
        "europe": .object(["value": .int(42)]),
        "america": .int(7),
        "asia": .object(["rule": .array([.int(1),.int(2),.int(3)])])
    ])
    #expect(NativeAchievementCore.continent(profile: profile, key: "europe").digits == [4,2])
    #expect(NativeAchievementCore.continent(profile: profile, key: "america").digits == [7])
    #expect(NativeAchievementCore.continent(profile: profile, key: "asia").digits == [1,2,3])
}

@Test func p72AchievementGeometryMatchesFrozenOriginalForm() throws {
    let G = NativeOriginalFormGeometryCore.Achievement.self
    #expect(G.championButton == NativeRect(x:15,y:31,width:49,height:32))
    #expect(G.rankingButton == NativeRect(x:80,y:31,width:49,height:32))
    #expect(G.militaryGroup == NativeRect(x:327,y:28,width:120,height:38))
    #expect(G.nobilityGroup == NativeRect(x:448,y:28,width:120,height:38))
    #expect(G.claimFrame == NativeRect(x:184,y:110,width:200,height:100))
    let xml = try String(contentsOf: p72PackageRoot().appendingPathComponent("SOURCE_LEAN/EW4_Web_Port_v0.61/assets/data/original_layout-568h.xml"), encoding: .utf8)
    for needle in [
        "<Layout id=\"form_achivement\" type=\"user_window\" prevent=\"1\" title=\"title_achivement\" btn_back=\"true\"",
        "id=\"btn_champion\" type=\"button\" frm1=\"button_champion.png\" x=\"15\" y=\"31\" w=\"49\" h=\"32\"",
        "id=\"group_milrank\" type=\"groupbox\" x=\"327\" y=\"28\" w=\"120\" h=\"38\"",
        "id=\"lbox_general\" type=\"listbox\" orient=\"1\" x=\"23\" y=\"223\" w=\"600\" h=\"98\" scale=\"0.75\"",
        "<Layout id=\"form_claim\" type=\"user_window\" x=\"0\" y=\"0\" w=\"200\" h=\"100\""
    ] { #expect(xml.contains(needle), Comment(rawValue: needle)) }
}

@Test func p72AchievementRendererAndCoordinatorAreActuallyWiredWithoutInventedClaimTrigger() throws {
    let renderer = try String(contentsOf: p72CoreRoot().appendingPathComponent("Sources/EW4NativeRenderer/NativeOriginalAchievementScene.swift"), encoding: .utf8)
    let main = try String(contentsOf: p72CoreRoot().appendingPathComponent("Sources/EW4NativeRenderer/NativeOriginalMainMenuScene.swift"), encoding: .utf8)
    let app = try String(contentsOf: p72CoreRoot().deletingLastPathComponent().appendingPathComponent("iOSApp/App/EW4NativePortApp.swift"), encoding: .utf8)
    for needle in ["NativeAchievementCore.viewModel", "button_champion.png", "button_rule_europa.png", "rule_\\(d).png", "board_smallgenerals.png", "NativeOriginalClaimScene"] {
        #expect(renderer.contains(needle), Comment(rawValue: needle))
    }
    #expect(main.contains("achievementHandler?()"))
    #expect(app.contains("menu.achievementHandler = { [weak self] in self?.showAchievement() }"))
    #expect(app.contains("NativeOriginalAchievementScene"))
    #expect(app.contains("playFormOpen(\"form_achivement\""))
    #expect(!app.contains("NativeOriginalClaimScene"))
    let ui = TestResourcePaths.resources.appendingPathComponent("Sprites/image_ui_hd")
    for file in ["button_champion.png","button_rank.png","board_rankclass.png","marker_rank.png","marker_class.png","button_rule_europa.png","button_rule_america.png","button_rule_asia.png","stage_star.png","pattern_save.png","pattern_bg_bottom.png","board_smallgenerals.png","rule_0.png","rule_9.png"] {
        #expect(FileManager.default.fileExists(atPath: ui.appendingPathComponent(file).path), Comment(rawValue: file))
    }
}
