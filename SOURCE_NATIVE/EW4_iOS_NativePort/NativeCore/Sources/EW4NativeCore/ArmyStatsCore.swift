import Foundation

public enum ArmyStatsCore {
    public static let preferredCountryOrder = [
        "fra", "gbr", "rus", "pru", "aus", "tur", "spa", "usa", "others", "nap"
    ]

    public static let seaArmyNames: Set<String> = [
        "Privateer", "Frigate", "Battleship", "Ironclad"
    ]

    public static let fortArmyNames: Set<String> = [
        "Small Fortress", "Fortress", "Large Fortress", "Coastal Fort"
    ]

    public static func key(armyName: String, grade: Int) -> String {
        "\(armyName)|\(grade)"
    }

    public static func resolve(
        catalog: ArmyStatsCatalog,
        countryCode: String,
        armyName: String,
        grade: Int
    ) -> ArmyStatDefinition? {
        let statKey = key(armyName: armyName, grade: grade)
        if let value = catalog[countryCode]?[statKey] {
            return value
        }
        if let value = catalog["others"]?[statKey] {
            return value
        }
        for code in preferredCountryOrder where code != countryCode && code != "others" {
            if let value = catalog[code]?[statKey] {
                return value
            }
        }
        return catalog.keys.sorted().lazy.compactMap { catalog[$0]?[statKey] }.first
    }

    public static func isSeaUnit(armyName: String) -> Bool {
        seaArmyNames.contains(armyName)
    }

    public static func isFort(armyName: String) -> Bool {
        fortArmyNames.contains(armyName)
    }

    public static func combatStat(_ definition: ArmyStatDefinition) -> CombatStat {
        CombatStat(type: definition.type, minAttack: definition.minatk, maxAttack: definition.maxatk)
    }

    public static func combatCommander(_ commander: Commander?) -> CombatCommander? {
        guard let commander else { return nil }
        return CombatCommander(
            infantry: commander.infantry,
            cavalry: commander.cavalry,
            artillery: commander.artillery,
            warship: commander.warship,
            fort: commander.fort,
            skills: commander.skillIDs
        )
    }
}
