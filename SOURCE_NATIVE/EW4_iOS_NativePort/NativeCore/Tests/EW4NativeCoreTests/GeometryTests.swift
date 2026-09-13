import Testing
@testable import EW4NativeCore

@Test func logicalSpaceFrozen(){ #expect(EW4LogicalSpace.width == 568); #expect(EW4LogicalSpace.height == 320); #expect(EW4LogicalSpace.center == NativePoint(x:284,y:160)) }
@Test func nativeHexCentersAndRoundTrip(){
    for cell in [HexCell(q:0,r:0),.init(q:4,r:3),.init(q:15,r:31),.init(q:78,r:67)] { let p=NativeHexGeometry.cellCenter(cell); #expect(NativeHexGeometry.worldToCell(x:p.x,y:p.y) == cell) }
    #expect(NativeHexGeometry.neighbors(of:.init(q:5,r:2)) == [.init(q:6,r:2),.init(q:5,r:3),.init(q:4,r:3),.init(q:4,r:2),.init(q:4,r:1),.init(q:5,r:1)])
    #expect(NativeHexGeometry.distance(.init(q:0,r:0),.init(q:3,r:3)) == 5)
}
@Test func nativeCameraSemantics(){
    let c=NativeCameraState(x:100,y:200,zoom:0.5)
    let w=NativeCamera.screenToWorld(c,point:.init(x:284,y:160)); #expect(w == NativePoint(x:100,y:200))
    #expect(NativeCamera.isNativeTap(start:.init(x:0,y:0),end:.init(x:14.9,y:14.9)))
    #expect(!NativeCamera.isNativeTap(start:.init(x:0,y:0),end:.init(x:15,y:0)))
    let p=NativeCamera.panStep(c,previous:.init(x:100,y:100),current:.init(x:110,y:90)); #expect(p.x == 80); #expect(p.y == 220)
    #expect(NativeCamera.clampZoom(0.01) == 0.2); #expect(NativeCamera.clampZoom(2) == 1)
}

@Test func nativeProgrammaticCameraMotorMatchesRecoveredCoefficients(){
    #expect(NativeCamera.gameSpeedCoefficient(1) == 0.012)
    #expect(NativeCamera.gameSpeedCoefficient(2) == 0.015)
    #expect(NativeCamera.gameSpeedCoefficient(3) == 0.020)
    #expect(NativeCamera.gameSpeedCoefficient(4) == 0.020)
    #expect(NativeCamera.gameSpeedCoefficient(5) == 0.020)
    #expect(NativeCamera.gameSpeedCoefficient(0) == 0.012)
    #expect(NativeCamera.gameSpeedCoefficient(99) == 0.020)

    let started = NativeCamera.startProgrammaticMove(
        NativeCameraState(x: 0, y: 0, zoom: 0.4),
        target: NativePoint(x: 100, y: 50), gameSpeed: 2, targetZoom: 1
    )
    #expect(started.camera == NativeCameraState(x: 0, y: 0, zoom: 0.4))
    #expect(abs(started.motion.velocityX - 1.5) < 0.000_001)
    #expect(abs(started.motion.velocityY - 0.75) < 0.000_001)
    #expect(abs(started.motion.velocityZoom - 0.009) < 0.000_001)
    let frame = NativeCamera.stepProgrammaticMove(started.camera, motion: started.motion, dtSeconds: 1.0 / 60.0)
    #expect(abs(frame.camera.x - 1.5) < 0.000_001)
    #expect(abs(frame.camera.y - 0.75) < 0.000_001)
    #expect(abs(frame.camera.zoom - 0.409) < 0.000_001)
    let overshoot = NativeCamera.stepProgrammaticMove(started.camera, motion: started.motion, dtSeconds: 2)
    #expect(overshoot.camera == NativeCameraState(x: 100, y: 50, zoom: 1))
    #expect(!overshoot.active)
}

@Test func nativeCameraFocusVisibilityUsesRecoveredInsets(){
    let c = NativeCameraState(x: 284, y: 160, zoom: 1)
    #expect(NativeCamera.focusRectVisible(c, rect: NativeRect(x: 250, y: 130, width: 68, height: 60)))
    #expect(!NativeCamera.focusRectVisible(c, rect: NativeRect(x: 0, y: 0, width: 68, height: 60)))
}
