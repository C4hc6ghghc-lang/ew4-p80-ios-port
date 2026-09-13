import Foundation
import Testing
@testable import EW4NativeCore

private func p68Root() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
}

@Test func p68OriginalRegroupConfirmPreviewGeometryMatchesXML() {
    let G = NativeOriginalFormGeometryCore.RegroupConfirm.self
    #expect(G.commander == NativeRect(x: 174, y: 119, width: 78, height: 98))
    #expect(G.commanderPortrait == NativeRect(x: 177, y: 119, width: 72, height: 72))
    #expect(G.equipment == NativeRect(x: 261, y: 119, width: 132, height: 98))
    #expect(G.equipmentTitle == NativeRect(x: 261, y: 119, width: 132, height: 20))
    #expect(G.equipmentList == NativeRect(x: 277, y: 155, width: 100, height: 45))
    #expect(G.equipmentSlots == [NativeRect(x:277,y:155,width:45,height:45),NativeRect(x:332,y:155,width:45,height:45)])
    #expect(G.equipmentTopSplit == NativeRect(x:261,y:153,width:132,height:1))
    #expect(G.equipmentBottomSplit == NativeRect(x:261,y:201,width:132,height:1))
}

@Test func p68FrozenXMLContainsCommanderAndEquipmentPreviewInternals() throws {
    let root = p68Root().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let xmlURL = root.appendingPathComponent("SOURCE_LEAN/EW4_Web_Port_v0.61/assets/data/original_layout-568h.xml")
    let xml = try String(contentsOf: xmlURL, encoding: .utf8)
    #expect(xml.contains("<Layout id=\"form_regroupconfirm\""))
    #expect(xml.contains("id=\"tcmder\" type=\"tmp_commander\" font=\"font_text_2\" x=\"50\" y=\"70\" w=\"78\" h=\"98\""))
    #expect(xml.contains("id=\"group_items\" type=\"groupbox\" x=\"137\" y=\"70\" w=\"132\" h=\"98\""))
    #expect(xml.contains("id=\"lbox_equipitem\" type=\"listbox\" x=\"16\" y=\"36\" w=\"100\" h=\"45\" orient=\"1\" itemh=\"45\" interval=\"10\""))
}

@Test func p68RendererConsumesSourceCommanderAndRealEquipmentPreview() throws {
    let source = p68Root().appendingPathComponent("Sources/EW4NativeRenderer/NativeOriginalRegroupScene.swift")
    let text = try String(contentsOf: source, encoding: .utf8)
    for needle in [
        "items=try store.items()",
        "renderConfirmCommander(source)",
        "renderConfirmEquipment(source)",
        "NativeHeadquartersManagementCore.equipmentPair(profile:profile,commander:source)",
        "strings[\"text_equipitem\"]",
        "common_lineframe_bold.png",
        "infomarker_board.png",
        "pattern_reoganizion.png",
        "common_line_hor.png",
        "itemNode(it)"
    ] { #expect(text.contains(needle), Comment(rawValue: needle)) }
    #expect(!text.contains("装备预览占位"))
}
