import Foundation

public struct NativeCampaignRecordResult: Equatable, Sendable {
    public let document: [String: NativeJSONValue]
    public let changed: Bool
    public let delta: Int
    public let oldBest: Int
    public let next: Int
}

public struct NativeCampaignZoneCompletionResult: Equatable, Sendable {
    public let document: [String: NativeJSONValue]
    public let applied: Bool
}

/// Swift parity for mature P39 `native_campaign_session_core.js`.
/// It mutates only campaign-meta fields and preserves every unknown profile field.
public enum NativeCampaignSessionCore {
    public static let maxStars = 999

    public static func progressLevel(_ document: [String: NativeJSONValue], file: String) -> Int {
        guard !file.isEmpty,
              case .object(let progress) = document["campaignProgress"],
              let value = progress[file] else { return 0 }
        return max(0, int(value))
    }

    public static func bestRating(_ document: [String: NativeJSONValue], file: String) -> Int {
        guard !file.isEmpty else { return 0 }
        if case .object(let best) = document["campaignBestRating"], let value = best[file] {
            let rating = clampScore(int(value))
            if rating > 0 { return rating }
        }
        let legacy = progressLevel(document, file: file)
        return legacy >= 2 ? 5 : (legacy >= 1 ? 1 : 0)
    }

    public static func legacyStarTotal(_ raw: [String: NativeJSONValue]) -> Int {
        let best = object(raw["campaignBestRating"])
        let progress = object(raw["campaignProgress"])
        var keys = Set(best.keys)
        keys.formUnion(progress.keys)
        let total = keys.reduce(into: 0) { sum, file in
            var rating = clampScore(int(best[file]))
            if rating == 0 {
                let legacy = max(0, int(progress[file]))
                rating = legacy >= 2 ? 5 : (legacy >= 1 ? 1 : 0)
            }
            sum += rating
        }
        return clampStars(total)
    }

    /// `source` must be the raw persisted object. This preserves P39's distinction
    /// between a legacy save with no Stars field and a modern save whose Stars is 0.
    public static func normalizeDocument(
        state: [String: NativeJSONValue],
        source: [String: NativeJSONValue]? = nil
    ) -> [String: NativeJSONValue] {
        let src = source ?? state
        var out = state
        out["campaignProgress"] = .object(object(out["campaignProgress"]))
        out["campaignBestRating"] = .object(object(out["campaignBestRating"]))
        out["campaignSecretUnlocks"] = .object(object(out["campaignSecretUnlocks"]))
        out["campaignCompletedZones"] = .object(object(out["campaignCompletedZones"]))

        let earned = object(out["campaignCompletionEarned"])
        out["campaignCompletionEarned"] = .object([
            "medals": .int(max(0, int(earned["medals"]))),
            "badges": .int(max(0, int(earned["badges"]))),
            "score": .int(max(0, int(earned["score"])))
        ])

        if src.keys.contains("campaignStars") {
            out["campaignStars"] = .int(clampStars(int(out["campaignStars"])))
        } else {
            out["campaignStars"] = .int(legacyStarTotal(src))
        }

        if src.keys.contains("warzoneTech"), case .object = out["warzoneTech"] {
            // Preserve the authoritative persisted object byte-semantically at JSON level.
        } else {
            out["warzoneTech"] = .null
        }
        return out
    }

    public static func recordResult(
        _ document: [String: NativeJSONValue],
        file: String,
        rating: Int
    ) -> NativeCampaignRecordResult {
        guard !file.isEmpty else {
            return NativeCampaignRecordResult(document: document, changed: false, delta: 0, oldBest: 0, next: 0)
        }
        let oldBest = bestRating(document, file: file)
        let clamped = clampScore(rating)
        let next = max(1, clamped == 0 ? 1 : clamped)
        let delta = max(0, next - oldBest)

        var out = document
        var progress = object(document["campaignProgress"])
        var best = object(document["campaignBestRating"])
        progress[file] = .int(max(1, progressLevel(document, file: file)))
        if next > oldBest { best[file] = .int(next) }
        out["campaignProgress"] = .object(progress)
        out["campaignBestRating"] = .object(best)
        out["campaignStars"] = .int(clampStars(int(document["campaignStars"]) + delta))
        return NativeCampaignRecordResult(
            document: out,
            changed: next > oldBest || progressLevel(document, file: file) < 1,
            delta: delta,
            oldBest: oldBest,
            next: next
        )
    }

    public static func zoneCompleted(_ document: [String: NativeJSONValue], zone: Int) -> Bool {
        let key = String(max(1, min(6, zone)))
        guard case .object(let zones) = document["campaignCompletedZones"], let value = zones[key] else { return false }
        return truthy(value)
    }

    public static func recordZoneCompletion(
        _ document: [String: NativeJSONValue],
        zone: Int,
        reward: NativeCampaignCompletionReward
    ) -> NativeCampaignZoneCompletionResult {
        let z = max(1, min(6, zone))
        guard !zoneCompleted(document, zone: z) else {
            return NativeCampaignZoneCompletionResult(document: document, applied: false)
        }
        var out = document
        var zones = object(document["campaignCompletedZones"])
        zones[String(z)] = .bool(true)
        out["campaignCompletedZones"] = .object(zones)

        let earned = object(document["campaignCompletionEarned"])
        out["campaignCompletionEarned"] = .object([
            "medals": .int(max(0, int(earned["medals"])) + max(0, reward.medal)),
            "badges": .int(max(0, int(earned["badges"])) + max(0, reward.badge)),
            "score": .int(max(0, int(earned["score"])) + max(0, reward.score))
        ])
        return NativeCampaignZoneCompletionResult(document: out, applied: true)
    }

    public static func storageRoundTrip(
        _ document: [String: NativeJSONValue],
        source: [String: NativeJSONValue]? = nil
    ) throws -> [String: NativeJSONValue] {
        let data = try JSONEncoder().encode(document)
        let decoded = try JSONDecoder().decode([String: NativeJSONValue].self, from: data)
        return normalizeDocument(state: decoded, source: source ?? document)
    }

    private static func object(_ value: NativeJSONValue?) -> [String: NativeJSONValue] {
        if case .object(let object) = value { return object }
        return [:]
    }

    private static func int(_ value: NativeJSONValue?) -> Int {
        guard let value else { return 0 }
        switch value {
        case .int(let x): return x
        case .double(let x): return Int(x)
        case .string(let x): return Int(x) ?? 0
        case .bool(let x): return x ? 1 : 0
        default: return 0
        }
    }

    private static func clampScore(_ value: Int) -> Int { max(0, min(5, value)) }
    public static func clampStars(_ value: Int) -> Int { max(0, min(maxStars, value)) }

    private static func truthy(_ value: NativeJSONValue) -> Bool {
        switch value {
        case .bool(let x): return x
        case .int(let x): return x != 0
        case .double(let x): return x != 0
        case .string(let x): return !x.isEmpty && x != "0"
        case .null: return false
        case .array(let x): return !x.isEmpty
        case .object: return true
        }
    }
}
