import Foundation
import Testing
@testable import EW4NativeCore

@Test func p78TransportProfilesMatchFrozenP34Rule() {
    let ordinary = NativeTransportPresentationCore.profile(armoredCarrier: false)
    #expect(ordinary.spriteKey == "transportship1.png")
    #expect(ordinary.naturalFacing == "right")
    let armored = NativeTransportPresentationCore.profile(armoredCarrier: true)
    #expect(armored.spriteKey == "transportship2.png")
    #expect(armored.naturalFacing == "left")
}

@Test func p78TransportPlacementUsesNativeHalfScaleRefs() {
    let normal = NativeTransportPresentationCore.placement(
        refX: 70, refY: 107, width: 151, height: 170,
        desiredFacing: "right", naturalFacing: "right"
    )
    #expect(normal == .init(x: -35, y: 53.5, width: 75.5, height: 85, mirrored: false))

    let flipped = NativeTransportPresentationCore.placement(
        refX: 70, refY: 107, width: 151, height: 170,
        desiredFacing: "left", naturalFacing: "right"
    )
    #expect(flipped == .init(x: 35, y: 53.5, width: 75.5, height: 85, mirrored: true))

    let armored = NativeTransportPresentationCore.placement(
        refX: 94, refY: 119, width: 150, height: 194,
        desiredFacing: "left", naturalFacing: "left"
    )
    #expect(armored == .init(x: -47, y: 59.5, width: 75, height: 97, mirrored: false))
}

@Test func p78TransportAssetsKeepFrozenRefs() throws {
    let here = URL(fileURLWithPath: #filePath)
    let nativeRoot = here.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let manifestURL = nativeRoot.appendingPathComponent("Resources/sprite_manifest.json")
    let manifest = try ResourceLoader.decode([String: SpriteManifestEntry].self, from: manifestURL)
    let ship1 = try #require(manifest["transportship1.png"])
    let ship2 = try #require(manifest["transportship2.png"])
    #expect(ship1.refx == 70 && ship1.refy == 107 && ship1.w == 151 && ship1.h == 170)
    #expect(ship2.refx == 94 && ship2.refy == 119 && ship2.w == 150 && ship2.h == 194)
    #expect(ship1.file.hasSuffix("buildings_hd/transportship1.png"))
    #expect(ship2.file.hasSuffix("buildings_hd/transportship2.png"))
}

@Test func p78NativeBattleSceneConsumesTransportPresentation() throws {
    let here = URL(fileURLWithPath: #filePath)
    let nativeRoot = here.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let sceneURL = nativeRoot.appendingPathComponent("NativeCore/Sources/EW4NativeRenderer/NativeBattleScene.swift")
    let scene = try String(contentsOf: sceneURL, encoding: .utf8)
    #expect(scene.contains("if unit.embarked && statType != \"warship\""))
    #expect(scene.contains("renderTransportUnit(unit, gameplay: gameplay, store: store)"))
    #expect(scene.contains("gameplay.hasEquipmentFunction(unit, function: 12)"))
    #expect(scene.contains("updateTransportFacing(unitIndex: unitIndex, desiredFacing: sample.facing, gameplay: gameplay)"))
    #expect(scene.contains("if unit.embarked && statType != \"warship\" { continue }"))
    #expect(scene.contains("refreshUnitNode(unitIndex, gameplay: gameplay)"))
}
