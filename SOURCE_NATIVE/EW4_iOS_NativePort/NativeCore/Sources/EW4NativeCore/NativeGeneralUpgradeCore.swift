import Foundation

public enum NativeGeneralUpgradeKind: Equatable, Sendable {
    case military
    case nobility
    case all
}

public struct NativeGeneralUpgradeSnapshot: Equatable, Sendable {
    public let growth: NativeGeneralGrowthState
    public let nextMilitaryLevel: Int
    public let nextNobilityLevel: Int
    public let militaryCost: Int
    public let nobilityCost: Int
    public let allFullCost: Int
    public let militaryMax: Int
    public let nobilityMax: Int

    public var militaryFull: Bool { growth.rank >= militaryMax }
    public var nobilityFull: Bool { growth.nobility >= nobilityMax }
    public var allFull: Bool { militaryFull && nobilityFull }
}

/// Native counterpart of the mature P39 `native_general_core.js` upgrade math.
/// Player-side policy is intentionally infinite medals: original costs remain
/// visible, but applying an upgrade does not decrement any medal balance.
public enum NativeGeneralUpgradeCore {
    public static let militaryMedalRate = 0.008
    public static let nobilityMedalRate = 0.2
    public static let allFullMedalCap = 3_600

    public static func nextMilitaryCost(rank: Int, progress: Int) -> Int {
        let level = max(0, min(NativeGeneralGrowthCore.militaryMax, rank))
        guard level < NativeGeneralGrowthCore.militaryMax else { return 0 }
        let remaining = max(0, NativeGeneralGrowthCore.militaryThresholds[level] - max(0, progress))
        return Int(ceil(Double(remaining) * militaryMedalRate))
    }

    public static func nextNobilityCost(level: Int, progress: Int) -> Int {
        let level = max(0, min(NativeGeneralGrowthCore.nobilityMax, level))
        guard level < NativeGeneralGrowthCore.nobilityMax else { return 0 }
        let remaining = max(0, NativeGeneralGrowthCore.nobilityThresholds[level] - max(0, progress))
        return Int(ceil(Double(remaining) * nobilityMedalRate))
    }

    private static func remainingRaw(level: Int, progress: Int, thresholds: [Int]) -> Int {
        let level = max(0, min(thresholds.count, level))
        guard level < thresholds.count else { return 0 }
        var raw = -max(0, progress)
        for index in level..<thresholds.count { raw += thresholds[index] }
        return max(0, raw)
    }

    public static func allFullCost(rank: Int, militaryProgress: Int, nobility: Int, nobilityProgress: Int) -> Int {
        let military = Int(ceil(Double(remainingRaw(level: rank, progress: militaryProgress, thresholds: NativeGeneralGrowthCore.militaryThresholds)) * militaryMedalRate))
        let noble = Int(ceil(Double(remainingRaw(level: nobility, progress: nobilityProgress, thresholds: NativeGeneralGrowthCore.nobilityThresholds)) * nobilityMedalRate))
        return min(allFullMedalCap, military + noble)
    }

    public static func snapshot(profile: NativePlayerProfile, commander: Commander) -> NativeGeneralUpgradeSnapshot {
        let growth = NativePlayerProfileCore.generalGrowthState(profile: profile, raw: commander)
        return .init(
            growth: growth,
            nextMilitaryLevel: min(NativeGeneralGrowthCore.militaryMax, growth.rank + 1),
            nextNobilityLevel: min(NativeGeneralGrowthCore.nobilityMax, growth.nobility + 1),
            militaryCost: nextMilitaryCost(rank: growth.rank, progress: growth.militaryProgress),
            nobilityCost: nextNobilityCost(level: growth.nobility, progress: growth.nobilityProgress),
            allFullCost: allFullCost(rank: growth.rank, militaryProgress: growth.militaryProgress, nobility: growth.nobility, nobilityProgress: growth.nobilityProgress),
            militaryMax: NativeGeneralGrowthCore.militaryMax,
            nobilityMax: NativeGeneralGrowthCore.nobilityMax
        )
    }

    @discardableResult
    public static func apply(profile: inout NativePlayerProfile, commander: Commander, kind: NativeGeneralUpgradeKind) -> Bool {
        guard profile.ownedCommanderIDs.contains(commander.id) else { return false }
        let before = NativePlayerProfileCore.generalGrowthState(profile: profile, raw: commander)
        var after = before
        switch kind {
        case .military:
            guard before.rank < NativeGeneralGrowthCore.militaryMax else { return false }
            after.rank = min(NativeGeneralGrowthCore.militaryMax, before.rank + 1)
            after.militaryProgress = 0
        case .nobility:
            guard before.nobility < NativeGeneralGrowthCore.nobilityMax else { return false }
            after.nobility = min(NativeGeneralGrowthCore.nobilityMax, before.nobility + 1)
            after.nobilityProgress = 0
        case .all:
            guard before.rank < NativeGeneralGrowthCore.militaryMax || before.nobility < NativeGeneralGrowthCore.nobilityMax else { return false }
            after.rank = NativeGeneralGrowthCore.militaryMax
            after.militaryProgress = 0
            after.nobility = NativeGeneralGrowthCore.nobilityMax
            after.nobilityProgress = 0
        }
        let key = String(commander.id)
        NativePlayerProfileCore.setIntMapValue(&profile, key: "rank", nestedKey: key, value: after.rank)
        NativePlayerProfileCore.setIntMapValue(&profile, key: "rankProgress", nestedKey: key, value: after.militaryProgress)
        NativePlayerProfileCore.setIntMapValue(&profile, key: "nobility", nestedKey: key, value: after.nobility)
        NativePlayerProfileCore.setIntMapValue(&profile, key: "nobilityProgress", nestedKey: key, value: after.nobilityProgress)
        return true
    }
}
