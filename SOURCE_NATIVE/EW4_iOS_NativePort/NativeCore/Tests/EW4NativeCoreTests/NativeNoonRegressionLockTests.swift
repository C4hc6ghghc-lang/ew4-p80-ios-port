import Testing
@testable import EW4NativeCore

/// Hard guard for the presentation/touch constants that were frozen after the
/// P35/P39 noon-regression incident. Changes here require new original/native
/// evidence or a verified true-device defect; "looks sharper" is not enough.
@Test func nativeNoonRegressionContractFrozen() {
    #expect(EW4LogicalSpace.width == 568)
    #expect(EW4LogicalSpace.height == 320)
    #expect(EW4LogicalSpace.center == NativePoint(x: 284, y: 160))

    #expect(NativeCamera.minZoom == 0.2)
    #expect(NativeCamera.maxZoom == 1.0)
    #expect(NativeCamera.detailZoom == 0.5)
    #expect(NativeCamera.tapAxisSlop == 15.0)
    #expect(NativeCamera.pinchMinDistance == 40.0)
    #expect(NativeCamera.focusInsetX == 64.0)
    #expect(NativeCamera.focusInsetY == 72.0)

    #expect(NativePresentationLODCore.detailZoom == 0.5)
    #expect(NativePresentationLODCore.unitZoomMinimum == 0.76)
    #expect(NativePresentationLODCore.unitZoomMaximum == 1.18)
    #expect(NativePresentationLODCore.unitZoomExponent == 0.46)

    #expect(NativeBattleHUDCore.undo == NativeHUDRect(x: 0, y: 293, width: 37, height: 37))
    #expect(NativeBattleHUDCore.skip == NativeBattleHUDCore.undo)
    #expect(NativeBattleHUDCore.next == NativeHUDRect(x: 541, y: 293, width: 37, height: 37))

    let anchor = NativeAnimationUnit(
        resource: "army_militia",
        nativeAnchor: NativeAnchor(x: -34, y: -47),
        dir: nil,
        motions: []
    )
    #expect(
        NativeAnimationTiming.compactDrawOrigin(
            unit: anchor,
            worldPoint: NativePoint(x: 450, y: 350),
            unitZoom: 1
        ) == NativeDrawOrigin(x: 433, y: 326.5, scale: 0.5)
    )
}
