import Foundation
import Testing
@testable import EW4NativeCore

private func p79NativeRoot() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
}

@Test func p79BattleFlagAnimationAndLegacyCountryAliasesMatchFrozenWebParity() {
    #expect(NativeBattlefieldOverlayCore.flagCountryCode("gb") == "gbr")
    #expect(NativeBattlefieldOverlayCore.flagCountryCode("de") == "pru")
    #expect(NativeBattlefieldOverlayCore.flagCountryCode("fr") == "fra")
    #expect(NativeBattlefieldOverlayCore.flagCountryCode("rus") == "rus")

    #expect(NativeBattlefieldOverlayCore.flagFrame(unitIndex: 0, nowMilliseconds: 0) == 1)
    #expect(NativeBattlefieldOverlayCore.flagFrame(unitIndex: 0, nowMilliseconds: 119) == 1)
    #expect(NativeBattlefieldOverlayCore.flagFrame(unitIndex: 0, nowMilliseconds: 120) == 2)
    #expect(NativeBattlefieldOverlayCore.flagFrame(unitIndex: 3, nowMilliseconds: 0) == 4)
    #expect(NativeBattlefieldOverlayCore.flagFrame(unitIndex: 3, nowMilliseconds: 120) == 1)
}

@Test func p79OverlayGeometryMatchesMatureP32P39BattlefieldComposition() {
    let pole = NativeBattlefieldOverlayCore.flagPolePlacement(refX: 10, refY: 7, width: 18, height: 94)
    #expect(pole == .init(x: -19, y: 46.5, width: 9, height: 47))
    let cloth = NativeBattlefieldOverlayCore.flagClothPlacement(width: 50, height: 34)
    #expect(cloth == .init(x: -14, y: 43, width: 25, height: 17))

    let board = NativeBattlefieldOverlayCore.commanderBoardPlacement(refX: 30, refY: 74, width: 58, height: 79)
    #expect(board == .init(x: -15, y: 37, width: 29, height: 39.5))
    let portrait = NativeBattlefieldOverlayCore.commanderPortraitPlacement(board: board, width: 44, height: 44)
    #expect(portrait == .init(x: -11.5, y: 33.5, width: 22, height: 22))

    #expect(NativeBattlefieldOverlayCore.moraleSprite(1) == "morale_up.png")
    #expect(NativeBattlefieldOverlayCore.moraleSprite(0) == nil)
    #expect(NativeBattlefieldOverlayCore.moraleSprite(-1) == "morale_down1.png")
    #expect(NativeBattlefieldOverlayCore.moraleSprite(-2) == "morale_down2.png")
    #expect(NativeBattlefieldOverlayCore.moraleSprite(-3) == "morale_down3.png")
}

@Test func p79AllBattleCountriesFlagsAndCommanderBubblesResolveToFrozenAssets() throws {
    let root = p79NativeRoot()
    let manifest = try ResourceLoader.decode([String: SpriteManifestEntry].self, from: root.appendingPathComponent("Resources/sprite_manifest.json"))
    let battles = try ResourceLoader.decode(BattlesRuntimeFile.self, from: root.appendingPathComponent("Resources/Data/battles_runtime.json"))
    let commanders = try ResourceLoader.decode([String: Commander].self, from: root.appendingPathComponent("Resources/Data/commanders.json"))

    for key in ["flagpole.png", "board_smallgenerals.png", "morale_up.png", "morale_down1.png", "morale_down2.png", "morale_down3.png"] {
        #expect(manifest[key] != nil, "missing battlefield overlay sprite \(key)")
    }

    let rawCodes = Set(battles.battles.flatMap { $0.countries.map(\.code) })
    for raw in rawCodes {
        let code = NativeBattlefieldOverlayCore.flagCountryCode(raw)
        for frame in 1...4 {
            #expect(manifest["\(code)\(frame).png"] != nil, "missing flag frame \(code)\(frame).png from raw code \(raw)")
        }
    }

    let commanderIDs = Set(battles.battles.flatMap { $0.units.compactMap(\.commanderID) }).filter { $0 > 0 }
    for id in commanderIDs {
        let commander = try #require(commanders[String(id)], "missing commander \(id)")
        #expect(manifest["\(commander.name).png"] != nil, "missing battlefield commander portrait \(commander.name).png")
    }
}

@Test func p79NativeBattleSceneActuallyConsumesFlagsCommanderBubblesAndMorale() throws {
    let root = p79NativeRoot()
    let sceneURL = root.appendingPathComponent("NativeCore/Sources/EW4NativeRenderer/NativeBattleScene.swift")
    let scene = try String(contentsOf: sceneURL, encoding: .utf8)

    #expect(scene.contains("addNativeBattleFlag(to: container"))
    #expect(scene.contains("addNativeCommanderBubble(to: container"))
    #expect(scene.contains("installNativeMoraleMarker(to: container"))
    #expect(scene.contains("updateNativeBattlefieldOverlays(nowMilliseconds: now)"))
    #expect(scene.contains("battle-flag-cloth-"))
    #expect(scene.contains("board_smallgenerals.png"))
    #expect(scene.contains("gameplay.moraleState(for: unit)"))

    #expect(scene.contains("root.zPosition = 0"))
    #expect(scene.contains("model.zPosition = 1"))
    #expect(scene.contains("zBase: 10"))
    #expect(scene.contains("board.zPosition = 20"))
    #expect(scene.contains("portrait.zPosition = 21"))
    #expect(scene.contains("marker.zPosition = 22"))
}
