import Foundation
import Testing
@testable import EW4NativeCore

private func p70Root() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
}

@Test func p70DeployItemGeometryMatchesFrozenXML() {
    let G = NativeOriginalFormGeometryCore.DeployItem.self
    #expect(G.screenFrame == NativeRect(x:108,y:30,width:353,height:261))
    #expect(G.generalGroup == NativeRect(x:113,y:61,width:78,height:119))
    #expect(G.levelGroup == NativeRect(x:197,y:61,width:110,height:52))
    #expect(G.equipmentGroup == NativeRect(x:196,y:111,width:110,height:74))
    #expect(G.descriptionGroup == NativeRect(x:313,y:61,width:142,height:120))
    #expect(G.itemsGroup == NativeRect(x:112,y:189,width:344,height:99))
    #expect(G.itemGrid == NativeRect(x:114,y:191,width:342,height:95))
    #expect(G.equipButton == NativeRect(x:323,y:162,width:55,height:21))
    #expect(G.equipmentSlots == [NativeRect(x:201,y:136,width:45,height:45), NativeRect(x:256,y:136,width:45,height:45)])
}

@Test func p70DeployItemScrollMathMatchesFourRowGrid() {
    let G = NativeOriginalFormGeometryCore.DeployItem.self
    #expect(G.contentHeight == 189)
    #expect(G.maxScroll == 94)
    #expect(G.clampedScroll(-10) == 0)
    #expect(G.clampedScroll(120) == 94)
    #expect(G.itemRect(index: 27, scroll: 94) == NativeRect(x:402,y:241,width:45,height:45))
    #expect(G.thumbHeight > 47 && G.thumbHeight < 48)
}

@Test func p70FrozenXMLContainsDeployItemAuthority() throws {
    let root = p70Root().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let xml = try String(contentsOf: root.appendingPathComponent("SOURCE_LEAN/EW4_Web_Port_v0.61/assets/data/original_layout-568h.xml"), encoding:.utf8)
    for needle in [
        "<Layout id=\"form_deployitem\" type=\"user_window\" x=\"0\" y=\"0\" w=\"353\" h=\"261\"",
        "id=\"group_general\" type=\"groupbox\" x=\"5\" y=\"31\" w=\"78\" h=\"119\"",
        "frm1=\"button_changegeneral_gray.png\" frm2=\"button_changegeneral.png\"",
        "frm1=\"button_changegeneral_gray_2.png\" frm2=\"button_changegeneral_2.png\"",
        "id=\"group_level\" type=\"groupbox\" x=\"89\" y=\"31\" w=\"110\" h=\"52\"",
        "id=\"group_equip\" type=\"groupbox\" x=\"88\" y=\"81\" w=\"110\" h=\"74\"",
        "id=\"group_desc\" type=\"groupbox\" x=\"205\" y=\"31\" w=\"142\" h=\"120\"",
        "id=\"group_items\" type=\"groupbox\" x=\"4\" y=\"159\" w=\"344\" h=\"99\"",
        "cols=\"7\" rowh=\"45\" hbland=\"3\" vbland=\"3\" scrollback=\"scrollbar_gray.png\" scrollbar=\"scrollbar_darkgray.png\"",
        "id=\"btn_equip\" type=\"button\" frm1=\"button_confirm_blue.png\" x=\"215\" y=\"132\" w=\"55\" h=\"21\""
    ] { #expect(xml.contains(needle), Comment(rawValue: needle)) }
}

@Test func p70RendererConsumesOriginalDeployItemArtAndKeys() throws {
    let text = try String(contentsOf: p70Root().appendingPathComponent("Sources/EW4NativeRenderer/NativeOriginalDeployItemScene.swift"), encoding:.utf8)
    for needle in [
        "NativeOriginalFormGeometryCore.DeployItem",
        "button_changegeneral_gray.png",
        "button_changegeneral_gray_2.png",
        "general_nameboard.png",
        "common_lineframe_bold.png",
        "marker_hp_dark.png",
        "marker_recover_dark.png",
        "item_selected_ex.png",
        "scrollbar_gray.png",
        "scrollbar_darkgray.png",
        "button_confirm_blue.png",
        "strings[\"btn_remove\"]",
        "strings[\"desc_\\(def.name)\"]",
        "NativeHeadquartersManagementCore.equipmentPair",
        "NativeHeadquartersManagementCore.equip"
    ] { #expect(text.contains(needle), Comment(rawValue: needle)) }
    #expect(!text.contains("label(\"◀\""))
    #expect(!text.contains("label(\"▶\""))
}
