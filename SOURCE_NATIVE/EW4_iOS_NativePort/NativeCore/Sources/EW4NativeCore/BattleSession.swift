import Foundation

public struct NativeBattleSession: Sendable {
    public let battle: BattleRecord
    public let worldName: String
    public let world: WorldDefinition
    public var units: [BattleUnit]
    public var objects: [BattleObject]

    public init(battle: BattleRecord, worldName: String, world: WorldDefinition) {
        self.battle = battle
        self.worldName = worldName
        self.world = world
        self.units = battle.units
        self.objects = battle.objects
    }

    public func countryCode(owner: Int) -> String {
        battle.countries.first(where: { $0.index == owner })?.code ?? "fra"
    }
}

public enum NativeUnitVisualResolver {
    private static let ungraded: Set<String> = [
        "Privateer", "Frigate", "Battleship", "Ironclad",
        "Small Fortress", "Fortress", "Large Fortress", "Coastal Fort"
    ]

    public static func animationUnitName(armyName: String, grade rawGrade: Int, countryCode: String, manifest: NativeAnimationManifest) -> String? {
        if ungraded.contains(armyName) {
            return manifest.units[armyName] == nil ? nil : armyName
        }
        let grade = max(1, rawGrade + 1)
        let national = "\(armyName) \(countryCode) \(grade)"
        if manifest.units[national] != nil { return national }
        let generic = "\(armyName) \(grade)"
        return manifest.units[generic] == nil ? nil : generic
    }

    public static func animationUnitName(unit: BattleUnit, countryCode: String, manifest: NativeAnimationManifest) -> String? {
        animationUnitName(armyName: unit.armyName, grade: unit.grade, countryCode: countryCode, manifest: manifest)
    }

    public static func animationUnitName(unit: NativeBattleUnitState, countryCode: String, manifest: NativeAnimationManifest) -> String? {
        animationUnitName(armyName: unit.armyName, grade: unit.grade, countryCode: countryCode, manifest: manifest)
    }

    public static func readyMotion(
        for unitName: String,
        direction: String? = nil,
        manifest: NativeAnimationManifest
    ) -> NativeMotionRef? {
        guard let unit = manifest.units[unitName] else { return nil }
        if let direction {
            if let exact = NativeAnimationSequenceCore.pickMotion(
                unit: unit,
                type: "ready",
                index: 0,
                direction: direction
            ) {
                return exact
            }
        }
        return unit.motions.first(where: { $0.type == "ready" && $0.index == 0 })
    }
}

public enum NativeBattleLoader {
    public static func session(file: String, battles: BattlesRuntimeFile, worlds: WorldMapsFile) throws -> NativeBattleSession {
        guard let battle = battles.battles.first(where: { $0.file == file }) else {
            throw CocoaError(.fileNoSuchFile)
        }
        let worldName = battle.header.mapID == 2 ? "america" : "europe"
        guard let world = worlds.worlds[worldName] else { throw CocoaError(.fileReadCorruptFile) }
        return NativeBattleSession(battle: battle, worldName: worldName, world: world)
    }
}
