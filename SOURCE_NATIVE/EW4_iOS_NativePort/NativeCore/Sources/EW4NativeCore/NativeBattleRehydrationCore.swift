import Foundation

public enum NativeBattleRehydrationError: Error, Equatable, Sendable {
    case battleNotFound(String)
    case worldNotFound(String)
    case malformedUnit(Int)
    case malformedObject(Int)
}

public struct NativeRestoredBattleRuntime: Sendable {
    public var worldName: String
    public var gameplay: NativeBattleGameplayState
    public var resources: CountryResources
    public var countryResources: [Int: CountryResources]
    public var camera: NativeCameraState
    public var cameraGeometry: String
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
        worldName: String,
        gameplay: NativeBattleGameplayState,
        resources: CountryResources,
        countryResources: [Int: CountryResources],
        camera: NativeCameraState,
        cameraGeometry: String,
        ownership: [Int],
        assignments: [Int: Int],
        installations: [[String: NativeJSONValue]],
        fireCells: Set<String>,
        nativeFiredEvents: Set<String>,
        nativeAppliedEvents: Set<String>,
        itemStores: NativeJSONValue?,
        taverns: NativeJSONValue?,
        collectMedal: Int,
        campaignTech: [Int]?,
        campaignTechZone: Int,
        ended: NativeJSONValue?
    ) {
        self.worldName = worldName
        self.gameplay = gameplay
        self.resources = resources
        self.countryResources = countryResources
        self.camera = camera
        self.cameraGeometry = cameraGeometry
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
}

public enum NativeBattleRehydrationCore {
    public static func rehydrate(
        _ input: NativeBattleSavePayload,
        battles: BattlesRuntimeFile,
        worlds: WorldMapsFile,
        terrainTypes: [String: TerrainTypeDefinition],
        armyStats: ArmyStatsCatalog,
        commanders: [Int: Commander],
        itemEffects: NativeItemEffectCatalog = [:],
        constructions: NativeConstructionCatalog = [:],
        installationCatalog: NativeInstallationCatalog = [:],
        effectiveCommanderProvider: (@Sendable (Int, Bool) -> NativeEffectiveCommander?)? = nil,
        combatGrowthHandler: NativeCombatGrowthHandler? = nil
    ) throws -> NativeRestoredBattleRuntime {
        let payload = try NativeBattleSaveCore.normalize(input)
        guard let battle = battles.battles.first(where: { $0.file == payload.battleFile }) else {
            throw NativeBattleRehydrationError.battleNotFound(payload.battleFile)
        }
        let authoredWorldName = battle.header.mapID == 2 ? "america" : "europe"
        let worldName = worlds.worlds[payload.map] != nil ? payload.map : authoredWorldName
        guard let world = worlds.worlds[worldName] else {
            throw NativeBattleRehydrationError.worldNotFound(worldName)
        }
        let session = NativeBattleSession(battle: battle, worldName: worldName, world: world)
        let mode = BattleMode(rawValue: payload.mode) ?? .campaign
        var gameplay = NativeBattleGameplayState(
            session: session,
            terrainTypes: terrainTypes,
            armyStats: armyStats,
            commanders: commanders,
            itemEffects: itemEffects,
            constructions: constructions,
            installationCatalog: installationCatalog,
            effectiveCommanderProvider: effectiveCommanderProvider,
            combatGrowthHandler: combatGrowthHandler,
            mode: mode,
            playerOwner: payload.playerOwner
        )

        let assignments = assignmentMap(payload.assignments)
        let baseUnits = Dictionary(uniqueKeysWithValues: battle.units.map { ($0.index, $0) })
        var restoredUnits: [NativeBattleUnitState] = []
        restoredUnits.reserveCapacity(payload.units.count)
        for (ordinal, record) in payload.units.enumerated() {
            let index = int(record["index"]) ?? ordinal
            let fallback = baseUnits[index]
            guard let armyID = int(record["army_id"]) ?? fallback?.armyID,
                  let armyName = string(record["army_name"]) ?? fallback?.armyName,
                  let grade = int(record["grade"]) ?? fallback?.grade,
                  let owner = int(record["owner"]) ?? fallback?.owner,
                  let q = int(record["q"]) ?? fallback?.q,
                  let r = int(record["r"]) ?? fallback?.r,
                  let rawHP = int(record["hp"]) ?? fallback?.hp,
                  let rawMaxHP = int(record["max_hp"]) ?? fallback?.maxHP else {
                throw NativeBattleRehydrationError.malformedUnit(index)
            }
            let dead = bool(record["dead"]) ?? (rawHP <= 0)
            let hp = dead ? 0 : max(0, rawHP)
            let commander = int(record["commander_id"]) ?? assignments[index] ?? fallback?.commanderID
            restoredUnits.append(
                NativeBattleUnitState(
                    index: index,
                    armyID: armyID,
                    armyName: armyName,
                    grade: grade,
                    owner: owner,
                    commanderID: commander,
                    q: q,
                    r: r,
                    hp: hp,
                    maxHP: max(1, rawMaxHP),
                    moved: bool(record["moved"]) ?? false,
                    attacked: bool(record["attacked"]) ?? false,
                    embarked: bool(record["embarked"]) ?? false,
                    trainingLevel: int(record["trainingLevel"]) ?? fallback?.raw.flatMap { $0.indices.contains(20) ? $0[20] : nil } ?? 0,
                    trainingExp: int(record["trainingExp"]) ?? 0,
                    underConstruction: bool(record["underConstruction"]) ?? false,
                    constructionRoundsRemaining: int(record["constructionRoundsRemaining"]) ?? 0,
                    constructionTotalRounds: int(record["constructionTotalRounds"]) ?? 0,
                    playerCommanderHPBonus: int(record["playerCommanderHpBonus"]) ?? 0,
                    nativeMoraleBase: int(record["nativeMoraleBase"]) ?? 0,
                    nativeMoraleUntilRound: int(record["nativeMoraleUntilRound"]) ?? 0
                )
            )
        }

        let baseObjects = Dictionary(uniqueKeysWithValues: battle.objects.map { ($0.index, $0) })
        var restoredObjects: [NativeBattleObjectState] = []
        restoredObjects.reserveCapacity(payload.objects.count)
        for (ordinal, record) in payload.objects.enumerated() {
            let index = int(record["index"]) ?? ordinal
            let fallback = baseObjects[index]
            guard let q = int(record["q"]) ?? fallback?.q,
                  let r = int(record["r"]) ?? fallback?.r,
                  let constructionID = int(record["construction_id"]) ?? fallback?.constructionID,
                  let level = int(record["level"]) ?? fallback?.level,
                  let extra = int(record["extra"]) ?? fallback?.extra,
                  let owner = int(record["owner"]) ?? fallback?.owner else {
                throw NativeBattleRehydrationError.malformedObject(index)
            }
            restoredObjects.append(
                NativeBattleObjectState(
                    index: index,
                    q: q,
                    r: r,
                    constructionID: constructionID,
                    constructionType: string(record["construction_type"]) ?? fallback?.constructionType,
                    level: level,
                    extra: extra,
                    owner: owner
                )
            )
        }

        gameplay.restoreRuntimeState(
            round: payload.round,
            ended: isEnded(payload.ended),
            restoredUnits: restoredUnits,
            restoredObjects: restoredObjects
        )
        gameplay.setInstallations(payload.installations.compactMap { record in
            guard let q = int(record["q"]), let r = int(record["r"]),
                  let type = string(record["type"]), let owner = int(record["owner"]) else { return nil }
            return NativeBattleInstallationState(q: q, r: r, type: type, owner: owner)
        })

        let restoredLedgers: [Int: CountryResources]? = payload.countryResources.map { source in
            Dictionary(uniqueKeysWithValues: source.compactMap { key, value in
                Int(key).map { ($0, value) }
            })
        }
        var ledgers = CountryTurnCore.buildLedgers(
            battle,
            mode: mode,
            playerOwner: payload.playerOwner,
            restored: restoredLedgers
        )
        if payload.countryResources == nil {
            ledgers[payload.playerOwner] = payload.resources
        }
        let resources = ledgers[payload.playerOwner] ?? CountryTurnCore.headerResources(battle)
        let camera = restoredCamera(payload: payload, gameplay: gameplay, battle: battle)

        return NativeRestoredBattleRuntime(
            worldName: worldName,
            gameplay: gameplay,
            resources: resources,
            countryResources: ledgers,
            camera: camera,
            cameraGeometry: NativeHexGeometry.geometryID,
            ownership: payload.ownership,
            assignments: assignments,
            installations: payload.installations,
            fireCells: Set(payload.fireCells),
            nativeFiredEvents: Set(payload.nativeFiredEvents),
            nativeAppliedEvents: Set(payload.nativeAppliedEvents),
            itemStores: payload.itemStores,
            taverns: payload.taverns,
            collectMedal: max(0, payload.collectMedal ?? 0),
            campaignTech: payload.campaignTech,
            campaignTechZone: payload.campaignTechZone ?? 0,
            ended: payload.ended
        )
    }

    private static func assignmentMap(_ rows: [[Int]]) -> [Int: Int] {
        var out: [Int: Int] = [:]
        for row in rows where row.count >= 2 {
            out[row[0]] = row[1]
        }
        return out
    }

    private static func restoredCamera(
        payload: NativeBattleSavePayload,
        gameplay: NativeBattleGameplayState,
        battle: BattleRecord
    ) -> NativeCameraState {
        if payload.cameraGeometry == NativeHexGeometry.geometryID {
            return NativeCameraState(x: payload.camera.x, y: payload.camera.y, zoom: payload.camera.zoom)
        }
        let own = gameplay.unitOrder.compactMap { gameplay.units[$0] }.filter {
            !$0.dead && $0.owner == gameplay.playerOwner
        }
        let focus = own.first(where: { ($0.commanderID ?? 0) > 0 }) ?? own.first
        if let focus {
            let p = NativeHexGeometry.cellCenter(focus.cell)
            return NativeCameraState(x: p.x, y: p.y, zoom: payload.camera.zoom)
        }
        let origin = NativeHexGeometry.battlePixelOrigin(
            originX: battle.header.originX,
            originY: battle.header.originY
        )
        return NativeCameraState(
            x: origin.x + Double(max(1, battle.header.width) * NativeHexGeometry.halfWidth),
            y: origin.y + Double(max(1, battle.header.height)) * Double(NativeHexGeometry.rowStep) / 2.0,
            zoom: payload.camera.zoom
        )
    }

    private static func isEnded(_ value: NativeJSONValue?) -> Bool {
        guard let value else { return false }
        if case .null = value { return false }
        return true
    }

    private static func int(_ value: NativeJSONValue?) -> Int? {
        switch value {
        case .int(let v): return v
        case .double(let v): return Int(v.rounded(.towardZero))
        case .string(let v): return Int(v)
        default: return nil
        }
    }

    private static func string(_ value: NativeJSONValue?) -> String? {
        switch value {
        case .string(let v): return v
        case .int(let v): return String(v)
        default: return nil
        }
    }

    private static func bool(_ value: NativeJSONValue?) -> Bool? {
        switch value {
        case .bool(let v): return v
        case .int(let v): return v != 0
        case .string(let v):
            if v == "true" || v == "1" { return true }
            if v == "false" || v == "0" { return false }
            return nil
        default: return nil
        }
    }
}
