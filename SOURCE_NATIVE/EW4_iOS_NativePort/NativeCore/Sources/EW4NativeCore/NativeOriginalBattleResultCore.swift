import Foundation

public enum NativeOriginalBattleResultKind: String, Equatable, Sendable {
    case victory
    case defeat
}

public enum NativeOriginalBattleResultReason: String, Equatable, Sendable {
    case combat
    case turnLimit
}

public enum NativeOriginalBattleResultAction: Equatable, Sendable {
    case continueBattle
    case restart
    case exit
}

public struct NativeOriginalBattleResultContent: Equatable, Sendable {
    public let kind: NativeOriginalBattleResultKind
    public let reason: NativeOriginalBattleResultReason
    public let battleFile: String
    public let battleName: String
    public let round: Int
    public let score: Int
    public let awardMedal: Int
    public let collectedMedal: Int
    public let limits: NativeStageTurnLimits
    public let generalIDs: [Int]
    public let playerCountryCode: String
    public let playerCountryName: String
    public let narrationKey: String

    public init(
        kind: NativeOriginalBattleResultKind,
        reason: NativeOriginalBattleResultReason,
        battleFile: String,
        battleName: String,
        round: Int,
        score: Int,
        awardMedal: Int,
        collectedMedal: Int,
        limits: NativeStageTurnLimits,
        generalIDs: [Int],
        playerCountryCode: String,
        playerCountryName: String,
        narrationKey: String
    ) {
        self.kind = kind
        self.reason = reason
        self.battleFile = battleFile
        self.battleName = battleName
        self.round = max(0, round)
        self.score = max(0, min(5, score))
        self.awardMedal = max(0, awardMedal)
        self.collectedMedal = max(0, collectedMedal)
        self.limits = limits
        self.generalIDs = Array(generalIDs.prefix(6))
        self.playerCountryCode = playerCountryCode
        self.playerCountryName = playerCountryName
        self.narrationKey = narrationKey
    }
}

public enum NativeOriginalBattleResultCore {
    public static func content(
        kind: NativeOriginalBattleResultKind,
        reason: NativeOriginalBattleResultReason = .combat,
        gameplay: NativeBattleGameplayState,
        previousBestScore: Int = 0,
        collectedMedal: Int = 0
    ) -> NativeOriginalBattleResultContent {
        let battle = gameplay.battle
        let country = battle.countries.first(where: { $0.index == gameplay.playerOwner })
        let generalIDs = NativeResultCore.participatingGeneralIDs(
            units: gameplay.unitOrder.compactMap { gameplay.units[$0] },
            playerOwner: gameplay.playerOwner,
            slots: 6
        )
        if kind == .victory, gameplay.mode == .campaign {
            let result = NativeResultCore.result(round: gameplay.round, battle: battle, previousBestScore: previousBestScore)
            return NativeOriginalBattleResultContent(
                kind: kind,
                reason: reason,
                battleFile: battle.file,
                battleName: battle.titleCN,
                round: gameplay.round,
                score: result.score,
                awardMedal: result.awardMedal,
                collectedMedal: collectedMedal,
                limits: result.limits,
                generalIDs: generalIDs,
                playerCountryCode: country?.code ?? "",
                playerCountryName: country?.nameCN ?? "",
                narrationKey: result.descriptionKey
            )
        }
        let limits = NativeResultCore.stageTurnLimits(battle)
        let narration = kind == .defeat
            ? (reason == .turnLimit ? "desc_failure 2" : "desc_failure 1")
            : ""
        return NativeOriginalBattleResultContent(
            kind: kind,
            reason: reason,
            battleFile: battle.file,
            battleName: battle.titleCN,
            round: gameplay.round,
            score: 0,
            awardMedal: 0,
            collectedMedal: collectedMedal,
            limits: limits,
            generalIDs: generalIDs,
            playerCountryCode: country?.code ?? "",
            playerCountryName: country?.nameCN ?? "",
            narrationKey: narration
        )
    }

    public static func action(kind: NativeOriginalBattleResultKind, at local: NativePoint) -> NativeOriginalBattleResultAction? {
        switch kind {
        case .victory:
            if contains(NativeOriginalFormGeometryCore.Victory.continueButton, local) { return .continueBattle }
            if contains(NativeOriginalFormGeometryCore.Victory.exitButton, local) { return .exit }
        case .defeat:
            if contains(NativeOriginalFormGeometryCore.Failure.okButton, local) { return .restart }
        }
        return nil
    }

    private static func contains(_ rect: NativeRect, _ p: NativePoint) -> Bool {
        p.x >= rect.origin.x && p.x <= rect.origin.x + rect.size.width &&
        p.y >= rect.origin.y && p.y <= rect.origin.y + rect.size.height
    }
}
