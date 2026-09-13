import Foundation

public struct NativeStageTurnLimits: Equatable, Sendable {
    public let valid: Bool
    public let win: Int
    public let best: Int

    public init(valid: Bool, win: Int, best: Int) {
        self.valid = valid
        self.win = win
        self.best = best
    }
}

public struct NativeVictoryResult: Equatable, Sendable {
    public let limits: NativeStageTurnLimits
    public let score: Int
    public let grade: Int
    public let awardMedal: Int
    public let cumulativeMedal: Int
    public let descriptionKey: String
}

public struct NativeCampaignRow: Equatable, Sendable {
    public let file: String
    public let hidden: Bool

    public init(file: String, hidden: Bool = false) {
        self.file = file
        self.hidden = hidden
    }
}

public struct NativeCampaignContinueDecision: Equatable, Sendable {
    public let valid: Bool
    public let complete: Bool
    public let continueBattle: Int
    public let index: Int
    public let lastVisible: Int
}

public struct NativeCampaignCompletionReward: Equatable, Sendable {
    public let zone: Int
    public let medal: Int
    public let badge: Int
    public let score: Int
    public let image: String
    public let firstTime: Bool
}

public enum NativeResultCore {
    public static let medalTable = [0, 0, 5, 15, 25, 50]
    public static let campaignCompleteRewards = [
        [0, 1, 1], [50, 0, 1], [50, 0, 1],
        [0, 1, 1], [50, 0, 1], [0, 1, 1]
    ]
    public static let campaignCompleteImages = [
        "campaignend_fr.png", "campaignend_coalitiont.png", "campaignend_holyroma.png",
        "campaignend_east.png", "campaignend_us.png", "campaignend_gb.png"
    ]

    public static func stageTurnLimits(_ battle: BattleRecord) -> NativeStageTurnLimits {
        let raw = battle.header.raw ?? []
        let win = raw.indices.contains(12) ? Int(raw[12]) : 0
        let best = raw.indices.contains(13) ? Int(raw[13]) : 0
        let valid = win > 0 && best > 0 && win >= best
        return valid
            ? NativeStageTurnLimits(valid: true, win: win, best: best)
            : NativeStageTurnLimits(valid: false, win: 0, best: 0)
    }

    // Recovered native C++ formula: score 5 is best; visible grade is 6-score.
    public static func victoryScore(round: Int, limits: NativeStageTurnLimits) -> Int {
        let turn = max(0, round)
        guard limits.valid, turn > 0 else { return 0 }
        if turn <= limits.best { return 5 }
        if turn >= limits.win { return 1 }
        let span = limits.win - limits.best
        if span <= 0 { return 5 }
        return max(2, ((limits.win - turn) * 4) / span + 1)
    }

    public static func victoryScore(round: Int, battle: BattleRecord) -> Int {
        victoryScore(round: round, limits: stageTurnLimits(battle))
    }

    public static func victoryGrade(round: Int, battle: BattleRecord) -> Int {
        let score = victoryScore(round: round, battle: battle)
        return score == 0 ? 0 : 6 - score
    }

    public static func cumulativeMedal(forScore score: Int) -> Int {
        let clamped = max(0, min(5, score))
        return medalTable[clamped]
    }

    public static func medalGain(score: Int, previousBestScore: Int = 0) -> Int {
        max(0, cumulativeMedal(forScore: score) - cumulativeMedal(forScore: previousBestScore))
    }

    public static func descriptionKey(score: Int, awardMedal: Int = 0) -> String {
        let clamped = max(1, min(5, score))
        let grade = 6 - clamped
        return grade == 5 || awardMedal > 0
            ? "desc_victory \(grade)"
            : "desc_victory \(grade) no award"
    }

    public static func result(round: Int, battle: BattleRecord, previousBestScore: Int = 0) -> NativeVictoryResult {
        let limits = stageTurnLimits(battle)
        let score = victoryScore(round: round, limits: limits)
        let grade = score == 0 ? 0 : 6 - score
        let award = medalGain(score: score, previousBestScore: previousBestScore)
        return NativeVictoryResult(
            limits: limits,
            score: score,
            grade: grade,
            awardMedal: award,
            cumulativeMedal: cumulativeMedal(forScore: score),
            descriptionKey: score == 0 ? "" : descriptionKey(score: score, awardMedal: award)
        )
    }

    public static func participatingGeneralIDs(
        units: [NativeBattleUnitState],
        playerOwner: Int,
        slots: Int = 6
    ) -> [Int] {
        guard slots > 0 else { return [] }
        var seen = Set<Int>()
        var result: [Int] = []
        for unit in units where unit.owner == playerOwner {
            guard let id = unit.commanderID, id > 0, !seen.contains(id) else { continue }
            seen.insert(id)
            result.append(id)
            if result.count >= slots { break }
        }
        return result
    }

    public static func campaignContinueDecision(
        rows: [NativeCampaignRow],
        currentFile: String
    ) -> NativeCampaignContinueDecision {
        guard let index = rows.firstIndex(where: { $0.file == currentFile }) else {
            let lastVisible = rows.lastIndex(where: { !$0.hidden }) ?? -1
            return NativeCampaignContinueDecision(valid: false, complete: false, continueBattle: 0, index: -1, lastVisible: lastVisible)
        }
        let lastVisible = rows.lastIndex(where: { !$0.hidden }) ?? -1
        if index == lastVisible {
            return NativeCampaignContinueDecision(valid: true, complete: true, continueBattle: 0, index: index, lastVisible: lastVisible)
        }
        return NativeCampaignContinueDecision(
            valid: true,
            complete: false,
            continueBattle: index == rows.count - 1 ? 0 : 1,
            index: index,
            lastVisible: lastVisible
        )
    }

    public static func campaignCompletionReward(zone: Int, alreadyCompleted: Bool = false) -> NativeCampaignCompletionReward {
        let index = max(0, min(5, zone - 1))
        let base = campaignCompleteRewards[index]
        return NativeCampaignCompletionReward(
            zone: index + 1,
            medal: alreadyCompleted ? 0 : base[0],
            badge: alreadyCompleted ? 0 : base[1],
            score: alreadyCompleted ? 0 : base[2],
            image: campaignCompleteImages[index],
            firstTime: !alreadyCompleted
        )
    }

    public static func collectMedalAdjustedRoll(_ roll: Int, nativeType: Int = 255, nativeLevel: Int = 0) -> Int {
        var adjusted = max(0, min(99, roll))
        let level = max(0, nativeLevel)
        if nativeType == 0 || nativeType == 3 {
            adjusted += 2 * level
        } else if nativeType == 1 {
            adjusted += 3 * level
        }
        return adjusted
    }

    public static func collectMedalProc(
        damage: Int,
        roll: Int,
        nativeType: Int = 255,
        nativeLevel: Int = 0
    ) -> Bool {
        let adjusted = collectMedalAdjustedRoll(roll, nativeType: nativeType, nativeLevel: nativeLevel)
        switch damage {
        case 20...24: return adjusted > 95
        case 25...29: return adjusted > 91
        case 30...34: return adjusted > 87
        case 35...: return adjusted > 82
        default: return false
        }
    }
}
