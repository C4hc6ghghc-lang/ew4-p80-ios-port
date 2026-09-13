import Foundation

public enum NativeAnimationSequenceError: Error, Equatable, Sendable {
    case unknownUnit(String)
    case missingMotion(unit: String, type: String, index: Int, direction: String)
    case missingAsset(String)
    case emptySequence
}

public struct NativeAttackAnimationContext: Equatable, Sendable {
    public var weapon: String
    public var targetClass: String
    public var direction: String
    public var attackIndex: Int?

    public init(
        weapon: String = "",
        targetClass: String = "",
        direction: String = "all",
        attackIndex: Int? = nil
    ) {
        self.weapon = weapon
        self.targetClass = targetClass
        self.direction = direction
        self.attackIndex = attackIndex
    }
}

public struct NativeAnimationPhase: Equatable, Sendable {
    public let kind: String
    public let motionIndex: Int
    public let requestedDirection: String
    public let resolvedDirection: String
    public let assetID: String
    public let terminal: Bool

    public init(
        kind: String,
        motionIndex: Int,
        requestedDirection: String,
        resolvedDirection: String,
        assetID: String,
        terminal: Bool = false
    ) {
        self.kind = kind
        self.motionIndex = motionIndex
        self.requestedDirection = requestedDirection
        self.resolvedDirection = resolvedDirection
        self.assetID = assetID
        self.terminal = terminal
    }
}

public struct NativeAnimationSequence: Equatable, Sendable {
    public let unitName: String
    public let phases: [NativeAnimationPhase]
    public let phaseStartsMilliseconds: [Double]
    public let activeDurationMilliseconds: Double

    public init(
        unitName: String,
        phases: [NativeAnimationPhase],
        phaseStartsMilliseconds: [Double],
        activeDurationMilliseconds: Double
    ) {
        self.unitName = unitName
        self.phases = phases
        self.phaseStartsMilliseconds = phaseStartsMilliseconds
        self.activeDurationMilliseconds = activeDurationMilliseconds
    }
}

public struct NativeAnimationSequenceSample: Equatable, Sendable {
    public let phase: String
    public let motionIndex: Int
    public let assetID: String
    public let frameIndex: Int
    public let terminal: Bool
    public let completedAttackChain: Bool

    public init(
        phase: String,
        motionIndex: Int,
        assetID: String,
        frameIndex: Int,
        terminal: Bool,
        completedAttackChain: Bool
    ) {
        self.phase = phase
        self.motionIndex = motionIndex
        self.assetID = assetID
        self.frameIndex = frameIndex
        self.terminal = terminal
        self.completedAttackChain = completedAttackChain
    }
}

public enum NativeAnimationSequenceCore {
    public static func motionRecords(
        unit: NativeAnimationUnit,
        type: String,
        index: Int = 0,
        direction: String = "all"
    ) -> [NativeMotionRef] {
        unit.motions.filter {
            $0.type == type && $0.index == index && $0.direction == direction
        }
    }

    public static func hasMotion(
        unit: NativeAnimationUnit,
        type: String,
        index: Int = 0,
        direction: String = "all"
    ) -> Bool {
        !motionRecords(unit: unit, type: type, index: index, direction: direction).isEmpty
    }

    public static func pickMotion(
        unit: NativeAnimationUnit,
        type: String,
        index: Int = 0,
        direction: String = "all"
    ) -> NativeMotionRef? {
        if let exact = motionRecords(unit: unit, type: type, index: index, direction: direction).first {
            return exact
        }
        if direction != "all" {
            return motionRecords(unit: unit, type: type, index: index, direction: "all").first
        }
        return nil
    }

    public static func selectAttackIndex(
        unit: NativeAnimationUnit,
        context: NativeAttackAnimationContext
    ) -> Int {
        let hasAlternate = hasMotion(unit: unit, type: "attack", index: 1, direction: context.direction)
            || hasMotion(unit: unit, type: "attack", index: 1, direction: "all")
        if context.weapon == "guns",
           (context.targetClass == "warship" || context.targetClass == "fort"),
           hasAlternate {
            return 1
        }
        return 0
    }

    public static func buildAttackSequence(
        manifest: NativeAnimationManifest,
        unitName: String,
        context: NativeAttackAnimationContext = NativeAttackAnimationContext()
    ) throws -> NativeAnimationSequence {
        guard let unit = manifest.units[unitName] else {
            throw NativeAnimationSequenceError.unknownUnit(unitName)
        }
        let direction = context.direction
        let attackIndex = context.attackIndex ?? selectAttackIndex(unit: unit, context: context)
        guard let attack = pickMotion(unit: unit, type: "attack", index: attackIndex, direction: direction) else {
            throw NativeAnimationSequenceError.missingMotion(
                unit: unitName,
                type: "attack",
                index: attackIndex,
                direction: direction
            )
        }

        var phases: [NativeAnimationPhase] = []
        try appendPhase(
            &phases,
            manifest: manifest,
            motion: attack,
            kind: "attack",
            index: attackIndex,
            requestedDirection: direction
        )

        // Native-proven alternate attack tail: ATTACK(index > 0) -> READY.
        if attackIndex == 0 {
            if let reload = pickMotion(unit: unit, type: "reload", index: 0, direction: direction) {
                try appendPhase(
                    &phases,
                    manifest: manifest,
                    motion: reload,
                    kind: "reload",
                    index: 0,
                    requestedDirection: direction
                )
            }
            if let finish = pickMotion(unit: unit, type: "finish", index: 0, direction: direction) {
                try appendPhase(
                    &phases,
                    manifest: manifest,
                    motion: finish,
                    kind: "finish",
                    index: 0,
                    requestedDirection: direction
                )
            }
        }

        guard let ready = pickMotion(unit: unit, type: "ready", index: 0, direction: direction) else {
            throw NativeAnimationSequenceError.missingMotion(
                unit: unitName,
                type: "ready",
                index: 0,
                direction: direction
            )
        }
        guard manifest.assets[ready.asset] != nil else {
            throw NativeAnimationSequenceError.missingAsset(ready.asset)
        }
        phases.append(
            NativeAnimationPhase(
                kind: "ready",
                motionIndex: 0,
                requestedDirection: direction,
                resolvedDirection: ready.direction,
                assetID: ready.asset,
                terminal: true
            )
        )

        var starts: [Double] = []
        var time = 0.0
        for phase in phases {
            starts.append(time)
            if !phase.terminal {
                guard let asset = manifest.assets[phase.assetID] else {
                    throw NativeAnimationSequenceError.missingAsset(phase.assetID)
                }
                time += NativeAnimationTiming.rawDurationMilliseconds(asset)
            }
        }
        return NativeAnimationSequence(
            unitName: unitName,
            phases: phases,
            phaseStartsMilliseconds: starts,
            activeDurationMilliseconds: time
        )
    }

    public static func sample(
        sequence: NativeAnimationSequence,
        manifest: NativeAnimationManifest,
        elapsedMilliseconds: Double
    ) throws -> NativeAnimationSequenceSample {
        guard !sequence.phases.isEmpty else {
            throw NativeAnimationSequenceError.emptySequence
        }
        let elapsed = max(0, elapsedMilliseconds)
        for (index, phase) in sequence.phases.enumerated() {
            let start = sequence.phaseStartsMilliseconds[index]
            let local = elapsed - start
            guard let asset = manifest.assets[phase.assetID] else {
                throw NativeAnimationSequenceError.missingAsset(phase.assetID)
            }
            if phase.terminal {
                return NativeAnimationSequenceSample(
                    phase: phase.kind,
                    motionIndex: phase.motionIndex,
                    assetID: phase.assetID,
                    frameIndex: 0,
                    terminal: true,
                    completedAttackChain: elapsed >= sequence.activeDurationMilliseconds
                )
            }
            let duration = NativeAnimationTiming.rawDurationMilliseconds(asset)
            if local < duration {
                return NativeAnimationSequenceSample(
                    phase: phase.kind,
                    motionIndex: phase.motionIndex,
                    assetID: phase.assetID,
                    frameIndex: NativeAnimationTiming.frame(at: max(0, local), asset: asset),
                    terminal: false,
                    completedAttackChain: false
                )
            }
        }
        throw NativeAnimationSequenceError.emptySequence
    }

    private static func appendPhase(
        _ phases: inout [NativeAnimationPhase],
        manifest: NativeAnimationManifest,
        motion: NativeMotionRef,
        kind: String,
        index: Int,
        requestedDirection: String
    ) throws {
        guard manifest.assets[motion.asset] != nil else {
            throw NativeAnimationSequenceError.missingAsset(motion.asset)
        }
        phases.append(
            NativeAnimationPhase(
                kind: kind,
                motionIndex: index,
                requestedDirection: requestedDirection,
                resolvedDirection: motion.direction,
                assetID: motion.asset
            )
        )
    }
}
