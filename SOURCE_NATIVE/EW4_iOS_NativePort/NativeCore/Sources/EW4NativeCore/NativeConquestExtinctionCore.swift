import Foundation

public struct NativeConquestCountryStatus: Equatable, Sendable {
    public let owner: Int
    public let landArmyAlive: Bool
    public let landFacilitiesHeld: Bool
    public let portsHeld: Bool
    public var defeated: Bool { !landArmyAlive && !landFacilitiesHeld && !portsHeld }
}

public enum NativeConquestOutcome: Equatable, Sendable {
    case victory(reason: String, owners: [Int])
    case defeat(reason: String, owner: Int, status: NativeConquestCountryStatus)
}

public enum NativeConquestExtinctionCore {
    public static let landArmyTypes: Set<String> = ["infantry", "cavalry", "artillery"]
    public static let landFacilityTypes: Set<String> = ["city", "industry", "stable", "farmland"]
    public static let portType = "port"

    public static func countryStatus(_ state: NativeBattleGameplayState, owner: Int) -> NativeConquestCountryStatus {
        let landArmyAlive = state.unitOrder.compactMap { state.units[$0] }.contains { unit in
            guard unit.owner == owner, !unit.dead, let stat = state.stat(for: unit) else { return false }
            return landArmyTypes.contains(stat.type.lowercased())
        }
        let landFacilitiesHeld = state.objects.values.contains { object in
            object.owner == owner && landFacilityTypes.contains((object.constructionType ?? "").lowercased())
        }
        let portsHeld = state.objects.values.contains { object in
            object.owner == owner && (object.constructionType ?? "").lowercased() == portType
        }
        return NativeConquestCountryStatus(
            owner: owner,
            landArmyAlive: landArmyAlive,
            landFacilitiesHeld: landFacilitiesHeld,
            portsHeld: portsHeld
        )
    }

    public static func ownerCandidates(_ state: NativeBattleGameplayState) -> [Int] {
        var owners = Set<Int>()
        for country in state.battle.countries where country.index != 255 { owners.insert(country.index) }
        for unit in state.units.values where unit.owner != 255 { owners.insert(unit.owner) }
        for object in state.objects.values {
            let type = (object.constructionType ?? "").lowercased()
            if object.owner != 255 && (landFacilityTypes.contains(type) || type == portType) {
                owners.insert(object.owner)
            }
        }
        return owners.sorted()
    }

    public static func defeatedOwners(_ state: NativeBattleGameplayState) -> [Int] {
        ownerCandidates(state).filter { countryStatus(state, owner: $0).defeated }
    }

    public static func hostileOwners(_ state: NativeBattleGameplayState) -> [Int] {
        ownerCandidates(state).filter { owner in
            owner != state.playerOwner && state.relation(state.playerOwner, owner) == .hostile
        }
    }

    public static func outcome(_ state: NativeBattleGameplayState) -> NativeConquestOutcome? {
        let player = countryStatus(state, owner: state.playerOwner)
        if player.defeated {
            return .defeat(reason: "country-extinction", owner: state.playerOwner, status: player)
        }
        let hostile = hostileOwners(state)
        if !hostile.isEmpty && hostile.allSatisfy({ countryStatus(state, owner: $0).defeated }) {
            return .victory(reason: "hostile-powers-extinct", owners: hostile)
        }
        return nil
    }
}
