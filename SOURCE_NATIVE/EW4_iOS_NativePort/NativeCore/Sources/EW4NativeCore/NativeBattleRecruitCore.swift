import Foundation

public enum NativeBattleRecruitCore {
    public static let armyIDs: [String: Int] = [
        "Militia": 0, "Line Infantry": 1, "Light Infantry": 2, "Grenadier": 3, "Guards": 4, "Machine Gun": 5,
        "Light Cavalry": 6, "Heavy Cavalry": 7, "Guards Cavalry": 8, "Armored Car": 9,
        "Light Artillery": 10, "Heavy Artillery": 11, "Siege Artillery": 12, "Rocket": 13,
        "Privateer": 14, "Frigate": 15, "Battleship": 16, "Ironclad": 17,
        "Small Fortress": 18, "Fortress": 19, "Large Fortress": 20, "Coastal Fort": 21
    ]

    public static func armyID(_ name: String) -> Int? { armyIDs[name] }

    public static func technologyID(_ name: String) -> Int? { armyIDs[name] }

    /// Original recruitment parity: campaign tech value is also the initial training level.
    /// A negative value means the troop/fort is not unlocked. Missing tech data is treated as
    /// level 0 so tutorial/recovered legacy battles remain playable instead of hiding every card.
    public static func initialTrainingLevel(name: String, mode: BattleMode, campaignTech: [Int]?) -> Int? {
        guard mode == .campaign else { return 0 }
        guard let tech = campaignTech, let id = technologyID(name), tech.indices.contains(id) else { return 0 }
        let value = tech[id]
        guard value >= 0 else { return nil }
        return max(0, min(3, value))
    }

    public static func nextUnitIndex(existing: [Int]) -> Int {
        max(100_000 + existing.count, (existing.max() ?? 99_999) + 1)
    }
}
