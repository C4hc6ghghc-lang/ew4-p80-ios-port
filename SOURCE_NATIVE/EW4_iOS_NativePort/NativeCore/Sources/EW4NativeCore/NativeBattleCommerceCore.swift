import Foundation

public enum NativeMarketResource: String, Equatable, Sendable {
    case money
    case industry
    case food
}

public struct NativeMarketQuote: Equatable, Sendable {
    public enum Direction: String, Equatable, Sendable { case buy, sell }
    public let direction: Direction
    public let index: Int
    public let rate: Double
    public let payResource: NativeMarketResource
    public let pay: Int
    public let receiveResource: NativeMarketResource
    public let receive: Int

    public init(direction: Direction, index: Int, rate: Double, payResource: NativeMarketResource, pay: Int, receiveResource: NativeMarketResource, receive: Int) {
        self.direction = direction
        self.index = index
        self.rate = rate
        self.payResource = payResource
        self.pay = max(0, pay)
        self.receiveResource = receiveResource
        self.receive = max(0, receive)
    }
}

/// Native form_exchange parity. Values mirror `native_commerce_core.js`, which in
/// turn was recovered from libeuropean-war-4.so.
public enum NativeBattleCommerceCore {
    public static let marketMoney = [10, 50, 10, 50]
    public static let marketGoods = [2, 10, 50, 250]

    public static func businessStars(_ value: Int) -> Int { max(0, min(5, value)) }

    /// Native helper: `1.0 + (5 - business) * 0.4`.
    public static func tradeRate(business: Int) -> Double {
        1.0 + Double(5 - businessStars(business)) * 0.4
    }

    public static func resource(for index: Int) -> NativeMarketResource {
        index <= 1 ? .industry : .food
    }

    public static func buyQuote(index: Int, business: Int) -> NativeMarketQuote? {
        guard marketMoney.indices.contains(index) else { return nil }
        let rate = tradeRate(business: business)
        return NativeMarketQuote(
            direction: .buy,
            index: index,
            rate: rate,
            payResource: .money,
            pay: Int(Double(marketMoney[index]) * rate),
            receiveResource: resource(for: index),
            receive: marketGoods[index]
        )
    }

    public static func sellQuote(index: Int, business: Int) -> NativeMarketQuote? {
        guard marketMoney.indices.contains(index) else { return nil }
        let rate = tradeRate(business: business)
        return NativeMarketQuote(
            direction: .sell,
            index: index,
            rate: rate,
            payResource: resource(for: index),
            pay: Int(Double(marketGoods[index]) * rate),
            receiveResource: .money,
            receive: marketMoney[index]
        )
    }

    public static func canApply(_ quote: NativeMarketQuote, to resources: CountryResources) -> Bool {
        amount(of: quote.payResource, in: resources) >= quote.pay
    }

    @discardableResult
    public static func apply(_ quote: NativeMarketQuote, to resources: inout CountryResources) -> Bool {
        guard canApply(quote, to: resources) else { return false }
        setAmount(amount(of: quote.payResource, in: resources) - quote.pay, of: quote.payResource, in: &resources)
        setAmount(amount(of: quote.receiveResource, in: resources) + quote.receive, of: quote.receiveResource, in: &resources)
        return true
    }

    public static func amount(of resource: NativeMarketResource, in resources: CountryResources) -> Int {
        switch resource {
        case .money: return resources.money
        case .industry: return resources.industry
        case .food: return resources.food
        }
    }

    private static func setAmount(_ value: Int, of resource: NativeMarketResource, in resources: inout CountryResources) {
        let value = max(0, value)
        switch resource {
        case .money: resources.money = value
        case .industry: resources.industry = value
        case .food: resources.food = value
        }
    }
}
