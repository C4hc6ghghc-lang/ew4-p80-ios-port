import Testing
@testable import EW4NativeCore

struct NativeBattleCommerceCoreTests {
    @Test func nativeQuotesMatchRecoveredTables() {
        #expect(NativeBattleCommerceCore.tradeRate(business: 5) == 1.0)
        #expect(NativeBattleCommerceCore.tradeRate(business: 0) == 3.0)
        let buy = NativeBattleCommerceCore.buyQuote(index: 1, business: 3)
        #expect(buy?.pay == 90)
        #expect(buy?.receive == 10)
        #expect(buy?.receiveResource == .industry)
        let sell = NativeBattleCommerceCore.sellQuote(index: 3, business: 3)
        #expect(sell?.pay == 450)
        #expect(sell?.receive == 50)
        #expect(sell?.payResource == .food)
    }

    @Test func quoteApplicationIsAtomic() {
        var resources = CountryResources(money: 89, industry: 7, food: 11)
        let quote = NativeBattleCommerceCore.buyQuote(index: 1, business: 3)!
        #expect(!NativeBattleCommerceCore.apply(quote, to: &resources))
        #expect(resources == CountryResources(money: 89, industry: 7, food: 11))
        resources.money = 90
        #expect(NativeBattleCommerceCore.apply(quote, to: &resources))
        #expect(resources == CountryResources(money: 0, industry: 17, food: 11))
    }
}
