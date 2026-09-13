import Foundation

public struct NativeHUDRect: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public func contains(_ point: NativePoint) -> Bool {
        point.x >= x && point.x <= x + width && point.y >= y && point.y <= y + height
    }
}

public enum NativeBattleHUDCore {
    // Recovered directly from original layout-568h.xml form_game.
    public static let undo = NativeHUDRect(x: 0, y: 293, width: 37, height: 37)
    public static let skip = NativeHUDRect(x: 0, y: 293, width: 37, height: 37)
    public static let next = NativeHUDRect(x: 541, y: 293, width: 37, height: 37)
}
