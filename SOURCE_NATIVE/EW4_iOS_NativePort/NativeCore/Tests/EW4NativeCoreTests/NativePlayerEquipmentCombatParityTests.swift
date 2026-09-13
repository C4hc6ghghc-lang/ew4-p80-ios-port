import Foundation
import Testing
@testable import EW4NativeCore

private func p46EquipmentCombatFixture(
    equipment: [Int: [Int]]
) throws -> NativeBattleGameplayState {
    let battleJSON = """
    {
      "file":"equipment-fixture.btl","name_key":"fixture","name_cn":"fixture","title_cn":"fixture",
      "header":{"version":1,"map_id":1,"origin_x":0,"origin_y":0,"width":5,"height":5,"country_count":2,"object_count":0,"unit_count":4,"raw":[]},
      "countries":[
        {"index":0,"code":"fra","relation_hint":2,"raw_u32_36_180":[]},
        {"index":1,"code":"gbr","relation_hint":1,"raw_u32_36_180":[]}
      ],
      "relation_groups":{"0":2,"1":1},"ownership":[],"player_owner_default":0,"owner_index_bias":0,
      "units":[
        {"index":0,"q":1,"r":1,"army_id":1,"army_name":"Line Infantry","grade":0,"hp":80,"max_hp":80,"commander_id":1,"owner":0},
        {"index":1,"q":1,"r":2,"army_id":1,"army_name":"Line Infantry","grade":0,"hp":80,"max_hp":80,"commander_id":2,"owner":0},
        {"index":2,"q":2,"r":1,"army_id":1,"army_name":"Line Infantry","grade":0,"hp":80,"max_hp":80,"commander_id":3,"owner":1},
        {"index":3,"q":2,"r":2,"army_id":1,"army_name":"Line Infantry","grade":0,"hp":80,"max_hp":80,"commander_id":4,"owner":1}
      ],
      "objects":[]
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
      "fra":{"Line Infantry|0":{"name":"Line Infantry","grade":0,"type":"infantry","strength":80,"movement":6,"minatk":1,"maxatk":7,"weapon":"gun","minatkrange":1,"maxatkrange":1,"consumption":5}},
      "gbr":{"Line Infantry|0":{"name":"Line Infantry","grade":0,"type":"infantry","strength":80,"movement":6,"minatk":1,"maxatk":7,"weapon":"gun","minatkrange":1,"maxatkrange":1,"consumption":5}},
      "others":{}
    }
    """
    let stats = try JSONDecoder().decode(ArmyStatsCatalog.self, from: Data(statsJSON.utf8))
    let items = try ResourceLoader.decode(NativeItemEffectCatalog.self, from: TestResourcePaths.data("items.json"))
    let provider: @Sendable (Int, Bool) -> NativeEffectiveCommander? = { id, _ in
        NativeEffectiveCommander(
            id: id,
            infantry: 0,
            cavalry: 0,
            artillery: 0,
            warship: 0,
            fort: 0,
            business: 0,
            movement: 0,
            training: 0,
            skillIDs: [],
            equippedItemIDs: equipment[id] ?? [],
            rankLevel: 0,
            nobilityLevel: 0,
            rankHPBonus: 0,
            nobilityHealCap: 0
        )
    }
    let session = NativeBattleSession(battle: battle, worldName: "europe", world: worlds.worlds["europe"]!)
    return NativeBattleGameplayState(
        session: session,
        terrainTypes: worlds.terrainTypes,
        armyStats: stats,
        commanders: [:],
        itemEffects: items,
        effectiveCommanderProvider: provider,
        mode: .campaign,
        playerOwner: 0
    )
}

@Test func weaponArmorAndAdjacentFlagsMatchP39CombatEquipmentPipeline() throws {
    let baseline = try p46EquipmentCombatFixture(equipment: [:])
    let equipped = try p46EquipmentCombatFixture(equipment: [
        1: [20], // Ferguson Rifle: function 11, +6 infantry fixed damage
        2: [48], // Dragon Flag: function 14, +2 adjacent attack aura
        3: [18], // Combat Uniform: function 10, -4 infantry damage
        4: [49]  // Lions Flag: function 15, -2 adjacent defense aura
    ])
    let a0 = try #require(baseline.units[0])
    let d0 = try #require(baseline.units[2])
    let a1 = try #require(equipped.units[0])
    let d1 = try #require(equipped.units[2])
    let plain = try baseline.resolveCombatDamage(attacker: a0, defender: d0, rng: { 0.41 })
    let modified = try equipped.resolveCombatDamage(attacker: a1, defender: d1, rng: { 0.41 })
    #expect(modified.bounds.fixedBonus == 8)
    #expect(modified.notes.contains("armor-6"))
    #expect(modified.value == plain.value + 2)
}

@Test func snareDrumFunction4ForcesFullFormationAtLowHP() throws {
    let baseline = try p46EquipmentCombatFixture(equipment: [:])
    let equipped = try p46EquipmentCombatFixture(equipment: [1: [7]])
    var a0 = try #require(baseline.units[0])
    var a1 = try #require(equipped.units[0])
    let d0 = try #require(baseline.units[2])
    let d1 = try #require(equipped.units[2])
    a0.hp = 5
    a1.hp = 5
    let plain = try baseline.resolveCombatDamage(attacker: a0, defender: d0, rng: { 0.3 })
    let full = try equipped.resolveCombatDamage(attacker: a1, defender: d1, rng: { 0.3 })
    #expect(plain.bounds.coefficient == 1)
    #expect(full.bounds.coefficient == 5)
    #expect(full.value > plain.value)
}

@Test func armoredCarrierFunction12SuppressesEmbarkedAttackPenalty() throws {
    let baseline = try p46EquipmentCombatFixture(equipment: [:])
    let equipped = try p46EquipmentCombatFixture(equipment: [1: [40]])
    var a0 = try #require(baseline.units[0])
    var a1 = try #require(equipped.units[0])
    let d0 = try #require(baseline.units[2])
    let d1 = try #require(equipped.units[2])
    a0.embarked = true
    a1.embarked = true
    let penalized = try baseline.resolveCombatDamage(attacker: a0, defender: d0, rng: { 0.5 })
    let armored = try equipped.resolveCombatDamage(attacker: a1, defender: d1, rng: { 0.5 })
    #expect(penalized.notes.contains("embarked-penalty"))
    #expect(!armored.notes.contains("embarked-penalty"))
    #expect(armored.value > penalized.value)
}

@Test func counterDamageResultValueMatchesActuallyAppliedP39Multiplier() throws {
    var state = try p46EquipmentCombatFixture(equipment: [:])
    state.selectUnit(0)
    let result = try state.attackSelected(target: 2, rng: { 0.5 })
    let counter = try #require(result.counter)
    let applied = try #require(result.counterDamage)
    #expect(counter.value == applied)
}
