import Foundation

public enum NativeCampaignBattleEndKind: String, Equatable, Sendable {
    case victory
    case defeat
}

public enum NativeCampaignBattleEndReason: String, Equatable, Sendable {
    case objective
    case annihilated
    case turnLimit
}

public struct NativeCampaignBattleEndDecision: Equatable, Sendable {
    public let kind: NativeCampaignBattleEndKind
    public let reason: NativeCampaignBattleEndReason
}

public struct NativeCampaignVictoryCommit: Equatable, Sendable {
    public let profile: NativePlayerProfile
    public let canonicalFile: String
    public let previousBestScore: Int
    public let result: NativeVictoryResult
    public let unlockedSecretFiles: [String]
}

public enum NativeCampaignContinueRoute: Equatable, Sendable {
    case campaignList(zone: Int, preferContinueBattle: Bool)
    case zoneComplete(zone: Int, reward: NativeCampaignCompletionReward, firstTime: Bool)
}

public struct NativeCampaignContinueCommit: Equatable, Sendable {
    public let profile: NativePlayerProfile
    public let route: NativeCampaignContinueRoute
}

/// Native coordinator for the already-mature P39 campaign outer-flow rules.
/// This does not author campaign content. It consumes pristine BTL target contracts,
/// live gameplay state, NativeResultCore and NativeCampaignSessionCore.
public enum NativeCampaignBattleFlowCore {
    public static func outcome(
        gameplay: NativeBattleGameplayState,
        manifest: NativeCampaignTargetManifestFile,
        initial: NativeCampaignInitialTargetSnapshot
    ) -> NativeCampaignBattleEndDecision? {
        guard gameplay.mode == .campaign, !gameplay.ended else { return nil }
        let playerAlive = gameplay.units.values.contains { !$0.dead && $0.owner == gameplay.playerOwner }
        let hostileAlive = gameplay.units.values.contains {
            !$0.dead && gameplay.relation(gameplay.playerOwner, $0.owner) == .hostile
        }
        if let objective = NativeCampaignCore.mainObjectiveOutcome(
            gameplay: gameplay,
            manifest: manifest,
            initial: initial,
            playerAlive: playerAlive,
            hostileAlive: hostileAlive
        ) {
            switch objective {
            case .victory(let reason):
                return NativeCampaignBattleEndDecision(
                    kind: .victory,
                    reason: reason == "annihilated" ? .annihilated : .objective
                )
            case .defeat(let reason):
                return NativeCampaignBattleEndDecision(
                    kind: .defeat,
                    reason: reason == "annihilated" ? .annihilated : .objective
                )
            }
        }
        let limits = NativeResultCore.stageTurnLimits(gameplay.battle)
        if limits.valid && gameplay.round > limits.win {
            return NativeCampaignBattleEndDecision(kind: .defeat, reason: .turnLimit)
        }
        return nil
    }

    public static func commitVictory(
        profile: NativePlayerProfile,
        gameplay: NativeBattleGameplayState,
        manifest: NativeCampaignTargetManifestFile,
        battles: [BattleRecord]
    ) -> NativeCampaignVictoryCommit {
        let battle = gameplay.battle
        let canonical = NativeCampaignCore.canonicalFile(battle)
        let previous = NativeCampaignSessionCore.bestRating(profile.document, file: canonical)
        let result = NativeResultCore.result(round: gameplay.round, battle: battle, previousBestScore: previous)
        let recorded = NativeCampaignSessionCore.recordResult(profile.document, file: canonical, rating: result.score)
        var document = recorded.document

        var unlocked: [String] = []
        if NativeCampaignCore.yellowSecretCleared(gameplay: gameplay, manifest: manifest),
           let number = NativeCampaignCore.stageNumber(canonical) {
            let rows = NativeCampaignCore.rows(zone: number.zone, battles: battles)
            let playerCode = battle.countries.first(where: { $0.index == gameplay.playerOwner })?.code ?? ""
            let candidates = NativeCampaignCore.hiddenUnlockFiles(
                rows: rows,
                currentBattle: battle,
                playerCode: playerCode,
                yellowCleared: true
            )
            var secret: [String: NativeJSONValue]
            if case .object(let existing) = document["campaignSecretUnlocks"] { secret = existing }
            else { secret = [:] }
            for file in candidates where !file.isEmpty {
                let already: Bool
                if case .bool(let value) = secret[file] { already = value }
                else { already = false }
                if !already {
                    secret[file] = .bool(true)
                    unlocked.append(file)
                }
            }
            document["campaignSecretUnlocks"] = .object(secret)
        }

        return NativeCampaignVictoryCommit(
            profile: NativePlayerProfile(document: document),
            canonicalFile: canonical,
            previousBestScore: previous,
            result: result,
            unlockedSecretFiles: unlocked.sorted()
        )
    }

    public static func continueAfterVictory(
        profile: NativePlayerProfile,
        battle: BattleRecord,
        battles: [BattleRecord]
    ) -> NativeCampaignContinueCommit {
        guard let number = NativeCampaignCore.stageNumber(NativeCampaignCore.canonicalFile(battle)) else {
            return NativeCampaignContinueCommit(
                profile: profile,
                route: .campaignList(zone: 1, preferContinueBattle: false)
            )
        }
        let rows = NativeCampaignCore.rows(zone: number.zone, battles: battles)
        let resultRows = rows.map {
            NativeCampaignRow(file: NativeCampaignCore.canonicalFile($0), hidden: NativeCampaignCore.originalHide($0))
        }
        let decision = NativeResultCore.campaignContinueDecision(
            rows: resultRows,
            currentFile: NativeCampaignCore.canonicalFile(battle)
        )
        guard decision.complete else {
            return NativeCampaignContinueCommit(
                profile: profile,
                route: .campaignList(zone: number.zone, preferContinueBattle: decision.continueBattle > 0)
            )
        }

        let already = NativeCampaignSessionCore.zoneCompleted(profile.document, zone: number.zone)
        let reward = NativeResultCore.campaignCompletionReward(zone: number.zone, alreadyCompleted: already)
        let recorded = NativeCampaignSessionCore.recordZoneCompletion(profile.document, zone: number.zone, reward: reward)
        return NativeCampaignContinueCommit(
            profile: NativePlayerProfile(document: recorded.document),
            route: .zoneComplete(zone: number.zone, reward: reward, firstTime: recorded.applied)
        )
    }
}
