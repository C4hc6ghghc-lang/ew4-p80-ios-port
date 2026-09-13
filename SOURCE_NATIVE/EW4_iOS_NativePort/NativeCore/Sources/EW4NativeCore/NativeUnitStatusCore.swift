import Foundation

public enum NativeUnitRelationVisual: String, Equatable, Sendable {
    case own
    case ally
    case hostile
    case neutral
}

public struct NativeRGB: Equatable, Sendable {
    public let r: Int
    public let g: Int
    public let b: Int
}

public struct NativeHPArc: Equatable, Sendable {
    public let start: Double
    public let sweep: Double
    public let end: Double
    public let radius: Double
    public let width: Double
    public let color: NativeRGB
}

public enum NativeUnitStatusCore {
    public static let hpStartRadians = 2.9845130443573
    public static let hpFullSweepRadians = 3.455751993850178
    public static let hpInnerRadius = 10 * 1.4199999570846558
    public static let hpStrokeRadius = (13.92838827718412 + 20.396078054371138) / 2
    public static let hpStrokeWidth = 20.396078054371138 - 13.92838827718412

    public static func relationVisual(owner: Int, playerOwner: Int, relation: CountryRelation) -> NativeUnitRelationVisual {
        if owner == playerOwner { return .own }
        switch relation {
        case .ally: return .ally
        case .hostile: return .hostile
        case .neutral: return .neutral
        }
    }

    public static func relationSprite(_ visual: NativeUnitRelationVisual) -> String {
        switch visual {
        case .own: return "hpbar_green.png"
        case .ally: return "hpbar_blue.png"
        case .hostile: return "hpbar_red.png"
        case .neutral: return "hpbar_black.png"
        }
    }

    public static func clamp01(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(1, max(0, value))
    }

    public static func hpColor(ratio: Double) -> NativeRGB {
        let ratio = clamp01(ratio)
        if ratio <= 0.5 {
            let q = Int((255 * (1 - 2 * ratio)).rounded(.towardZero))
            return NativeRGB(r: 255, g: 255 - q, b: 0)
        }
        let q = Int((255 * (2 * ratio - 1)).rounded(.towardZero))
        let red = 255 - q
        return NativeRGB(r: red, g: 255, b: 128 - Int((Double(red) / 2).rounded(.towardZero)))
    }

    public static func hpArc(ratio: Double) -> NativeHPArc {
        let ratio = clamp01(ratio)
        let sweep = hpFullSweepRadians * ratio
        return NativeHPArc(
            start: hpStartRadians,
            sweep: sweep,
            end: hpStartRadians + sweep,
            radius: hpStrokeRadius,
            width: hpStrokeWidth,
            color: hpColor(ratio: ratio)
        )
    }

    public static func armyMarkerID(_ armyID: Int) -> Int? {
        (0...21).contains(armyID) ? armyID : nil
    }
}
