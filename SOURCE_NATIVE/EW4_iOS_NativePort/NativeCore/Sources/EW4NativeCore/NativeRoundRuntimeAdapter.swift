import Foundation

/// Effective commander state consumed by round settlement. The projection is
/// intentionally supplied by the app/profile layer so battle logic never
/// mistakes raw commander data for the user's upgraded/equipped commander.
public struct NativeCommanderRoundProjection: Equatable, Sendable {
    public let skillIDs: Set<Int>
    public let equippedItemIDs: [Int]
    public let nobilityLevel: Int
    public let nobilityHealCap: Int

    public init(
        skillIDs: Set<Int> = [],
        equippedItemIDs: [Int] = [],
        nobilityLevel: Int = 0,
        nobilityHealCap: Int = 25
    ) {
        self.skillIDs = skillIDs
        self.equippedItemIDs = equippedItemIDs.filter { $0 >= 0 }
        self.nobilityLevel = max(0, nobilityLevel)
        self.nobilityHealCap = max(0, nobilityHealCap)
    }

    public static func base(_ commander: Commander?) -> NativeCommanderRoundProjection {
        guard let commander else { return NativeCommanderRoundProjection() }
        return NativeCommanderRoundProjection(
            skillIDs: commander.skillIDs,
            equippedItemIDs: [commander.item1, commander.item2].compactMap { value in
                guard let value, value >= 0 else { return nil }
                return value
            },
            nobilityLevel: commander.nobilityrank,
            nobilityHealCap: 25
        )
    }
}

public enum NativeRoundRuntimeAdapter {
    public typealias ProjectionProvider = @Sendable (_ commanderID: Int, _ playerControlled: Bool) -> NativeCommanderRoundProjection?

    public static func unitContexts(
        gameplay: NativeBattleGameplayState,
        projectionProvider: ProjectionProvider? = nil
    ) -> [NativeRoundUnitContext] {
        gameplay.unitOrder.compactMap { index in
            guard let unit = gameplay.units[index], let stat = gameplay.stat(for: unit) else { return nil }
            let commander = gameplay.commander(for: unit)
            let projection: NativeCommanderRoundProjection
            if let commanderID = unit.commanderID,
               let supplied = projectionProvider?(commanderID, unit.owner == gameplay.playerOwner) {
                projection = supplied
            } else {
                projection = .base(commander)
            }
            return NativeRoundUnitContext(
                index: unit.index,
                owner: unit.owner,
                q: unit.q,
                r: unit.r,
                armyName: unit.armyName,
                grade: unit.grade,
                commanderID: unit.commanderID,
                commanderSkillIDs: projection.skillIDs,
                equippedItemIDs: projection.equippedItemIDs,
                nobilityLevel: projection.nobilityLevel,
                nobilityHealCap: projection.nobilityHealCap,
                trainingLevel: unit.trainingLevel,
                consumption: stat.consumption,
                attacked: unit.attacked,
                hp: unit.hp,
                maxHP: unit.maxHP
            )
        }
    }

    public static func objectContexts(gameplay: NativeBattleGameplayState) -> [NativeRoundObjectContext] {
        gameplay.objects.values.sorted { $0.index < $1.index }.map {
            NativeRoundObjectContext(
                index: $0.index,
                owner: $0.owner,
                q: $0.q,
                r: $0.r,
                constructionType: $0.constructionType,
                level: $0.level
            )
        }
    }

    @discardableResult
    public static func settleCountryEconomy(
        owner: Int,
        gameplay: NativeBattleGameplayState,
        context: inout NativeBattlePersistenceContext,
        constructions: NativeConstructionCatalog,
        items: NativeItemEffectCatalog,
        projectionProvider: ProjectionProvider? = nil
    ) -> NativeCountryEconomySettlement {
        let units = unitContexts(gameplay: gameplay, projectionProvider: projectionProvider)
        let objects = objectContexts(gameplay: gameplay)
        let current = context.countryResources[owner] ?? CountryResources(money: 0, industry: 0, food: 0)
        let result = NativeRoundSettlementCore.settleCountryEconomy(
            owner: owner,
            resources: current,
            units: units,
            objects: objects,
            constructions: constructions,
            items: items,
            mode: gameplay.mode,
            playerOwner: gameplay.playerOwner,
            campaignTechLevels: context.campaignTech
        )
        context.countryResources[owner] = result.resources
        if owner == gameplay.playerOwner {
            context.resources = result.resources
        }
        return result
    }

    /// P39 order: player economy -> training recovery -> facility supply ->
    /// player nobility/flag/tent recovery. Crucially this runs before action
    /// flags are reset, because tent healing depends on whether the unit attacked.
    @discardableResult
    public static func settlePlayerRound(
        gameplay: inout NativeBattleGameplayState,
        context: inout NativeBattlePersistenceContext,
        constructions: NativeConstructionCatalog,
        items: NativeItemEffectCatalog,
        projectionProvider: ProjectionProvider? = nil
    ) -> NativePlayerRoundSettlement {
        let units = unitContexts(gameplay: gameplay, projectionProvider: projectionProvider)
        let objects = objectContexts(gameplay: gameplay)
        let resources = context.countryResources[gameplay.playerOwner] ?? context.resources
        let result = NativeRoundSettlementCore.settlePlayerRound(
            playerOwner: gameplay.playerOwner,
            resources: resources,
            units: units,
            objects: objects,
            constructions: constructions,
            items: items,
            mode: gameplay.mode,
            campaignTechLevels: context.campaignTech,
            relation: { gameplay.relation($0, $1) }
        )
        gameplay.applyRoundHitPoints(Dictionary(uniqueKeysWithValues: result.units.map { ($0.index, $0.hp) }))
        context.resources = result.resources
        context.countryResources[gameplay.playerOwner] = result.resources
        return result
    }
}
