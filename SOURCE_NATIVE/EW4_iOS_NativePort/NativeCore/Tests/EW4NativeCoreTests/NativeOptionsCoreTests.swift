import Testing
@testable import EW4NativeCore

struct NativeOptionsCoreTests {
    @Test func recoveredDefaultsAndCommitMatchMatureSaveContract() {
        var profile = NativePlayerProfile.fresh()
        #expect(NativeOptionsCore.settings(from: profile) == .init(backgroundVolume: 50, soundEffectVolume: 50, gameSpeed: 2, showGrids: false))
        let committed = NativeOptionsCore.apply(.init(backgroundVolume: 73, soundEffectVolume: 28, gameSpeed: 5, showGrids: true), to: &profile)
        #expect(committed.musicEnabled)
        #expect(profile.document["bgVol"] == .int(73))
        #expect(profile.document["seVol"] == .int(28))
        #expect(profile.document["gameSpeed"] == .int(5))
        #expect(profile.document["showGrids"] == .bool(true))
        #expect(profile.document["music"] == .bool(true))
    }

    @Test func recoveredOptionGeometryAndSliderClampingStayExact() {
        #expect(NativeOptionsCore.screenFrame == NativeRect(x: 104, y: 51, width: 360, height: 218))
        #expect(NativeOptionsCore.speedButtons.count == 5)
        #expect(NativeOptionsCore.sliderPercent(atX: NativeOptionsCore.musicTrack.origin.x - 10, track: NativeOptionsCore.musicTrack) == 0)
        #expect(NativeOptionsCore.sliderPercent(atX: NativeOptionsCore.musicTrack.origin.x + 50, track: NativeOptionsCore.musicTrack) == 50)
        #expect(NativeOptionsCore.sliderPercent(atX: NativeOptionsCore.musicTrack.origin.x + 150, track: NativeOptionsCore.musicTrack) == 100)
    }
}
