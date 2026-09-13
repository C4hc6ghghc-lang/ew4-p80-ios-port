import Foundation

/// Sidecar state that belongs to a live battle but is intentionally kept outside
/// the low-level movement/combat state. This mirrors the fields P39 BattleSave
/// persists so the renderer/app can round-trip a battle without inventing a
/// second native-only save format.
public struct NativeBattlePersistenceContext: Equatable, Sendable {
    public var resources: CountryResources
    public var countryResources: [Int: CountryResources]
    public var ownership: [Int]
    public var assignments: [Int: Int]
    public var installations: [[String: NativeJSONValue]]
    public var fireCells: Set<String>
    public var nativeFiredEvents: Set<String>
    public var nativeAppliedEvents: Set<String>
    public var itemStores: NativeJSONValue?
    public var taverns: NativeJSONValue?
    public var collectMedal: Int
    public var campaignTech: [Int]?
    public var campaignTechZone: Int
    public var ended: NativeJSONValue?

    public init(
        resources: CountryResources,
        countryResources: [Int: CountryResources],
        ownership: [Int] = [],
        assignments: [Int: Int] = [:],
        installations: [[String: NativeJSONValue]] = [],
        fireCells: Set<String> = [],
        nativeFiredEvents: Set<String> = [],
        nativeAppliedEvents: Set<String> = [],
        itemStores: NativeJSONValue? = nil,
        taverns: NativeJSONValue? = nil,
        collectMedal: Int = 0,
        campaignTech: [Int]? = nil,
        campaignTechZone: Int = 0,
        ended: NativeJSONValue? = nil
    ) {
        self.resources = resources
        self.countryResources = countryResources
        self.ownership = ownership
        self.assignments = assignments
        self.installations = installations
        self.fireCells = fireCells
        self.nativeFiredEvents = nativeFiredEvents
        self.nativeAppliedEvents = nativeAppliedEvents
        self.itemStores = itemStores
        self.taverns = taverns
        self.collectMedal = collectMedal
        self.campaignTech = campaignTech
        self.campaignTechZone = campaignTechZone
        self.ended = ended
    }

    public static func fresh(gameplay: NativeBattleGameplayState) -> NativeBattlePersistenceContext {
        let ledgers = CountryTurnCore.buildLedgers(
            gameplay.battle,
            mode: gameplay.mode,
            playerOwner: gameplay.playerOwner
        )
        let resources = ledgers[gameplay.playerOwner] ?? CountryTurnCore.headerResources(gameplay.battle)
        let assignmentPairs: [(Int, Int)] = gameplay.unitOrder.compactMap { index in
            guard let commanderID = gameplay.units[index]?.commanderID else { return nil }
            return (index, commanderID)
        }
        let assignments = Dictionary(uniqueKeysWithValues: assignmentPairs)
        return NativeBattlePersistenceContext(
            resources: resources,
            countryResources: ledgers,
            ownership: gameplay.battle.ownership ?? [],
            assignments: assignments
        )
    }

    public static func restored(_ runtime: NativeRestoredBattleRuntime) -> NativeBattlePersistenceContext {
        NativeBattlePersistenceContext(
            resources: runtime.resources,
            countryResources: runtime.countryResources,
            ownership: runtime.ownership,
            assignments: runtime.assignments,
            installations: runtime.installations,
            fireCells: runtime.fireCells,
            nativeFiredEvents: runtime.nativeFiredEvents,
            nativeAppliedEvents: runtime.nativeAppliedEvents,
            itemStores: runtime.itemStores,
            taverns: runtime.taverns,
            collectMedal: runtime.collectMedal,
            campaignTech: runtime.campaignTech,
            campaignTechZone: runtime.campaignTechZone,
            ended: runtime.ended
        )
    }
}

public enum NativeBattleSnapshotCore {
    public static func makePayload(
        gameplay: NativeBattleGameplayState,
        worldName: String,
        camera: NativeCameraState,
        context: NativeBattlePersistenceContext,
        savedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) throws -> NativeBattleSavePayload {
        let state = NativeBattleSaveState(
            battleFile: gameplay.battle.file,
            battleTitle: gameplay.battle.titleCN,
            map: worldName,
            mode: gameplay.mode.rawValue,
            playerOwner: gameplay.playerOwner,
            round: gameplay.round,
            resources: context.countryResources[gameplay.playerOwner] ?? context.resources,
            countryResources: Dictionary(uniqueKeysWithValues: context.countryResources.map { (String($0.key), $0.value) }),
            camera: NativeSaveCamera(x: camera.x, y: camera.y, zoom: camera.zoom),
            cameraGeometry: NativeHexGeometry.geometryID,
            units: gameplay.unitOrder.compactMap { gameplay.units[$0] }.map(unitRecord),
            objects: gameplay.objects.values.sorted { $0.index < $1.index }.map(objectRecord),
            ownership: context.ownership,
            assignments: context.assignments.keys.sorted().compactMap { index in
                context.assignments[index].map { [index, $0] }
            },
            installations: context.installations,
            fireCells: context.fireCells.sorted(),
            nativeFiredEvents: context.nativeFiredEvents.sorted(),
            nativeAppliedEvents: context.nativeAppliedEvents.sorted(),
            itemStores: context.itemStores,
            taverns: context.taverns,
            collectMedal: context.collectMedal,
            campaignTech: context.campaignTech,
            campaignTechZone: context.campaignTechZone,
            ended: context.ended
        )
        return try NativeBattleSaveCore.makePayload(from: state, savedAt: savedAt)
    }

    private static func unitRecord(_ unit: NativeBattleUnitState) -> [String: NativeJSONValue] {
        var out: [String: NativeJSONValue] = [
            "index": .int(unit.index),
            "q": .int(unit.q),
            "r": .int(unit.r),
            "army_id": .int(unit.armyID),
            "army_name": .string(unit.armyName),
            "grade": .int(unit.grade),
            "hp": .int(unit.hp),
            "max_hp": .int(unit.maxHP),
            "owner": .int(unit.owner),
            "dead": .bool(unit.dead),
            "moved": .bool(unit.moved),
            "attacked": .bool(unit.attacked),
            "embarked": .bool(unit.embarked),
            "trainingLevel": .int(unit.trainingLevel),
            "trainingExp": .int(unit.trainingExp),
            "underConstruction": .bool(unit.underConstruction),
            "constructionRoundsRemaining": .int(unit.constructionRoundsRemaining),
            "constructionTotalRounds": .int(unit.constructionTotalRounds),
            "playerCommanderHpBonus": .int(unit.playerCommanderHPBonus),
            "nativeMoraleBase": .int(unit.nativeMoraleBase),
            "nativeMoraleUntilRound": .int(unit.nativeMoraleUntilRound)
        ]
        out["commander_id"] = unit.commanderID.map(NativeJSONValue.int) ?? .null
        return out
    }

    private static func objectRecord(_ object: NativeBattleObjectState) -> [String: NativeJSONValue] {
        var out: [String: NativeJSONValue] = [
            "index": .int(object.index),
            "q": .int(object.q),
            "r": .int(object.r),
            "construction_id": .int(object.constructionID),
            "level": .int(object.level),
            "extra": .int(object.extra),
            "owner": .int(object.owner)
        ]
        out["construction_type"] = object.constructionType.map(NativeJSONValue.string) ?? .null
        return out
    }
}
