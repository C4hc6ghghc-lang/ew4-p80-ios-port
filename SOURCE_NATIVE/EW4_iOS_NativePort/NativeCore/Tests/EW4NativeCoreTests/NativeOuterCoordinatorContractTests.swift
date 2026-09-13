import Foundation
import Testing
@testable import EW4NativeCore

@Test func nativeAppBootsThroughOriginalMainMenuInsteadOfHardcodedToulon() throws {
    let app = try String(contentsOf: TestResourcePaths.projectRoot
        .appendingPathComponent("iOSApp/App/EW4NativePortApp.swift"), encoding: .utf8)
    #expect(app.contains("NativeOriginalMainMenuScene"))
    #expect(app.contains("NativeOriginalOuterMenuScene"))
    #expect(app.contains("showCampaignSelection()"))
    #expect(app.contains("showConquestSelection()"))
    #expect(!app.contains("loadBattle(file: \"campaign1_01.btl\""))
    #expect(app.contains("battle.loadBattle(file: launch.file, store: store, profile: currentProfile, mode: launch.mode, playerOwner: launch.playerOwner)"))
}

@Test func nativeOuterShellRoutesCampaignConquestAndAutosaveWithoutWebRuntime() throws {
    let outer = try String(contentsOf: TestResourcePaths.projectRoot
        .appendingPathComponent("NativeCore/Sources/EW4NativeRenderer/NativeOriginalOuterMenuScene.swift"), encoding: .utf8)
    #expect(outer.contains("NativeCampaignCore.stageSelectable"))
    #expect(outer.contains("NativeCampaignCore.resolveVariant"))
    #expect(outer.contains("mode: .campaign"))
    #expect(outer.contains("mode: .conquest"))
    #expect(!outer.contains("WK" + "WebView"))
    #expect(!outer.contains("JavaScript" + "Core"))
}

@Test func headquartersRoutesShopAndAcademyIntoNativeScenes() throws {
    let app = try String(contentsOf: TestResourcePaths.projectRoot
        .appendingPathComponent("iOSApp/App/EW4NativePortApp.swift"), encoding: .utf8)
    #expect(app.contains("NativeOriginalHeadquartersScene"))
    #expect(app.contains("showHQShop()"))
    #expect(app.contains("showMilitaryAcademy()"))
    #expect(app.contains("NativeOriginalHQShopScene"))
    #expect(app.contains("NativeOriginalAcademyScene"))
    #expect(!app.contains("HQ Shop native binding pending in P51"))
    #expect(!app.contains("Military Academy native binding pending in P51"))
}
