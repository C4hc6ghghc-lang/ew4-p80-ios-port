import Testing
@testable import EW4NativeCore

@Test func nativeUnitStatusRecoveredMath() {
    #expect(NativeUnitStatusCore.relationSprite(.own) == "hpbar_green.png")
    #expect(NativeUnitStatusCore.relationSprite(.ally) == "hpbar_blue.png")
    #expect(NativeUnitStatusCore.relationSprite(.hostile) == "hpbar_red.png")
    #expect(NativeUnitStatusCore.relationSprite(.neutral) == "hpbar_black.png")

    #expect(NativeUnitStatusCore.hpColor(ratio: 0) == NativeRGB(r: 255, g: 0, b: 0))
    #expect(NativeUnitStatusCore.hpColor(ratio: 0.5) == NativeRGB(r: 255, g: 255, b: 0))
    #expect(NativeUnitStatusCore.hpColor(ratio: 1) == NativeRGB(r: 0, g: 255, b: 128))

    let quarter = NativeUnitStatusCore.hpArc(ratio: 0.25)
    #expect(abs(quarter.sweep - 49.5 * Double.pi / 180) < 0.000001)
    #expect(NativeUnitStatusCore.armyMarkerID(21) == 21)
    #expect(NativeUnitStatusCore.armyMarkerID(22) == nil)
}
