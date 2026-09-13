import Foundation

public struct NativeStageIntroContent: Equatable, Sendable {
    public let battleFile: String
    public let description: String
    public let commanderID: Int?
    public let commanderName: String
    public let victoryRounds: Int
    public let bestVictoryRounds: Int

    public init(battleFile: String, description: String, commanderID: Int?, commanderName: String, victoryRounds: Int, bestVictoryRounds: Int) {
        self.battleFile = battleFile
        self.description = description
        self.commanderID = commanderID
        self.commanderName = commanderName
        self.victoryRounds = victoryRounds
        self.bestVictoryRounds = bestVictoryRounds
    }
}


public struct NativeRoundTurnGeneralContent: Equatable, Sendable {
    public let commanderID: Int
    public let name: String

    public init(commanderID: Int, name: String) {
        self.commanderID = commanderID
        self.name = name
    }
}

public struct NativeRoundTurnContent: Equatable, Sendable {
    public let money: Int
    public let industry: Int
    public let foodAdd: Int
    public let foodDel: Int
    public let round: Int
    public let bestRound: Int
    public let winRound: Int
    public let generals: [NativeRoundTurnGeneralContent]

    public init(money: Int, industry: Int, foodAdd: Int, foodDel: Int, round: Int, bestRound: Int, winRound: Int, generals: [NativeRoundTurnGeneralContent]) {
        self.money = max(0, money)
        self.industry = max(0, industry)
        self.foodAdd = max(0, foodAdd)
        self.foodDel = max(0, foodDel)
        self.round = max(1, round)
        self.bestRound = max(0, bestRound)
        self.winRound = max(0, winRound)
        self.generals = Array(generals.prefix(6))
    }
}

public enum NativeOriginalFormContentCore {
    /// Exact P39 `campaignIntroCommander`: first commander belonging to the
    /// player owner, otherwise first commander anywhere in the battle.
    public static func stageIntro(battle: BattleRecord, commanders: [Int: Commander]) -> NativeStageIntroContent {
        let owner = battle.playerOwnerDefault ?? 0
        let unit = battle.units.first { $0.owner == owner && $0.commanderID != nil }
            ?? battle.units.first { $0.commanderID != nil }
        let commanderID = unit?.commanderID
        let limits = NativeResultCore.stageTurnLimits(battle)
        return NativeStageIntroContent(
            battleFile: battle.file,
            description: battle.descCN ?? "",
            commanderID: commanderID,
            commanderName: commanderID.flatMap { commanders[$0]?.name } ?? "",
            victoryRounds: limits.valid ? limits.win : 0,
            bestVictoryRounds: limits.valid ? limits.best : 0
        )
    }
    /// P39 `renderNativeRoundTurn`: show the just-completed player economy
    /// summary, the new player round, stage limits, and up to six distinct
    /// living deployed player commanders.
    public static func roundTurn(
        gameplay: NativeBattleGameplayState,
        settlement: NativePlayerRoundSettlement,
        commanders: [Int: Commander]
    ) -> NativeRoundTurnContent {
        let limits = NativeResultCore.stageTurnLimits(gameplay.battle)
        var seen = Set<Int>()
        var generalRows: [NativeRoundTurnGeneralContent] = []
        for index in gameplay.unitOrder {
            guard let unit = gameplay.units[index],
                  !unit.dead,
                  unit.owner == gameplay.playerOwner,
                  let commanderID = unit.commanderID,
                  commanderID > 0,
                  !seen.contains(commanderID) else { continue }
            seen.insert(commanderID)
            generalRows.append(NativeRoundTurnGeneralContent(
                commanderID: commanderID,
                name: commanders[commanderID]?.name ?? ""
            ))
            if generalRows.count == 6 { break }
        }
        return NativeRoundTurnContent(
            money: settlement.money, industry: settlement.industry,
            foodAdd: settlement.foodAdd, foodDel: settlement.foodDel,
            round: gameplay.round,
            bestRound: limits.valid ? limits.best : 0,
            winRound: limits.valid ? limits.win : 0,
            generals: generalRows
        )
    }

}
