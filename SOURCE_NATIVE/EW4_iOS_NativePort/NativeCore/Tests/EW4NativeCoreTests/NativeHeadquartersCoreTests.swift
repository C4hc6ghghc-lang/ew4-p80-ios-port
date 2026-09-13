import Testing
@testable import EW4NativeCore

@Test func headquartersRecoveredGeometryAndRouting() {
    #expect(NativeHeadquartersCore.princessButton == NativeRect(x: 20, y: 30, width: 70, height: 40))
    #expect(NativeHeadquartersCore.shopButton == NativeRect(x: 249, y: 30, width: 70, height: 40))
    #expect(NativeHeadquartersCore.academyButton == NativeRect(x: 480, y: 30, width: 70, height: 40))
    #expect(NativeHeadquartersCore.generalGrid == NativeRect(x: 30, y: 85, width: 508, height: 204))
    #expect(NativeHeadquartersCore.action(at: .init(x: 55, y: 50), generalCount: 0) == .princess)
    #expect(NativeHeadquartersCore.action(at: .init(x: 280, y: 50), generalCount: 0) == .shop)
    #expect(NativeHeadquartersCore.action(at: .init(x: 510, y: 50), generalCount: 0) == .academy)
}

@Test func headquartersGridKeepsSixColumnOriginalLayoutAndScroll() {
    #expect(NativeHeadquartersCore.cardRect(index: 0) == NativeRect(x: 30, y: 85, width: 78, height: 99))
    #expect(NativeHeadquartersCore.cardRect(index: 5) == NativeRect(x: 460, y: 85, width: 78, height: 99))
    #expect(NativeHeadquartersCore.cardRect(index: 6) == NativeRect(x: 30, y: 190, width: 78, height: 99))
    #expect(NativeHeadquartersCore.maxScroll(count: 18) > 0)
    #expect(NativeHeadquartersCore.clampedScroll(999, count: 18) == NativeHeadquartersCore.maxScroll(count: 18))
    #expect(NativeHeadquartersCore.action(at: .init(x: 50, y: 100), generalCount: 12) == .generalAt(index: 0))
}

@Test func headquartersPrincessOrderMatchesMatureController() {
    #expect(NativeHeadquartersCore.princessOrder == [202, 204, 201, 203, 205, 206, 207, 208])
    #expect(NativeHeadquartersCore.princessRect(index: 0) == NativeRect(x: 100, y: 45, width: 78, height: 122))
    #expect(NativeHeadquartersCore.princessRect(index: 7) == NativeRect(x: 394, y: 174, width: 78, height: 122))
}
