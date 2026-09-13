import Foundation

public struct NativeBattleOverlayPlacement: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }
}

public enum NativeBattlefieldOverlayCore {
    public static let nativeAssetScale = 0.5
    public static let flagFrameMilliseconds = 120.0
    public static let flagAnchor = NativePoint(x: -14, y: 43)
    public static let commanderInset = 3.5
    public static let moraleAnchor = NativePoint(x: 9, y: 31)
    public static let moraleHeight = 14.0

    /// A few legacy BTLs use two-letter aliases while the native flag atlas uses
    /// the canonical three-letter country code stored as code2 in the extractor.
    public static func flagCountryCode(_ raw: String) -> String {
        switch raw.lowercased() {
        case "gb": return "gbr"
        case "fr": return "fra"
        case "de": return "pru"
        default: return raw.lowercased()
        }
    }

    public static func flagFrame(unitIndex: Int, nowMilliseconds: Double) -> Int {
        let tick = Int(floor(max(0, nowMilliseconds) / flagFrameMilliseconds))
        return 1 + ((tick + max(0, unitIndex)) % 4)
    }

    public static func flagPolePlacement(refX: Double, refY: Double, width: Double, height: Double) -> NativeBattleOverlayPlacement {
        .init(
            x: flagAnchor.x - refX * nativeAssetScale,
            y: flagAnchor.y + refY * nativeAssetScale,
            width: width * nativeAssetScale,
            height: height * nativeAssetScale
        )
    }

    public static func flagClothPlacement(width: Double, height: Double) -> NativeBattleOverlayPlacement {
        .init(
            x: flagAnchor.x,
            y: flagAnchor.y,
            width: width * nativeAssetScale,
            height: height * nativeAssetScale
        )
    }

    public static func commanderBoardPlacement(refX: Double, refY: Double, width: Double, height: Double) -> NativeBattleOverlayPlacement {
        .init(
            x: -refX * nativeAssetScale,
            y: refY * nativeAssetScale,
            width: width * nativeAssetScale,
            height: height * nativeAssetScale
        )
    }

    public static func commanderPortraitPlacement(board: NativeBattleOverlayPlacement, width: Double, height: Double) -> NativeBattleOverlayPlacement {
        .init(
            x: board.x + commanderInset,
            y: board.y - commanderInset,
            width: width * nativeAssetScale,
            height: height * nativeAssetScale
        )
    }

    public static func moraleSprite(_ morale: Int) -> String? {
        if morale > 0 { return "morale_up.png" }
        if morale <= -3 { return "morale_down3.png" }
        if morale <= -2 { return "morale_down2.png" }
        if morale < 0 { return "morale_down1.png" }
        return nil
    }

    public static func moralePlacement(width: Double, height: Double) -> NativeBattleOverlayPlacement {
        let safeHeight = max(1, height)
        let renderedWidth = moraleHeight * width / safeHeight
        return .init(x: moraleAnchor.x, y: moraleAnchor.y, width: renderedWidth, height: moraleHeight)
    }
}
