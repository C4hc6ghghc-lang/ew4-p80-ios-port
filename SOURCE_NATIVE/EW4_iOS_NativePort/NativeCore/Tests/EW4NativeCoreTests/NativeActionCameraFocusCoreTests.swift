import Testing
@testable import EW4NativeCore

@Test func actionPairFocusSkipsWhenBothCellsFitSafeViewport() {
    let camera = NativeCameraState(x: 284, y: 160, zoom: 1)
    let source = HexCell(q: 4, r: 3)
    let target = HexCell(q: 5, r: 3)
    let plan = NativeActionCameraFocusCore.plan(camera: camera, source: source, target: target)
    #expect(plan.required == false)
    #expect(plan.targetZoom == nil)
}

@Test func actionPairFocusUsesExactMidpointWhenEitherCellIsOutsideSafeViewport() {
    let camera = NativeCameraState(x: 284, y: 160, zoom: 1)
    let source = HexCell(q: 0, r: 0)
    let target = HexCell(q: 9, r: 6)
    let plan = NativeActionCameraFocusCore.plan(camera: camera, source: source, target: target)
    let a = NativeHexGeometry.cellCenter(source)
    let b = NativeHexGeometry.cellCenter(target)
    #expect(plan.required)
    #expect(plan.target == NativePoint(x: (a.x + b.x) * 0.5, y: (a.y + b.y) * 0.5))
    #expect(plan.targetZoom == nil)
}

@Test func actionPairFocusRestoresOneToOneZoomBelowDetailThreshold() {
    let camera = NativeCameraState(x: 284, y: 160, zoom: 0.4)
    let plan = NativeActionCameraFocusCore.plan(camera: camera, source: .init(q: 4, r: 3), target: .init(q: 5, r: 3))
    #expect(plan.required)
    #expect(plan.targetZoom == 1.0)
}
