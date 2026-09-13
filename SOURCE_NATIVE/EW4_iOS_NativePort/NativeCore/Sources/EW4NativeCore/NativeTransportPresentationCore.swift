import Foundation

public struct NativeTransportVisualProfile: Equatable, Sendable {
    public let spriteKey: String
    public let naturalFacing: String

    public init(spriteKey: String, naturalFacing: String) {
        self.spriteKey = spriteKey
        self.naturalFacing = naturalFacing
    }
}

public struct NativeTransportSpritePlacement: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double
    public let mirrored: Bool

    public init(x: Double, y: Double, width: Double, height: Double, mirrored: Bool) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.mirrored = mirrored
    }
}

public enum NativeTransportPresentationCore {
    public static func profile(armoredCarrier: Bool) -> NativeTransportVisualProfile {
        armoredCarrier
            ? .init(spriteKey: "transportship2.png", naturalFacing: "left")
            : .init(spriteKey: "transportship1.png", naturalFacing: "right")
    }

    public static func placement(
        refX: Double,
        refY: Double,
        width: Double,
        height: Double,
        scale: Double = 0.5,
        desiredFacing: String,
        naturalFacing: String
    ) -> NativeTransportSpritePlacement {
        let mirrored = desiredFacing != naturalFacing
        return .init(
            x: (mirrored ? refX : -refX) * scale,
            y: refY * scale,
            width: width * scale,
            height: height * scale,
            mirrored: mirrored
        )
    }
}
