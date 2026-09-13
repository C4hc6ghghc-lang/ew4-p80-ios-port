import Foundation
import Testing
@testable import EW4NativeCore

@Test func p75BattleDeploymentKeepsPrincessesEligible() {
    let owned = [1, 2, 201, 202, 203, 204, 205, 206, 207, 208]
    let units: [NativeBattleUnitState] = [
        .init(index: 0, armyID: 1, armyName: "Militia", grade: 0, owner: 0, commanderID: nil, q: 0, r: 0, hp: 100, maxHP: 100, moved: false, attacked: false, embarked: false),
        .init(index: 1, armyID: 1, armyName: "Militia", grade: 0, owner: 0, commanderID: 201, q: 1, r: 0, hp: 100, maxHP: 100, moved: false, attacked: false, embarked: false)
    ]
    let ids = NativeGeneralDeploymentCore.eligibleCommanderIDs(
        ownedCommanderIDs: owned,
        units: units,
        playerOwner: 0,
        targetUnitIndex: 0
    )
    #expect(!ids.contains(201))
    for id in 202...208 { #expect(ids.contains(id)) }
}

@Test func p75OriginalDeployGeneralAndPrincessGeometryIsFrozen() throws {
    let here = URL(fileURLWithPath: #filePath)
    let root = here.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let xmlURL = root.appendingPathComponent("Resources/Data/original_layout-568h.xml")
    let xml = try String(contentsOf: xmlURL, encoding: .utf8)
    #expect(xml.contains("id=\"form_deploygeneral\""))
    #expect(xml.contains("id=\"btn_princess\" type=\"tmp_button\" frm1=\"btn_common_green.png\" x=\"20\" y=\"30\" w=\"70\" h=\"40\""))
    #expect(xml.contains("id=\"grid_general\" type=\"grid\" x=\"30\" y=\"85\" w=\"508\" h=\"204\" cols=\"6\" rowh=\"99\" hbland=\"8\" vbland=\"6\""))
    #expect(xml.contains("id=\"image_depnums\" type=\"image\" name=\"generalnumber.png\" x=\"255\" y=\"43\""))
    #expect(xml.contains("id=\"form_princess\" type=\"user_window\" w=\"468\" h=\"300\""))
    #expect(xml.contains("id=\"btn_go_8\" type=\"button\" frm1=\"button_confirm_blue.png\" x=\"354\" y=\"264\" w=\"55\" h=\"22\""))
    #expect(NativeHeadquartersCore.princessOrder == [202,204,201,203,205,206,207,208])
}

@Test func p75RendererConsumesOriginalDeploymentFlow() throws {
    let here = URL(fileURLWithPath: #filePath)
    let root = here.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let rendererURL = root.appendingPathComponent("NativeCore/Sources/EW4NativeRenderer/NativeOriginalBattleGeneralDeploymentRenderer.swift")
    let battleURL = root.appendingPathComponent("NativeCore/Sources/EW4NativeRenderer/NativeBattleScene.swift")
    let renderer = try String(contentsOf: rendererURL, encoding: .utf8)
    let battle = try String(contentsOf: battleURL, encoding: .utf8)
    #expect(renderer.contains("NativeHeadquartersCore.generalGrid"))
    #expect(renderer.contains("NativeHeadquartersCore.princessButton"))
    #expect(renderer.contains("NativeHeadquartersCore.academyButton"))
    #expect(renderer.contains("generalnumber.png"))
    #expect(renderer.contains("item_selected_ex.png"))
    #expect(renderer.contains("NativeHeadquartersCore.princessOrder"))
    #expect(renderer.contains("button_confirm_blue.png"))
    #expect(!battle.contains("!NativePlayerProfile.princessIDs.contains(id) || id == current"))
    #expect(battle.contains("case .princessSelect(let id)"))
    #expect(battle.contains("generalDeploymentAcademyHandler?()"))
}

@Test func p75AcademyReturnsToSameBattleScene() throws {
    let here = URL(fileURLWithPath: #filePath)
    let nativeRoot = here.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let appURL = nativeRoot.appendingPathComponent("iOSApp/App/EW4NativePortApp.swift")
    let app = try String(contentsOf: appURL, encoding: .utf8)
    #expect(app.contains("private func showMilitaryAcademy(returnScene: SKScene? = nil)"))
    #expect(app.contains("if let returnScene { self.scene = returnScene"))
    #expect(app.contains("if let battle = returnScene as? NativeBattleScene { battle.applyOptionsProfile(profile) }"))
    #expect(app.contains("battle.generalDeploymentAcademyHandler"))
}
