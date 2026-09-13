import Foundation
import Testing
@testable import EW4NativeCore

private func dialogueEvent(_ id: Int, left: Bool) throws -> NativeBattleScriptEvent {
    let data = """
    {"sequence":\(id),"trigger_type":2,"param_a":4,"param_b":1,"event_id":\(1000 + id),"param_c":0,"country":"fra","param_d":0,"param_e":0,"param_f":0,"dialogue":{"commander_id":0,"left":\(left ? "true" : "false"),"text":"line \(id)"}}
    """.data(using: .utf8)!
    return try JSONDecoder().decode(NativeBattleScriptEvent.self, from: data)
}

@Test func dialogueQueueShowsOnlyOneEventAtATime() throws {
    var queue = NativeBattleDialogueQueueCore()
    let one = try dialogueEvent(1, left: true)
    let two = try dialogueEvent(2, left: false)
    let update = queue.enqueue([one, two])
    #expect(update.active == one)
    #expect(update.pendingCount == 1)
    #expect(queue.active == one)
    #expect(queue.queuedCount == 2)
}

@Test func advancingDialoguePresentsNextThenDrainsExactlyOnce() throws {
    var queue = NativeBattleDialogueQueueCore()
    let one = try dialogueEvent(1, left: true)
    let two = try dialogueEvent(2, left: false)
    _ = queue.enqueue([one, two])
    let next = queue.advance()
    #expect(next.active == two)
    #expect(next.activeChanged)
    #expect(!next.drained)
    #expect(queue.queuedCount == 1)
    let done = queue.advance()
    #expect(done.active == nil)
    #expect(done.drained)
    #expect(queue.queuedCount == 0)
    let idle = queue.advance()
    #expect(!idle.drained)
}

@Test func enqueueDuringActiveDialogueDoesNotReplaceCurrentSpeaker() throws {
    var queue = NativeBattleDialogueQueueCore()
    let one = try dialogueEvent(1, left: true)
    let two = try dialogueEvent(2, left: false)
    _ = queue.enqueue([one])
    let update = queue.enqueue([two])
    #expect(!update.activeChanged)
    #expect(queue.active == one)
    #expect(queue.pending == [two])
}
