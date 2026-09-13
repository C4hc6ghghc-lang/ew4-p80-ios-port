import Foundation
import Testing
@testable import EW4NativeCore

@Test func nativeDefenseChoicesKeepRecoveredCostsAndTypes() throws {
    let json = """
    {"Trench":{"name":"Trench","id":41,"type":"installation","price":30,"industry":10,"grade":"0"},"Fence":{"name":"Fence","id":42,"type":"installation","price":20,"industry":15,"grade":"0"},"Bunker":{"name":"Bunker","id":43,"type":"installation","price":10,"industry":25,"grade":"0"},"Small Fortress":{"name":"Small Fortress","id":37,"type":"fortress","price":120,"industry":10,"army":"Small Fortress","grade":"0","buildround":2},"Fortress":{"name":"Fortress","id":38,"type":"fortress","price":200,"industry":80,"army":"Fortress","grade":"0","buildround":3},"Large Fortress":{"name":"Large Fortress","id":39,"type":"fortress","price":280,"industry":160,"army":"Large Fortress","grade":"0","buildround":4},"Coastal Fort":{"name":"Coastal Fort","id":40,"type":"fortress","price":60,"industry":60,"army":"Coastal Fort","grade":"0","buildround":3}}
    """
    let cards = try JSONDecoder().decode(NativeBuildCardCatalog.self, from: Data(json.utf8))
    let install = NativeBattleDefenseCore.installationChoices(cards: cards)
    #expect(install.map(\.money) == [30,20,10])
    #expect(install.map(\.industry) == [10,15,25])
    let forts = NativeBattleDefenseCore.fortressChoices(cards: cards, coastal: true)
    #expect(forts.map(\.key) == ["Small Fortress","Fortress","Large Fortress","Coastal Fort"])
    #expect(forts.map(\.buildRounds) == [2,3,4,3])
}
