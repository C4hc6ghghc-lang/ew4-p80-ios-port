import Foundation
import Testing
@testable import EW4NativeCore

private func extinctionFixture(
    playerUnits: [(name: String, hp: Int)] = [("Line Infantry", 80)],
    enemyUnits: [(name: String, hp: Int)] = [("Line Infantry", 80)],
    playerFacilities: [String] = ["city"],
    enemyFacilities: [String] = ["city"],
    neutralFacilities: [String] = []
) throws -> NativeBattleGameplayState {
    var units: [[String: Any]] = []
    var objects: [[String: Any]] = []
    var index = 0
    for entry in playerUnits {
        units.append(["index": index, "q": index, "r": 0, "army_id": 1, "army_name": entry.name, "grade": 0, "hp": entry.hp, "max_hp": max(1, entry.hp), "owner": 0])
        index += 1
    }
    for entry in enemyUnits {
        units.append(["index": index, "q": index, "r": 1, "army_id": 1, "army_name": entry.name, "grade": 0, "hp": entry.hp, "max_hp": max(1, entry.hp), "owner": 1])
        index += 1
    }
    var objectIndex = 0
    for type in playerFacilities {
        objects.append(["index": objectIndex, "q": objectIndex, "r": 2, "construction_id": 1, "construction_type": type, "level": 1, "extra": 0, "owner": 0]); objectIndex += 1
    }
    for type in enemyFacilities {
        objects.append(["index": objectIndex, "q": objectIndex, "r": 3, "construction_id": 1, "construction_type": type, "level": 1, "extra": 0, "owner": 1]); objectIndex += 1
    }
    for type in neutralFacilities {
        objects.append(["index": objectIndex, "q": objectIndex, "r": 4, "construction_id": 1, "construction_type": type, "level": 1, "extra": 0, "owner": 2]); objectIndex += 1
    }

    let battleObject: [String: Any] = [
        "file": "conquest-fixture.btl", "name_key": "fixture", "name_cn": "fixture", "title_cn": "fixture",
        "header": ["version": 1, "map_id": 1, "origin_x": 0, "origin_y": 0, "width": 12, "height": 8, "country_count": 3, "object_count": objects.count, "unit_count": units.count, "raw": []],
        "countries": [
            ["index": 0, "code": "fra", "relation_hint": 2, "raw_u32_36_180": []],
            ["index": 1, "code": "gbr", "relation_hint": 1, "raw_u32_36_180": []],
            ["index": 2, "code": "oth", "relation_hint": 4, "raw_u32_36_180": []]
        ],
        "relation_groups": ["0": 2, "1": 1, "2": 4],
        "ownership": [], "player_owner_default": 0, "owner_index_bias": 0,
        "units": units, "objects": objects
    ]
    let battleData = try JSONSerialization.data(withJSONObject: battleObject)
    let battle = try JSONDecoder().decode(BattleRecord.self, from: battleData)

    let cells = Array(repeating: ["terrain_id": 0, "variant": 0, "type": "plain"] as [String: Any], count: 96)
    let worldObject: [String: Any] = [
        "terrains": [["id": 0, "name": "plain", "type": "plain"]],
        "terrain_types": ["plain": ["type": "plain", "movementcost": 3]],
        "worlds": ["europe": ["map_id": 1, "width": 12, "height": 8, "magic": "x", "version": 1, "cells": cells]]
    ]
    let worldData = try JSONSerialization.data(withJSONObject: worldObject)
    let worlds = try JSONDecoder().decode(WorldMapsFile.self, from: worldData)

    let stat = { (name: String, type: String) -> [String: Any] in
        ["name": name, "grade": 0, "type": type, "strength": 80, "movement": type == "fort" ? 0 : 6, "minatk": 1, "maxatk": 7, "weapon": "gun", "minatkrange": 1, "maxatkrange": 1, "consumption": 5]
    }
    let statsObject: [String: Any] = [
        "fra": ["Line Infantry|0": stat("Line Infantry", "infantry"), "Privateer|0": stat("Privateer", "warship"), "Fortress|0": stat("Fortress", "fort")],
        "gbr": ["Line Infantry|0": stat("Line Infantry", "infantry"), "Privateer|0": stat("Privateer", "warship"), "Fortress|0": stat("Fortress", "fort")],
        "others": [:]
    ]
    let statsData = try JSONSerialization.data(withJSONObject: statsObject)
    let stats = try JSONDecoder().decode(ArmyStatsCatalog.self, from: statsData)
    let session = NativeBattleSession(battle: battle, worldName: "europe", world: worlds.worlds["europe"]!)
    return NativeBattleGameplayState(session: session, terrainTypes: worlds.terrainTypes, armyStats: stats, commanders: [:], mode: .conquest, playerOwner: 0)
}

@Test func conquestNavyAndFortDoNotPreserveNationAfterLandAndFacilitiesAreGone() throws {
    let state = try extinctionFixture(
        playerUnits: [("Line Infantry", 80)],
        enemyUnits: [("Privateer", 100), ("Fortress", 100)],
        playerFacilities: ["city"],
        enemyFacilities: []
    )
    let enemy = NativeConquestExtinctionCore.countryStatus(state, owner: 1)
    #expect(!enemy.landArmyAlive)
    #expect(!enemy.landFacilitiesHeld)
    #expect(!enemy.portsHeld)
    #expect(enemy.defeated)
    if case .victory(let reason, let owners) = NativeConquestExtinctionCore.outcome(state) {
        #expect(reason == "hostile-powers-extinct")
        #expect(owners == [1])
    } else {
        Issue.record("expected conquest victory")
    }
}

@Test func conquestPortOrLandFacilityOrArtilleryEachPreservesNation() throws {
    let portState = try extinctionFixture(enemyUnits: [("Privateer", 100)], enemyFacilities: ["port"])
    #expect(!NativeConquestExtinctionCore.countryStatus(portState, owner: 1).defeated)
    let farmState = try extinctionFixture(enemyUnits: [("Privateer", 100)], enemyFacilities: ["farmland"])
    #expect(!NativeConquestExtinctionCore.countryStatus(farmState, owner: 1).defeated)
    let artilleryState = try extinctionFixture(enemyUnits: [("Line Infantry", 1)], enemyFacilities: [])
    #expect(!NativeConquestExtinctionCore.countryStatus(artilleryState, owner: 1).defeated)
}

@Test func conquestPlayerCanBeDefeatedWithOnlyNavyRemainingAndNeutralIsExcluded() throws {
    let state = try extinctionFixture(
        playerUnits: [("Privateer", 100)],
        enemyUnits: [("Line Infantry", 80)],
        playerFacilities: [],
        enemyFacilities: ["city"],
        neutralFacilities: ["city"]
    )
    #expect(NativeConquestExtinctionCore.countryStatus(state, owner: 0).defeated)
    #expect(NativeConquestExtinctionCore.hostileOwners(state) == [1])
    if case .defeat(let reason, let owner, _) = NativeConquestExtinctionCore.outcome(state) {
        #expect(reason == "country-extinction")
        #expect(owner == 0)
    } else {
        Issue.record("expected conquest defeat")
    }
}
