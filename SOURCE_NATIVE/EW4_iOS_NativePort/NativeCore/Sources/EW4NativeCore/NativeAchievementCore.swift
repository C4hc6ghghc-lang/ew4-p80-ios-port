import Foundation

public struct NativeAchievementStatSummary: Equatable, Sendable {
    public let level: Int
    public let score: Int
    public let raw: Int
}

public struct NativeAchievementContinent: Equatable, Sendable {
    public let value: Int
    public let display: Int
    public let digits: [Int]
}

public struct NativeAchievementViewModel: Equatable, Sendable {
    public let stageStarsEarned: Int
    public let stageStarsMax: Int
    public let military: NativeAchievementStatSummary
    public let nobility: NativeAchievementStatSummary
    public let continents: [String: NativeAchievementContinent]
    public let generalIDs: [Int]
}

/// Swift parity for mature P28 `native_achievement_core.js` local semantics.
/// Champion/Ranking platform navigation remains intentionally outside the
/// single-player PORT_ONLY runtime.
public enum NativeAchievementCore {
    public static let stageCounts = [18, 17, 15, 13, 11, 10]
    public static let maxStageStars = stageCounts.reduce(0) { $0 + $1 * 5 }

    public static func ownedGeneralIDs(profile: NativePlayerProfile, maxID: Int = 208) -> [Int] {
        var seen = Set<Int>()
        return profile.ownedCommanderIDs.filter { id in
            guard id >= 1, id <= maxID, !seen.contains(id) else { return false }
            seen.insert(id); return true
        }
    }

    public static func rawMilitary(profile: NativePlayerProfile, commander: Commander) -> Int {
        let state = NativePlayerProfileCore.generalGrowthState(profile: profile, raw: commander)
        var total = 300 + max(0, state.militaryProgress)
        if state.rank > 0 {
            for i in 0..<min(state.rank, NativeGeneralGrowthCore.militaryThresholds.count) {
                total += NativeGeneralGrowthCore.militaryThresholds[i]
            }
        }
        return total
    }

    public static func rawNobility(profile: NativePlayerProfile, commander: Commander) -> Int {
        let state = NativePlayerProfileCore.generalGrowthState(profile: profile, raw: commander)
        var total = 60 + max(0, state.nobilityProgress)
        if state.nobility > 0 {
            for i in 0..<min(state.nobility, NativeGeneralGrowthCore.nobilityThresholds.count) {
                total += NativeGeneralGrowthCore.nobilityThresholds[i]
            }
        }
        return total
    }

    public static func aggregateLevel(total: Int, cutoff: Int, first: Int, multiplier: Float) -> Int {
        let total = max(0, total)
        if total <= cutoff { return 1 }
        var level = 2
        var threshold = first
        while level < 99 && total >= threshold {
            threshold = Int(Float(threshold) * multiplier)
            level += 1
        }
        return level
    }

    public static func globalSummary(profile: NativePlayerProfile, commanders: [Int: Commander]) -> (military: NativeAchievementStatSummary, nobility: NativeAchievementStatSummary) {
        let generals = ownedGeneralIDs(profile: profile).compactMap { commanders[$0] }
        let militaryRaw = generals.reduce(0) { $0 + rawMilitary(profile: profile, commander: $1) }
        let nobilityRaw = generals.reduce(0) { $0 + rawNobility(profile: profile, commander: $1) }
        return (
            .init(level: aggregateLevel(total: militaryRaw, cutoff: 99, first: 121, multiplier: 1.214), score: militaryRaw / 10, raw: militaryRaw),
            .init(level: aggregateLevel(total: nobilityRaw, cutoff: 49, first: 56, multiplier: 1.125), score: nobilityRaw * 4, raw: nobilityRaw)
        )
    }

    public static func campaignStageStars(profile: NativePlayerProfile) -> (earned: Int, max: Int) {
        let best = profile.intMap("campaignBestRating")
        let progress = profile.intMap("campaignProgress")
        var earned = 0
        for zone in 1...stageCounts.count {
            for stage in 1...stageCounts[zone - 1] {
                let file = "campaign\(zone)_\(String(format: "%02d", stage)).btl"
                if let rating = best[file] { earned += min(5, max(0, rating)) }
                else {
                    let p = min(2, max(0, progress[file] ?? 0))
                    earned += p >= 2 ? 5 : (p >= 1 ? 1 : 0)
                }
            }
        }
        return (min(maxStageStars, max(0, earned)), maxStageStars)
    }

    public static func continentStoredValue(profile: NativePlayerProfile, key: String) -> Int {
        guard case .object(let records) = profile.document["achievementConquests"], let raw = records[key] else { return 0 }
        let value: Int
        switch raw {
        case .int(let v): value = v
        case .double(let v): value = Int(v)
        case .string(let v): value = Int(v) ?? 0
        case .object(let object):
            if let item = object["value"] {
                switch item { case .int(let v): value=v; case .double(let v): value=Int(v); case .string(let v): value=Int(v) ?? 0; default: value=0 }
            } else if case .array(let digits)? = object["rule"] {
                value = digits.prefix(3).reduce(0) { partial, item in
                    let d: Int
                    switch item { case .int(let v): d=v; case .double(let v): d=Int(v); case .string(let v): d=Int(v) ?? 0; default: d=0 }
                    return partial * 10 + min(9, max(0, d))
                }
            } else { value = 0 }
        default: value = 0
        }
        return min(1000, max(0, value))
    }

    public static func ruleDigits(_ value: Int) -> [Int] {
        String(min(999, max(0, value))).compactMap { Int(String($0)) }
    }

    public static func continent(profile: NativePlayerProfile, key: String) -> NativeAchievementContinent {
        let stored = continentStoredValue(profile: profile, key: key)
        let display = min(999, stored)
        return .init(value: stored, display: display, digits: ruleDigits(display))
    }

    public static func viewModel(profile: NativePlayerProfile, commanders: [Int: Commander]) -> NativeAchievementViewModel {
        let stars = campaignStageStars(profile: profile)
        let summary = globalSummary(profile: profile, commanders: commanders)
        return .init(
            stageStarsEarned: stars.earned,
            stageStarsMax: stars.max,
            military: summary.military,
            nobility: summary.nobility,
            continents: [
                "europe": continent(profile: profile, key: "europe"),
                "america": continent(profile: profile, key: "america"),
                "asia": continent(profile: profile, key: "asia")
            ],
            generalIDs: ownedGeneralIDs(profile: profile)
        )
    }
}
