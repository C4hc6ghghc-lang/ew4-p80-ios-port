import Foundation

public enum NativeConquestBattleEndKind: String, Equatable, Sendable { case victory, defeat }

public struct NativeConquestBattleEndDecision: Equatable, Sendable {
    public let kind: NativeConquestBattleEndKind
    public let reason: String
    public let defeatedOwners: [Int]
}

public enum NativeConquestContinueRoute: Equatable, Sendable {
    case challenge(NativeConquestVictoryPrepared)
    case summary(NativeConquestAchievementResult)
}

public struct NativeConquestContinueCommit: Equatable, Sendable {
    public let profile: NativePlayerProfile
    public let route: NativeConquestContinueRoute
}

public enum NativeConquestBattleFlowCore {
    public static func outcome(gameplay: NativeBattleGameplayState) -> NativeConquestBattleEndDecision? {
        guard gameplay.mode == .conquest, !gameplay.ended,
              let outcome = NativeConquestExtinctionCore.outcome(gameplay) else { return nil }
        switch outcome {
        case .victory(let reason, let owners):
            return NativeConquestBattleEndDecision(kind: .victory, reason: reason, defeatedOwners: owners.sorted())
        case .defeat(let reason, let owner, _):
            return NativeConquestBattleEndDecision(kind: .defeat, reason: reason, defeatedOwners: [owner])
        }
    }

    public static func prepareVictory(
        gameplay: NativeBattleGameplayState,
        map: String,
        resources: CountryResources,
        profile: NativePlayerProfile,
        commanders: [Int: Commander]
    ) -> NativeConquestVictoryPrepared {
        NativeConquestAchievementCore.prepareVictory(
            round: gameplay.round,
            map: map,
            resources: resources,
            profile: profile,
            commanders: commanders
        )
    }

    public static func continueAfterVictory(
        profile: NativePlayerProfile,
        prepared: NativeConquestVictoryPrepared
    ) -> NativeConquestContinueCommit {
        if prepared.asiaEligible {
            return NativeConquestContinueCommit(profile: profile, route: .challenge(prepared))
        }
        let recorded = NativeConquestAchievementCore.recordResult(profile: profile, result: prepared.normal)
        return NativeConquestContinueCommit(profile: recorded.profile, route: .summary(recorded.result))
    }

    public static func resolveChallenge(
        profile: NativePlayerProfile,
        prepared: NativeConquestVictoryPrepared,
        chooseAsia: Bool
    ) -> NativeConquestContinueCommit {
        let candidate = chooseAsia ? prepared.asia : prepared.normal
        guard let candidate else {
            let recorded = NativeConquestAchievementCore.recordResult(profile: profile, result: prepared.normal)
            return NativeConquestContinueCommit(profile: recorded.profile, route: .summary(recorded.result))
        }
        let recorded = NativeConquestAchievementCore.recordResult(profile: profile, result: candidate)
        return NativeConquestContinueCommit(profile: recorded.profile, route: .summary(recorded.result))
    }
}
