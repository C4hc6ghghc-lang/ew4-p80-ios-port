import Foundation

/// Shared recovered SceneShop geometry/scroll contract.
///
/// Evidence:
/// - original_layout-568h.xml `form_shop`: 7 columns, rowh=45, hbland/vbland=4,
///   14 seller slots and the original player ItemBank.
/// - mature P39 `r14_native_forms.css`: `.shop-buyer-grid` is a 345x98
///   vertical scrolling grid with 45x45 cells and a 4px gap.
public enum NativeShopFormCore {
    public static let columns = 7
    public static let slotSize = 45.0
    public static let gap = 4.0
    public static let buyerRows = 4
    public static let sellerRows = 2

    // Keep the already-frozen Native screen placement; only the internal grid
    // semantics are centralized here.
    public static let sellerOrigin = NativePoint(x: 152, y: 58)
    public static let buyerOrigin = NativePoint(x: 72, y: 191)
    public static let buyerViewport = NativeRect(x: 72, y: 191, width: 345, height: 96)

    public static var buyerContentHeight: Double {
        Double(buyerRows) * slotSize + Double(buyerRows - 1) * gap
    }

    public static var maxBuyerScroll: Double {
        max(0, buyerContentHeight - buyerViewport.size.height)
    }

    public static func sellerRect(index: Int) -> NativeRect? {
        guard index >= 0, index < NativeBattleShopCore.sellerSize else { return nil }
        let col = index % columns
        let row = index / columns
        return NativeRect(
            x: sellerOrigin.x + Double(col) * (slotSize + gap),
            y: sellerOrigin.y + Double(row) * (slotSize + gap),
            width: slotSize,
            height: slotSize
        )
    }

    public static func buyerRect(index: Int, scroll: Double) -> NativeRect? {
        guard index >= 0, index < NativeItemInventoryBank.size else { return nil }
        let col = index % columns
        let row = index / columns
        return NativeRect(
            x: buyerOrigin.x + Double(col) * (slotSize + gap),
            y: buyerOrigin.y + Double(row) * (slotSize + gap) - clampedBuyerScroll(scroll),
            width: slotSize,
            height: slotSize
        )
    }

    public static func clampedBuyerScroll(_ value: Double) -> Double {
        min(max(0, value), maxBuyerScroll)
    }

    public static func buyerScroll(startScroll: Double, startY: Double, currentY: Double) -> Double {
        clampedBuyerScroll(startScroll + (startY - currentY))
    }

    public static func buyerIndex(at point: NativePoint, scroll: Double) -> Int? {
        guard contains(buyerViewport, point) else { return nil }
        for index in 0..<NativeItemInventoryBank.size {
            if let rect = buyerRect(index: index, scroll: scroll), contains(rect, point) { return index }
        }
        return nil
    }

    private static func contains(_ rect: NativeRect, _ point: NativePoint) -> Bool {
        point.x >= rect.origin.x && point.y >= rect.origin.y &&
        point.x <= rect.origin.x + rect.size.width && point.y <= rect.origin.y + rect.size.height
    }
}
