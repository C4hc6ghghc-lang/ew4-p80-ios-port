import Foundation
import Testing
@testable import EW4NativeCore

private func animationManifest() throws -> NativeAnimationManifest {
    let root = TestResourcePaths.data("native_animation_core877.json")
    return try ResourceLoader.decode(NativeAnimationManifest.self, from: root)
}

@Test func nativeAttack0ChainMatchesRecoveredStateMachine() throws {
    let manifest = try animationManifest()
    let sequence = try NativeAnimationSequenceCore.buildAttackSequence(
        manifest: manifest,
        unitName: "Grenadier 1"
    )
    #expect(sequence.phases.map(\.kind) == ["attack", "reload", "finish", "ready"])
    #expect(sequence.phases.map(\.motionIndex) == [0, 0, 0, 0])
    #expect(sequence.phases.last?.terminal == true)
    #expect(sequence.activeDurationMilliseconds > 0)
}

@Test func gunsAgainstFortUseAttack1AndSkipTail() throws {
    let manifest = try animationManifest()
    let sequence = try NativeAnimationSequenceCore.buildAttackSequence(
        manifest: manifest,
        unitName: "Grenadier 1",
        context: NativeAttackAnimationContext(weapon: "guns", targetClass: "fort")
    )
    #expect(sequence.phases.map(\.kind) == ["attack", "ready"])
    #expect(sequence.phases.first?.motionIndex == 1)
}

@Test func machineGunSpeedShortensRealDuration() throws {
    let manifest = try animationManifest()
    let sequence = try NativeAnimationSequenceCore.buildAttackSequence(
        manifest: manifest,
        unitName: "Machine Gun 1"
    )
    #expect(sequence.phases.map(\.kind) == ["attack", "finish", "ready"])
    let firstPhase = try #require(sequence.phases.first)
    let attack = try #require(manifest.assets[firstPhase.assetID])
    #expect(attack.motionSpeedAttr == 2.5)
    let rawAtSpeedOne = Double(attack.frameCount) / Double(attack.fps) * 1000
    #expect(abs(NativeAnimationTiming.rawDurationMilliseconds(attack) - rawAtSpeedOne / 2.5) < 0.001)
}

@Test func directionalMotionFallsBackOnlyWhenNeeded() throws {
    let manifest = try animationManifest()
    let ship = try #require(manifest.units["Privateer"])
    let right = try #require(NativeAnimationSequenceCore.pickMotion(unit: ship, type: "attack", direction: "right"))
    #expect(right.direction == "right")

    let grenadier = try #require(manifest.units["Grenadier 1"])
    let fallback = try #require(NativeAnimationSequenceCore.pickMotion(unit: grenadier, type: "attack", direction: "left"))
    #expect(fallback.direction == "all")
}

@Test func terminalReadyStartsAtFrameZeroAfterActiveChain() throws {
    let manifest = try animationManifest()
    let sequence = try NativeAnimationSequenceCore.buildAttackSequence(
        manifest: manifest,
        unitName: "Grenadier 1"
    )
    let sample = try NativeAnimationSequenceCore.sample(
        sequence: sequence,
        manifest: manifest,
        elapsedMilliseconds: sequence.activeDurationMilliseconds + 500
    )
    #expect(sample.phase == "ready")
    #expect(sample.frameIndex == 0)
    #expect(sample.terminal)
    #expect(sample.completedAttackChain)
}

@Test func all877NativeUnitsBuildAttackChainsInBothHorizontalDirections() throws {
    let manifest = try animationManifest()
    var checked = 0
    for unitName in manifest.units.keys.sorted() {
        for direction in ["left", "right"] {
            let sequence = try NativeAnimationSequenceCore.buildAttackSequence(
                manifest: manifest,
                unitName: unitName,
                context: NativeAttackAnimationContext(
                    weapon: "",
                    targetClass: "infantry",
                    direction: direction
                )
            )
            #expect(sequence.phases.first?.kind == "attack")
            #expect(sequence.phases.last?.kind == "ready")
            #expect(sequence.phases.last?.terminal == true)
            checked += 1
        }
    }
    #expect(checked == manifest.unitCount * 2)
    #expect(manifest.unitCount == 877)
}
