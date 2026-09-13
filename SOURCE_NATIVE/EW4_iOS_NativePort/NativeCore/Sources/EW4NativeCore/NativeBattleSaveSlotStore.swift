import Foundation

public enum NativeBattleSaveSlot: Hashable, Sendable, CustomStringConvertible {
    case autosave
    case manual(Int)

    public static let manualRange = 1...6
    public static let all: [NativeBattleSaveSlot] = [.autosave] + manualRange.map(NativeBattleSaveSlot.manual)

    public var description: String {
        switch self {
        case .autosave: return "auto"
        case .manual(let index): return String(index)
        }
    }

    public var isValid: Bool {
        switch self {
        case .autosave: return true
        case .manual(let index): return Self.manualRange.contains(index)
        }
    }
}

public struct NativeBattleSaveSlotMetadata: Equatable, Sendable {
    public let slot: NativeBattleSaveSlot
    public let battleFile: String
    public let battleTitle: String
    public let playerOwner: Int
    public let round: Int
    public let savedAt: Int64

    public init(slot: NativeBattleSaveSlot, payload: NativeBattleSavePayload) {
        self.slot = slot
        self.battleFile = payload.battleFile
        self.battleTitle = payload.battleTitle
        self.playerOwner = payload.playerOwner
        self.round = payload.round
        self.savedAt = payload.savedAt
    }
}

public enum NativeBattleSaveSlotStoreError: Error, Equatable, Sendable {
    case invalidSlot(Int)
}

/// Native filesystem equivalent of P39's one autosave + six manual battle slots.
/// The slot layer deliberately stores the exact BattleSave JSON envelope instead
/// of creating a second archive format.
public struct NativeBattleSaveSlotStore: Sendable {
    public let rootDirectory: URL

    public init(rootDirectory: URL) {
        self.rootDirectory = rootDirectory
    }

    public static func applicationSupport(
        fileManager: FileManager = .default,
        subdirectory: String = "EW4NativePort/BattleSaves"
    ) throws -> NativeBattleSaveSlotStore {
        let base = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return NativeBattleSaveSlotStore(rootDirectory: base.appendingPathComponent(subdirectory, isDirectory: true))
    }

    public func url(for slot: NativeBattleSaveSlot) throws -> URL {
        try validate(slot)
        switch slot {
        case .autosave:
            return rootDirectory.appendingPathComponent("battle_autosave.json")
        case .manual(let index):
            return rootDirectory.appendingPathComponent("battle_slot_\(index).json")
        }
    }

    public func write(_ payload: NativeBattleSavePayload, to slot: NativeBattleSaveSlot) throws {
        try validate(slot)
        try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        let data = try NativeBattleSaveCore.encode(payload)
        try data.write(to: url(for: slot), options: .atomic)
    }

    /// Mirrors P39 readBattleSave: a missing, corrupt, or unsupported slot is
    /// presented as empty rather than crashing the save/load form.
    public func read(_ slot: NativeBattleSaveSlot) -> NativeBattleSavePayload? {
        guard slot.isValid, let url = try? url(for: slot), let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? NativeBattleSaveCore.decode(data)
    }

    public func metadata(for slot: NativeBattleSaveSlot) -> NativeBattleSaveSlotMetadata? {
        read(slot).map { NativeBattleSaveSlotMetadata(slot: slot, payload: $0) }
    }

    public func allMetadata() -> [NativeBattleSaveSlotMetadata] {
        NativeBattleSaveSlot.all.compactMap(metadata)
    }

    public func remove(_ slot: NativeBattleSaveSlot) throws {
        let url = try url(for: slot)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    private func validate(_ slot: NativeBattleSaveSlot) throws {
        if case .manual(let index) = slot, !NativeBattleSaveSlot.manualRange.contains(index) {
            throw NativeBattleSaveSlotStoreError.invalidSlot(index)
        }
    }
}
