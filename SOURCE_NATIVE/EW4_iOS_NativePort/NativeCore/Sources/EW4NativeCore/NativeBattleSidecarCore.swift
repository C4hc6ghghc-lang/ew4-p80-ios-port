import Foundation

public enum NativeBattleSidecarCore {
    @discardableResult
    public static func applyAttackResult(
        _ result: NativeBattleAttackResult,
        context: inout NativeBattlePersistenceContext
    ) -> Int {
        let delta = max(0, result.collectedMedals)
        if delta > 0 { context.collectMedal = max(0, context.collectMedal) + delta }
        return delta
    }
}
