import Foundation

public struct NativeDrawOrigin: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let scale: Double
}

public enum NativeAnimationTiming {
    public static func motionSpeed(_ asset: NativeAnimationAsset) -> Double {
        let speed = asset.motionSpeedAttr
        return speed.isFinite && speed > 0 ? speed : 1
    }

    public static func rawDurationMilliseconds(_ asset: NativeAnimationAsset) -> Double {
        Double(asset.frameCount) / Double(asset.fps == 0 ? 24 : asset.fps) * 1000 / motionSpeed(asset)
    }

    public static func frame(at elapsedMilliseconds: Double, asset: NativeAnimationAsset) -> Int {
        let fps = Double(asset.fps == 0 ? 24 : asset.fps)
        let count = max(1, asset.frameCount)
        let index = Int(floor(max(0, elapsedMilliseconds) * motionSpeed(asset) * fps / 1000))
        return min(count - 1, max(0, index))
    }

    public static func compactDrawOrigin(unit: NativeAnimationUnit, worldPoint: NativePoint, unitZoom: Double = 1) -> NativeDrawOrigin {
        let scale = 0.5 * unitZoom
        return NativeDrawOrigin(
            x: worldPoint.x + unit.nativeAnchor.x * scale,
            y: worldPoint.y + unit.nativeAnchor.y * scale,
            scale: scale
        )
    }
}
