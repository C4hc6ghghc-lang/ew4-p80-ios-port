import Foundation
import Testing
@testable import EW4NativeCore

@Test func p65OuterAndHQOriginalCNValuesAreFrozen() throws {
    let strings = try ResourceLoader.decode([String: String].self, from: TestResourcePaths.data("strings_cn.json"))
    #expect(strings["title_buygeneral"] == "军事学院")
    #expect(strings["title_generaltips"] == "获得将军")
    #expect(strings["title_headquarters"] == "指挥部")
    #expect(strings["title_deploygeneral"] == "指挥部")
    #expect(strings["btn_deploy"] == "出征")
    #expect(strings["btn_princess"] == "公主")
    #expect(strings["btn_college"] == "军事学院")
    #expect(strings["text_equipitem"] == "装备")
    #expect(strings["btn_regroup"] == "整编")
    #expect(strings["btn_equip"] == "装备")
    #expect(strings["btn_infantry"] == "步兵")
    #expect(strings["btn_cavalry"] == "骑兵")
    #expect(strings["btn_artillery"] == "炮兵")
    #expect(strings["btn_navy"] == "海军")
    #expect(strings["btn_fortress"] == "要塞")
    #expect(strings["text_economy"] == "经济")
    #expect(strings["text2_american"] == "美洲")
    #expect(strings["text2_european"] == "欧洲")
}

@Test func p65OriginalXMLBindsOuterAndHQKeys() throws {
    let xml = try String(contentsOf: TestResourcePaths.data("original_layout-568h.xml"), encoding: .utf8)
    #expect(xml.contains("<Layout id=\"form_getgeneral\""))
    #expect(xml.contains("title=\"title_buygeneral\""))
    #expect(xml.contains("<Layout id=\"form_getgeneraltips\""))
    #expect(xml.contains("title=\"title_generaltips\""))
    #expect(xml.contains("<Layout id=\"form_generalinfo\""))
    #expect(xml.contains("title=\"title_headquarters\""))
    #expect(xml.contains("<Layout id=\"form_deploygeneral\""))
    #expect(xml.contains("text=\"btn_princess\""))
    #expect(xml.contains("text=\"btn_college\""))
    #expect(xml.contains("text=\"btn_deploy\""))
    #expect(xml.contains("text=\"text2_european\""))
    #expect(xml.contains("text=\"text2_american\""))
}

@Test func p65NativeRenderersConsumeOuterAndHQStringAuthority() throws {
    let root = TestResourcePaths.projectRoot.appendingPathComponent("NativeCore/Sources/EW4NativeRenderer", isDirectory: true)
    let academy = try String(contentsOf: root.appendingPathComponent("NativeOriginalAcademyScene.swift"), encoding: .utf8)
    let deploy = try String(contentsOf: root.appendingPathComponent("NativeOriginalBattleGeneralDeploymentRenderer.swift"), encoding: .utf8)
    let hq = try String(contentsOf: root.appendingPathComponent("NativeOriginalHeadquartersScene.swift"), encoding: .utf8)
    let outer = try String(contentsOf: root.appendingPathComponent("NativeOriginalOuterMenuScene.swift"), encoding: .utf8)

    #expect(academy.contains("strings[\"title_buygeneral\"]"))
    #expect(academy.contains("strings[\"title_generaltips\"]"))
    #expect(!academy.contains("label(\"获得上将\""))

    #expect(deploy.contains("strings[\"btn_deploy\"]"))
    #expect(!deploy.contains("addButton(confirmRect,\"确　定\""))

    for key in ["btn_princess", "btn_college", "title_headquarters", "text_equipitem", "btn_regroup", "btn_equip", "btn_infantry", "btn_cavalry", "btn_artillery", "btn_navy", "btn_fortress", "text_economy"] {
        #expect(hq.contains("strings[\"\(key)\"]"))
    }
    #expect(!hq.contains("addPanel(panel, title: \"总　部\")"))

    #expect(outer.contains("strings[\"text2_american\"]"))
    #expect(outer.contains("strings[\"text2_european\"]"))
}
