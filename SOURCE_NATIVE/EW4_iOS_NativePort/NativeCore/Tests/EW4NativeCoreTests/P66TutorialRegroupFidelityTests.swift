import Foundation
import Testing
@testable import EW4NativeCore

@Test func p66TutorialAndRegroupCNValuesAreFrozen() throws {
    let strings = try ResourceLoader.decode([String: String].self, from: TestResourcePaths.data("strings_cn.json"))
    #expect(strings["title_tutorials"] == "教  程")
    #expect(strings["btn_basic"] == "基础教程")
    #expect(strings["btn_classic"] == "高级教程")
    #expect(strings["btn_notice"] == "如何游戏")
    #expect(strings["title_notice"] == "注  意")
    #expect(strings["text_regroupnotice"] == "被整编的将领和物品会消失")
    #expect(strings["text_regroup"] == "确定要整编吗?")
    #expect(strings["btn_confirm"] == "确认")
    #expect(strings["btn_cancel"] == "取消")
}

@Test func p66OriginalXMLBindsTutorialAndRegroupConfirmation() throws {
    let xml = try String(contentsOf: TestResourcePaths.data("original_layout-568h.xml"), encoding: .utf8)
    #expect(xml.contains("<Layout id=\"form_tutorials\""))
    #expect(xml.contains("id=\"btn_basic\" type=\"tmp_button\" frm1=\"btn_common_green.png\" x=\"53\" y=\"40\" w=\"145\" h=\"40\" text=\"btn_basic\""))
    #expect(xml.contains("id=\"btn_classic\" type=\"tmp_button\" frm1=\"btn_common_green.png\" x=\"53\" y=\"85\" w=\"145\" h=\"40\" text=\"btn_classic\""))
    #expect(xml.contains("id=\"btn_notice\" type=\"tmp_button\" frm1=\"btn_common_green.png\" x=\"53\" y=\"130\" w=\"145\" h=\"40\" text=\"btn_notice\""))
    #expect(xml.contains("<Layout id=\"form_regroupconfirm\" type=\"user_window\" x=\"0\" y=\"0\" w=\"320\" h=\"222\""))
    #expect(xml.contains("title=\"title_notice\""))
    #expect(xml.contains("id=\"text_tips\" type=\"text\" font=\"font_text_2\" text=\"text_regroupnotice\""))
    #expect(xml.contains("id=\"text_info\" type=\"text\" font=\"font_text_2\" text=\"text_regroup\""))
    #expect(xml.contains("id=\"btn_confirm\" type=\"tmp_button\" frm1=\"btn_common_blue.png\" x=\"50\" y=\"182\" w=\"75\" h=\"30\" font=\"font_text_3\" text=\"btn_confirm\""))
    #expect(xml.contains("id=\"btn_cancel\" type=\"tmp_button\" frm1=\"btn_common_blue.png\" x=\"195\" y=\"182\" w=\"75\" h=\"30\" font=\"font_text_3\" text=\"btn_cancel\""))
}

@Test func p66RecoveredTutorialAndRegroupGeometryMatchesXML() {
    #expect(NativeOriginalFormGeometryCore.Tutorial.screenFrame == NativeRect(x: 159, y: 60, width: 250, height: 200))
    #expect(NativeOriginalFormGeometryCore.Tutorial.basicButton == NativeRect(x: 212, y: 100, width: 145, height: 40))
    #expect(NativeOriginalFormGeometryCore.Tutorial.classicButton == NativeRect(x: 212, y: 145, width: 145, height: 40))
    #expect(NativeOriginalFormGeometryCore.Tutorial.noticeButton == NativeRect(x: 212, y: 190, width: 145, height: 40))
    #expect(NativeOriginalFormGeometryCore.RegroupConfirm.screenFrame == NativeRect(x: 124, y: 49, width: 320, height: 222))
    #expect(NativeOriginalFormGeometryCore.RegroupConfirm.confirmButton == NativeRect(x: 174, y: 231, width: 75, height: 30))
    #expect(NativeOriginalFormGeometryCore.RegroupConfirm.cancelButton == NativeRect(x: 319, y: 231, width: 75, height: 30))
    #expect(NativeOriginalFormGeometryCore.RegroupConfirm.tips == NativeRect(x: 124, y: 79, width: 320, height: 15))
    #expect(NativeOriginalFormGeometryCore.RegroupConfirm.info == NativeRect(x: 124, y: 96, width: 320, height: 15))
}

@Test func p66NativeRenderersConsumeOriginalTutorialAndRegroupAuthority() throws {
    let root = TestResourcePaths.projectRoot.appendingPathComponent("NativeCore/Sources/EW4NativeRenderer", isDirectory: true)
    let tutorial = try String(contentsOf: root.appendingPathComponent("NativeOriginalTutorialScene.swift"), encoding: .utf8)
    let regroup = try String(contentsOf: root.appendingPathComponent("NativeOriginalRegroupScene.swift"), encoding: .utf8)

    #expect(tutorial.contains("strings[\"btn_basic\"]"))
    #expect(tutorial.contains("strings[\"btn_classic\"]"))
    #expect(tutorial.contains("strings[\"btn_notice\"]"))
    #expect(tutorial.contains("btn_common_green.png"))
    #expect(!tutorial.contains("strings[\"tutorials1\"]"))
    #expect(!tutorial.contains("strings[\"tutorials2\"]"))

    #expect(regroup.contains("strings[\"title_notice\"]"))
    #expect(regroup.contains("strings[\"text_regroupnotice\"]"))
    #expect(regroup.contains("strings[\"text_regroup\"]"))
    #expect(regroup.contains("strings[\"btn_confirm\"]"))
    #expect(regroup.contains("strings[\"btn_cancel\"]"))
    #expect(regroup.contains("if contains(confirmRect,p){commit();return}"))
    #expect(regroup.contains("if contains(cancelRect,p){confirm=false"))
    #expect(!regroup.contains("strings[\"btn_ok\"]"))
    #expect(!regroup.contains("strings[\"msg_title_regroup\"]"))
}
