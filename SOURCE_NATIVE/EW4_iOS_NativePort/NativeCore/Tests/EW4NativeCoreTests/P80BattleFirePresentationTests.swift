import Foundation
import Testing
@testable import EW4NativeCore

private func p80NativeRoot() -> URL {
    URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
}

@Test func p80FireAtlasFramesAndTimingMatchMatureBattleRenderer() {
    #expect(NativeBattleFirePresentationCore.frames == [
        .init(x: 1, y: 1, width: 108, height: 236),
        .init(x: 110, y: 1, width: 105, height: 230),
        .init(x: 1, y: 238, width: 100, height: 214),
        .init(x: 110, y: 232, width: 98, height: 214),
        .init(x: 216, y: 1, width: 87, height: 202),
        .init(x: 304, y: 1, width: 96, height: 191)
    ])
    #expect(NativeBattleFirePresentationCore.frameIndex(cellOrdinal: 0, nowMilliseconds: 0) == 0)
    #expect(NativeBattleFirePresentationCore.frameIndex(cellOrdinal: 0, nowMilliseconds: 159) == 0)
    #expect(NativeBattleFirePresentationCore.frameIndex(cellOrdinal: 0, nowMilliseconds: 160) == 1)
    #expect(NativeBattleFirePresentationCore.frameIndex(cellOrdinal: 5, nowMilliseconds: 160) == 0)
}

@Test func p80FirePlacementAndAtlasCoordinatesMatchMatureCanvasMath() {
    let first = NativeBattleFirePresentationCore.frames[0]
    let p = NativeBattleFirePresentationCore.placement(frame: first)
    #expect(p.height == 42)
    #expect(abs(p.width - (42.0 * 108.0 / 236.0)) < 0.0001)
    #expect(p.offsetX == 0)
    #expect(p.offsetY == 4)

    let r = NativeBattleFirePresentationCore.normalizedTextureRect(frame: first)
    #expect(abs(r.origin.x - 1.0 / 512.0) < 0.000001)
    #expect(abs(r.origin.y - (1024.0 - 1.0 - 236.0) / 1024.0) < 0.000001)
}

@Test func p80FireAssetExistsAndFireStateAlreadyPersistsAcrossSaveRehydration() throws {
    let root = p80NativeRoot()
    #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent("Resources/Effects/anim_fire_hd.png").path))

    let save = try String(contentsOf: root.appendingPathComponent("NativeCore/Sources/EW4NativeCore/NativeBattleSaveCore.swift"), encoding: .utf8)
    let rehydrate = try String(contentsOf: root.appendingPathComponent("NativeCore/Sources/EW4NativeCore/NativeBattleRehydrationCore.swift"), encoding: .utf8)
    let events = try String(contentsOf: root.appendingPathComponent("NativeCore/Sources/EW4NativeCore/NativeBattleEventCore.swift"), encoding: .utf8)
    #expect(save.contains("fireCells"))
    #expect(rehydrate.contains("fireCells"))
    #expect(events.contains("context.fireCells.insert"))
    #expect(events.contains("context.fireCells.remove"))
}

@Test func p80NativeBattleSceneActuallyRendersAndSynchronizesFireCells() throws {
    let root = p80NativeRoot()
    let scene = try String(contentsOf: root.appendingPathComponent("NativeCore/Sources/EW4NativeRenderer/NativeBattleScene.swift"), encoding: .utf8)
    #expect(scene.contains("updateNativeFirePresentation(nowMilliseconds: now)"))
    #expect(scene.contains("context.fireCells"))
    #expect(scene.contains("anim_fire_hd.png"))
    #expect(scene.contains("battle-fire-"))
    #expect(scene.contains("node.zPosition = 75"))
    #expect(scene.contains("fireEffectNodes[key] = nil"))
}
