import Foundation

public struct NativeBattleResultAudioCue: Equatable, Sendable {
    public let stopBattleMusic: Bool
    public let backgroundMusic: String?
    public let soundEffect: String?
    public init(stopBattleMusic: Bool, backgroundMusic: String?, soundEffect: String?) {
        self.stopBattleMusic = stopBattleMusic
        self.backgroundMusic = backgroundMusic
        self.soundEffect = soundEffect
    }
}

public enum NativeAudioPolicyCore {
    public static let originalBattleTracks = ["battle1.mp3", "battle2.mp3", "battle3.mp3", "battle4.mp3"]
    public static let formOpenSFX: [String: String] = [
        "form_generalinfo": "sfx_pop.wav",
        "form_option": "sfx_pop.wav",
        "form_save": "sfx_pop.wav",
        "form_upgrade": "sfx_pop.wav",
        "form_princess": "sfx_pop.wav",
        "form_complete": "sfx_pop.wav",
        "form_getgeneraltips": "sfx_lvup2.wav",
    ]

    public static func formOpenSound(_ formID: String) -> String? { formOpenSFX[formID] }

    public static func battleTrack(randomIndex: Int) -> String {
        let n = originalBattleTracks.count
        let normalized = ((randomIndex % n) + n) % n
        return originalBattleTracks[normalized]
    }

    public static func resultCue(kind: String) -> NativeBattleResultAudioCue {
        switch kind.lowercased() {
        case "victory": return .init(stopBattleMusic: true, backgroundMusic: nil, soundEffect: "sfx_celebrate.wav")
        case "defeat", "failure": return .init(stopBattleMusic: true, backgroundMusic: "defeat_music.mp3", soundEffect: nil)
        default: return .init(stopBattleMusic: false, backgroundMusic: nil, soundEffect: nil)
        }
    }
}
