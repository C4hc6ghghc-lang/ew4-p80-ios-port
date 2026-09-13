import Testing
@testable import EW4NativeCore

@Test func originalMainMenuGeometryMatchesFrozenP39Shell() {
    #expect(NativeOriginalMainMenuCore.title == NativeRect(x: 20, y: 15, width: 380, height: 96))
    #expect(NativeOriginalMainMenuCore.buttons.count == 5)
    #expect(NativeOriginalMainMenuCore.buttons[0] == NativeRect(x: 435, y: 115, width: 134, height: 33))
    #expect(NativeOriginalMainMenuCore.buttons[4] == NativeRect(x: 435, y: 267, width: 134, height: 33))
    #expect(NativeOriginalMainMenuCore.achievement == NativeRect(x: 35, y: 287, width: 33, height: 33))
}

@Test func originalMainMenuHitboxesRouteCampaignConquestHQWithoutDrift() {
    #expect(NativeOriginalMainMenuCore.action(at: NativePoint(x: 500, y: 130)) == .campaign)
    #expect(NativeOriginalMainMenuCore.action(at: NativePoint(x: 500, y: 168)) == .conquest)
    #expect(NativeOriginalMainMenuCore.action(at: NativePoint(x: 500, y: 244)) == .headquarters)
    #expect(NativeOriginalMainMenuCore.achievementHit(at: NativePoint(x: 50, y: 300)))
}
