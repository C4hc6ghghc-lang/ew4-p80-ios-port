import Foundation

public struct NativeCameraState: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var zoom: Double
    public init(x: Double = 0, y: Double = 0, zoom: Double = 1) {
        self.x = x; self.y = y; self.zoom = NativeCamera.clampZoom(zoom)
    }
}


public struct NativeProgrammaticCameraMotion: Equatable, Sendable {
    public var target: NativeCameraState
    public var velocityX: Double
    public var velocityY: Double
    public var velocityZoom: Double
    public var active: Bool
    public var gameSpeed: Int

    public init(target: NativeCameraState, velocityX: Double, velocityY: Double, velocityZoom: Double, active: Bool, gameSpeed: Int) {
        self.target = target
        self.velocityX = velocityX
        self.velocityY = velocityY
        self.velocityZoom = velocityZoom
        self.active = active
        self.gameSpeed = gameSpeed
    }
}

public enum NativeCamera {
    public static let minZoom = 0.2
    public static let maxZoom = 1.0
    public static let detailZoom = 0.5
    public static let tapAxisSlop = 15.0
    public static let pinchMinDistance = 40.0
    public static let viewCenter = EW4LogicalSpace.center
    public static let focusInsetX = 64.0
    public static let focusInsetY = 72.0
    public static let defaultGameSpeed = 2
    public static let gameSpeedCoefficients = [0.012, 0.015, 0.020, 0.020, 0.020]
    public static let nativeTickRate = 60.0
    public static let positionSnap = 1.0
    public static let zoomSnap = 0.01

    public static func clampZoom(_ z: Double) -> Double { min(max(z, minZoom), maxZoom) }
    public static func detailInteractionEnabled(_ zoom: Double) -> Bool { zoom >= detailZoom }

    public static func isNativeTap(start: NativePoint, end: NativePoint) -> Bool {
        abs(end.x - start.x) < tapAxisSlop && abs(end.y - start.y) < tapAxisSlop
    }

    public static func screenToWorld(_ camera: NativeCameraState, point: NativePoint, center: NativePoint = viewCenter) -> NativePoint {
        NativePoint(x: (point.x-center.x)/camera.zoom + camera.x,
                    y: (point.y-center.y)/camera.zoom + camera.y)
    }

    public static func zoomAt(_ camera: NativeCameraState, nextZoom: Double, screen: NativePoint = viewCenter, worldAnchor: NativePoint? = nil, center: NativePoint = viewCenter) -> NativeCameraState {
        let anchor = worldAnchor ?? screenToWorld(camera, point: screen, center: center)
        let z = clampZoom(nextZoom)
        return NativeCameraState(x: anchor.x-(screen.x-center.x)/z,
                                 y: anchor.y-(screen.y-center.y)/z,
                                 zoom: z)
    }

    public static func panStep(_ camera: NativeCameraState, previous: NativePoint, current: NativePoint) -> NativeCameraState {
        NativeCameraState(x: camera.x + (previous.x-current.x)/camera.zoom,
                          y: camera.y + (previous.y-current.y)/camera.zoom,
                          zoom: camera.zoom)
    }

    public static func focusRectVisible(_ camera: NativeCameraState, rect: NativeRect) -> Bool {
        let z = clampZoom(camera.zoom)
        let halfWidth = viewCenter.x / z
        let halfHeight = viewCenter.y / z
        let left = camera.x - halfWidth + focusInsetX
        let right = camera.x + halfWidth - focusInsetX
        let top = camera.y - halfHeight + focusInsetY
        let bottom = camera.y + halfHeight - focusInsetY
        return rect.origin.x >= left && rect.origin.x + rect.size.width <= right && rect.origin.y >= top && rect.origin.y + rect.size.height <= bottom
    }

    public static func gameSpeedCoefficient(_ speed: Int = defaultGameSpeed) -> Double {
        let clamped = min(5, max(1, speed))
        return gameSpeedCoefficients[clamped - 1]
    }

    private static func axisMotor(current: Double, target: Double, coefficient: Double, snap: Double) -> (current: Double, target: Double, velocity: Double) {
        let delta = target - current
        if abs(delta) <= snap { return (target, target, 0) }
        return (current, target, delta * coefficient)
    }

    public static func startProgrammaticMove(
        _ camera: NativeCameraState,
        target: NativePoint,
        gameSpeed: Int = defaultGameSpeed,
        targetZoom: Double? = nil
    ) -> (camera: NativeCameraState, motion: NativeProgrammaticCameraMotion) {
        let speed = min(5, max(1, gameSpeed))
        let coefficient = gameSpeedCoefficient(speed)
        let x = axisMotor(current: camera.x, target: target.x, coefficient: coefficient, snap: positionSnap)
        let y = axisMotor(current: camera.y, target: target.y, coefficient: coefficient, snap: positionSnap)
        let zoomTarget = clampZoom(targetZoom ?? camera.zoom)
        let z = axisMotor(current: camera.zoom, target: zoomTarget, coefficient: coefficient, snap: zoomSnap)
        let state = NativeCameraState(x: x.current, y: y.current, zoom: z.current)
        let motion = NativeProgrammaticCameraMotion(
            target: NativeCameraState(x: x.target, y: y.target, zoom: z.target),
            velocityX: x.velocity, velocityY: y.velocity, velocityZoom: z.velocity,
            active: x.velocity != 0 || y.velocity != 0 || z.velocity != 0, gameSpeed: speed
        )
        return (state, motion)
    }

    private static func stepAxis(current: Double, target: Double, velocity: Double, factor: Double) -> (current: Double, velocity: Double) {
        guard velocity != 0 else { return (current, 0) }
        let remaining = target - current
        let step = velocity * factor
        if abs(step) >= abs(remaining) { return (target, 0) }
        return (current + step, velocity)
    }

    public static func stepProgrammaticMove(
        _ camera: NativeCameraState,
        motion: NativeProgrammaticCameraMotion,
        dtSeconds: Double
    ) -> (camera: NativeCameraState, motion: NativeProgrammaticCameraMotion, active: Bool) {
        guard motion.active else { return (camera, motion, false) }
        let factor = max(0, dtSeconds) * nativeTickRate
        let x = stepAxis(current: camera.x, target: motion.target.x, velocity: motion.velocityX, factor: factor)
        let y = stepAxis(current: camera.y, target: motion.target.y, velocity: motion.velocityY, factor: factor)
        let z = stepAxis(current: camera.zoom, target: motion.target.zoom, velocity: motion.velocityZoom, factor: factor)
        let active = x.velocity != 0 || y.velocity != 0 || z.velocity != 0
        let nextMotion = NativeProgrammaticCameraMotion(
            target: motion.target, velocityX: x.velocity, velocityY: y.velocity, velocityZoom: z.velocity,
            active: active, gameSpeed: motion.gameSpeed
        )
        return (NativeCameraState(x: x.current, y: y.current, zoom: z.current), nextMotion, active)
    }

    public static func pinchStep(_ camera: NativeCameraState, movedBefore: NativePoint, movedAfter: NativePoint, stationary: NativePoint, center: NativePoint = viewCenter) -> (applied: Bool, camera: NativeCameraState) {
        let oldDistance = hypot(movedBefore.x-stationary.x, movedBefore.y-stationary.y)
        let newDistance = hypot(movedAfter.x-stationary.x, movedAfter.y-stationary.y)
        guard oldDistance > pinchMinDistance, newDistance > pinchMinDistance else { return (false, camera) }
        let anchor = screenToWorld(camera, point: stationary, center: center)
        let z = clampZoom(camera.zoom * (newDistance / oldDistance))
        return (true, NativeCameraState(x: anchor.x-(stationary.x-center.x)/z,
                                        y: anchor.y-(stationary.y-center.y)/z,
                                        zoom: z))
    }
}
