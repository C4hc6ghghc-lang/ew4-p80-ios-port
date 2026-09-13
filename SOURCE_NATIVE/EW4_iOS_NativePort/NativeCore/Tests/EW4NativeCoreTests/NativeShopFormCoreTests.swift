import Testing
@testable import EW4NativeCore

@Suite("Native SceneShop grid / scroll parity")
struct NativeShopFormCoreTests {
    @Test func recoveredGridContract() {
        #expect(NativeShopFormCore.columns == 7)
        #expect(NativeShopFormCore.slotSize == 45)
        #expect(NativeShopFormCore.gap == 4)
        #expect(NativeShopFormCore.buyerContentHeight == 192)
        #expect(NativeShopFormCore.maxBuyerScroll == 96)
    }

    @Test func allTwentyEightSlotsRemainFullSizeAndScrollable() {
        let top = NativeShopFormCore.buyerRect(index: 0, scroll: 0)!
        let bottom = NativeShopFormCore.buyerRect(index: 27, scroll: NativeShopFormCore.maxBuyerScroll)!
        #expect(top.size.width == 45 && top.size.height == 45)
        #expect(bottom.size.width == 45 && bottom.size.height == 45)
        #expect(bottom.origin.y == 242)
    }

    @Test func scrollClampsAtBothEnds() {
        #expect(NativeShopFormCore.clampedBuyerScroll(-50) == 0)
        #expect(NativeShopFormCore.clampedBuyerScroll(999) == NativeShopFormCore.maxBuyerScroll)
        #expect(NativeShopFormCore.buyerScroll(startScroll: 0, startY: 240, currentY: 140) == NativeShopFormCore.maxBuyerScroll)
    }

    @Test func clippedRowsCannotReceiveTouchesOutsideViewport() {
        let hiddenPoint = NativePoint(x: 80, y: 300)
        #expect(NativeShopFormCore.buyerIndex(at: hiddenPoint, scroll: 0) == nil)
        let visibleFourthRowPoint = NativePoint(x: 80, y: 250)
        #expect(NativeShopFormCore.buyerIndex(at: visibleFourthRowPoint, scroll: NativeShopFormCore.maxBuyerScroll) == 21)
    }
}
