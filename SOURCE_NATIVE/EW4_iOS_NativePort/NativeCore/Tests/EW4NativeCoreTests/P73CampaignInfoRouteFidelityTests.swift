import Foundation
import Testing
@testable import EW4NativeCore

private func p73CoreRoot() -> URL {
    URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
}
private func p73PackageRoot() -> URL { p73CoreRoot().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent() }

@Test func p73CampaignInfoBattleLinesMatchFrozenDefBattleline() throws {
    let C = NativeOriginalOuterShellCore.CampaignInfo.self
    #expect(C.lines == [
        .init(name: "imperialeagle", hide: 0, start: 1793, end: 1820, stars: 10, countries: ["fra"]),
        .init(name: "coalition", hide: 0, start: 1792, end: 1815, stars: 10, countries: ["aus","pru","rus","gbr"]),
        .init(name: "romanempire", hide: 0, start: 1807, end: 1822, stars: 10, countries: ["hre","aus","pru"]),
        .init(name: "eastern", hide: 0, start: 1798, end: 1820, stars: 10, countries: ["tur","rus"]),
        .init(name: "america", hide: 0, start: 1775, end: 1822, stars: 10, countries: ["usa"]),
        .init(name: "neversets", hide: 1, start: 1775, end: 1814, stars: 10, countries: ["gbr"]),
    ])
    let xml = try String(contentsOf: p73PackageRoot().appendingPathComponent("SOURCE_LEAN/EW4_Web_Port_v0.61/assets/data/def_battleline.xml"), encoding: .utf8)
    for needle in [
        "name=\"imperialeagle\" hide=\"0\" start=\"1793\" end=\"1820\" stars=\"10\" countries=\"fra\"",
        "name=\"coalition\" hide=\"0\" start=\"1792\" end=\"1815\" stars=\"10\" countries=\"aus,pru,rus,gbr\"",
        "name=\"romanempire\" hide=\"0\" start=\"1807\" end=\"1822\" stars=\"10\" countries=\"hre,aus,pru\"",
        "name=\"eastern\" hide=\"0\" start=\"1798\" end=\"1820\" stars=\"10\" countries=\"tur,rus\"",
        "name=\"america\" hide=\"0\" start=\"1775\" end=\"1822\" stars=\"10\" countries=\"usa\"",
        "name=\"neversets\" hide=\"1\" start=\"1775\" end=\"1814\" stars=\"10\" countries=\"gbr\"",
    ] { #expect(xml.contains(needle), Comment(rawValue: needle)) }
}

@Test func p73CampaignInfoGeometryAndMaturePinPlacementMatchP25() throws {
    let C = NativeOriginalOuterShellCore.CampaignInfo.self
    #expect(C.frame == NativeRect(x:0,y:0,width:155,height:83))
    #expect(C.back == NativeRect(x:-9,y:-4,width:173,height:70))
    #expect(C.arrow == NativeRect(x:60,y:56,width:31,height:22))
    #expect(C.nations == NativeRect(x:4,y:34,width:150,height:15))
    #expect(C.confirm == NativeRect(x:110,y:28,width:31,height:32))
    #expect(C.screenFrame(zone: 1) == NativeRect(x:250,y:78,width:155,height:83))
    #expect(C.screenFrame(zone: 2) == NativeRect(x:306,y:30,width:155,height:83))
    #expect(C.screenFrame(zone: 6) == NativeRect(x:215,y:0,width:155,height:83))
    let confirm = try #require(C.absolute(C.confirm, zone: 1))
    #expect(C.confirmContains(NativePoint(x: confirm.origin.x + 10, y: confirm.origin.y + 10), zone: 1))
    #expect(!C.confirmContains(NativePoint(x: 10, y: 10), zone: 1))
    let layout = try String(contentsOf: p73PackageRoot().appendingPathComponent("SOURCE_LEAN/EW4_Web_Port_v0.61/assets/data/original_layout-568h.xml"), encoding: .utf8)
    for needle in [
        "<Layout id=\"form_campaigninfo\" type=\"window\" x=\"0\" y=\"0\" w=\"155\" h=\"83\"",
        "name=\"button_choosebattlezoneinfo.png\" x=\"-9\" y=\"-4\" h=\"70\"",
        "name=\"arrow_choosebattlezoneinfo.png\" x=\"60\" y=\"56\"",
        "id=\"lbox_nation\" type=\"listbox\" x=\"4\" y=\"34\" w=\"150\" h=\"15\"",
        "frm1=\"button_confrim.png\" x=\"110\" y=\"28\" w=\"31\" h=\"32\"",
    ] { #expect(layout.contains(needle), Comment(rawValue: needle)) }
}

@Test func p73CampaignPinNowRoutesThroughInfoBeforeCampaignList() throws {
    let renderer = try String(contentsOf: p73CoreRoot().appendingPathComponent("Sources/EW4NativeRenderer/NativeOriginalOuterMenuScene.swift"), encoding: .utf8)
    #expect(renderer.contains("private var campaignInfoZone: Int?"))
    #expect(renderer.contains("private func openCampaignInfo(zone: Int)"))
    #expect(renderer.contains("if let zone = campaignInfoZone { renderCampaignInfo(zone: zone) }"))
    #expect(renderer.contains("CampaignInfo.confirmContains(point, zone: zone)"))
    #expect(renderer.contains("showCampaignList(zone: zone)"))
    #expect(renderer.contains("if case .campaignZone(let zone) = NativeOriginalOuterShellCore.campaignSelectionAction(at: point) { openCampaignInfo(zone: zone) }"))
    #expect(!renderer.contains("if case .campaignZone(let zone) = NativeOriginalOuterShellCore.campaignSelectionAction(at: point) { showCampaignList(zone: zone) }"))
}

@Test func p73CampaignInfoUsesOriginalFrozenAssetsAndCountryFlags() {
    let ui = TestResourcePaths.resources.appendingPathComponent("Sprites/image_ui_hd")
    for file in ["button_choosebattlezoneinfo.png", "arrow_choosebattlezoneinfo.png", "button_confrim.png"] {
        #expect(FileManager.default.fileExists(atPath: ui.appendingPathComponent(file).path), Comment(rawValue: file))
    }
    let flags = TestResourcePaths.resources.appendingPathComponent("Sprites/image_flag_hd")
    for code in ["fra","aus","pru","rus","gbr","hre","tur","usa"] {
        #expect(FileManager.default.fileExists(atPath: flags.appendingPathComponent("\(code)1.png").path), Comment(rawValue: code))
    }
}
