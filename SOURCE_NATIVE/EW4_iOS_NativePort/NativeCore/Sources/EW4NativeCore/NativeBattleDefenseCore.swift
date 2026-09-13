import Foundation

public struct NativeDefenseChoice: Equatable, Sendable {
    public let key: String
    public let type: String
    public let money: Int
    public let industry: Int
    public let armyName: String?
    public let grade: Int
    public let buildRounds: Int
    public let image: String?
    public let intro: String?
}

public enum NativeBattleDefenseCore {
    public static let installationKeys = ["Trench", "Fence", "Bunker"]
    public static let fortressKeys = ["Small Fortress", "Fortress", "Large Fortress"]

    public static func installationChoices(cards: NativeBuildCardCatalog) -> [NativeDefenseChoice] {
        installationKeys.compactMap { choice(key: $0, cards: cards) }
    }

    public static func fortressChoices(cards: NativeBuildCardCatalog, coastal: Bool) -> [NativeDefenseChoice] {
        let keys = fortressKeys + (coastal ? ["Coastal Fort"] : [])
        return keys.compactMap { choice(key: $0, cards: cards) }
    }

    public static func choice(key: String, cards: NativeBuildCardCatalog) -> NativeDefenseChoice? {
        guard let card = cards[key] else { return nil }
        return NativeDefenseChoice(
            key: key,
            type: card.type,
            money: max(0, card.price), industry: max(0, card.industry),
            armyName: card.army, grade: max(0, card.grade), buildRounds: max(0, card.buildround ?? 0),
            image: card.image, intro: card.intro
        )
    }

    public static func installationType(for key: String) -> String? {
        switch key { case "Trench": return "trench"; case "Fence": return "fence"; case "Bunker": return "bunker"; default: return nil }
    }

    public static func ownershipIndex(battle: BattleRecord, cell: HexCell) -> Int? {
        let x = cell.q - battle.header.originX
        let y = cell.r - battle.header.originY
        guard x >= 0, y >= 0, x < battle.header.width, y < battle.header.height else { return nil }
        let index = y * battle.header.width + x - (battle.ownerIndexBias ?? 0)
        return index >= 0 ? index : nil
    }

    public static func owner(battle: BattleRecord, ownership: [Int], cell: HexCell) -> Int? {
        guard let index = ownershipIndex(battle: battle, cell: cell), ownership.indices.contains(index) else { return nil }
        return ownership[index]
    }
}
