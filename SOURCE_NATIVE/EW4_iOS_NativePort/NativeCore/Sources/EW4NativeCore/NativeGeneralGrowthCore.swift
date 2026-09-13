import Foundation

public struct NativeGeneralGrowthState: Equatable, Sendable {
    public var rank: Int
    public var militaryProgress: Int
    public var nobility: Int
    public var nobilityProgress: Int

    public init(rank: Int, militaryProgress: Int = 0, nobility: Int, nobilityProgress: Int = 0) {
        self.rank = rank
        self.militaryProgress = militaryProgress
        self.nobility = nobility
        self.nobilityProgress = nobilityProgress
    }
}

public struct NativeGeneralGrowthContext: Equatable, Sendable {
    public let skillIDs: Set<Int>
    public let items: [NativeItemEffectDefinition]

    public init(skillIDs: Set<Int> = [], items: [NativeItemEffectDefinition] = []) {
        self.skillIDs = skillIDs
        self.items = items
    }
}

public struct NativeGeneralGrowthAward: Equatable, Sendable {
    public let militaryGain: Int
    public let nobilityGain: Int
    public let before: NativeGeneralGrowthState
    public let after: NativeGeneralGrowthState

    public var rankLeveled: Bool { after.rank > before.rank }
    public var nobilityLeveled: Bool { after.nobility > before.nobility }
}

public enum NativeGeneralGrowthCore {
    public static let militaryThresholds = [500, 800, 1_200, 1_900, 3_000, 4_800, 7_500, 12_000, 19_000, 30_000, 48_000, 76_000, 120_000, 200_000]
    public static let nobilityThresholds = [100, 200, 300, 450, 675, 1_000, 1_500, 2_250, 3_375]
    public static let militaryMax = militaryThresholds.count
    public static let nobilityMax = nobilityThresholds.count
    public static let nobilityGrowthSkill = 19
    public static let militaryGrowthExpertSkill = 20
    public static let militaryGrowthMasterSkill = 21

    public static func normalize(level: Int, progress: Int, thresholds: [Int]) -> (level: Int, progress: Int) {
        var level = max(0, min(thresholds.count, level))
        var progress = max(0, progress)
        while level < thresholds.count, progress >= thresholds[level] {
            progress -= thresholds[level]
            level += 1
        }
        if level >= thresholds.count { progress = 0 }
        return (level, progress)
    }

    public static func addMilitaryProgress(rank: Int, progress: Int, amount: Int) -> (level: Int, progress: Int) {
        normalize(level: rank, progress: max(0, progress) + max(0, amount), thresholds: militaryThresholds)
    }

    public static func addNobilityProgress(level: Int, progress: Int, amount: Int) -> (level: Int, progress: Int) {
        normalize(level: level, progress: max(0, progress) + max(0, amount), thresholds: nobilityThresholds)
    }

    public static func equipmentGrowthMultiplier(kind: String, items: [NativeItemEffectDefinition]) -> Double? {
        let function = kind == "military" ? 2 : (kind == "nobility" ? 1 : -1)
        guard function >= 0 else { return nil }
        var best: Double?
        for item in items where item.function == function {
            let multiplier = max(0, Double(item.value) / 100.0)
            if best == nil || multiplier > best! { best = multiplier }
        }
        return best
    }

    public static func skillGrowthMultiplier(kind: String, skillIDs: Set<Int>) -> Double {
        if kind == "nobility" {
            return skillIDs.contains(nobilityGrowthSkill) ? 1.5 : 1.0
        }
        if kind == "military" {
            if skillIDs.contains(militaryGrowthMasterSkill) { return 1.8 }
            if skillIDs.contains(militaryGrowthExpertSkill) { return 1.4 }
        }
        return 1.0
    }

    public static func growthMultiplier(kind: String, context: NativeGeneralGrowthContext) -> Double {
        equipmentGrowthMultiplier(kind: kind, items: context.items)
            ?? skillGrowthMultiplier(kind: kind, skillIDs: context.skillIDs)
    }

    public static func battleMilitaryGain(damage: Int, context: NativeGeneralGrowthContext = .init()) -> Int {
        let base = max(0, damage) * 2
        return Int(floor(Double(base) * growthMultiplier(kind: "military", context: context)))
    }

    public static func battleNobilityGain(victimGrade: Int, victimHasCommander: Bool, context: NativeGeneralGrowthContext = .init()) -> Int {
        let base = (max(0, victimGrade) + 1) * (victimHasCommander ? 2 : 1)
        return Int(floor(Double(base) * growthMultiplier(kind: "nobility", context: context)))
    }

    public static func award(
        state: NativeGeneralGrowthState,
        damage: Int,
        killed: Bool,
        victimGrade: Int,
        victimHasCommander: Bool,
        context: NativeGeneralGrowthContext = .init()
    ) -> NativeGeneralGrowthAward {
        let militaryGain = battleMilitaryGain(damage: damage, context: context)
        let nobilityGain = killed ? battleNobilityGain(victimGrade: victimGrade, victimHasCommander: victimHasCommander, context: context) : 0
        let military = addMilitaryProgress(rank: state.rank, progress: state.militaryProgress, amount: militaryGain)
        let noble = addNobilityProgress(level: state.nobility, progress: state.nobilityProgress, amount: nobilityGain)
        let after = NativeGeneralGrowthState(rank: military.level, militaryProgress: military.progress, nobility: noble.level, nobilityProgress: noble.progress)
        return NativeGeneralGrowthAward(militaryGain: militaryGain, nobilityGain: nobilityGain, before: state, after: after)
    }
}
