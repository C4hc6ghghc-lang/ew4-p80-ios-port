import Foundation
import Testing
@testable import EW4NativeCore

private func p74CoreRoot() -> URL {
    URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
}
private func p74PackageRoot() -> URL { p74CoreRoot().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent() }

@Test func p74RecruitGeneralGeometryMatchesFrozenXML() {
    let G = NativeOriginalFormGeometryCore.Tavern.self
    #expect(G.screenFrame == NativeRect(x:134,y:22.5,width:300,height:275))
    #expect(G.closeButton == NativeRect(x:417,y:15.5,width:25,height:25))
    #expect(G.row(0) == NativeRect(x:134,y:52.5,width:300,height:55))
    #expect(G.row(3) == NativeRect(x:134,y:217.5,width:300,height:55))
    #expect(G.portrait(0) == NativeRect(x:139,y:54.5,width:50,height:50))
    #expect(G.info(0) == NativeRect(x:167,y:55.5,width:24,height:24))
    #expect(G.nameBoard(0) == NativeRect(x:194,y:57.5,width:75,height:15))
    #expect(G.costGroup(0) == NativeRect(x:273,y:55.5,width:75,height:49))
    #expect(G.recruitButton(0) == NativeRect(x:350,y:60.5,width:80,height:40))
}

@Test func p74FrozenXMLContainsRecruitGeneralAuthority() throws {
    let xml = try String(contentsOf: p74PackageRoot().appendingPathComponent("SOURCE_LEAN/EW4_Web_Port_v0.61/assets/data/original_layout-568h.xml"), encoding:.utf8)
    for needle in [
        "<Layout id=\"form_recruitgeneral\" type=\"user_window\" w=\"300\" h=\"275\"",
        "id=\"group_gen_1\" type=\"groupbox\" x=\"0\" y=\"30\" h=\"55\" frame=\"common_lineframe_bold.png\"",
        "id=\"btn_rec_1\" type=\"tmp_button\" frm1=\"btn_common_green.png\" x=\"216\" y=\"8\" w=\"80\" h=\"40\"",
        "id=\"tcmder\" type=\"tmp_commander\" x=\"5\" y=\"2\" scale=\"0.65\"",
        "id=\"btn_gen_1\" type=\"button\" x=\"28\" y=\"1\" w=\"24\" h=\"24\" frm1=\"button_generalinfo_blue.png\"",
        "id=\"rank_military\" type=\"tmp_rank\" x=\"65\" y=\"24\" w=\"75\" ranktype=\"military\"",
        "id=\"rank_nobility\" type=\"tmp_rank\" x=\"104\" y=\"24\" w=\"75\" ranktype=\"nobility\"",
        "id=\"group\" type=\"groupbox\" x=\"139\" y=\"3\" h=\"49\" w=\"75\" frame=\"common_lineframe.png\"",
    ] { #expect(xml.contains(needle), Comment(rawValue: needle)) }
}

@Test func p74RendererConsumesOriginalRecruitGeneralFramesRanksAndCosts() throws {
    let text = try String(contentsOf: p74CoreRoot().appendingPathComponent("Sources/EW4NativeRenderer/NativeOriginalTavernRenderer.swift"), encoding:.utf8)
    for needle in [
        "NativeOriginalFormGeometryCore.Tavern",
        "form_back.png",
        "common_lineframe_bold.png",
        "common_lineframe.png",
        "button_generalinfo_blue.png",
        "general_nameboard.png",
        "rank_\\(min(14,c.rank)).png",
        "class_\\(min(9,c.nobilityrank)).png",
        "medals.png",
        "marker_money.png",
        "marker_industry.png",
        "btn_common_green.png",
        "NativeBattleTavernCore.availability"
    ] { #expect(text.contains(needle), Comment(rawValue: needle)) }
    #expect(!text.contains("String(repeating:\"★\""))
}

@Test func p74RecruitGeneralRankAndFrameAssetsExist() {
    let ui = TestResourcePaths.resources.appendingPathComponent("Sprites/image_ui_hd")
    for file in ["form_back.png","common_lineframe_bold.png","common_lineframe.png","button_generalinfo_blue.png","general_nameboard.png","medals.png","marker_money.png","marker_industry.png","btn_common_green.png"] {
        #expect(FileManager.default.fileExists(atPath: ui.appendingPathComponent(file).path), Comment(rawValue:file))
    }
    for level in 1...14 { #expect(FileManager.default.fileExists(atPath: ui.appendingPathComponent("rank_\(level).png").path)) }
    for level in 1...9 { #expect(FileManager.default.fileExists(atPath: ui.appendingPathComponent("class_\(level).png").path)) }
}
