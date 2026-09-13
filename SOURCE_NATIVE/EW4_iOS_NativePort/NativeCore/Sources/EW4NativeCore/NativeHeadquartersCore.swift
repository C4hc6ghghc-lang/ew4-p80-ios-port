import Foundation

public enum NativeHeadquartersAction: Equatable, Sendable {
    case back
    case princess
    case shop
    case academy
    case generalAt(index: Int)
}

/// Original SceneDeployGeneral / form_deploygeneral geometry recovered from the APK.
/// This is an outer-screen contract only. It deliberately does not own battle deployment.
public enum NativeHeadquartersCore {
    public static let princessButton = NativeRect(x: 20, y: 30, width: 70, height: 40)
    public static let shopButton = NativeRect(x: 249, y: 30, width: 70, height: 40)
    public static let academyButton = NativeRect(x: 480, y: 30, width: 70, height: 40)
    public static let countIcon = NativeRect(x: 255, y: 43, width: 29, height: 21)
    public static let generalGrid = NativeRect(x: 30, y: 85, width: 508, height: 204)
    public static let backButton = NativeRect(x: 0, y: 275, width: 45, height: 45)
    public static let deployButton = NativeRect(x: 478, y: 294, width: 59, height: 26)

    public static let columns = 6
    public static let cardWidth = 78.0
    public static let cardHeight = 99.0
    public static let columnGap = 8.0
    public static let rowGap = 6.0
    public static let rowStride = cardHeight + rowGap

    /// Original princess order from the mature P39 controller.
    public static let princessOrder = [202, 204, 201, 203, 205, 206, 207, 208]
    public static let princessPanel = NativeRect(x: 50, y: 10, width: 468, height: 300)

    public static func ownedGeneralIDs(profile: NativePlayerProfile, commanders: [Int: Commander]) -> [Int] {
        let princesses = Set(NativePlayerProfile.princessIDs)
        return profile.ownedCommanderIDs
            .filter { !princesses.contains($0) && commanders[$0] != nil }
            .sorted { lhs, rhs in
                let a = commanders[lhs]
                let b = commanders[rhs]
                if a?.star != b?.star { return (a?.star ?? 0) > (b?.star ?? 0) }
                return lhs < rhs
            }
    }

    public static func contentHeight(count: Int) -> Double {
        let rows = max(1, Int(ceil(Double(max(0, count)) / Double(columns))))
        return Double(rows) * cardHeight + Double(max(0, rows - 1)) * rowGap
    }

    public static func maxScroll(count: Int) -> Double {
        max(0, contentHeight(count: count) - generalGrid.size.height)
    }

    public static func clampedScroll(_ value: Double, count: Int) -> Double {
        min(max(0, value), maxScroll(count: count))
    }

    public static func cardRect(index: Int, scroll: Double = 0) -> NativeRect {
        let safe = max(0, index)
        let col = safe % columns
        let row = safe / columns
        return NativeRect(
            x: generalGrid.origin.x + Double(col) * (cardWidth + columnGap),
            y: generalGrid.origin.y + Double(row) * rowStride - scroll,
            width: cardWidth,
            height: cardHeight
        )
    }

    public static func upgradeHotspotRect(index: Int, scroll: Double = 0) -> NativeRect {
        let card = cardRect(index: index, scroll: scroll)
        return NativeRect(x: card.origin.x + card.size.width - 20, y: card.origin.y + 1, width: 19, height: 19)
    }

    public static func princessRect(index: Int) -> NativeRect {
        let safe = max(0, min(princessOrder.count - 1, index))
        let row = safe / 4
        let col = safe % 4
        return NativeRect(
            x: princessPanel.origin.x + [50.0, 148.0, 246.0, 344.0][col],
            y: princessPanel.origin.y + (row == 0 ? 35.0 : 164.0),
            width: 78,
            height: 122
        )
    }

    public static func action(at point: NativePoint, generalCount: Int, scroll: Double = 0) -> NativeHeadquartersAction? {
        if contains(backButton, point) { return .back }
        if contains(princessButton, point) { return .princess }
        if contains(shopButton, point) { return .shop }
        if contains(academyButton, point) { return .academy }
        guard contains(generalGrid, point) else { return nil }
        for index in 0..<max(0, generalCount) {
            let rect = cardRect(index: index, scroll: clampedScroll(scroll, count: generalCount))
            if contains(rect, point), intersects(rect, generalGrid) { return .generalAt(index: index) }
        }
        return nil
    }

    private static func contains(_ rect: NativeRect, _ point: NativePoint) -> Bool {
        point.x >= rect.origin.x && point.y >= rect.origin.y &&
        point.x <= rect.origin.x + rect.size.width && point.y <= rect.origin.y + rect.size.height
    }

    private static func intersects(_ a: NativeRect, _ b: NativeRect) -> Bool {
        let ax2 = a.origin.x + a.size.width, ay2 = a.origin.y + a.size.height
        let bx2 = b.origin.x + b.size.width, by2 = b.origin.y + b.size.height
        return a.origin.x < bx2 && ax2 > b.origin.x && a.origin.y < by2 && ay2 > b.origin.y
    }
}
