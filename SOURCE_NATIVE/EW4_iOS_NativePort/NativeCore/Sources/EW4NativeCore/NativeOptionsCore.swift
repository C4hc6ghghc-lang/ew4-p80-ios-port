import Foundation

public struct NativeOptionsSettings: Equatable, Sendable {
    public var backgroundVolume: Int
    public var soundEffectVolume: Int
    public var gameSpeed: Int
    public var showGrids: Bool

    public init(backgroundVolume: Int = 50, soundEffectVolume: Int = 50, gameSpeed: Int = 2, showGrids: Bool = false) {
        self.backgroundVolume = backgroundVolume
        self.soundEffectVolume = soundEffectVolume
        self.gameSpeed = gameSpeed
        self.showGrids = showGrids
    }

    public var musicEnabled: Bool { backgroundVolume > 0 }
}

public enum NativeOptionsCore {
    public static let screenFrame = NativeRect(x: 104, y: 51, width: 360, height: 218)
    public static let closeButton = NativeRect(x: 447, y: 43, width: 25, height: 25)
    public static let okButton = NativeRect(x: 427, y: 234, width: 30, height: 30)
    public static let musicTrack = NativeRect(x: 145, y: 119, width: 100, height: 18)
    public static let soundTrack = NativeRect(x: 322, y: 119, width: 100, height: 18)
    public static let speedButtons: [NativeRect] = (0..<5).map { index in
        NativeRect(x: 104 + 218 + Double(index) * 20, y: 51 + 125, width: 20, height: 15)
    }
    public static let gridButton = NativeRect(x: 104 + 258, y: 51 + 180, width: 19, height: 19)

    public static func settings(from profile: NativePlayerProfile) -> NativeOptionsSettings {
        NativeOptionsSettings(
            backgroundVolume: clamp(percent(profile.document["bgVol"], fallback: 50)),
            soundEffectVolume: clamp(percent(profile.document["seVol"], fallback: 50)),
            gameSpeed: max(1, min(5, percent(profile.document["gameSpeed"], fallback: 2))),
            showGrids: bool(profile.document["showGrids"], fallback: false)
        )
    }

    @discardableResult
    public static func apply(_ source: NativeOptionsSettings, to profile: inout NativePlayerProfile) -> NativeOptionsSettings {
        let value = NativeOptionsSettings(
            backgroundVolume: clamp(source.backgroundVolume),
            soundEffectVolume: clamp(source.soundEffectVolume),
            gameSpeed: max(1, min(5, source.gameSpeed)),
            showGrids: source.showGrids
        )
        profile.document["bgVol"] = .int(value.backgroundVolume)
        profile.document["seVol"] = .int(value.soundEffectVolume)
        profile.document["gameSpeed"] = .int(value.gameSpeed)
        profile.document["showGrids"] = .bool(value.showGrids)
        profile.document["music"] = .bool(value.musicEnabled)
        return value
    }

    public static func sliderPercent(atX x: Double, track: NativeRect) -> Int {
        let local = max(0, min(track.size.width, x - track.origin.x))
        return clamp(Int((local / track.size.width * 100).rounded()))
    }

    private static func percent(_ value: NativeJSONValue?, fallback: Int) -> Int {
        switch value {
        case .int(let v): return v
        case .double(let v): return Int(v.rounded())
        case .string(let v): return Int(v) ?? fallback
        default: return fallback
        }
    }

    private static func bool(_ value: NativeJSONValue?, fallback: Bool) -> Bool {
        switch value {
        case .bool(let v): return v
        case .int(let v): return v != 0
        case .string(let v): return v == "1" || v.lowercased() == "true"
        default: return fallback
        }
    }

    private static func clamp(_ value: Int) -> Int { max(0, min(100, value)) }
}
