import Foundation

public struct NativeBattleDialogueEvent: Decodable, Equatable, Sendable {
    public let id: Int?
    public let commanderID: Int?
    public let textID: Int?
    public let left: Bool?
    public let text: String?

    enum CodingKeys: String, CodingKey {
        case id
        case commanderID = "commander_id"
        case textID = "text_id"
        case left, text
    }
}

public struct NativeBattleScriptEvent: Decodable, Equatable, Sendable {
    public let sequence: Int
    public let triggerType: Int
    public let paramA: Int
    public let paramB: Int
    public let eventID: Int
    public let paramC: Int
    public let country: String
    public let paramD: Int
    public let paramE: Int
    public let paramF: Int
    public let dialogue: NativeBattleDialogueEvent?

    enum CodingKeys: String, CodingKey {
        case sequence
        case triggerType = "trigger_type"
        case paramA = "param_a"
        case paramB = "param_b"
        case eventID = "event_id"
        case paramC = "param_c"
        case country
        case paramD = "param_d"
        case paramE = "param_e"
        case paramF = "param_f"
        case dialogue
    }

    public var eventKey: String {
        "\(triggerType):\(paramA):\(paramB):\(sequence):\(eventID):\(paramC)"
    }

    public var dialogueKey: String { "\(sequence):\(eventID)" }
}

public struct NativeBattleEventBattle: Decodable, Sendable {
    public let events: [NativeBattleScriptEvent]
}

public struct NativeBattleEventCatalogFile: Decodable, Sendable {
    public let format: String
    public let battles: [String: NativeBattleEventBattle]
}

public struct NativeTriggerBinding: Decodable, Equatable, Sendable {
    public let sequence: Int
    public let eventID: Int?
    public let targetIndex: Int
    enum CodingKeys: String, CodingKey {
        case sequence
        case eventID = "event_id"
        case targetIndex = "target_index"
    }
}

public struct NativeTriggerTargetCatalogFile: Decodable, Sendable {
    public let format: String
    public let capture: [String: [NativeTriggerBinding]]
    public let death: [String: [NativeTriggerBinding]]
}

public struct NativeBattleEventApplication: Equatable, Sendable {
    public var appliedEvents: [NativeBattleScriptEvent]
    public var newlyQueuedDialogues: [NativeBattleScriptEvent]
    public var moraleUnitCount: Int
    public var fireApplied: [HexCell]
    public var fireBlocked: [HexCell]

    public init(
        appliedEvents: [NativeBattleScriptEvent] = [],
        newlyQueuedDialogues: [NativeBattleScriptEvent] = [],
        moraleUnitCount: Int = 0,
        fireApplied: [HexCell] = [],
        fireBlocked: [HexCell] = []
    ) {
        self.appliedEvents = appliedEvents
        self.newlyQueuedDialogues = newlyQueuedDialogues
        self.moraleUnitCount = moraleUnitCount
        self.fireApplied = fireApplied
        self.fireBlocked = fireBlocked
    }

    public mutating func merge(_ other: NativeBattleEventApplication) {
        appliedEvents.append(contentsOf: other.appliedEvents)
        newlyQueuedDialogues.append(contentsOf: other.newlyQueuedDialogues)
        moraleUnitCount += other.moraleUnitCount
        fireApplied.append(contentsOf: other.fireApplied)
        fireBlocked.append(contentsOf: other.fireBlocked)
    }
}

public enum NativeBattleEventCore {
    public static func moraleForAction(_ action: Int) -> Int? {
        switch action {
        case 0: return 1
        case 1: return -1
        case 2: return -2
        case 3: return -3
        default: return nil
        }
    }

    public static func captureEvents(
        battleFile: String,
        objectIndex: Int,
        catalog: NativeBattleEventCatalogFile,
        targets: NativeTriggerTargetCatalogFile
    ) -> [NativeBattleScriptEvent] {
        boundEvents(triggerType: 0, battleFile: battleFile, targetIndex: objectIndex, bindings: targets.capture[battleFile] ?? [], catalog: catalog)
    }

    public static func deathEvents(
        battleFile: String,
        unitIndex: Int,
        catalog: NativeBattleEventCatalogFile,
        targets: NativeTriggerTargetCatalogFile
    ) -> [NativeBattleScriptEvent] {
        boundEvents(triggerType: 1, battleFile: battleFile, targetIndex: unitIndex, bindings: targets.death[battleFile] ?? [], catalog: catalog)
    }

    public static func roundEvents(
        battleFile: String,
        round: Int,
        catalog: NativeBattleEventCatalogFile
    ) -> [NativeBattleScriptEvent] {
        (catalog.battles[battleFile]?.events ?? [])
            .filter { $0.triggerType == 2 && $0.paramB == round }
            .sorted { lhs, rhs in
                if lhs.sequence != rhs.sequence { return lhs.sequence < rhs.sequence }
                return lhs.eventID < rhs.eventID
            }
    }

    public static func eventCell(_ event: NativeBattleScriptEvent, worldWidth: Int) -> HexCell? {
        guard event.paramC > 0, worldWidth > 0 else { return nil }
        return HexCell(q: event.paramC % worldWidth, r: event.paramC / worldWidth)
    }

    public static func applyScriptEvents(
        _ events: [NativeBattleScriptEvent],
        gameplay: inout NativeBattleGameplayState,
        context: inout NativeBattlePersistenceContext
    ) -> NativeBattleEventApplication {
        var result = NativeBattleEventApplication()
        for event in events {
            guard !context.nativeAppliedEvents.contains(event.eventKey) else { continue }
            context.nativeAppliedEvents.insert(event.eventKey)
            result.appliedEvents.append(event)
            applyEffect(event, gameplay: &gameplay, context: &context, result: &result, effectRound: gameplay.round)
            queueDialogueIfNeeded(event, context: &context, result: &result)
        }
        return result
    }

    public static func applyRoundEvents(
        battleFile: String,
        round: Int,
        catalog: NativeBattleEventCatalogFile,
        gameplay: inout NativeBattleGameplayState,
        context: inout NativeBattlePersistenceContext
    ) -> NativeBattleEventApplication {
        var result = NativeBattleEventApplication()
        for event in roundEvents(battleFile: battleFile, round: round, catalog: catalog) {
            if event.paramA == 4 {
                queueDialogueIfNeeded(event, context: &context, result: &result)
                continue
            }
            guard !context.nativeAppliedEvents.contains(event.eventKey) else {
                queueDialogueIfNeeded(event, context: &context, result: &result)
                continue
            }
            context.nativeAppliedEvents.insert(event.eventKey)
            result.appliedEvents.append(event)
            applyEffect(event, gameplay: &gameplay, context: &context, result: &result, effectRound: round)
            queueDialogueIfNeeded(event, context: &context, result: &result)
        }
        return result
    }

    private static func boundEvents(
        triggerType: Int,
        battleFile: String,
        targetIndex: Int,
        bindings: [NativeTriggerBinding],
        catalog: NativeBattleEventCatalogFile
    ) -> [NativeBattleScriptEvent] {
        let events = catalog.battles[battleFile]?.events ?? []
        return bindings
            .filter { $0.targetIndex == targetIndex }
            .compactMap { binding in
                events.first {
                    $0.triggerType == triggerType &&
                    $0.sequence == binding.sequence &&
                    (binding.eventID == nil || $0.eventID == binding.eventID)
                }
            }
    }

    private static func applyEffect(
        _ event: NativeBattleScriptEvent,
        gameplay: inout NativeBattleGameplayState,
        context: inout NativeBattlePersistenceContext,
        result: inout NativeBattleEventApplication,
        effectRound: Int
    ) {
        if let morale = moraleForAction(event.paramA), !event.country.isEmpty {
            result.moraleUnitCount += gameplay.applyNativeMorale(
                countryCode: event.country,
                base: morale,
                untilRound: effectRound + 3
            )
        }
        if event.paramA == 5, let cell = eventCell(event, worldWidth: gameplay.world.width) {
            let key = "\(cell.q),\(cell.r)"
            if gameplay.isFireproof(at: cell) {
                context.fireCells.remove(key)
                result.fireBlocked.append(cell)
            } else {
                context.fireCells.insert(key)
                result.fireApplied.append(cell)
            }
        }
    }

    private static func queueDialogueIfNeeded(
        _ event: NativeBattleScriptEvent,
        context: inout NativeBattlePersistenceContext,
        result: inout NativeBattleEventApplication
    ) {
        guard let text = event.dialogue?.text, !text.isEmpty else { return }
        guard !context.nativeFiredEvents.contains(event.dialogueKey) else { return }
        context.nativeFiredEvents.insert(event.dialogueKey)
        result.newlyQueuedDialogues.append(event)
    }
}
