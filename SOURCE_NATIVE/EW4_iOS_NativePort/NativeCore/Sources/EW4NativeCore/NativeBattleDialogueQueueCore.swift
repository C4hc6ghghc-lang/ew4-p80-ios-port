import Foundation

public struct NativeBattleDialogueQueueUpdate: Equatable, Sendable {
    public let active: NativeBattleScriptEvent?
    public let pendingCount: Int
    public let activeChanged: Bool
    public let drained: Bool

    public init(active: NativeBattleScriptEvent?, pendingCount: Int, activeChanged: Bool, drained: Bool) {
        self.active = active
        self.pendingCount = pendingCount
        self.activeChanged = activeChanged
        self.drained = drained
    }
}

/// Presentation queue matching mature P39 semantics: one active dialogue at a
/// time, click/advance consumes it, and autosave is requested only once the
/// final queued dialogue has drained.
public struct NativeBattleDialogueQueueCore: Sendable {
    public private(set) var active: NativeBattleScriptEvent?
    public private(set) var pending: [NativeBattleScriptEvent]

    public init(active: NativeBattleScriptEvent? = nil, pending: [NativeBattleScriptEvent] = []) {
        self.active = active
        self.pending = pending
    }

    public var isActive: Bool { active != nil }
    public var queuedCount: Int { pending.count + (active == nil ? 0 : 1) }

    @discardableResult
    public mutating func enqueue(_ events: [NativeBattleScriptEvent]) -> NativeBattleDialogueQueueUpdate {
        guard !events.isEmpty else {
            return NativeBattleDialogueQueueUpdate(active: active, pendingCount: pending.count, activeChanged: false, drained: false)
        }
        pending.append(contentsOf: events)
        let changed = activateNextIfNeeded()
        return NativeBattleDialogueQueueUpdate(active: active, pendingCount: pending.count, activeChanged: changed, drained: false)
    }

    @discardableResult
    public mutating func advance() -> NativeBattleDialogueQueueUpdate {
        guard active != nil else {
            return NativeBattleDialogueQueueUpdate(active: nil, pendingCount: pending.count, activeChanged: false, drained: false)
        }
        active = nil
        if activateNextIfNeeded() {
            return NativeBattleDialogueQueueUpdate(active: active, pendingCount: pending.count, activeChanged: true, drained: false)
        }
        return NativeBattleDialogueQueueUpdate(active: nil, pendingCount: 0, activeChanged: true, drained: true)
    }

    public mutating func reset() {
        active = nil
        pending.removeAll(keepingCapacity: true)
    }

    private mutating func activateNextIfNeeded() -> Bool {
        guard active == nil, !pending.isEmpty else { return false }
        active = pending.removeFirst()
        return true
    }
}
