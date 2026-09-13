import Foundation

public struct NativeCampaignStageNumber: Equatable, Sendable {
    public let zone: Int
    public let stage: Int
}

public struct NativeCampaignVariant: Sendable {
    public let battle: BattleRecord
    public let playerCode: String
    public let variant: Bool
}

public struct NativeCampaignTargetManifestFile: Decodable, Sendable {
    public let format: String
    public let battles: [String: NativeCampaignTargetBattle]
    public let totals: NativeCampaignTargetTotals?
}

public struct NativeCampaignTargetTotals: Decodable, Equatable, Sendable {
    public let battles: Int
    public let mapType1: Int
    public let mapType2: Int
    public let unitType1: Int
    public let unitType2: Int
    enum CodingKeys: String, CodingKey {
        case battles
        case mapType1 = "map_type1"
        case mapType2 = "map_type2"
        case unitType1 = "unit_type1"
        case unitType2 = "unit_type2"
    }
}

public struct NativeCampaignTargetBattle: Decodable, Sendable {
    public let mapID: Int
    public let countries: [NativeCampaignTargetCountry]
    public let mapTargets: [NativeCampaignMapTarget]
    public let unitTargets: [NativeCampaignUnitTarget]
    enum CodingKeys: String, CodingKey {
        case mapID = "map_id", countries
        case mapTargets = "map_targets"
        case unitTargets = "unit_targets"
    }
}

public struct NativeCampaignTargetCountry: Decodable, Equatable, Sendable {
    public let owner: Int
    public let side: Int
    public let playerMarker: Int
    enum CodingKeys: String, CodingKey { case owner, side, playerMarker = "player_marker" }
}

public struct NativeCampaignMapTarget: Decodable, Equatable, Sendable {
    public let recordIndex: Int
    public let pos: Int
    public let q: Int
    public let r: Int
    public let type: Int
    enum CodingKeys: String, CodingKey { case recordIndex = "record_index", pos, q, r, type }
}

public struct NativeCampaignUnitTarget: Decodable, Equatable, Sendable {
    public let unitIndex: Int
    public let pos: Int
    public let q: Int
    public let r: Int
    public let type: Int
    enum CodingKeys: String, CodingKey { case unitIndex = "unit_index", pos, q, r, type }
}

public struct NativeCampaignTargetCounts: Equatable, Sendable {
    public var friendly = 0
    public var hostile = 0
    public var neutral = 0
    public var total = 0
}

public struct NativeCampaignInitialTargetSnapshot: Equatable, Sendable {
    public let type1: NativeCampaignTargetCounts
    public let type2: NativeCampaignTargetCounts
}

public enum NativeCampaignObjectiveOutcome: Equatable, Sendable {
    case victory(reason: String)
    case defeat(reason: String)
}

public enum NativeCampaignCore {
    public static func canonicalFile(_ battle: BattleRecord) -> String {
        battle.meta?.pairedFrom ?? battle.file
    }

    public static func originalHide(_ battle: BattleRecord) -> Bool {
        Int(battle.meta?.hide ?? "0") == 1
    }

    public static func stageNumber(_ file: String) -> NativeCampaignStageNumber? {
        let pattern = #"^campaign([1-6])_(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: file, range: NSRange(file.startIndex..., in: file)),
              let zRange = Range(match.range(at: 1), in: file),
              let sRange = Range(match.range(at: 2), in: file),
              let zone = Int(file[zRange]), let stage = Int(file[sRange]) else { return nil }
        return NativeCampaignStageNumber(zone: zone, stage: stage)
    }

    public static func rows(zone: Int, battles: [BattleRecord]) -> [BattleRecord] {
        let prefix = "campaign\(max(1, min(6, zone)))_"
        return battles.filter { battle in
            guard battle.file.hasPrefix(prefix) else { return false }
            let tail = battle.file.dropFirst(prefix.count)
            guard tail.hasSuffix(".btl") else { return false }
            return Int(tail.dropLast(4)) != nil // excludes alternate *b.btl variants
        }.sorted {
            (stageNumber($0.file)?.stage ?? Int.max) < (stageNumber($1.file)?.stage ?? Int.max)
        }
    }

    public static func buildOpenStates(
        rows: [BattleRecord],
        progress: (String) -> Int
    ) -> [Int] {
        var states = Array(repeating: 0, count: rows.count)
        if !rows.isEmpty { states[0] = 1 }
        for i in rows.indices where progress(canonicalFile(rows[i])) > 0 {
            var j = i + 1
            while j < rows.count && originalHide(rows[j]) {
                states[j] = max(states[j], 1)
                j += 1
            }
            if j < rows.count { states[j] = max(states[j], 1) }
        }
        return states
    }

    public static func effectiveHide(_ battle: BattleRecord, secretUnlocked: (String) -> Bool) -> Int {
        originalHide(battle) && !secretUnlocked(canonicalFile(battle)) ? 1 : 0
    }

    public static func stageSelectable(
        rows: [BattleRecord],
        index: Int,
        progress: (String) -> Int,
        secretUnlocked: (String) -> Bool
    ) -> Bool {
        guard rows.indices.contains(index) else { return false }
        return buildOpenStates(rows: rows, progress: progress)[index] > effectiveHide(rows[index], secretUnlocked: secretUnlocked)
    }

    public static func selectableCountryCodes(_ battle: BattleRecord) -> [String] {
        (battle.meta?.countries ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    public static func resolveVariant(
        baseBattle: BattleRecord,
        countryCode: String,
        battles: [BattleRecord]
    ) -> NativeCampaignVariant? {
        let codes = selectableCountryCodes(baseBattle)
        let code = countryCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = baseBattle.countries.first(where: { $0.index == (baseBattle.playerOwnerDefault ?? 0) })?.code ?? code
        if codes.count < 2 || code.isEmpty {
            return NativeCampaignVariant(battle: baseBattle, playerCode: fallback, variant: false)
        }
        if code == codes[0] { return NativeCampaignVariant(battle: baseBattle, playerCode: code, variant: false) }
        if code == codes[1], let file2 = baseBattle.meta?.file2, let alt = battles.first(where: { $0.file == file2 }) {
            return NativeCampaignVariant(battle: alt, playerCode: code, variant: true)
        }
        return nil
    }

    public static func followingHidden(rows: [BattleRecord], currentFile: String) -> [BattleRecord] {
        guard let index = rows.firstIndex(where: { canonicalFile($0) == currentFile || $0.file == currentFile }) else { return [] }
        var out: [BattleRecord] = []
        var i = index + 1
        while i < rows.count && originalHide(rows[i]) { out.append(rows[i]); i += 1 }
        return out
    }

    public static func hiddenUnlockFiles(
        rows: [BattleRecord],
        currentBattle: BattleRecord,
        playerCode: String,
        yellowCleared: Bool
    ) -> [String] {
        guard yellowCleared, !originalHide(currentBattle) else { return [] }
        let followers = followingHidden(rows: rows, currentFile: canonicalFile(currentBattle))
        guard !followers.isEmpty else { return [] }
        let branch = selectableCountryCodes(currentBattle)
        if !branch.isEmpty {
            let matches = followers.filter { selectableCountryCodes($0).contains(playerCode) }
            return matches.map(canonicalFile)
        }
        return [canonicalFile(followers[0])]
    }

    public static func countrySide(_ spec: NativeCampaignTargetBattle, owner: Int) -> Int {
        if owner < 0 || owner == 255 { return 0 }
        return spec.countries.first(where: { $0.owner == owner })?.side ?? 0
    }

    public static func relation(_ spec: NativeCampaignTargetBattle, _ a: Int, _ b: Int) -> CountryRelation {
        if a == b { return .ally }
        if a < 0 || b < 0 || a == 255 || b == 255 { return .neutral }
        let sa = countrySide(spec, owner: a), sb = countrySide(spec, owner: b)
        if sa == 0 || sb == 0 { return .neutral }
        if sa == sb { return .ally }
        if sa == 4 || sb == 4 { return .neutral }
        if (sa == 1 && sb == 2) || (sa == 2 && sb == 1) { return .hostile }
        if (sa == 3 && (sb == 1 || sb == 2)) || (sb == 3 && (sa == 1 || sa == 2)) { return .hostile }
        return .neutral
    }

    public static func targetCounts(
        gameplay: NativeBattleGameplayState,
        manifest: NativeCampaignTargetManifestFile,
        type: Int
    ) -> NativeCampaignTargetCounts {
        guard let spec = manifest.battles[gameplay.battle.file], type != 0 else { return NativeCampaignTargetCounts() }
        var counts = NativeCampaignTargetCounts()
        func add(owner: Int) {
            switch relation(spec, gameplay.playerOwner, owner) {
            case .ally: counts.friendly += 1
            case .hostile: counts.hostile += 1
            case .neutral: counts.neutral += 1
            }
            counts.total += 1
        }
        for target in spec.unitTargets where target.type == type {
            guard let unit = gameplay.units[target.unitIndex], !unit.dead else { continue }
            add(owner: unit.owner)
        }
        for target in spec.mapTargets where target.type == type {
            // Every recovered native map target is an actual BTL object/facility cell.
            // Runtime object ownership therefore tracks capture without a second map-state model.
            guard let object = gameplay.object(at: HexCell(q: target.q, r: target.r)) else { continue }
            add(owner: object.owner)
        }
        return counts
    }

    public static func initialTargetSnapshot(
        gameplay: NativeBattleGameplayState,
        manifest: NativeCampaignTargetManifestFile
    ) -> NativeCampaignInitialTargetSnapshot {
        NativeCampaignInitialTargetSnapshot(
            type1: targetCounts(gameplay: gameplay, manifest: manifest, type: 1),
            type2: targetCounts(gameplay: gameplay, manifest: manifest, type: 2)
        )
    }

    /// Captures the objective contract from the pristine authored BTL rather than
    /// from a restored runtime. P39 deliberately does this before applying a save,
    /// so a mid-battle restore cannot redefine which red objectives existed at
    /// battle start. Every recovered map target is an authored BTL object cell.
    public static func authoredInitialTargetSnapshot(
        battle: BattleRecord,
        manifest: NativeCampaignTargetManifestFile,
        playerOwner explicitPlayerOwner: Int? = nil
    ) -> NativeCampaignInitialTargetSnapshot {
        guard let spec = manifest.battles[battle.file] else {
            return NativeCampaignInitialTargetSnapshot(
                type1: NativeCampaignTargetCounts(),
                type2: NativeCampaignTargetCounts()
            )
        }
        let playerOwner = explicitPlayerOwner ?? battle.playerOwnerDefault ?? 0

        func counts(type: Int) -> NativeCampaignTargetCounts {
            var out = NativeCampaignTargetCounts()
            func add(owner: Int) {
                switch relation(spec, playerOwner, owner) {
                case .ally: out.friendly += 1
                case .hostile: out.hostile += 1
                case .neutral: out.neutral += 1
                }
                out.total += 1
            }
            for target in spec.unitTargets where target.type == type {
                guard let unit = battle.units.first(where: { $0.index == target.unitIndex }) else { continue }
                add(owner: unit.owner)
            }
            for target in spec.mapTargets where target.type == type {
                guard let object = battle.objects.first(where: { $0.q == target.q && $0.r == target.r }) else { continue }
                add(owner: object.owner)
            }
            return out
        }

        return NativeCampaignInitialTargetSnapshot(type1: counts(type: 1), type2: counts(type: 2))
    }

    public static func mainObjectiveOutcome(
        gameplay: NativeBattleGameplayState,
        manifest: NativeCampaignTargetManifestFile,
        initial: NativeCampaignInitialTargetSnapshot,
        playerAlive: Bool,
        hostileAlive: Bool
    ) -> NativeCampaignObjectiveOutcome? {
        let now = targetCounts(gameplay: gameplay, manifest: manifest, type: 1)
        if initial.type1.friendly > 0 && now.friendly == 0 { return .defeat(reason: "objective") }
        if initial.type1.hostile > 0 && now.hostile == 0 { return .victory(reason: "objective") }
        if initial.type1.friendly == 0 && !playerAlive { return .defeat(reason: "annihilated") }
        if initial.type1.hostile == 0 && !hostileAlive { return .victory(reason: "annihilated") }
        return nil
    }

    public static func yellowSecretCleared(
        gameplay: NativeBattleGameplayState,
        manifest: NativeCampaignTargetManifestFile
    ) -> Bool {
        guard let spec = manifest.battles[gameplay.battle.file] else { return false }
        let total = spec.mapTargets.filter { $0.type == 2 }.count + spec.unitTargets.filter { $0.type == 2 }.count
        return total > 0 && targetCounts(gameplay: gameplay, manifest: manifest, type: 2).hostile == 0
    }

    public static func hasTargets(_ manifest: NativeCampaignTargetManifestFile, battle: BattleRecord, type: Int) -> Bool {
        guard let spec = manifest.battles[battle.file] else { return false }
        return spec.mapTargets.contains(where: { $0.type == type }) || spec.unitTargets.contains(where: { $0.type == type })
    }
}
