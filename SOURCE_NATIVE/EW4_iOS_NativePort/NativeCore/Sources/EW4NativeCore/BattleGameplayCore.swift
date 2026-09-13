import Foundation

public enum NativeBattlePhase: String, Equatable, Sendable {
    case player
    case ai
    case ended
}

public struct NativeBattleUnitState: Equatable, Sendable {
    public let index: Int
    public let armyID: Int
    public let armyName: String
    public let grade: Int
    public let owner: Int
    public let commanderID: Int?
    public var q: Int
    public var r: Int
    public var hp: Int
    public var maxHP: Int
    public var moved: Bool
    public var attacked: Bool
    public var embarked: Bool
    public var trainingLevel: Int
    public var trainingExp: Int
    public var underConstruction: Bool
    public var constructionRoundsRemaining: Int
    public var constructionTotalRounds: Int
    public var playerCommanderHPBonus: Int
    public var nativeMoraleBase: Int
    public var nativeMoraleUntilRound: Int

    public var cell: HexCell { HexCell(q: q, r: r) }
    public var dead: Bool { hp <= 0 }

    public init(
        index: Int,
        armyID: Int,
        armyName: String,
        grade: Int,
        owner: Int,
        commanderID: Int?,
        q: Int,
        r: Int,
        hp: Int,
        maxHP: Int,
        moved: Bool,
        attacked: Bool,
        embarked: Bool,
        trainingLevel: Int = 0,
        trainingExp: Int = 0,
        underConstruction: Bool = false,
        constructionRoundsRemaining: Int = 0,
        constructionTotalRounds: Int = 0,
        playerCommanderHPBonus: Int = 0,
        nativeMoraleBase: Int = 0,
        nativeMoraleUntilRound: Int = 0
    ) {
        self.index = index
        self.armyID = armyID
        self.armyName = armyName
        self.grade = grade
        self.owner = owner
        self.commanderID = commanderID
        self.q = q
        self.r = r
        self.hp = max(0, hp)
        self.maxHP = max(1, maxHP)
        self.moved = moved
        self.attacked = attacked
        self.embarked = embarked
        self.trainingLevel = NativeTrainingParityCore.level(trainingLevel)
        self.trainingExp = max(0, trainingExp)
        self.underConstruction = underConstruction
        self.constructionRoundsRemaining = max(0, constructionRoundsRemaining)
        self.constructionTotalRounds = max(0, constructionTotalRounds)
        self.playerCommanderHPBonus = max(0, playerCommanderHPBonus)
        self.nativeMoraleBase = max(-3, min(1, nativeMoraleBase))
        self.nativeMoraleUntilRound = max(0, nativeMoraleUntilRound)
    }

    public init(unit: BattleUnit, isPlayer: Bool, embarked: Bool) {
        let migrated = PlayerUnitRules.migratedHP(
            hp: unit.hp,
            maxHP: unit.maxHP,
            previousAppliedBonus: nil,
            isPlayer: isPlayer
        )
        self.index = unit.index
        self.armyID = unit.armyID
        self.armyName = unit.armyName
        self.grade = unit.grade
        self.owner = unit.owner
        self.commanderID = unit.commanderID
        self.q = unit.q
        self.r = unit.r
        self.hp = migrated.hp
        self.maxHP = migrated.maxHP
        self.moved = false
        self.attacked = false
        self.embarked = embarked
        let rawTraining = unit.raw.flatMap { $0.indices.contains(20) ? $0[20] : nil } ?? 0
        self.trainingLevel = NativeTrainingParityCore.level(rawTraining)
        self.trainingExp = 0
        self.underConstruction = false
        self.constructionRoundsRemaining = 0
        self.constructionTotalRounds = 0
        self.playerCommanderHPBonus = 0
        self.nativeMoraleBase = 0
        self.nativeMoraleUntilRound = 0
    }
}

public struct NativeBattleObjectState: Equatable, Sendable {
    public let index: Int
    public let q: Int
    public let r: Int
    public let constructionID: Int
    public let constructionType: String?
    public var level: Int
    public let extra: Int
    public var owner: Int

    public var cell: HexCell { HexCell(q: q, r: r) }

    public init(
        index: Int,
        q: Int,
        r: Int,
        constructionID: Int,
        constructionType: String?,
        level: Int,
        extra: Int,
        owner: Int
    ) {
        self.index = index
        self.q = q
        self.r = r
        self.constructionID = constructionID
        self.constructionType = constructionType
        self.level = level
        self.extra = extra
        self.owner = owner
    }

    public init(object: BattleObject) {
        self.index = object.index
        self.q = object.q
        self.r = object.r
        self.constructionID = object.constructionID
        self.constructionType = object.constructionType
        self.level = object.level
        self.extra = object.extra
        self.owner = object.owner
    }
}

public struct NativeBattleMoveUndo: Equatable, Sendable {
    public let unitIndex: Int
    public let q: Int
    public let r: Int
    public let embarked: Bool
    public let moved: Bool
    public let attacked: Bool
    public let path: [HexCell]
}

public struct NativeBattleMoveResult: Equatable, Sendable {
    public let unitIndex: Int
    public let path: [HexCell]
    public let capturedObjectIndices: [Int]
    public let undoAvailable: Bool
    public init(unitIndex: Int, path: [HexCell], capturedObjectIndices: [Int], undoAvailable: Bool) {
        self.unitIndex = unitIndex
        self.path = path
        self.capturedObjectIndices = capturedObjectIndices
        self.undoAvailable = undoAvailable
    }
}

public typealias NativeCombatGrowthHandler = @Sendable (_ commanderID: Int, _ damage: Int, _ killed: Bool, _ victimGrade: Int, _ victimHasCommander: Bool) -> NativeGeneralGrowthApplication?

public struct NativeBattleAttackResult: Sendable {
    public let attackerIndex: Int
    public let defenderIndex: Int
    public let damage: Int
    public let counterDamage: Int?
    public let defenderKilled: Bool
    public let attackerKilled: Bool
    public let cavalryExtraAction: Bool
    public let hit: DamageResult
    public let counter: DamageResult?
    public let attackerTraining: NativeTrainingExpResult?
    public let counterAttackerTraining: NativeTrainingExpResult?
    public let generalGrowth: [NativeGeneralGrowthApplication]
    public let collectedMedals: Int

    public init(
        attackerIndex: Int, defenderIndex: Int, damage: Int, counterDamage: Int?,
        defenderKilled: Bool, attackerKilled: Bool, cavalryExtraAction: Bool,
        hit: DamageResult, counter: DamageResult?,
        attackerTraining: NativeTrainingExpResult? = nil,
        counterAttackerTraining: NativeTrainingExpResult? = nil,
        generalGrowth: [NativeGeneralGrowthApplication] = [],
        collectedMedals: Int = 0
    ) {
        self.attackerIndex = attackerIndex
        self.defenderIndex = defenderIndex
        self.damage = damage
        self.counterDamage = counterDamage
        self.defenderKilled = defenderKilled
        self.attackerKilled = attackerKilled
        self.cavalryExtraAction = cavalryExtraAction
        self.hit = hit
        self.counter = counter
        self.attackerTraining = attackerTraining
        self.counterAttackerTraining = counterAttackerTraining
        self.generalGrowth = generalGrowth
        self.collectedMedals = max(0, collectedMedals)
    }
}

public enum NativeBattleCommandError: Error, Equatable, Sendable {
    case wrongPhase
    case noSelection
    case unitMissing
    case notPlayerUnit
    case unitDead
    case destinationNotReachable
    case targetNotHostile
    case targetOutOfRange
    case actionAlreadySpent
    case statMissing
    case undoUnavailable
}

public struct NativeBattleGameplayState: Sendable {
    public let battle: BattleRecord
    public let world: WorldDefinition
    public let terrainTypes: [String: TerrainTypeDefinition]
    public let armyStats: ArmyStatsCatalog
    public let commanders: [Int: Commander]
    public let itemEffects: NativeItemEffectCatalog
    public let constructions: NativeConstructionCatalog
    public let installationCatalog: NativeInstallationCatalog
    public let effectiveCommanderProvider: (@Sendable (Int, Bool) -> NativeEffectiveCommander?)?
    public let combatGrowthHandler: NativeCombatGrowthHandler?
    public let mode: BattleMode
    public let playerOwner: Int

    public private(set) var round: Int
    public private(set) var phase: NativeBattlePhase
    public var ended: Bool { phase == .ended }
    public private(set) var activeOwner: Int
    public private(set) var units: [Int: NativeBattleUnitState]
    public private(set) var unitOrder: [Int]
    public private(set) var objects: [Int: NativeBattleObjectState]
    public private(set) var installations: [NativeBattleInstallationState]
    public private(set) var selectedUnitIndex: Int?
    public private(set) var reachable: [HexCell: Int]
    public private(set) var undo: NativeBattleMoveUndo?
    public private(set) var fortressBuiltRound: Int?

    public init(
        session: NativeBattleSession,
        terrainTypes: [String: TerrainTypeDefinition],
        armyStats: ArmyStatsCatalog,
        commanders: [Int: Commander],
        itemEffects: NativeItemEffectCatalog = [:],
        constructions: NativeConstructionCatalog = [:],
        installationCatalog: NativeInstallationCatalog = [:],
        effectiveCommanderProvider: (@Sendable (Int, Bool) -> NativeEffectiveCommander?)? = nil,
        combatGrowthHandler: NativeCombatGrowthHandler? = nil,
        mode: BattleMode = .campaign,
        playerOwner explicitPlayerOwner: Int? = nil
    ) {
        self.battle = session.battle
        self.world = session.world
        self.terrainTypes = terrainTypes
        self.armyStats = armyStats
        self.commanders = commanders
        self.itemEffects = itemEffects
        self.constructions = constructions
        self.installationCatalog = installationCatalog
        self.effectiveCommanderProvider = effectiveCommanderProvider
        self.combatGrowthHandler = combatGrowthHandler
        self.mode = mode
        self.playerOwner = explicitPlayerOwner ?? session.battle.playerOwnerDefault ?? 0
        self.round = 1
        self.phase = .player
        self.activeOwner = explicitPlayerOwner ?? session.battle.playerOwnerDefault ?? 0
        self.unitOrder = session.units.map(\.index)
        self.objects = Dictionary(uniqueKeysWithValues: session.objects.map { ($0.index, NativeBattleObjectState(object: $0)) })
        self.installations = []
        self.selectedUnitIndex = nil
        self.reachable = [:]
        self.undo = nil
        self.fortressBuiltRound = nil

        var unitStates: [Int: NativeBattleUnitState] = [:]
        for unit in session.units {
            let cell = HexCell(q: unit.q, r: unit.r)
            let terrain = Self.terrainCell(world: session.world, cell: cell)
            let startsEmbarked = !ArmyStatsCore.isSeaUnit(armyName: unit.armyName)
                && !ArmyStatsCore.isFort(armyName: unit.armyName)
                && terrain?.type == "sea"
            var state = NativeBattleUnitState(
                unit: unit,
                isPlayer: unit.owner == self.playerOwner,
                embarked: startsEmbarked
            )
            if unit.owner == self.playerOwner,
               let commanderID = unit.commanderID,
               let effective = effectiveCommanderProvider?(commanderID, true),
               effective.rankHPBonus > 0 {
                state.playerCommanderHPBonus = effective.rankHPBonus
                state.maxHP += effective.rankHPBonus
                state.hp += effective.rankHPBonus
            }
            unitStates[unit.index] = state
        }
        self.units = unitStates
    }

    public func unit(at cell: HexCell) -> NativeBattleUnitState? {
        unitOrder.lazy.compactMap { units[$0] }.first { !$0.dead && $0.cell == cell }
    }

    public func object(at cell: HexCell) -> NativeBattleObjectState? {
        objects.values.first { $0.cell == cell && $0.constructionType != nil }
    }

    public func countryCode(owner: Int) -> String {
        battle.countries.first(where: { $0.index == owner })?.code ?? "others"
    }

    public func stat(for unit: NativeBattleUnitState) -> ArmyStatDefinition? {
        ArmyStatsCore.resolve(
            catalog: armyStats,
            countryCode: countryCode(owner: unit.owner),
            armyName: unit.armyName,
            grade: unit.grade
        )
    }

    public func commander(for unit: NativeBattleUnitState) -> Commander? {
        guard let id = unit.commanderID else { return nil }
        return commanders[id]
    }

    public func effectiveCommander(for unit: NativeBattleUnitState) -> NativeEffectiveCommander? {
        guard let id = unit.commanderID else { return nil }
        if let projected = effectiveCommanderProvider?(id, unit.owner == playerOwner) {
            return projected
        }
        guard let raw = commanders[id] else { return nil }
        return NativeEffectiveCommander(
            id: raw.id,
            infantry: raw.infantry, cavalry: raw.cavalry, artillery: raw.artillery,
            warship: raw.warship, fort: raw.fort, business: raw.business,
            movement: raw.movement, training: raw.training, skillIDs: raw.skillIDs,
            equippedItemIDs: [raw.item1, raw.item2].compactMap { value in
                guard let value, value >= 0 else { return nil }
                return value
            },
            rankLevel: raw.rank, nobilityLevel: raw.nobilityrank,
            rankHPBonus: 0, nobilityHealCap: 25
        )
    }

    public func relation(_ a: Int, _ b: Int) -> CountryRelation {
        CountryTurnCore.relation(battle, a, b, mode: mode, playerOwner: playerOwner)
    }

    public func itemTargetsUnit(_ item: NativeItemEffectDefinition, stat: ArmyStatDefinition) -> Bool {
        guard let target = item.target else { return false }
        return target == "all" || target == stat.type || (target == "navy" && stat.type == "warship")
    }

    public func hasEquipmentFunction(_ unit: NativeBattleUnitState, function: Int) -> Bool {
        guard let commander = effectiveCommander(for: unit) else { return false }
        return commander.equippedItemIDs.contains { itemID in
            itemEffects[String(itemID)]?.function == function
        }
    }

    public func equipmentFunctionValue(
        _ unit: NativeBattleUnitState,
        function: Int,
        requireTargetMatch: Bool = false
    ) -> Int {
        guard let commander = effectiveCommander(for: unit) else { return 0 }
        let stat = stat(for: unit)
        return commander.equippedItemIDs.reduce(0) { total, itemID in
            guard let item = itemEffects[String(itemID)], item.function == function else { return total }
            if requireTargetMatch {
                guard let stat, itemTargetsUnit(item, stat: stat) else { return total }
            }
            return total + item.value
        }
    }

    public func auraEquipmentValueAround(_ unit: NativeBattleUnitState, function: Int) -> Int {
        units.values.reduce(0) { total, source in
            guard source.index != unit.index,
                  !source.dead,
                  NativeHexGeometry.distance(source.cell, unit.cell) == 1,
                  relation(source.owner, unit.owner) == .ally else {
                return total
            }
            return total + equipmentFunctionValue(source, function: function)
        }
    }

    public func attackEquipmentFixedBonus(for unit: NativeBattleUnitState) -> Int {
        equipmentFunctionValue(unit, function: 11, requireTargetMatch: true)
            + auraEquipmentValueAround(unit, function: 14)
    }

    public func defenseEquipmentBonus(for unit: NativeBattleUnitState) -> Int {
        equipmentFunctionValue(unit, function: 10, requireTargetMatch: true)
            + auraEquipmentValueAround(unit, function: 15)
    }

    @discardableResult
    public mutating func applyNativeMorale(countryCode code: String, base: Int, untilRound: Int) -> Int {
        let clamped = max(-3, min(1, base))
        var count = 0
        for index in unitOrder {
            guard var unit = units[index], !unit.dead, countryCode(owner: unit.owner) == code else { continue }
            unit.nativeMoraleBase = clamped
            unit.nativeMoraleUntilRound = max(0, untilRound)
            units[index] = unit
            count += 1
        }
        return count
    }

    public func isFireproof(at cell: HexCell) -> Bool {
        guard let unit = unit(at: cell), !unit.dead else { return false }
        let hasSkill = effectiveCommander(for: unit)?.skillIDs.contains(2) ?? false
        return hasSkill || hasEquipmentFunction(unit, function: 16)
    }

    public func moraleState(for unit: NativeBattleUnitState) -> Int {
        guard !unit.dead else { return 0 }
        let flank = NativeBattleEnvironmentCore.flankPenalty(
            defender: unit,
            units: units,
            relation: { a, b in relation(a, b) }
        )
        let base = NativeBattleEnvironmentCore.eventMoraleBase(
            base: unit.nativeMoraleBase,
            untilRound: unit.nativeMoraleUntilRound,
            round: round
        )
        let leadership = effectiveCommander(for: unit)?.skillIDs.contains(3) ?? false
        return NativeBattleEnvironmentCore.combinedMorale(
            eventBase: base,
            flankPenalty: flank,
            leadership: leadership
        )
    }

    public func resolveCombatDamage(
        attacker: NativeBattleUnitState,
        defender: NativeBattleUnitState,
        isCounter: Bool = false,
        rng: () -> Double = { Double.random(in: 0..<1) }
    ) throws -> DamageResult {
        guard let attackerStat = stat(for: attacker), let defenderStat = stat(for: defender) else {
            throw NativeBattleCommandError.statMissing
        }
        let attackerSnapshot = CombatUnitSnapshot(
            grade: attacker.grade,
            hp: attacker.hp,
            maxHP: attacker.maxHP,
            forceFullFormation: hasEquipmentFunction(attacker, function: 4)
        )
        var options = DamageOptions(
            attacker: attackerSnapshot,
            attackerStat: ArmyStatsCore.combatStat(attackerStat),
            attackerCommander: effectiveCommander(for: attacker)?.combatCommander,
            defenderStat: ArmyStatsCore.combatStat(defenderStat),
            defenderCommander: effectiveCommander(for: defender)?.combatCommander
        )
        options.isCounter = isCounter
        options.isPlayerAttacker = attacker.owner == playerOwner
        options.attackerIsFort = attackerStat.type == "fort"
        options.defenderIsFort = defenderStat.type == "fort"
        options.fixedBonus = attackEquipmentFixedBonus(for: attacker)
        options.defenderTrainingDefense = NativeTrainingParityCore.row(defender.trainingLevel).defense
        options.attackerEmbarked = attacker.embarked && !hasEquipmentFunction(attacker, function: 12)
        options.attackerMorale = moraleState(for: attacker)
        options.defenderMorale = moraleState(for: defender)
        options.terrainReduction = NativeBattleEnvironmentCore.terrainReduction(
            attackerType: attackerStat.type, defenderCell: defender.cell, world: world, terrainTypes: terrainTypes
        )
        options.installationReduction = NativeBattleEnvironmentCore.installationReduction(
            attackerType: attackerStat.type, defenderCell: defender.cell, installations: installations, catalog: installationCatalog
        )
        let building = NativeBattleEnvironmentCore.buildingReduction(
            defenderCell: defender.cell, objects: objects, constructions: constructions
        )
        options.buildingReduction = building.value
        options.defenderHasConstruction = building.hasConstruction

        let raw = CombatCore.resolveDamage(options, rng: rng)
        let armor = defenseEquipmentBonus(for: defender)
        guard armor > 0 else { return raw }
        return DamageResult(
            bounds: raw.bounds,
            value: max(1, raw.value - armor),
            attackTactic: raw.attackTactic,
            defenseTactic: raw.defenseTactic,
            totalReduction: raw.totalReduction,
            notes: raw.notes + ["armor-\(armor)"]
        )
    }

    public func scaledDamageResult(_ result: DamageResult, multiplier: Double) -> DamageResult {
        DamageResult(
            bounds: result.bounds,
            value: max(1, Int(floor(Double(result.value) * multiplier))),
            attackTactic: result.attackTactic,
            defenseTactic: result.defenseTactic,
            totalReduction: result.totalReduction,
            notes: result.notes
        )
    }

    public func canAttack(_ attacker: NativeBattleUnitState, _ defender: NativeBattleUnitState, ignoreAction: Bool = false) -> Bool {
        guard !attacker.dead, !defender.dead else { return false }
        guard relation(attacker.owner, defender.owner) == .hostile else { return false }
        guard let stat = stat(for: attacker) else { return false }
        let distance = NativeHexGeometry.distance(attacker.cell, defender.cell)
        let inRange = distance >= stat.minatkrange && distance <= stat.maxatkrange
        return inRange && (ignoreAction || !attacker.attacked)
    }

    public func effectiveMovement(for unit: NativeBattleUnitState) -> Int {
        guard let stat = stat(for: unit) else { return 0 }
        let commander = effectiveCommander(for: unit)
        var movement = PlayerUnitRules.effectiveMovement(
            stat.movement,
            type: stat.type,
            isPlayer: unit.owner == playerOwner
        )
        if let commander {
            if stat.type != "warship" {
                movement += commander.movement
            }
            if stat.type == "artillery" && commander.skillIDs.contains(6) {
                movement += 2
            }
            if stat.type == "warship" && commander.skillIDs.contains(18) {
                movement += 1
            }
        }
        movement += equipmentFunctionValue(unit, function: 9, requireTargetMatch: true)
        return max(0, movement)
    }

    public func movementCost(for unit: NativeBattleUnitState, entering cell: HexCell) -> Int {
        guard let terrain = terrainCell(cell) else { return Int.max / 4 }
        if terrain.type == "sea" {
            return ArmyStatsCore.isSeaUnit(armyName: unit.armyName)
                ? (terrainTypes[terrain.type]?.movementcost ?? 1)
                : 3
        }
        if unit.armyName == "Light Infantry"
            || (effectiveCommander(for: unit)?.skillIDs.contains(1) ?? false)
            || hasEquipmentFunction(unit, function: 0) {
            return 3
        }
        return terrainTypes[terrain.type]?.movementcost ?? 3
    }

    public func isPassable(_ unit: NativeBattleUnitState, entering cell: HexCell) -> Bool {
        let header = battle.header
        guard cell.q >= header.originX,
              cell.r >= header.originY,
              cell.q < header.originX + header.width,
              cell.r < header.originY + header.height,
              let terrain = terrainCell(cell) else {
            return false
        }

        let sea = terrain.type == "sea"
        if ArmyStatsCore.isSeaUnit(armyName: unit.armyName) {
            if !sea { return false }
        } else if sea && !unit.embarked {
            return false
        }

        return self.unit(at: cell) == nil || self.unit(at: cell)?.index == unit.index
    }

    public func reachableCells(for unit: NativeBattleUnitState) -> [HexCell: Int] {
        guard !unit.dead,
              !unit.moved,
              !ArmyStatsCore.isFort(armyName: unit.armyName) else {
            return [:]
        }
        return NativeMovementCore.reachable(
            start: unit.cell,
            maxCost: effectiveMovement(for: unit),
            canEnter: { isPassable(unit, entering: $0) },
            stepCost: { movementCost(for: unit, entering: $0) }
        )
    }

    @discardableResult
    public mutating func selectUnit(_ unitIndex: Int?) -> [HexCell: Int] {
        guard let unitIndex, let unit = units[unitIndex], !unit.dead else {
            selectedUnitIndex = nil
            reachable = [:]
            return reachable
        }
        selectedUnitIndex = unitIndex
        if phase == .player && unit.owner == playerOwner {
            reachable = reachableCells(for: unit)
        } else {
            reachable = [:]
        }
        return reachable
    }

    @discardableResult
    public mutating func moveSelected(to destination: HexCell) throws -> NativeBattleMoveResult {
        guard phase == .player, activeOwner == playerOwner else { throw NativeBattleCommandError.wrongPhase }
        guard let selectedIndex = selectedUnitIndex else { throw NativeBattleCommandError.noSelection }
        guard var unit = units[selectedIndex] else { throw NativeBattleCommandError.unitMissing }
        guard unit.owner == playerOwner else { throw NativeBattleCommandError.notPlayerUnit }
        guard !unit.dead else { throw NativeBattleCommandError.unitDead }
        guard reachable[destination] != nil else { throw NativeBattleCommandError.destinationNotReachable }

        let path = NativeMovementCore.path(
            start: unit.cell,
            goal: destination,
            maxCost: effectiveMovement(for: unit),
            canEnter: { isPassable(unit, entering: $0) },
            stepCost: { movementCost(for: unit, entering: $0) }
        )

        let hostileObjects = objects.values.filter {
            $0.cell == destination && $0.owner != unit.owner && relation(unit.owner, $0.owner) == .hostile
        }
        if hostileObjects.isEmpty {
            undo = NativeBattleMoveUndo(
                unitIndex: unit.index,
                q: unit.q,
                r: unit.r,
                embarked: unit.embarked,
                moved: unit.moved,
                attacked: unit.attacked,
                path: path
            )
        } else {
            undo = nil
        }

        unit.q = destination.q
        unit.r = destination.r
        if unit.embarked && terrainCell(destination)?.type != "sea" {
            unit.embarked = false
        }
        unit.moved = true
        units[unit.index] = unit

        var captured: [Int] = []
        for object in hostileObjects {
            var updated = object
            updated.owner = unit.owner
            objects[updated.index] = updated
            captured.append(updated.index)
        }

        reachable = [:]
        selectedUnitIndex = unit.index
        return NativeBattleMoveResult(
            unitIndex: unit.index,
            path: path,
            capturedObjectIndices: captured.sorted(),
            undoAvailable: undo != nil
        )
    }

    @discardableResult
    public mutating func undoLastMove() throws -> NativeBattleMoveResult {
        guard phase == .player else { throw NativeBattleCommandError.wrongPhase }
        guard let snapshot = undo, var unit = units[snapshot.unitIndex], !unit.attacked else {
            throw NativeBattleCommandError.undoUnavailable
        }

        unit.q = snapshot.q
        unit.r = snapshot.r
        unit.embarked = snapshot.embarked
        unit.moved = snapshot.moved
        unit.attacked = snapshot.attacked
        units[unit.index] = unit
        undo = nil
        selectedUnitIndex = unit.index
        reachable = reachableCells(for: unit)

        return NativeBattleMoveResult(
            unitIndex: unit.index,
            path: snapshot.path.reversed(),
            capturedObjectIndices: [],
            undoAvailable: false
        )
    }

    private func maybeCollectBattleMedal(
        attacker: NativeBattleUnitState,
        damage: Int,
        rng: () -> Double
    ) -> Bool {
        guard phase != .ended, attacker.owner == playerOwner, !attacker.dead,
              let stat = stat(for: attacker) else { return false }
        let nativeType: Int
        switch stat.type {
        case "infantry": nativeType = 0
        case "cavalry": nativeType = 1
        case "artillery": nativeType = 2
        case "warship": nativeType = 3
        case "fort": nativeType = 4
        default: nativeType = 255
        }
        let raw = max(0.0, min(0.999999999, rng()))
        let roll = Int(floor(raw * 100.0))
        return NativeResultCore.collectMedalProc(
            damage: damage, roll: roll, nativeType: nativeType, nativeLevel: max(0, attacker.grade)
        )
    }

    private func applyGeneralCombatGrowth(
        attacker: inout NativeBattleUnitState,
        victim: NativeBattleUnitState,
        damage: Int,
        killed: Bool
    ) -> NativeGeneralGrowthApplication? {
        guard attacker.owner == playerOwner, !attacker.dead,
              let commanderID = attacker.commanderID,
              let handler = combatGrowthHandler else { return nil }
        guard let application = handler(commanderID, damage, killed, victim.grade, victim.commanderID != nil) else { return nil }
        if application.rankHPDelta > 0 {
            attacker.maxHP += application.rankHPDelta
            attacker.hp = min(attacker.maxHP, attacker.hp + application.rankHPDelta)
            attacker.playerCommanderHPBonus = application.rankHPBonusAfter
        }
        return application
    }

    private func awardCombatTraining(
        unit: inout NativeBattleUnitState,
        damage: Int
    ) -> NativeTrainingExpResult? {
        guard damage > 0, let stat = stat(for: unit) else { return nil }
        let wasDead = unit.dead
        var state = NativeTrainingUnitState(
            trainingLevel: unit.trainingLevel,
            trainingExp: unit.trainingExp,
            hp: unit.hp,
            maxHP: unit.maxHP,
            dead: wasDead,
            commanderID: unit.commanderID
        )
        let result = NativeTrainingParityCore.awardExp(
            unit: &state,
            amount: damage,
            hasCommander: unit.commanderID != nil,
            unitType: stat.type
        )
        unit.trainingLevel = state.trainingLevel
        unit.trainingExp = state.trainingExp
        // P39 keeps the explicit `dead` flag after a post-counter training level-up.
        // Native death is HP-derived, so preserve the equivalent effective state.
        unit.hp = wasDead ? 0 : state.hp
        return result
    }

    @discardableResult
    public mutating func attackSelected(
        target targetIndex: Int,
        rng: () -> Double = { Double.random(in: 0..<1) }
    ) throws -> NativeBattleAttackResult {
        guard phase == .player, activeOwner == playerOwner else { throw NativeBattleCommandError.wrongPhase }
        guard let selectedIndex = selectedUnitIndex else { throw NativeBattleCommandError.noSelection }
        guard var attacker = units[selectedIndex], var defender = units[targetIndex] else {
            throw NativeBattleCommandError.unitMissing
        }
        guard attacker.owner == playerOwner else { throw NativeBattleCommandError.notPlayerUnit }
        guard !attacker.dead, !defender.dead else { throw NativeBattleCommandError.unitDead }
        guard relation(attacker.owner, defender.owner) == .hostile else { throw NativeBattleCommandError.targetNotHostile }
        guard !attacker.attacked else { throw NativeBattleCommandError.actionAlreadySpent }
        guard canAttack(attacker, defender) else { throw NativeBattleCommandError.targetOutOfRange }
        guard let attackerStat = stat(for: attacker) else {
            throw NativeBattleCommandError.statMissing
        }

        let hit = try resolveCombatDamage(attacker: attacker, defender: defender, rng: rng)
        var collectedMedals = maybeCollectBattleMedal(attacker: attacker, damage: hit.value, rng: rng) ? 1 : 0

        let defenderWasAlive = !defender.dead
        defender.hp = max(0, defender.hp - hit.value)
        let defenderKilled = defenderWasAlive && defender.dead
        var growth: [NativeGeneralGrowthApplication] = []
        if let application = applyGeneralCombatGrowth(attacker: &attacker, victim: defender, damage: hit.value, killed: defenderKilled) {
            growth.append(application)
        }
        attacker.attacked = true
        undo = nil

        var counterResult: DamageResult?
        var counterDamage: Int?
        if !defender.dead,
           attackerStat.type != "artillery",
           canAttack(defender, attacker, ignoreAction: true) {
            let rawCounter = try resolveCombatDamage(
                attacker: defender,
                defender: attacker,
                isCounter: true,
                rng: rng
            )
            let resolvedCounter = scaledDamageResult(rawCounter, multiplier: 0.68)
            if maybeCollectBattleMedal(attacker: defender, damage: resolvedCounter.value, rng: rng) { collectedMedals += 1 }
            let attackerWasAlive = !attacker.dead
            attacker.hp = max(0, attacker.hp - resolvedCounter.value)
            let attackerKilled = attackerWasAlive && attacker.dead
            if let application = applyGeneralCombatGrowth(attacker: &defender, victim: attacker, damage: resolvedCounter.value, killed: attackerKilled) {
                growth.append(application)
            }
            counterResult = resolvedCounter
            counterDamage = resolvedCounter.value
        }

        // P39 awards combat training only after the primary hit and optional counter resolve.
        let attackerTraining = awardCombatTraining(unit: &attacker, damage: hit.value)
        let counterTraining = counterDamage.flatMap { awardCombatTraining(unit: &defender, damage: $0) }

        let cavalryExtraAction = !attacker.dead && defender.dead && attackerStat.type == "cavalry"
        if cavalryExtraAction {
            attacker.moved = false
            attacker.attacked = false
        }

        units[attacker.index] = attacker
        units[defender.index] = defender
        reachable = cavalryExtraAction ? reachableCells(for: attacker) : [:]
        selectedUnitIndex = attacker.dead ? nil : attacker.index

        return NativeBattleAttackResult(
            attackerIndex: attacker.index,
            defenderIndex: defender.index,
            damage: hit.value,
            counterDamage: counterDamage,
            defenderKilled: defender.dead,
            attackerKilled: attacker.dead,
            cavalryExtraAction: cavalryExtraAction,
            hit: hit,
            counter: counterResult,
            attackerTraining: attackerTraining,
            counterAttackerTraining: counterTraining,
            generalGrowth: growth,
            collectedMedals: collectedMedals
        )
    }

    public mutating func endPlayerTurn() throws -> [Int] {
        guard phase == .player, activeOwner == playerOwner else { throw NativeBattleCommandError.wrongPhase }
        selectedUnitIndex = nil
        reachable = [:]
        undo = nil
        phase = .ai

        let livingOwners = Set(units.values.filter { !$0.dead }.map(\.owner))
        let order = CountryTurnCore.aiTurnOrder(
            battle,
            livingOwners: livingOwners,
            playerOwner: playerOwner,
            mode: mode
        )
        activeOwner = order.first ?? playerOwner
        return order
    }

    public mutating func beginAITurn(owner: Int) throws {
        guard phase == .ai else { throw NativeBattleCommandError.wrongPhase }
        let livingOwners = Set(units.values.filter { !$0.dead }.map(\.owner))
        let allowed = CountryTurnCore.aiTurnOrder(
            battle,
            livingOwners: livingOwners,
            playerOwner: playerOwner,
            mode: mode
        )
        guard allowed.contains(owner) else { throw NativeBattleCommandError.notPlayerUnit }
        activeOwner = owner
        selectedUnitIndex = nil
        reachable = [:]
        undo = nil
    }

    @discardableResult
    public mutating func moveAIUnit(_ unitIndex: Int, to destination: HexCell) throws -> NativeBattleMoveResult {
        guard phase == .ai else { throw NativeBattleCommandError.wrongPhase }
        guard var unit = units[unitIndex] else { throw NativeBattleCommandError.unitMissing }
        guard unit.owner == activeOwner else { throw NativeBattleCommandError.notPlayerUnit }
        guard !unit.dead else { throw NativeBattleCommandError.unitDead }
        guard !unit.moved else { throw NativeBattleCommandError.actionAlreadySpent }

        if destination == unit.cell || ArmyStatsCore.isFort(armyName: unit.armyName) {
            unit.moved = true
            units[unit.index] = unit
            return NativeBattleMoveResult(
                unitIndex: unit.index,
                path: [unit.cell],
                capturedObjectIndices: [],
                undoAvailable: false
            )
        }

        let reachable = reachableCells(for: unit)
        guard reachable[destination] != nil else { throw NativeBattleCommandError.destinationNotReachable }
        let path = NativeMovementCore.path(
            start: unit.cell,
            goal: destination,
            maxCost: effectiveMovement(for: unit),
            canEnter: { isPassable(unit, entering: $0) },
            stepCost: { movementCost(for: unit, entering: $0) }
        )

        unit.q = destination.q
        unit.r = destination.r
        if unit.embarked && terrainCell(destination)?.type != "sea" {
            unit.embarked = false
        }
        unit.moved = true
        units[unit.index] = unit

        var captured: [Int] = []
        for object in objects.values where object.cell == destination
            && object.owner != unit.owner
            && relation(unit.owner, object.owner) == .hostile {
            var updated = object
            updated.owner = unit.owner
            objects[updated.index] = updated
            captured.append(updated.index)
        }

        return NativeBattleMoveResult(
            unitIndex: unit.index,
            path: path,
            capturedObjectIndices: captured.sorted(),
            undoAvailable: false
        )
    }

    @discardableResult
    public mutating func attackAIUnit(
        attacker attackerIndex: Int,
        target targetIndex: Int,
        rng: () -> Double = { Double.random(in: 0..<1) }
    ) throws -> NativeBattleAttackResult {
        guard phase == .ai else { throw NativeBattleCommandError.wrongPhase }
        guard var attacker = units[attackerIndex], var defender = units[targetIndex] else {
            throw NativeBattleCommandError.unitMissing
        }
        guard attacker.owner == activeOwner else { throw NativeBattleCommandError.notPlayerUnit }
        guard !attacker.dead, !defender.dead else { throw NativeBattleCommandError.unitDead }
        guard relation(attacker.owner, defender.owner) == .hostile else {
            throw NativeBattleCommandError.targetNotHostile
        }
        guard !attacker.attacked else { throw NativeBattleCommandError.actionAlreadySpent }
        guard canAttack(attacker, defender) else { throw NativeBattleCommandError.targetOutOfRange }
        guard let attackerStat = stat(for: attacker) else {
            throw NativeBattleCommandError.statMissing
        }

        let hit = try resolveCombatDamage(attacker: attacker, defender: defender, rng: rng)
        var collectedMedals = maybeCollectBattleMedal(attacker: attacker, damage: hit.value, rng: rng) ? 1 : 0

        let defenderWasAlive = !defender.dead
        defender.hp = max(0, defender.hp - hit.value)
        let defenderKilled = defenderWasAlive && defender.dead
        var growth: [NativeGeneralGrowthApplication] = []
        if let application = applyGeneralCombatGrowth(attacker: &attacker, victim: defender, damage: hit.value, killed: defenderKilled) {
            growth.append(application)
        }
        attacker.attacked = true

        var counterResult: DamageResult?
        var counterDamage: Int?
        if !defender.dead,
           attackerStat.type != "artillery",
           canAttack(defender, attacker, ignoreAction: true) {
            let rawCounter = try resolveCombatDamage(
                attacker: defender,
                defender: attacker,
                isCounter: true,
                rng: rng
            )
            let resolvedCounter = scaledDamageResult(rawCounter, multiplier: 0.68)
            if maybeCollectBattleMedal(attacker: defender, damage: resolvedCounter.value, rng: rng) { collectedMedals += 1 }
            let attackerWasAlive = !attacker.dead
            attacker.hp = max(0, attacker.hp - resolvedCounter.value)
            let attackerKilled = attackerWasAlive && attacker.dead
            if let application = applyGeneralCombatGrowth(attacker: &defender, victim: attacker, damage: resolvedCounter.value, killed: attackerKilled) {
                growth.append(application)
            }
            counterResult = resolvedCounter
            counterDamage = resolvedCounter.value
        }

        let attackerTraining = awardCombatTraining(unit: &attacker, damage: hit.value)
        let counterTraining = counterDamage.flatMap { awardCombatTraining(unit: &defender, damage: $0) }

        let cavalryExtraAction = !attacker.dead && defender.dead && attackerStat.type == "cavalry"
        if cavalryExtraAction {
            attacker.moved = false
            attacker.attacked = false
        }
        units[attacker.index] = attacker
        units[defender.index] = defender

        return NativeBattleAttackResult(
            attackerIndex: attacker.index,
            defenderIndex: defender.index,
            damage: hit.value,
            counterDamage: counterDamage,
            defenderKilled: defender.dead,
            attackerKilled: attacker.dead,
            cavalryExtraAction: cavalryExtraAction,
            hit: hit,
            counter: counterResult,
            attackerTraining: attackerTraining,
            counterAttackerTraining: counterTraining,
            generalGrowth: growth,
            collectedMedals: collectedMedals
        )
    }

    /// First half of the P39 round boundary. The new round number becomes visible
    /// before settlement, while previous-round moved/attacked flags are preserved.
    public mutating func advanceRoundCounterForSettlement() {
        guard phase == .ai else { return }
        round += 1
    }

    /// Applies round-recovery HP values without touching action/construction state.
    /// This keeps settlement ordering independent from presentation/runtime adapters.
    public mutating func applyRoundHitPoints(_ hitPoints: [Int: Int]) {
        for (index, hp) in hitPoints {
            guard var unit = units[index] else { continue }
            unit.hp = max(0, min(unit.maxHP, hp))
            units[index] = unit
        }
    }

    /// Second half of the P39 round boundary: reset every surviving unit, then
    /// advance fortress construction so unfinished builds remain unavailable and
    /// completed builds become actionable in the new player round.
    @discardableResult
    public mutating func enterPlayerPhaseAfterRoundSettlement() -> [Int] {
        var completedConstruction: [Int] = []
        selectedUnitIndex = nil
        reachable = [:]
        undo = nil
        for index in unitOrder {
            guard var unit = units[index], !unit.dead else { continue }
            unit.moved = false
            unit.attacked = false
            if unit.underConstruction {
                unit.constructionRoundsRemaining = max(0, unit.constructionRoundsRemaining - 1)
                if unit.constructionRoundsRemaining > 0 {
                    unit.moved = true
                    unit.attacked = true
                } else {
                    unit.underConstruction = false
                    unit.moved = false
                    unit.attacked = false
                    completedConstruction.append(index)
                }
            }
            units[index] = unit
        }
        phase = .player
        activeOwner = playerOwner
        return completedConstruction.sorted()
    }

    /// Compatibility helper for simulations that do not model economy/recovery.
    public mutating func beginNextPlayerRound() {
        advanceRoundCounterForSettlement()
        _ = enterPlayerPhaseAfterRoundSettlement()
    }

    /// Applies an already-normalized persisted battle snapshot without re-running
    /// new-battle HP/movement initialization. This is deliberately narrow: save
    /// rehydration owns decoding and validation; gameplay owns its mutable state.
    public mutating func setInstallations(_ values: [NativeBattleInstallationState]) {
        installations = values
    }

    /// Native form_deploygeneral mutation hook. Keeps the lower-level unit table
    /// private while exposing the recovered deployment semantics to the renderer.
    public func canUpgradeConstruction(_ objectIndex: Int) -> Bool {
        guard let object = objects[objectIndex], object.owner == playerOwner else { return false }
        return NativeBattleConstructionCore.canUpgrade(object: object, constructions: constructions)
    }

    @discardableResult
    public mutating func upgradeConstruction(_ objectIndex: Int, resources: inout CountryResources) -> NativeConstructionUpgradeCost? {
        guard var object = objects[objectIndex], object.owner == playerOwner else { return nil }
        let occupant = unit(at: object.cell)
        let architecture = occupant.flatMap { effectiveCommander(for: $0) }?.skillIDs.contains(30) == true
        guard let result = NativeBattleConstructionCore.upgrade(object: &object, resources: &resources, constructions: constructions, architecture: architecture) else { return nil }
        objects[objectIndex] = object
        return result
    }

    public func canManualTrain(_ unitIndex: Int) -> Bool {
        guard let unit = units[unitIndex], unit.owner == playerOwner, !unit.dead, let commander = effectiveCommander(for: unit) else { return false }
        let state = NativeTrainingUnitState(trainingLevel: unit.trainingLevel, trainingExp: unit.trainingExp, hp: unit.hp, maxHP: unit.maxHP, dead: unit.dead, commanderID: unit.commanderID)
        return NativeTrainingParityCore.canManualTrain(unit: state, commanderTraining: commander.training)
    }

    @discardableResult
    public mutating func manualTrain(_ unitIndex: Int, resources: inout CountryResources) -> NativeTrainingActionResult {
        guard var unit = units[unitIndex], unit.owner == playerOwner, !unit.dead, let commander = effectiveCommander(for: unit), let stat = stat(for: unit) else {
            return NativeTrainingActionResult(ok: false, reason: "ineligible")
        }
        var state = NativeTrainingUnitState(trainingLevel: unit.trainingLevel, trainingExp: unit.trainingExp, hp: unit.hp, maxHP: unit.maxHP, dead: unit.dead, commanderID: unit.commanderID)
        let result = NativeTrainingParityCore.manualTrain(unit: &state, commanderTraining: commander.training, consumption: stat.consumption, resources: &resources)
        guard result.ok else { return result }
        unit.trainingLevel = state.trainingLevel
        unit.trainingExp = state.trainingExp
        unit.hp = state.hp
        unit.moved = true
        unit.attacked = true
        units[unitIndex] = unit
        selectedUnitIndex = unitIndex
        reachable.removeAll(keepingCapacity: true)
        undo = nil
        return result
    }

    public func canEmbark(_ unitIndex: Int) -> Bool {
        guard let unit = units[unitIndex], unit.owner == playerOwner, !unit.dead, !unit.embarked, !ArmyStatsCore.isSeaUnit(armyName: unit.armyName), !ArmyStatsCore.isFort(armyName: unit.armyName) else { return false }
        return NativeHexGeometry.neighbors(of: unit.cell).contains { terrainCell($0)?.type == "sea" }
    }

    @discardableResult
    public mutating func embark(_ unitIndex: Int, resources: inout CountryResources, buildCards: NativeBuildCardCatalog) -> CountryResources? {
        guard canEmbark(unitIndex), var unit = units[unitIndex], let card = buildCards["Troopship"] else { return nil }
        let cost = CountryResources(money: card.price, industry: card.industry, food: 0)
        guard resources.money >= cost.money, resources.industry >= cost.industry else { return nil }
        resources.money -= cost.money
        resources.industry -= cost.industry
        unit.embarked = true
        units[unitIndex] = unit
        selectedUnitIndex = unitIndex
        reachable = reachableCells(for: unit)
        undo = nil
        return cost
    }

    public func canRecruit(at objectIndex: Int) -> Bool {
        guard phase == .player, let object = objects[objectIndex], object.owner == playerOwner else { return false }
        return unit(at: object.cell) == nil && !NativeBattleConstructionCore.recruitDefinitions(object: object, constructions: constructions).isEmpty
    }

    @discardableResult
    public mutating func recruit(
        at objectIndex: Int,
        recruit: NativeRecruitDefinition,
        grade: Int,
        card: NativeRecruitCardDefinition,
        trainingLevel: Int,
        resources: inout CountryResources
    ) -> Int? {
        guard canRecruit(at: objectIndex),
              let object = objects[objectIndex],
              let armyID = NativeBattleRecruitCore.armyID(recruit.name),
              card.army == recruit.name,
              resources.money >= card.price, resources.industry >= card.industry,
              let stat = ArmyStatsCore.resolve(catalog: armyStats, countryCode: countryCode(owner: playerOwner), armyName: recruit.name, grade: max(0, min(recruit.grade, grade))) else { return nil }
        let actualGrade = max(0, min(recruit.grade, grade))
        resources.money -= card.price
        resources.industry -= card.industry
        let index = NativeBattleRecruitCore.nextUnitIndex(existing: unitOrder)
        let maxHP = PlayerUnitRules.effectiveBaseHP(strength: stat.strength, isPlayer: true)
        let state = NativeBattleUnitState(
            index: index, armyID: armyID, armyName: recruit.name, grade: actualGrade, owner: playerOwner, commanderID: nil,
            q: object.q, r: object.r, hp: maxHP, maxHP: maxHP, moved: true, attacked: true, embarked: false,
            trainingLevel: trainingLevel, trainingExp: 0
        )
        units[index] = state
        unitOrder.append(index)
        selectedUnitIndex = index
        reachable = [:]
        undo = nil
        return index
    }

    @discardableResult
    public mutating func useBattleConsumable(_ item: NativeItemEffectDefinition, on unitIndex: Int) -> Bool {
        guard phase == .player, var unit = units[unitIndex], unit.owner == playerOwner else { return false }
        guard NativeBattleConsumableCore.apply(item: item, unit: &unit, round: round) else { return false }
        units[unitIndex] = unit
        selectedUnitIndex = unitIndex
        reachable = [:]
        undo = nil
        return true
    }

    public func canBuildInstallation(_ unitIndex: Int) -> Bool {
        guard phase == .player, let unit = units[unitIndex], unit.owner == playerOwner, !unit.dead, !unit.attacked, !unit.embarked,
              let stat = stat(for: unit), stat.type == "infantry", !ArmyStatsCore.isFort(armyName: unit.armyName),
              terrainCell(unit.cell)?.type != "sea", !installations.contains(where: { $0.cell == unit.cell }) else { return false }
        return true
    }

    @discardableResult
    public mutating func buildInstallation(_ unitIndex: Int, choice: NativeDefenseChoice, resources: inout CountryResources) -> NativeBattleInstallationState? {
        guard canBuildInstallation(unitIndex), choice.type == "installation", let kind = NativeBattleDefenseCore.installationType(for: choice.key),
              resources.money >= choice.money, resources.industry >= choice.industry, var unit = units[unitIndex] else { return nil }
        resources.money -= choice.money
        resources.industry -= choice.industry
        let state = NativeBattleInstallationState(q: unit.q, r: unit.r, type: kind, owner: playerOwner)
        installations.removeAll(where: { $0.cell == unit.cell })
        installations.append(state)
        unit.moved = true; unit.attacked = true
        units[unitIndex] = unit
        selectedUnitIndex = unitIndex
        reachable = [:]; undo = nil
        return state
    }

    public func canBuildFortress(at cell: HexCell, ownership: [Int]) -> Bool {
        guard phase == .player, fortressBuiltRound != round, terrainCell(cell)?.type != "sea", unit(at: cell) == nil, object(at: cell) == nil,
              NativeBattleDefenseCore.owner(battle: battle, ownership: ownership, cell: cell) == playerOwner else { return false }
        return true
    }

    public func hasAdjacentSea(_ cell: HexCell) -> Bool {
        NativeHexGeometry.neighbors(of: cell).contains { terrainCell($0)?.type == "sea" }
    }

    @discardableResult
    public mutating func buildFortress(at cell: HexCell, choice: NativeDefenseChoice, ownership: [Int], trainingLevel: Int, resources: inout CountryResources) -> Int? {
        guard canBuildFortress(at: cell, ownership: ownership), choice.type == "fortress", let armyName = choice.armyName,
              let armyID = NativeBattleRecruitCore.armyID(armyName), resources.money >= choice.money, resources.industry >= choice.industry,
              let stat = ArmyStatsCore.resolve(catalog: armyStats, countryCode: countryCode(owner: playerOwner), armyName: armyName, grade: choice.grade) else { return nil }
        resources.money -= choice.money; resources.industry -= choice.industry
        let index = NativeBattleRecruitCore.nextUnitIndex(existing: unitOrder)
        let maxHP = PlayerUnitRules.effectiveBaseHP(strength: stat.strength, isPlayer: true)
        let rounds = max(1, choice.buildRounds)
        units[index] = NativeBattleUnitState(index: index, armyID: armyID, armyName: armyName, grade: choice.grade, owner: playerOwner, commanderID: nil, q: cell.q, r: cell.r, hp: maxHP, maxHP: maxHP, moved: true, attacked: true, embarked: false, trainingLevel: trainingLevel, trainingExp: 0, underConstruction: true, constructionRoundsRemaining: rounds, constructionTotalRounds: rounds)
        unitOrder.append(index); selectedUnitIndex = index; reachable = [:]; undo = nil; fortressBuiltRound = round
        return index
    }

    @discardableResult
    public mutating func deployCommander(to targetUnitIndex: Int, commanderID: Int, hpBonus: Int) -> NativeGeneralDeploymentResult? {
        let result = NativeGeneralDeploymentCore.assign(
            units: &units,
            targetUnitIndex: targetUnitIndex,
            commanderID: commanderID,
            playerOwner: playerOwner,
            hpBonus: hpBonus
        )
        if result != nil {
            selectedUnitIndex = targetUnitIndex
            if let target = units[targetUnitIndex] { reachable = reachableCells(for: target) }
            undo = nil
        }
        return result
    }

    /// Freezes gameplay after a native victory/defeat decision. Presentation may
    /// continue independently (narration/VictoryText/result form), but no battle
    /// command or AI round may resume from this state.
    public mutating func markEnded() {
        phase = .ended
        selectedUnitIndex = nil
        reachable = [:]
        undo = nil
    }

    public mutating func applyMoraleEvent(owner: Int, base: Int, round eventRound: Int) -> Int {
        let clamped = max(-3, min(1, base))
        guard (-3...1).contains(clamped) else { return 0 }
        var count = 0
        for index in unitOrder {
            guard var unit = units[index], !unit.dead, unit.owner == owner else { continue }
            unit.nativeMoraleBase = clamped
            unit.nativeMoraleUntilRound = max(1, eventRound) + 3
            units[index] = unit
            count += 1
        }
        return count
    }

    public mutating func restoreRuntimeState(
        round: Int,
        ended: Bool,
        restoredUnits: [NativeBattleUnitState],
        restoredObjects: [NativeBattleObjectState]
    ) {
        self.round = max(1, round)
        self.phase = ended ? .ended : .player
        self.activeOwner = playerOwner
        self.unitOrder = restoredUnits.map(\.index)
        self.units = Dictionary(uniqueKeysWithValues: restoredUnits.map { ($0.index, $0) })
        self.objects = Dictionary(uniqueKeysWithValues: restoredObjects.map { ($0.index, $0) })
        self.selectedUnitIndex = nil
        self.reachable = [:]
        self.undo = nil
        self.fortressBuiltRound = nil
    }

    public func terrainCell(_ cell: HexCell) -> WorldCell? {
        Self.terrainCell(world: world, cell: cell)
    }

    private static func terrainCell(world: WorldDefinition, cell: HexCell) -> WorldCell? {
        guard cell.q >= 0,
              cell.r >= 0,
              cell.q < world.width,
              cell.r < world.height else {
            return nil
        }
        let index = cell.r * world.width + cell.q
        guard index >= 0, index < world.cells.count else { return nil }
        return world.cells[index]
    }
}
