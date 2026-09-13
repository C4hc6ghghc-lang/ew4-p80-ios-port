import Foundation
import Testing
@testable import EW4NativeCore

@Test func p64BattleModalOriginalCNValuesAreFrozen() throws {
    let strings = try ResourceLoader.decode([String: String].self, from: TestResourcePaths.data("strings_cn.json"))
    #expect(strings["title_pause"] == "暂 停")
    #expect(strings["text_round_word"] == "回合")
    #expect(strings["btn_save"] == "保存")
    #expect(strings["btn_option"] == "设定")
    #expect(strings["btn_restart"] == "重新开始")
    #expect(strings["btn_exit"] == "退出")
    #expect(strings["title_roundturn"] == "你的回合")
    #expect(strings["text_economy"] == "经济")
    #expect(strings["text_round"] == "回合")
    #expect(strings["text_foodsuply"] == "食物补给")
    #expect(strings["title_savegame"] == "保存游戏")
    #expect(strings["title_loadgame"] == "载入游戏")
    #expect(strings["text_autosave"] == "自动保存")
    #expect(strings["text_empty"] == "无")
}

@Test func p64OriginalXMLBindsBattleModalStringKeys() throws {
    let xml = try String(contentsOf: TestResourcePaths.data("original_layout-568h.xml"), encoding: .utf8)
    #expect(xml.contains("<Layout id=\"form_pause\""))
    #expect(xml.contains("title=\"title_pause\""))
    #expect(xml.contains("text=\"text_round_word\""))
    #expect(xml.contains("text=\"btn_save\""))
    #expect(xml.contains("text=\"btn_option\""))
    #expect(xml.contains("text=\"btn_restart\""))
    #expect(xml.contains("text=\"btn_exit\""))
    #expect(xml.contains("<Layout id=\"form_roundturn\""))
    #expect(xml.contains("title=\"title_roundturn\""))
    #expect(xml.contains("text=\"text_economy\""))
    #expect(xml.contains("text=\"text_round\""))
    #expect(xml.contains("text=\"text_foodsuply\""))
    #expect(xml.contains("<Layout id=\"form_save\""))
    #expect(xml.contains("title=\"title_savegame\""))
    #expect(xml.contains("title=\"text_autosave\""))
}

@Test func p64BattleModalRendererConsumesFrozenCNKeys() throws {
    let source = try String(contentsOf: TestResourcePaths.projectRoot
        .appendingPathComponent("NativeCore/Sources/EW4NativeRenderer/NativeOriginalBattleModalRenderer.swift"), encoding: .utf8)
    let keys = [
        "title_pause", "text_round_word", "btn_save", "btn_option", "btn_restart", "btn_exit",
        "title_roundturn", "text_economy", "text_round", "text_foodsuply",
        "title_savegame", "title_loadgame", "text_autosave", "text_empty"
    ]
    for key in keys { #expect(source.contains("strings[\"\(key)\"]")) }
    #expect(!source.contains("\"军　粮\""))
    #expect(!source.contains("\"存　档\""))
    #expect(!source.contains("\"设　定\""))
    #expect(!source.contains("\"退　出\""))
}
