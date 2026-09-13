import Foundation
import Testing
@testable import EW4NativeCore

@Test func buildingKeyMatchesRecoveredRules() {
    let city = BattleObject(index: 1, q: 2, r: 3, constructionID: 1, constructionType: "city", level: 8, extra: 0, owner: 0)
    #expect(NativeBuildingVisualResolver.spriteKey(object: city, countryCode: "fra") == "city_west_lv7.png")
    #expect(NativeBuildingVisualResolver.spriteKey(object: city, countryCode: "rus") == "city_east_lv7.png")
    let farm = BattleObject(index: 2, q: 2, r: 3, constructionID: 4, constructionType: "farmland", level: 2, extra: 0, owner: 0)
    #expect(NativeBuildingVisualResolver.spriteKey(object: farm, countryCode: "fra") == "farm_2_lv2.png")
}
