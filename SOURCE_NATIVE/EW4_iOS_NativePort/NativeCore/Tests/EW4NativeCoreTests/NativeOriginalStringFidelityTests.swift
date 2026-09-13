import Foundation
import Testing
@testable import EW4NativeCore

@Test func p63OriginalCNStringAuthorityValuesAreFrozen() throws {
    let strings = try ResourceLoader.decode([String: String].self, from: TestResourcePaths.data("strings_cn.json"))
    #expect(strings["title_business"] == "交易所")
    #expect(strings["title_deploygeneral"] == "指挥部")
    #expect(strings["title_unitinfo"] == "信  息")
    #expect(strings["text_victory"] == "胜利")
    #expect(strings["text_bestvic"] == "重大胜利")
    #expect(strings["text_round_word"] == "回合")
    #expect(strings["title_shop"] == "商  店")
    #expect(strings["name_Seller"] == "商人")
    #expect(strings["text_sellersays"] == "欢迎光临！")
    #expect(strings["text_buy"] == "购买")
    #expect(strings["text_sell"] == "卖出")
}

@Test func p63StageIntroUsesOriginalCNKeysInsteadOfInventedBestVictoryCopy() throws {
    let source = try String(contentsOf: TestResourcePaths.projectRoot
        .appendingPathComponent("NativeCore/Sources/EW4NativeRenderer/NativeOriginalStageIntroRenderer.swift"), encoding: .utf8)
    #expect(source.contains("strings[\"text_victory\"]"))
    #expect(source.contains("strings[\"text_bestvic\"]"))
    #expect(source.contains("strings[\"text_round_word\"]"))
    #expect(source.contains("?? \"重大胜利\""))
    #expect(!source.contains("title: \"最佳胜利\""))
}

@Test func p63BattleFormsUseOriginalCNTitleKeys() throws {
    let rendererRoot = TestResourcePaths.projectRoot.appendingPathComponent("NativeCore/Sources/EW4NativeRenderer", isDirectory: true)
    let market = try String(contentsOf: rendererRoot.appendingPathComponent("NativeOriginalMarketRenderer.swift"), encoding: .utf8)
    let deployment = try String(contentsOf: rendererRoot.appendingPathComponent("NativeOriginalBattleGeneralDeploymentRenderer.swift"), encoding: .utf8)
    let unitInfo = try String(contentsOf: rendererRoot.appendingPathComponent("NativeOriginalBattleUnitInfoRenderer.swift"), encoding: .utf8)
    #expect(market.contains("strings[\"title_business\"]"))
    #expect(!market.contains("label(\"贸　易\""))
    #expect(deployment.contains("strings[\"title_deploygeneral\"]"))
    #expect(!deployment.contains("label(\"部署将领\""))
    #expect(unitInfo.contains("strings[\"title_unitinfo\"]"))
    #expect(!unitInfo.contains("label(\"信　息\""))
}

@Test func p63ShopSurfacesBindOriginalCNShopStrings() throws {
    let rendererRoot = TestResourcePaths.projectRoot.appendingPathComponent("NativeCore/Sources/EW4NativeRenderer", isDirectory: true)
    let battle = try String(contentsOf: rendererRoot.appendingPathComponent("NativeOriginalBattleShopRenderer.swift"), encoding: .utf8)
    let hq = try String(contentsOf: rendererRoot.appendingPathComponent("NativeOriginalHQShopScene.swift"), encoding: .utf8)
    for source in [battle, hq] {
        #expect(source.contains("strings[\"title_shop\"]"))
        #expect(source.contains("strings[\"name_Seller\"]"))
        #expect(source.contains("strings[\"text_sellersays\"]"))
        #expect(source.contains("strings[\"text_buy\"]"))
        #expect(source.contains("strings[\"text_sell\"]"))
    }
}
