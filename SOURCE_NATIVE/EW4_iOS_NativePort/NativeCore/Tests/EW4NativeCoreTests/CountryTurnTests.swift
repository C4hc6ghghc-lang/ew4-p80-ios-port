import Foundation
import Testing
@testable import EW4NativeCore

@Test func countryTurnCoreFixtureParity() throws {
 let json=#"{"file":"x","name_key":"x","name_cn":"x","title_cn":"x","header":{"version":1,"map_id":1,"origin_x":0,"origin_y":0,"width":1,"height":1,"country_count":3,"object_count":0,"unit_count":0,"raw":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,800,300,500]},"countries":[{"index":0,"code":"fra","relation_hint":2,"raw_u32_36_180":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,100,20,500]},{"index":1,"code":"gbr","relation_hint":1,"raw_u32_36_180":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,100,200,500]},{"index":2,"code":"pie","relation_hint":4,"raw_u32_36_180":[]}],"relation_groups":{"0":2,"1":1,"2":4},"units":[],"objects":[]}"#
 let battle=try JSONDecoder().decode(BattleRecord.self,from:Data(json.utf8))
 #expect(CountryTurnCore.countryResources(battle.countries[0]) == .init(money:100,industry:20,food:500))
 #expect(CountryTurnCore.relation(battle,0,1,mode:.conquest,playerOwner:0) == .hostile)
 #expect(CountryTurnCore.relation(battle,0,2,mode:.conquest,playerOwner:0) == .neutral)
 #expect(CountryTurnCore.aiTurnOrder(battle,livingOwners:[0,1,2],playerOwner:0,mode:.conquest) == [1])
 #expect(CountryTurnCore.relation(battle,0,1,mode:.campaign,playerOwner:0) == .hostile)
}
