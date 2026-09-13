import Foundation

public struct NativeConquestScoreComponents: Equatable, Sendable {
    public let resource: Int
    public let hq: Int
    public let stage: Int
    public let round: Int
}

public struct NativeConquestAchievementResult: Equatable, Sendable {
    public let kind: String
    public let value: Int
    public let normalized: Int
    public let total: Int
    public let components: NativeConquestScoreComponents
    public let storedValue: Int?

    public init(kind: String, value: Int, normalized: Int, total: Int, components: NativeConquestScoreComponents, storedValue: Int? = nil) {
        self.kind = kind
        self.value = value
        self.normalized = normalized
        self.total = total
        self.components = components
        self.storedValue = storedValue
    }
}

public struct NativeConquestVictoryPrepared: Equatable, Sendable {
    public let normal: NativeConquestAchievementResult
    public let asiaEligible: Bool
    public let asia: NativeConquestAchievementResult?
}

public struct NativeConquestRecordResult: Equatable, Sendable {
    public let profile: NativePlayerProfile
    public let changed: Bool
    public let result: NativeConquestAchievementResult
}

/// Swift parity for P39 native_conquest_achievement_core.js.
public enum NativeConquestAchievementCore {
    public static let normalThresholds = [91,87,83,79,75,71,67,63,59,55,51,47,43,39,35,31,27,23,16,1]
    public static let asiaThresholds = [95,91,87,83,79,75,71,67,63,59,55,51,47,43,39,35,31,27,23,16]
    public static let ruleYears = [1000,950,900,850,800,750,700,650,600,550,500,450,400,350,300,250,200,150,100,50]
    public static let stageCounts = [18,17,15,13,11,10]

    public static func mapType(_ map: String) -> Int { map.lowercased() == "america" ? 1 : 0 }
    public static func normalKey(_ map: String) -> String { mapType(map) == 1 ? "america" : "europe" }

    public static func ownedGeneralIDs(_ profile: NativePlayerProfile, maxID: Int = 208) -> [Int] {
        var seen = Set<Int>()
        return profile.ownedCommanderIDs.filter { id in
            guard id >= 1, id <= maxID, !seen.contains(id) else { return false }
            seen.insert(id); return true
        }
    }

    public static func generalLevelContribution(profile: NativePlayerProfile, commanders: [Int: Commander]) -> Int {
        let rank = profile.intMap("rank")
        let nobility = profile.intMap("nobility")
        return ownedGeneralIDs(profile).reduce(into: 0) { sum, id in
            let raw = commanders[id]
            let r = max(0, min(NativeGeneralGrowthCore.militaryMax, rank[String(id)] ?? raw?.rank ?? 0))
            let n = max(0, min(NativeGeneralGrowthCore.nobilityMax, nobility[String(id)] ?? raw?.nobilityrank ?? 0))
            sum += 10 * (r + 1) * (r + 2) + 25 * (n + 1) * (n + 2)
        }
    }

    public static func resourceContribution(_ resources: CountryResources) -> Int {
        (2 * resources.money + 4 * resources.industry + resources.food) / 10
    }

    public static func campaignStageStars(_ profile: NativePlayerProfile) -> Int {
        var earned = 0
        for zone in 1...stageCounts.count {
            for stage in 1...stageCounts[zone - 1] {
                let file = String(format: "campaign%d_%02d.btl", zone, stage)
                earned += NativeCampaignSessionCore.bestRating(profile.document, file: file)
            }
        }
        return max(0, min(420, earned))
    }

    public static func normalRoundContribution(_ round: Int) -> Int {
        let round = round
        if round <= 31 { return 23_330 }
        if round > 99 { return 0 }
        let k: Int
        if round <= 45 { k = 4 }
        else if round <= 55 { k = 3 }
        else if round <= 65 { k = 2 }
        else if round <= 75 { k = 1 }
        else { k = 0 }
        let base = 111 * (100 - round)
        let factor = Float(k) * Float(0.5) + Float(1)
        return Int(Float(base) * factor)
    }

    public static func asiaRoundContribution(_ round: Int, map: String) -> Int {
        if round <= 20 { return 21_000 }
        if round > 99 { return 0 }
        let k: Int
        if mapType(map) == 1 {
            if round <= 25 { k = 4 }
            else if round <= 35 { k = 3 }
            else if round <= 45 { k = 2 }
            else if round <= 50 { k = 1 }
            else { k = 0 }
        } else {
            if round <= 30 { k = 4 }
            else if round <= 40 { k = 3 }
            else if round <= 50 { k = 2 }
            else if round <= 60 { k = 1 }
            else { k = 0 }
        }
        return 65 * k * (100 - round)
    }

    public static func yearsFromScore(_ normalized: Int, thresholds: [Int], fallback: Int) -> Int {
        for (index, threshold) in thresholds.enumerated() where normalized >= threshold { return ruleYears[index] }
        return fallback
    }

    public static func normalValue(round: Int, map: String, resources: CountryResources, profile: NativePlayerProfile, commanders: [Int: Commander]) -> NativeConquestAchievementResult {
        let resource = resourceContribution(resources)
        let hq = min(6_999, generalLevelContribution(profile: profile, commanders: commanders))
        let stage = min(2_333, campaignStageStars(profile) * 10)
        let roundScore = normalRoundContribution(round)
        let total = resource + hq + stage + roundScore
        let normalized = max(1, min(100, total * 100 / 46_660))
        let value = yearsFromScore(normalized, thresholds: normalThresholds, fallback: 0)
        return NativeConquestAchievementResult(
            kind: normalKey(map), value: value, normalized: normalized, total: total,
            components: NativeConquestScoreComponents(resource: resource, hq: hq, stage: stage, round: roundScore)
        )
    }

    public static func asiaValue(round: Int, map: String, resources: CountryResources, profile: NativePlayerProfile, commanders: [Int: Commander]) -> NativeConquestAchievementResult {
        let resource = resourceContribution(resources)
        let hq = min(17_500, generalLevelContribution(profile: profile, commanders: commanders))
        let stage = min(7_000, campaignStageStars(profile) * 17)
        let roundScore = asiaRoundContribution(round, map: map)
        let total = resource + hq + stage + roundScore
        let normalized = min(100, total / 700)
        let value = yearsFromScore(normalized, thresholds: asiaThresholds, fallback: 10)
        return NativeConquestAchievementResult(
            kind: "asia", value: value, normalized: normalized, total: total,
            components: NativeConquestScoreComponents(resource: resource, hq: hq, stage: stage, round: roundScore)
        )
    }

    public static func asiaEligible(round: Int, map: String) -> Bool {
        round <= (mapType(map) == 1 ? 55 : 65)
    }

    public static func prepareVictory(round: Int, map: String, resources: CountryResources, profile: NativePlayerProfile, commanders: [Int: Commander]) -> NativeConquestVictoryPrepared {
        let normal = normalValue(round: round, map: map, resources: resources, profile: profile, commanders: commanders)
        let eligible = asiaEligible(round: round, map: map)
        return NativeConquestVictoryPrepared(
            normal: normal,
            asiaEligible: eligible,
            asia: eligible ? asiaValue(round: round, map: map, resources: resources, profile: profile, commanders: commanders) : nil
        )
    }

    public static func storedValue(_ profile: NativePlayerProfile, key: String) -> Int {
        guard case .object(let records) = profile.document["achievementConquests"], let value = records[key] else { return 0 }
        switch value {
        case .int(let n): return max(0, min(1000, n))
        case .double(let n): return max(0, min(1000, Int(n)))
        case .object(let record):
            if case .int(let n) = record["value"] { return max(0, min(1000, n)) }
            if case .double(let n) = record["value"] { return max(0, min(1000, Int(n))) }
            return 0
        default: return 0
        }
    }

    public static func recordResult(profile: NativePlayerProfile, result: NativeConquestAchievementResult) -> NativeConquestRecordResult {
        precondition(["europe", "america", "asia"].contains(result.kind))
        let old = storedValue(profile, key: result.kind)
        let value = max(0, min(1000, result.value))
        let stored = max(old, value)
        var document = profile.document
        var records: [String: NativeJSONValue]
        if case .object(let existing) = document["achievementConquests"] { records = existing } else { records = [:] }
        if value > old { records[result.kind] = .object(["value": .int(value)]) }
        document["achievementConquests"] = .object(records)
        let recorded = NativeConquestAchievementResult(
            kind: result.kind, value: result.value, normalized: result.normalized, total: result.total,
            components: result.components, storedValue: stored
        )
        return NativeConquestRecordResult(profile: NativePlayerProfile(document: document), changed: value > old, result: recorded)
    }
}
