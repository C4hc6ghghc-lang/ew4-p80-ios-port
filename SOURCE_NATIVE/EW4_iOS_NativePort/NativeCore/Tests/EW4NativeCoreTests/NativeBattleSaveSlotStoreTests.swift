import Foundation
import Testing
@testable import EW4NativeCore

private func slotPayload(savedAt: Int64 = 100, round: Int = 3) throws -> NativeBattleSavePayload {
    try NativeBattleSaveCore.makePayload(
        from: NativeBattleSaveState(
            battleFile: "campaign1_01.btl",
            battleTitle: "土伦港之战",
            map: "europe",
            mode: "campaign",
            playerOwner: 0,
            round: round,
            resources: CountryResources(money: 1, industry: 2, food: 3),
            camera: NativeSaveCamera(x: 100, y: 200, zoom: 0.8),
            cameraGeometry: NativeHexGeometry.geometryID
        ),
        savedAt: savedAt
    )
}

private func tempSlotStore() throws -> (NativeBattleSaveSlotStore, URL) {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("ew4-native-slot-tests-\(UUID().uuidString)", isDirectory: true)
    return (NativeBattleSaveSlotStore(rootDirectory: root), root)
}

@Test func battleSaveSlotsMatchP39AutoPlusSixContract() throws {
    #expect(NativeBattleSaveSlot.all.count == 7)
    #expect(NativeBattleSaveSlot.all.first == .autosave)
    #expect(NativeBattleSaveSlot.all.dropFirst() == (1...6).map(NativeBattleSaveSlot.manual)[...])
    let (store, root) = try tempSlotStore()
    defer { try? FileManager.default.removeItem(at: root) }
    #expect(try store.url(for: .autosave).lastPathComponent == "battle_autosave.json")
    #expect(try store.url(for: .manual(6)).lastPathComponent == "battle_slot_6.json")
    #expect(throws: NativeBattleSaveSlotStoreError.invalidSlot(7)) {
        _ = try store.url(for: .manual(7))
    }
}

@Test func battleSaveSlotStoreAtomicallyRoundTripsAndExposesNativeFormMetadata() throws {
    let (store, root) = try tempSlotStore()
    defer { try? FileManager.default.removeItem(at: root) }
    let payload = try slotPayload(savedAt: 123456789, round: 7)
    try store.write(payload, to: .manual(4))
    let read = try #require(store.read(.manual(4)))
    #expect(read == payload)
    let meta = try #require(store.metadata(for: .manual(4)))
    #expect(meta.battleTitle == "土伦港之战")
    #expect(meta.battleFile == "campaign1_01.btl")
    #expect(meta.playerOwner == 0)
    #expect(meta.round == 7)
    #expect(meta.savedAt == 123456789)
    #expect(store.allMetadata().map(\.slot) == [.manual(4)])
    try store.remove(.manual(4))
    #expect(store.read(.manual(4)) == nil)
}

@Test func corruptOrUnsupportedBattleSaveSlotBehavesAsEmptyLikeP39() throws {
    let (store, root) = try tempSlotStore()
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    try Data("not json".utf8).write(to: try store.url(for: .autosave))
    #expect(store.read(.autosave) == nil)

    var unsupported = try slotPayload()
    unsupported.schema = 99
    let data = try JSONEncoder().encode(unsupported)
    try data.write(to: try store.url(for: .manual(1)), options: .atomic)
    #expect(store.read(.manual(1)) == nil)
}
