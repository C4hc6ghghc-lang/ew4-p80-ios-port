import Foundation
import Testing
@testable import EW4NativeCore

private func p69Root() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
}

@Test func p69OriginalMainRegroupGeometryMatchesFrozenXML() {
    let G = NativeOriginalFormGeometryCore.Regroup.self
    #expect(G.previewGroup == NativeRect(x: 8, y: 37, width: 146, height: 120))
    #expect(G.sourceCommander == NativeRect(x: 160, y: 37, width: 78, height: 98))
    #expect(G.arrow == NativeRect(x: 242, y: 48, width: 84, height: 82))
    #expect(G.targetCommander == NativeRect(x: 331, y: 37, width: 78, height: 98))
    #expect(G.regroupButton == NativeRect(x: 243, y: 100, width: 83, height: 35))
    #expect(G.equipmentGroup == NativeRect(x: 415, y: 37, width: 146, height: 120))
    #expect(G.equipmentList == NativeRect(x: 437, y: 88, width: 100, height: 45))
    #expect(G.generalList == NativeRect(x: 24, y: 190, width: 550, height: 98))
    #expect(G.notice == NativeRect(x: 0, y: 164, width: 568, height: 15))
    #expect(G.lowerLine == NativeRect(x: 0, y: 295, width: 568, height: 2))
}

@Test func p69FrozenXMLContainsMainRegroupContentAuthority() throws {
    let root = p69Root().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let xmlURL = root.appendingPathComponent("SOURCE_LEAN/EW4_Web_Port_v0.61/assets/data/original_layout-568h.xml")
    let xml = try String(contentsOf: xmlURL, encoding: .utf8)
    for needle in [
        "<Layout id=\"form_regroup\"",
        "id=\"group_infos\" type=\"groupbox\" x=\"8\" y=\"37\" w=\"146\" h=\"120\"",
        "id=\"group_items\" type=\"groupbox\" x=\"415\" y=\"37\" w=\"146\" h=\"120\"",
        "id=\"tcmder_target\" type=\"tmp_commander\" font=\"font_text_2\" x=\"331\" y=\"37\" w=\"78\" h=\"98\"",
        "id=\"tcmder_source\" type=\"tmp_commander\" font=\"font_text_2\" x=\"160\" y=\"37\" w=\"78\" h=\"98\"",
        "id=\"image_arrow\" type=\"image\" name=\"arrow_reoganizion.png\" y=\"48\" align=\"hmiddle\"",
        "id=\"btn_regroup\" type=\"tmp_button\" frm1=\"btn_common_red.png\" x=\"243\" y=\"100\" w=\"83\" h=\"35\"",
        "id=\"lbox_general\" type=\"listbox\" orient=\"1\" x=\"24\" y=\"190\" w=\"550\" h=\"98\" itemh=\"78\" interval=\"10\""
    ] { #expect(xml.contains(needle), Comment(rawValue: needle)) }
}

@Test func p69RendererConsumesRecoveredMainRegroupStructure() throws {
    let source = p69Root().appendingPathComponent("Sources/EW4NativeRenderer/NativeOriginalRegroupScene.swift")
    let text = try String(contentsOf: source, encoding: .utf8)
    for needle in [
        "NativeOriginalFormGeometryCore.Regroup.generalList",
        "NativeOriginalFormGeometryCore.Regroup.self",
        "drawCommander(target,rect:G.targetCommander)",
        "drawCommander(source,rect:G.sourceCommander)",
        "arrow_reoganizion.png",
        "renderPreviewGroup(target:target,preview:p)",
        "renderMainEquipment(source)",
        "btn_common_red.png",
        "pattern_bg_bottom.png",
        "cardW=78.0; private let gap=10.0",
        "NativeHeadquartersManagementCore.equipmentPair(profile:profile,commander:source)",
        "previewRankHP(target:target,rank:preview.rank)",
        "previewNobilityHeal(target:target,nobility:preview.nobility)"
    ] { #expect(text.contains(needle), Comment(rawValue: needle)) }
    #expect(!text.contains("width:120,height:142"))
    #expect(!text.contains("cardW=62.0"))
    #expect(!text.contains("width:520,height:98"))
}
