import Testing
@testable import EW4NativeCore

@Test func buildingUpgradeCostsMatchRecoveredNativeTables() {
    #expect(NativeBattleConstructionCore.upgradeCost(type: "city", architecture: false) == .init(money: 65, industry: 0, discounted: false))
    #expect(NativeBattleConstructionCore.upgradeCost(type: "industry", architecture: true) == .init(money: 36, industry: 12, discounted: true))
    #expect(NativeBattleConstructionCore.upgradeCost(type: "stable", architecture: true) == .init(money: 48, industry: 3, discounted: true))
    #expect(NativeBattleConstructionCore.upgradeCost(type: "port", architecture: true) == .init(money: 45, industry: 6, discounted: true))
}

@Test func buildingUpgradeIsAtomicAndIncrementsLevel() {
    let levels = (0...2).map { NativeConstructionLevelDefinition(idx: $0, image: nil, tax: 0, industry: 0, food: 0, supply: 0, avoid: nil, recruit: nil) }
    let catalog: NativeConstructionCatalog = ["city": .init(maxlevel: 2, levels: levels)]
    var object = NativeBattleObjectState(index: 1, q: 1, r: 1, constructionID: 1, constructionType: "city", level: 1, extra: 0, owner: 0)
    var resources = CountryResources(money: 64, industry: 0, food: 0)
    #expect(NativeBattleConstructionCore.upgrade(object: &object, resources: &resources, constructions: catalog, architecture: false) == nil)
    #expect(object.level == 1)
    #expect(resources.money == 64)
    resources.money = 100
    let result = NativeBattleConstructionCore.upgrade(object: &object, resources: &resources, constructions: catalog, architecture: false)
    #expect(result?.money == 65)
    #expect(object.level == 2)
    #expect(resources.money == 35)
}
