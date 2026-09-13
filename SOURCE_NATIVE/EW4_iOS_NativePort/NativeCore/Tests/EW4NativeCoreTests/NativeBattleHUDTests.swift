import Testing
@testable import EW4NativeCore

@Test func nativeBattleCornerHUDGeometryFrozen() {
    #expect(NativeBattleHUDCore.undo == NativeHUDRect(x: 0, y: 293, width: 37, height: 37))
    #expect(NativeBattleHUDCore.skip == NativeBattleHUDCore.undo)
    #expect(NativeBattleHUDCore.next == NativeHUDRect(x: 541, y: 293, width: 37, height: 37))
    #expect(NativeBattleHUDCore.undo.contains(NativePoint(x: 18, y: 310)))
    #expect(!NativeBattleHUDCore.undo.contains(NativePoint(x: 40, y: 310)))
}
