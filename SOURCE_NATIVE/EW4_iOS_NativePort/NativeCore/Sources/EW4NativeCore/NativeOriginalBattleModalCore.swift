import Foundation

public enum NativeSavePanelMode: Equatable, Sendable { case save, load }
public enum NativeBattleModalState: Equatable, Sendable { case none, pause, save(NativeSavePanelMode), roundTurn }

public struct NativeSaveSlotDisplay: Equatable, Sendable {
    public let slot: NativeBattleSaveSlot
    public let title: String
    public let countryCode: String
    public let savedAt: Int64
    public let empty: Bool

    public init(slot: NativeBattleSaveSlot, title: String = "", countryCode: String = "", savedAt: Int64 = 0, empty: Bool = true) {
        self.slot = slot; self.title = title; self.countryCode = countryCode; self.savedAt = savedAt; self.empty = empty
    }
}

public enum NativeOriginalBattleModalCore {
    public static func saveSlotDisplays(
        metadata: [NativeBattleSaveSlotMetadata],
        battles: [BattleRecord]
    ) -> [NativeSaveSlotDisplay] {
        let bySlot = Dictionary(uniqueKeysWithValues: metadata.map { ($0.slot, $0) })
        let byFile = Dictionary(uniqueKeysWithValues: battles.map { ($0.file, $0) })
        return NativeBattleSaveSlot.all.map { slot in
            guard let m = bySlot[slot] else { return NativeSaveSlotDisplay(slot: slot) }
            let code = byFile[m.battleFile]?.countries.first(where: { $0.index == m.playerOwner })?.code ?? ""
            return NativeSaveSlotDisplay(slot: slot, title: m.battleTitle, countryCode: code, savedAt: m.savedAt, empty: false)
        }
    }
}

public enum NativePauseAction: Equatable, Sendable { case close, save, option, restart, exit }

extension NativeOriginalBattleModalCore {
    public static func pauseAction(at local: NativePoint) -> NativePauseAction? {
        if contains(NativeOriginalFormGeometryCore.Pause.closeButton, local) { return .close }
        if contains(NativeOriginalFormGeometryCore.Pause.saveButton, local) { return .save }
        if contains(NativeOriginalFormGeometryCore.Pause.optionButton, local) { return .option }
        if contains(NativeOriginalFormGeometryCore.Pause.restartButton, local) { return .restart }
        if contains(NativeOriginalFormGeometryCore.Pause.exitButton, local) { return .exit }
        return nil
    }


    public static func roundTurnCloseHit(at local: NativePoint) -> Bool {
        contains(NativeOriginalFormGeometryCore.RoundTurn.closeButton, local)
    }

    public static func saveCloseHit(at local: NativePoint) -> Bool {
        contains(NativeOriginalFormGeometryCore.Save.closeButton, local)
    }

    public static func saveSlotAction(at local: NativePoint) -> NativeBattleSaveSlot? {
        let auto = offset(NativeOriginalFormGeometryCore.Save.autosaveOK, by: NativeOriginalFormGeometryCore.Save.autosaveSlot.origin)
        if contains(auto, local) { return .autosave }
        for (index, slotRect) in NativeOriginalFormGeometryCore.Save.manualSlots.enumerated() {
            let action = offset(NativeOriginalFormGeometryCore.Save.manualOK, by: slotRect.origin)
            if contains(action, local) { return .manual(index + 1) }
        }
        return nil
    }

    private static func contains(_ rect: NativeRect, _ p: NativePoint) -> Bool {
        p.x >= rect.origin.x && p.x <= rect.origin.x + rect.size.width &&
        p.y >= rect.origin.y && p.y <= rect.origin.y + rect.size.height
    }

    private static func offset(_ rect: NativeRect, by p: NativePoint) -> NativeRect {
        NativeRect(x: rect.origin.x + p.x, y: rect.origin.y + p.y, width: rect.size.width, height: rect.size.height)
    }
}
