import Foundation

public struct NativeActionCameraFocusPlan: Equatable, Sendable {
    public let required: Bool
    public let target: NativePoint
    public let targetZoom: Double?

    public init(required: Bool, target: NativePoint, targetZoom: Double?) {
        self.required = required
        self.target = target
        self.targetZoom = targetZoom
    }
}

public enum NativeActionCameraFocusCore {
    public static func plan(
        camera: NativeCameraState,
        source: HexCell,
        target: HexCell
    ) -> NativeActionCameraFocusPlan {
        let sourceRect = NativeHexGeometry.cellRect(source)
        let targetRect = NativeHexGeometry.cellRect(target)
        let detail = NativeCamera.detailInteractionEnabled(camera.zoom)
        let bothVisible = detail
            && NativeCamera.focusRectVisible(camera, rect: sourceRect)
            && NativeCamera.focusRectVisible(camera, rect: targetRect)
        let a = NativeHexGeometry.cellCenter(source)
        let b = NativeHexGeometry.cellCenter(target)
        return NativeActionCameraFocusPlan(
            required: !bothVisible,
            target: NativePoint(x: (a.x + b.x) * 0.5, y: (a.y + b.y) * 0.5),
            targetZoom: camera.zoom < NativeCamera.detailZoom ? 1.0 : nil
        )
    }
}
