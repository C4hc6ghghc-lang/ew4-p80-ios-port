import Foundation
import Testing
@testable import EW4NativeCore

private func gameplayFixture(
    playerArmy: String = "Line Infantry",
    playerHP: Int = 80,
    enemyCell: (Int, Int) = (2, 1),
    enemyHP: Int = 80,
    objectAt: (Int, Int)? = nil,
    playerCommanderID: Int? = nil,
    combatGrowthHandler: NativeCombatGrowthHandler? = nil
) throws -> NativeBattleGameplayState {
    let objectJSON: String
    if let objectAt {
        objectJSON = """
        {"index":0,"q":\(objectAt.0),"r":\(objectAt.1),"construction_id":1,"construction_type":"city","level":1,"extra":0,"owner":1}
        """
    } else {
        objectJSON = ""
    }

    let battleJSON = """
    {
      "file":"fixture.btl","name_key":"fixture","name_cn":"fixture","title_cn":"fixture",
      "header":{"version":1,"map_id":1,"origin_x":0,"origin_y":0,"width":5,"height":5,"country_count":2,"object_count":\(objectAt == nil ? 0 : 1),"unit_count":2,"raw":[]},
      "countries":[
        {"index":0,"code":"fra","relation_hint":2,"raw_u32_36_180":[]},
        {"index":1,"code":"gbr","relation_hint":1,"raw_u32_36_180":[]}
      ],
      "relation_groups":{"0":2,"1":1},
      "ownership":[],"player_owner_default":0,"owner_index_bias":0,
      "units":[
        {"index":0,"q":1,"r":1,"army_id":1,"army_name":"\(playerArmy)","grade":0,"hp":\(playerHP),"max_hp":\(playerHP),"commander_id":\(playerCommanderID.map(String.init) ?? "null"),"owner":0},
        {"index":1,"q":\(enemyCell.0),"r":\(enemyCell.1),"army_id":1,"army_name":"Line Infantry","grade":0,"hp":\(enemyHP),"max_hp":\(enemyHP),"commander_id":null,"owner":1}
      ],
      "objects":[\(objectJSON.hasPrefix(",") ? String(objectJSON.dropFirst()) : objectJSON)]
    }
    """

    let battle = try JSONDecoder().decode(BattleRecord.self, from: Data(battleJSON.utf8))

    let worldJSON = """
    {
      "terrains":[{"id":0,"name":"plain","type":"plain"}],
      "terrain_types":{"plain":{"type":"plain","movementcost":3},"sea":{"type":"sea","movementcost":1}},
      "worlds":{"europe":{"map_id":1,"width":5,"height":5,"magic":"x","version":1,"cells":[
        \(Array(repeating: "{\"terrain_id\":0,\"variant\":0,\"type\":\"plain\"}", count: 25).joined(separator: ","))
      ]}}
    }
    """
    let worlds = try JSONDecoder().decode(WorldMapsFile.self, from: Data(worldJSON.utf8))

    let statsJSON = """
    {
      "fra":{
        "Line Infantry|0":{"name":"Line Infantry","grade":0,"type":"infantry","strength":80,"movement":6,"minatk":1,"maxatk":7,"weapon":"gun","minatkrange":1,"maxatkrange":1,"consumption":5},
        "Cavalry|0":{"name":"Cavalry","grade":0,"type":"cavalry","strength":80,"movement":9,"minatk":50,"maxatk":50,"weapon":"sword","minatkrange":1,"maxatkrange":1,"consumption":5}
      },
      "gbr":{
        "Line Infantry|0":{"name":"Line Infantry","grade":0,"type":"infantry","strength":80,"movement":6,"minatk":1,"maxatk":7,"weapon":"gun","minatkrange":1,"maxatkrange":1,"consumption":5}
      },
      "others":{}
    }
    """
    let stats = try JSONDecoder().decode(ArmyStatsCatalog.self, from: Data(statsJSON.utf8))
    let session = NativeBattleSession(battle: battle, worldName: "europe", world: worlds.worlds["europe"]!)
    return NativeBattleGameplayState(
        session: session,
        terrainTypes: worlds.terrainTypes,
        armyStats: stats,
        commanders: [:],
        combatGrowthHandler: combatGrowthHandler,
        mode: .campaign,
        playerOwner: 0
    )
}

@Test func nativeGameplayPlayerBuffMoveAndUndo() throws {
    var state = try gameplayFixture(enemyCell: (4, 4))
    let player = state.units[0]!
    #expect(player.hp == 200)
    #expect(player.maxHP == 200)
    #expect(state.effectiveMovement(for: player) == 8)

    let reachable = state.selectUnit(0)
    #expect(reachable[HexCell(q: 2, r: 1)] == 3)

    let moved = try state.moveSelected(to: HexCell(q: 2, r: 1))
    #expect(moved.path.first == HexCell(q: 1, r: 1))
    #expect(moved.path.last == HexCell(q: 2, r: 1))
    #expect(moved.undoAvailable)
    #expect(state.units[0]?.moved == true)

    let undone = try state.undoLastMove()
    #expect(undone.path.first == HexCell(q: 2, r: 1))
    #expect(undone.path.last == HexCell(q: 1, r: 1))
    #expect(state.units[0]?.cell == HexCell(q: 1, r: 1))
    #expect(state.units[0]?.moved == false)
}

@Test func nativeGameplayAttackAndCounter() throws {
    var state = try gameplayFixture(enemyCell: (2, 1))
    state.selectUnit(0)
    let result = try state.attackSelected(target: 1, rng: { 0 })
    #expect(result.damage > 0)
    #expect(result.counterDamage != nil)
    #expect(state.units[0]?.attacked == true)
    #expect((state.units[1]?.hp ?? 0) < 80)
    #expect((state.units[0]?.hp ?? 0) < 200)
}

@Test func nativeGameplayCavalryAnnihilationGrantsExtraAction() throws {
    var state = try gameplayFixture(playerArmy: "Cavalry", enemyCell: (2, 1), enemyHP: 10)
    state.selectUnit(0)
    let result = try state.attackSelected(target: 1, rng: { 0 })
    #expect(result.defenderKilled)
    #expect(result.cavalryExtraAction)
    #expect(state.units[0]?.moved == false)
    #expect(state.units[0]?.attacked == false)
    #expect(!state.reachable.isEmpty)
}

@Test func nativeGameplayHostileFacilityCaptureDisablesUndo() throws {
    var state = try gameplayFixture(enemyCell: (4, 4), objectAt: (2, 1))
    state.selectUnit(0)
    let result = try state.moveSelected(to: HexCell(q: 2, r: 1))
    #expect(result.capturedObjectIndices == [0])
    #expect(result.undoAvailable == false)
    #expect(state.objects[0]?.owner == 0)
    #expect(throws: NativeBattleCommandError.undoUnavailable) {
        try state.undoLastMove()
    }
}

@Test func nativeGameplayTurnBoundaryResetsPlayerActions() throws {
    var state = try gameplayFixture(enemyCell: (4, 4))
    state.selectUnit(0)
    _ = try state.moveSelected(to: HexCell(q: 2, r: 1))
    let order = try state.endPlayerTurn()
    #expect(order == [1])
    #expect(state.phase == .ai)
    #expect(state.activeOwner == 1)

    state.beginNextPlayerRound()
    #expect(state.round == 2)
    #expect(state.phase == .player)
    #expect(state.activeOwner == 0)
    #expect(state.units[0]?.moved == false)
    #expect(state.units[0]?.attacked == false)
}


@Test func combatTrainingAwardsAfterPrimaryAndCounterUsingActualDamage() throws {
    var state = try gameplayFixture(enemyCell: (2, 1))
    state.selectUnit(0)
    let result = try state.attackSelected(target: 1, rng: { 0 })
    #expect(result.attackerTraining?.awarded == result.damage)
    #expect(state.units[0]?.trainingExp == result.damage)
    if let counter = result.counterDamage {
        #expect(result.counterAttackerTraining?.awarded == counter)
        #expect(state.units[1]?.trainingExp == counter)
    } else {
        #expect(result.counterAttackerTraining == nil)
    }
}

@Test func liveGeneralGrowthHandlerAppliesRankHPDeltaWithoutChangingLegacyAttackAPI() throws {
    let before = NativeGeneralGrowthState(rank: 0, militaryProgress: 499, nobility: 0, nobilityProgress: 0)
    let after = NativeGeneralGrowthState(rank: 1, militaryProgress: 1, nobility: 0, nobilityProgress: 0)
    let application = NativeGeneralGrowthApplication(
        commanderID: 77,
        award: NativeGeneralGrowthAward(militaryGain: 2, nobilityGain: 0, before: before, after: after),
        rankHPBonusBefore: 0,
        rankHPBonusAfter: 40
    )
    var state = try gameplayFixture(
        enemyCell: (2, 1),
        playerCommanderID: 77,
        combatGrowthHandler: { commanderID, _, _, _, _ in commanderID == 77 ? application : nil }
    )
    state.selectUnit(0)
    let hpBefore = state.units[0]!.maxHP
    let result = try state.attackSelected(target: 1, rng: { 0 })
    #expect(result.generalGrowth.count == 1)
    #expect(result.generalGrowth[0].rankHPDelta == 40)
    #expect(state.units[0]!.maxHP == hpBefore + 40)
    #expect(state.units[0]!.playerCommanderHPBonus == 40)
}

@Test func playerPrimaryAttackCollectsBattleMedalUsingSameRNGStream() throws {
    var state = try gameplayFixture(playerArmy: "Cavalry", enemyCell: (2, 1), enemyHP: 200)
    state.selectUnit(0)
    let result = try state.attackSelected(target: 1, rng: { 0.999999 })
    #expect(result.damage >= 35)
    #expect(result.collectedMedals == 1)
}

@Test func playerCounterDuringAITurnCanCollectBattleMedal() throws {
    var state = try gameplayFixture(playerArmy: "Cavalry", playerHP: 200, enemyCell: (2, 1), enemyHP: 200)
    _ = try state.endPlayerTurn()
    let result = try state.attackAIUnit(attacker: 1, target: 0, rng: { 0.999999 })
    #expect(result.counterDamage != nil)
    #expect((result.counterDamage ?? 0) >= 35)
    #expect(result.collectedMedals == 1)
}

@Test func nativeGameplayEndedProjectionMatchesPhase() throws {
    var state = try gameplayFixture(enemyCell: (4, 4))
    #expect(!state.ended)
    state.restoreRuntimeState(
        round: 3,
        ended: true,
        restoredUnits: state.unitOrder.compactMap { state.units[$0] },
        restoredObjects: state.objects.values.sorted { $0.index < $1.index }
    )
    #expect(state.ended)
    #expect(state.phase == .ended)
}
