import Foundation
import Testing
@testable import EW4NativeCore

@Test func battleGameplayMarkEndedClearsInteractionStateAndStaysEnded() throws {
    let battles = try ResourceLoader.decode(BattlesRuntimeFile.self, from: TestResourcePaths.data("battles_runtime.json"))
    let worlds = try ResourceLoader.decode(WorldMapsFile.self, from: TestResourcePaths.data("worldmaps.json"))
    let stats = try ResourceLoader.decode(ArmyStatsCatalog.self, from: TestResourcePaths.data("army_stats.json"))
    let battle = try #require(battles.battles.first(where: { $0.file == "campaign1_01.btl" }))
    let worldName = battle.header.mapID == 2 ? "america" : "europe"
    let world = try #require(worlds.worlds[worldName])
    let session = NativeBattleSession(battle: battle, worldName: worldName, world: world)
    var gameplay = NativeBattleGameplayState(
        session: session,
        terrainTypes: worlds.terrainTypes,
        armyStats: stats,
        commanders: [:],
        mode: .campaign,
        playerOwner: battle.playerOwnerDefault
    )
    if let playerIndex = gameplay.unitOrder.first(where: { gameplay.units[$0]?.owner == gameplay.playerOwner }) {
        gameplay.selectUnit(playerIndex)
    }
    gameplay.markEnded()
    #expect(gameplay.ended)
    #expect(gameplay.phase == .ended)
    #expect(gameplay.selectedUnitIndex == nil)
    #expect(gameplay.reachable.isEmpty)
    #expect(gameplay.undo == nil)
}
