import Foundation

public struct NativeMovementPresentationSample: Equatable, Sendable {
    public let point: NativePoint
    public let segmentIndex: Int
    public let fraction: Double
    public let facing: String
    public let completed: Bool
}

public enum NativeMovementPresentationCore {
    public static let minimumDurationMilliseconds = 220.0
    public static let maximumDurationMilliseconds = 1180.0
    public static let millisecondsPerSegment = 150.0
    public static let fastAIMaximumDurationMilliseconds = 80.0

    public static func durationMilliseconds(path: [HexCell], fastAI: Bool = false) -> Double {
        guard path.count >= 2 else { return 0 }
        let normal = max(
            minimumDurationMilliseconds,
            min(maximumDurationMilliseconds, Double(path.count - 1) * millisecondsPerSegment)
        )
        return fastAI ? min(fastAIMaximumDurationMilliseconds, normal) : normal
    }

    public static func sample(path: [HexCell], elapsedMilliseconds: Double, durationMilliseconds: Double) -> NativeMovementPresentationSample? {
        guard path.count >= 2 else { return nil }
        let duration = max(1, durationMilliseconds)
        if elapsedMilliseconds >= duration {
            let last = NativeHexGeometry.cellCenter(path[path.count - 1])
            let a = NativeHexGeometry.cellCenter(path[path.count - 2])
            return NativeMovementPresentationSample(
                point: last,
                segmentIndex: path.count - 2,
                fraction: 1,
                facing: last.x < a.x ? "left" : "right",
                completed: true
            )
        }
        let progress = max(0, min(0.999_999, elapsedMilliseconds / duration))
        let segments = path.count - 1
        let scaled = progress * Double(segments)
        let index = min(segments - 1, Int(floor(scaled)))
        let fraction = scaled - Double(index)
        let a = NativeHexGeometry.cellCenter(path[index])
        let b = NativeHexGeometry.cellCenter(path[index + 1])
        return NativeMovementPresentationSample(
            point: NativePoint(
                x: a.x + (b.x - a.x) * fraction,
                y: a.y + (b.y - a.y) * fraction
            ),
            segmentIndex: index,
            fraction: fraction,
            facing: b.x < a.x ? "left" : "right",
            completed: false
        )
    }
}
