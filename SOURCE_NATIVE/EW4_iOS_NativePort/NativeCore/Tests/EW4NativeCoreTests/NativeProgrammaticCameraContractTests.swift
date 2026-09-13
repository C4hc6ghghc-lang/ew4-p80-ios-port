import Foundation
import Testing
@testable import EW4NativeCore

@Test func nativeBattleSceneConsumesGameSpeedForTutorialProgrammaticCamera() throws {
    let source = try String(contentsOf: TestResourcePaths.projectRoot
        .appendingPathComponent("NativeCore/Sources/EW4NativeRenderer/NativeBattleScene.swift"), encoding: .utf8)
    #expect(source.contains("NativeOptionsCore.settings(from: playerProfile)"))
    #expect(source.contains("NativeCamera.startProgrammaticMove("))
    #expect(source.contains("gameSpeed: settings.gameSpeed"))
    #expect(source.contains("case .moveToArea(let cell): if let cell { focusProgrammatically(on: cell) }"))
    #expect(source.contains("updateProgrammaticCamera(dtSeconds: dt)"))
}

@Test func manualSetCameraCancelsProgrammaticMotor() throws {
    let source = try String(contentsOf: TestResourcePaths.projectRoot
        .appendingPathComponent("NativeCore/Sources/EW4NativeRenderer/NativeBattleScene.swift"), encoding: .utf8)
    let setter = try #require(source.range(of: "public func setCamera(_ next: NativeCameraState)"))
    let end = source.range(of: "private func startProgrammaticCameraMove", range: setter.upperBound..<source.endIndex)?.lowerBound ?? source.endIndex
    let block = String(source[setter.lowerBound..<end])
    #expect(block.contains("programmaticCameraMotion = nil"))
}

@Test func playerPairFocusDefersMutationUntilCameraMotorStops() throws {
    let source = try String(contentsOf: TestResourcePaths.projectRoot
        .appendingPathComponent("NativeCore/Sources/EW4NativeRenderer/NativeBattleScene.swift"), encoding: .utf8)
    #expect(source.contains("continuation: .playerAttack(attackerIndex: selected.index, defenderIndex: target.index)"))
    #expect(source.contains("continuation: .playerMove(unitIndex: selected.index, target: cell)"))
    #expect(source.contains("if !step.active { resumeActionAfterCameraFocus() }"))
    let attackQueue = try #require(source.range(of: "continuation: .playerAttack(attackerIndex: selected.index, defenderIndex: target.index)"))
    let attackResolve = try #require(source.range(of: "resolvePlayerAttack(attackerIndex: selected.index, defenderIndex: target.index)", range: attackQueue.upperBound..<source.endIndex))
    #expect(attackQueue.lowerBound < attackResolve.lowerBound)
}

@Test func aiPairFocusHoldsMutatedGameplayAndDriverOffLiveStateUntilCameraStops() throws {
    let source = try String(contentsOf: TestResourcePaths.projectRoot
        .appendingPathComponent("NativeCore/Sources/EW4NativeRenderer/NativeBattleScene.swift"), encoding: .utf8)
    #expect(source.contains("continuation: .ai(driver: driver, gameplay: gameplay, action: action)"))
    #expect(source.contains("case .ai(let driver, var gameplay, let action):"))
    #expect(source.contains("commitFocusedAIAction(action, driver: driver, gameplay: &gameplay"))
    #expect(source.contains("guard pendingActionCameraContinuation == nil,"))
}

@Test func nativeAIFastForwardKeepsSimulationDriverButBypassesCameraAndCompressesPresentation() throws {
    let source = try String(contentsOf: TestResourcePaths.projectRoot
        .appendingPathComponent("NativeCore/Sources/EW4NativeRenderer/NativeBattleScene.swift"), encoding: .utf8)
    #expect(source.contains("private var aiFastForward = false"))
    #expect(source.contains("if gameplay.phase == .ai, aiPresentationDriver != nil"))
    #expect(source.contains("aiFastForward = true"))
    #expect(source.contains("programmaticCameraMotion = nil"))
    #expect(source.contains("if !aiFastForward"))
    #expect(source.contains("fastAI: aiFastForward"))
    #expect(source.contains("NativeImpactPresentationCore.fastAI(plan)"))
    #expect(source.contains("aiFastForward = false"))
}
