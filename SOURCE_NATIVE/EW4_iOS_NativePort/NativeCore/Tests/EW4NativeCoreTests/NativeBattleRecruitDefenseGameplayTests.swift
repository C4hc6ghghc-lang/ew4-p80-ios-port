import Foundation
import Testing
@testable import EW4NativeCore

private func p55ActionGameplayFixture() throws -> NativeBattleGameplayState {
    let battleJSON = """
    {
      "file":"tutorials1.btl","name_key":"fixture","name_cn":"fixture","title_cn":"fixture",
      "header":{"version":1,"map_id":1,"origin_x":0,"origin_y":0,"width":5,"height":5,"country_count":1,"object_count":1,"unit_count":1,"raw":[]},
      "countries":[{"index":0,"code":"fra","relation_hint":2,"raw_u32_36_180":[]}],
      "relation_groups":{"0":2},"ownership":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"player_owner_default":0,"owner_index_bias":0,
      "units":[{"index":0,"q":1,"r":1,"army_id":1,"army_name":"Line Infantry","grade":0,"hp":80,"max_hp":80,"commander_id":null,"owner":0}],
      "objects":[{"index":0,"q":2,"r":2,"construction_id":1,"construction_type":"city","level":0,"extra":0,"owner":0}]
    }
    """
    let battle = try JSONDecoder().decode(BattleRecord.self, from: Data(battleJSON.utf8))
    let cellJSON = #"{"terrain_id":0,"variant":0,"type":"plain"}"#
    let worldJSON = """
    {"terrains":[{"id":0,"name":"plain","type":"plain"}],"terrain_types":{"plain":{"type":"plain","movementcost":3}},"worlds":{"europe":{"map_id":1,"width":5,"height":5,"magic":"x","version":1,"cells":[
    \(Array(repeating: cellJSON, count: 25).joined(separator: ","))
    ]}}}
    """
    let worlds = try JSONDecoder().decode(WorldMapsFile.self, from: Data(worldJSON.utf8))
    let statsJSON = """
    {"fra":{
      "Line Infantry|0":{"name":"Line Infantry","grade":0,"type":"infantry","strength":80,"movement":6,"minatk":1,"maxatk":7,"weapon":"gun","minatkrange":1,"maxatkrange":1,"consumption":5},
      "Militia|0":{"name":"Militia","grade":0,"type":"infantry","strength":60,"movement":5,"minatk":1,"maxatk":5,"weapon":"gun","minatkrange":1,"maxatkrange":1,"consumption":4},
      "Small Fortress|0":{"name":"Small Fortress","grade":0,"type":"fort","strength":180,"movement":0,"minatk":3,"maxatk":7,"weapon":"gun","minatkrange":1,"maxatkrange":2,"consumption":0}
    },"others":{}}
    """
    let stats = try JSONDecoder().decode(ArmyStatsCatalog.self, from: Data(statsJSON.utf8))
    let constructionJSON = #"{"city":{"maxlevel":6,"levels":[{"idx":0,"image":null,"tax":0,"industry":0,"food":0,"supply":0,"recruit":[{"name":"Militia","grade":"0"}]}]}}"#
    let constructions = try JSONDecoder().decode(NativeConstructionCatalog.self, from: Data(constructionJSON.utf8))
    let session = NativeBattleSession(battle: battle, worldName: "europe", world: worlds.worlds["europe"]!)
    return NativeBattleGameplayState(session: session, terrainTypes: worlds.terrainTypes, armyStats: stats, commanders: [:], constructions: constructions, mode: .tutorial, playerOwner: 0)
}

@Test func p55RecruitCommitsCostPlayerHPBuffAndSpentActionStateAtomically() throws {
    var gameplay = try p55ActionGameplayFixture()
    var resources = CountryResources(money: 100, industry: 50, food: 0)
    let cap = NativeRecruitDefinition(name: "Militia", grade: 0)
    let cardJSON = #"{"id":1,"army":"Militia","grade":0,"price":15,"industry":3,"image":null,"intro":null}"#
    let card = try JSONDecoder().decode(NativeRecruitCardDefinition.self, from: Data(cardJSON.utf8))
    let index = gameplay.recruit(at: 0, recruit: cap, grade: 0, card: card, trainingLevel: 0, resources: &resources)
    #expect(index != nil)
    #expect(resources.money == 85 && resources.industry == 47)
    let unit = gameplay.units[index!]!
    #expect(unit.armyID == 0)
    #expect(unit.maxHP == 180) // original 60 + locked player +120 HP rule
    #expect(unit.hp == 180 && unit.moved && unit.attacked)
    #expect(gameplay.recruit(at: 0, recruit: cap, grade: 0, card: card, trainingLevel: 0, resources: &resources) == nil)
    #expect(resources.money == 85 && resources.industry == 47)
}

@Test func p55DefenseBuildsInstallationAndOneFortressPerRound() throws {
    var gameplay = try p55ActionGameplayFixture()
    var resources = CountryResources(money: 500, industry: 500, food: 0)
    let trench = NativeDefenseChoice(key: "Trench", type: "installation", money: 30, industry: 10, armyName: nil, grade: 0, buildRounds: 0, image: nil, intro: nil)
    #expect(gameplay.buildInstallation(0, choice: trench, resources: &resources) != nil)
    #expect(gameplay.installations.first?.type == "trench")
    #expect(gameplay.units[0]?.attacked == true)
    #expect(resources.money == 470 && resources.industry == 490)

    let fort = NativeDefenseChoice(key: "Small Fortress", type: "fortress", money: 120, industry: 10, armyName: "Small Fortress", grade: 0, buildRounds: 2, image: nil, intro: nil)
    let ownership = Array(repeating: 0, count: 25)
    let first = gameplay.buildFortress(at: HexCell(q: 3, r: 3), choice: fort, ownership: ownership, trainingLevel: 0, resources: &resources)
    #expect(first != nil)
    #expect(gameplay.units[first!]?.underConstruction == true)
    #expect(gameplay.units[first!]?.constructionRoundsRemaining == 2)
    #expect(gameplay.units[first!]?.maxHP == 300)
    let before = resources
    #expect(gameplay.buildFortress(at: HexCell(q: 4, r: 4), choice: fort, ownership: ownership, trainingLevel: 0, resources: &resources) == nil)
    #expect(resources == before)
}
