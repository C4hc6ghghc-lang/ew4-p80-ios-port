import Testing
@testable import EW4NativeCore

@Test func originalAudioPolicyMatchesRecoveredFormAndBattleContract() {
    #expect(NativeAudioPolicyCore.originalBattleTracks == ["battle1.mp3", "battle2.mp3", "battle3.mp3", "battle4.mp3"])
    #expect(NativeAudioPolicyCore.formOpenSound("form_option") == "sfx_pop.wav")
    #expect(NativeAudioPolicyCore.formOpenSound("form_getgeneraltips") == "sfx_lvup2.wav")
    #expect(NativeAudioPolicyCore.battleTrack(randomIndex: 5) == "battle2.mp3")
    #expect(NativeAudioPolicyCore.resultCue(kind: "victory") == .init(stopBattleMusic: true, backgroundMusic: nil, soundEffect: "sfx_celebrate.wav"))
    #expect(NativeAudioPolicyCore.resultCue(kind: "defeat") == .init(stopBattleMusic: true, backgroundMusic: "defeat_music.mp3", soundEffect: nil))
}
