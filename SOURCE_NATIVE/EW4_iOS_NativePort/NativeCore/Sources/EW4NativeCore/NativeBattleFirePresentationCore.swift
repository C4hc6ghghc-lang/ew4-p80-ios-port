import Foundation

public struct NativeBattleFireFrame: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }
}

public struct NativeBattleFirePlacement: Equatable, Sendable {
    public var offsetX: Double
    public var offsetY: Double
    public var width: Double
    public var height: Double
    public init(offsetX: Double, offsetY: Double, width: Double, height: Double) {
        self.offsetX = offsetX; self.offsetY = offsetY; self.width = width; self.height = height
    }
}

public enum NativeBattleFirePresentationCore {
    public static let frameMilliseconds = 160.0
    public static let renderedHeight = 42.0
    public static let bottomOffset = 17.0
    public static let alpha = 0.86
    public static let atlasWidth = 512.0
    public static let atlasHeight = 1024.0

    // Mature P33/P39 anim_fire_hd.png source rectangles (top-left atlas coordinates).
    public static let frames: [NativeBattleFireFrame] = [
        .init(x: 1, y: 1, width: 108, height: 236),
        .init(x: 110, y: 1, width: 105, height: 230),
        .init(x: 1, y: 238, width: 100, height: 214),
        .init(x: 110, y: 232, width: 98, height: 214),
        .init(x: 216, y: 1, width: 87, height: 202),
        .init(x: 304, y: 1, width: 96, height: 191)
    ]

    public static func frameIndex(cellOrdinal: Int, nowMilliseconds: Double) -> Int {
        let tick = Int(floor(max(0, nowMilliseconds) / frameMilliseconds))
        return (tick + max(0, cellOrdinal)) % frames.count
    }

    public static func placement(frame: NativeBattleFireFrame) -> NativeBattleFirePlacement {
        let safeHeight = max(1, frame.height)
        let width = renderedHeight * frame.width / safeHeight
        // Mature canvas draws from y = cellY - h + 17 to cellY + 17.
        // SpriteKit is y-up, so the frame center sits h/2 - 17 above cell center.
        return .init(offsetX: 0, offsetY: renderedHeight / 2 - bottomOffset, width: width, height: renderedHeight)
    }

    /// SpriteKit texture rect in normalized bottom-left coordinates. The mature
    /// source rectangles above are top-left pixel coordinates.
    public static func normalizedTextureRect(frame: NativeBattleFireFrame) -> NativeRect {
        let x = frame.x / atlasWidth
        let y = (atlasHeight - frame.y - frame.height) / atlasHeight
        let width = frame.width / atlasWidth
        let height = frame.height / atlasHeight
        return NativeRect(
            x: x,
            y: y,
            width: width,
            height: height
        )
    }
}
