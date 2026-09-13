import Foundation

public enum NativePresentationLODCore {
    public static let detailZoom = 0.5
    public static let unitZoomMinimum = 0.76
    public static let unitZoomMaximum = 1.18
    public static let unitZoomExponent = 0.46

    public static func tacticalVisible(cameraZoom: Double) -> Bool {
        cameraZoom >= detailZoom
    }

    public static func strategicVisible(cameraZoom: Double) -> Bool {
        cameraZoom < detailZoom
    }

    public static func unitVisualZoom(cameraZoom: Double) -> Double {
        let raw = pow(max(0.000_001, cameraZoom), unitZoomExponent)
        return max(unitZoomMinimum, min(unitZoomMaximum, raw))
    }

    // A child of the zoomed world layer needs this compensating local scale so
    // its final on-screen scale is semanticUnitZoom rather than cameraZoom.
    public static func tacticalContainerScale(cameraZoom: Double) -> Double {
        unitVisualZoom(cameraZoom: cameraZoom) / max(0.000_001, cameraZoom)
    }

    // Strategic markers are authored in screen-space in the recovered renderer.
    public static func strategicContainerScale(cameraZoom: Double) -> Double {
        1 / max(0.000_001, cameraZoom)
    }
}
