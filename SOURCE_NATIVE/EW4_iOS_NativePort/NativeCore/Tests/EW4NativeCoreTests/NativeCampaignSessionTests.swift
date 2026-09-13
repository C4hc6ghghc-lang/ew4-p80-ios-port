import Foundation
import Testing
@testable import EW4NativeCore

@Test func campaignLegacyMigrationMatchesP39ExactlyOnce() throws {
    let legacy: [String: NativeJSONValue] = [
        "campaignProgress": .object([
            "campaign1_01.btl": .int(1),
            "campaign1_02.btl": .int(2),
            "campaign1_03.btl": .int(1)
        ]),
        "campaignBestRating": .object(["campaign1_01.btl": .int(3)])
    ]
    var state = legacy
    state["campaignStars"] = .int(0)
    state["warzoneTech"] = .null
    let migrated = NativeCampaignSessionCore.normalizeDocument(state: state, source: legacy)
    #expect(migrated["campaignStars"] == .int(9))
    #expect(migrated["warzoneTech"] == .null)

    var modernSource = legacy
    modernSource["campaignStars"] = .int(0)
    let modern = NativeCampaignSessionCore.normalizeDocument(state: modernSource, source: modernSource)
    #expect(modern["campaignStars"] == .int(0))
}

@Test func profileDecodeMigratesLegacyStarsBeforeDefaultsCanMaskThem() throws {
    let raw: [String: NativeJSONValue] = [
        "campaignProgress": .object(["campaign1_01.btl": .int(2)]),
        "campaignBestRating": .object([:]),
        "futureField": .string("keep")
    ]
    let data = try JSONEncoder().encode(raw)
    let profile = try NativePlayerProfile.decode(data)
    #expect(profile.document["campaignStars"] == .int(5))
    #expect(profile.document["futureField"] == .string("keep"))
}

@Test func campaignResultAwardsOnlyPositiveBestRatingDeltaAndCapsStars() {
    let state = NativeCampaignSessionCore.normalizeDocument(
        state: [
            "campaignStars": .int(998),
            "campaignProgress": .object([:]),
            "campaignBestRating": .object([:]),
            "campaignCompletedZones": .object([:]),
            "campaignCompletionEarned": .object([:])
        ],
        source: ["campaignStars": .int(998)]
    )
    let first = NativeCampaignSessionCore.recordResult(state, file: "campaign1_01.btl", rating: 5)
    #expect(first.delta == 5)
    #expect(first.document["campaignStars"] == .int(999))
    #expect(NativeCampaignSessionCore.bestRating(first.document, file: "campaign1_01.btl") == 5)

    let replay = NativeCampaignSessionCore.recordResult(first.document, file: "campaign1_01.btl", rating: 2)
    #expect(replay.delta == 0)
    #expect(replay.document["campaignStars"] == .int(999))
    #expect(NativeCampaignSessionCore.bestRating(replay.document, file: "campaign1_01.btl") == 5)
}

@Test func campaignZoneCompletionRewardIsOneShot() {
    let state = NativeCampaignSessionCore.normalizeDocument(
        state: ["campaignStars": .int(0)],
        source: ["campaignStars": .int(0)]
    )
    let reward = NativeCampaignCompletionReward(zone: 2, medal: 50, badge: 1, score: 1, image: "campaignend_coalitiont.png", firstTime: true)
    let first = NativeCampaignSessionCore.recordZoneCompletion(state, zone: 2, reward: reward)
    #expect(first.applied)
    #expect(first.document["campaignCompletionEarned"] == .object(["medals": .int(50), "badges": .int(1), "score": .int(1)]))
    let second = NativeCampaignSessionCore.recordZoneCompletion(first.document, zone: 2, reward: reward)
    #expect(!second.applied)
    #expect(second.document["campaignCompletionEarned"] == first.document["campaignCompletionEarned"])
}

@Test func campaignMetaStorageIsStableAcross500Reloads() throws {
    var state = NativeCampaignSessionCore.normalizeDocument(
        state: [
            "campaignStars": .int(7),
            "campaignProgress": .object(["campaign1_01.btl": .int(1)]),
            "campaignBestRating": .object(["campaign1_01.btl": .int(4)]),
            "campaignSecretUnlocks": .object(["campaign1_03b.btl": .bool(true)]),
            "campaignCompletedZones": .object(["1": .bool(true)]),
            "campaignCompletionEarned": .object(["medals": .int(0), "badges": .int(1), "score": .int(1)]),
            "warzoneTech": .object(["1": .array(Array(repeating: .int(0), count: 26))]),
            "futureField": .object(["keep": .string("yes")])
        ],
        source: [
            "campaignStars": .int(7),
            "warzoneTech": .object(["1": .array(Array(repeating: .int(0), count: 26))])
        ]
    )
    let canonical = state
    for _ in 0..<500 { state = try NativeCampaignSessionCore.storageRoundTrip(state, source: state) }
    #expect(state == canonical)
    #expect(state["futureField"] == .object(["keep": .string("yes")]))

    let profile = NativePlayerProfile(document: state)
    #expect(try profile.encoded() == profile.encoded())
}
