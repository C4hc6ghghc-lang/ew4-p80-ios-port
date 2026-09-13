import Foundation
import Testing
@testable import EW4NativeCore

private func p49Battles() throws -> [BattleRecord] {
    try ResourceLoader.decode(BattlesRuntimeFile.self, from: TestResourcePaths.data("battles_runtime.json")).battles
}

private func p49CampaignTargets() throws -> NativeCampaignTargetManifestFile {
    try ResourceLoader.decode(NativeCampaignTargetManifestFile.self, from: TestResourcePaths.data("native_campaign_targets.json"))
}

@Test func campaignRowsOpenHiddenProgressionAndSecretSelectionMatchP39() throws {
    let battles = try p49Battles()
    let rows = NativeCampaignCore.rows(zone: 1, battles: battles)
    let progress = ["campaign1_04.btl": 1]
    let i5 = try #require(rows.firstIndex(where: { $0.file == "campaign1_05.btl" }))
    let i6 = try #require(rows.firstIndex(where: { $0.file == "campaign1_06.btl" }))
    #expect(!NativeCampaignCore.stageSelectable(rows: rows, index: i5, progress: { progress[$0] ?? 0 }, secretUnlocked: { _ in false }))
    #expect(NativeCampaignCore.stageSelectable(rows: rows, index: i6, progress: { progress[$0] ?? 0 }, secretUnlocked: { _ in false }))
    #expect(NativeCampaignCore.stageSelectable(rows: rows, index: i5, progress: { progress[$0] ?? 0 }, secretUnlocked: { $0 == "campaign1_05.btl" }))
}

@Test func campaignCountryVariantsAndBranchSpecificSecretsMatchRecoveredP39() throws {
    let battles = try p49Battles()
    let b410 = try #require(battles.first(where: { $0.file == "campaign4_10.btl" }))
    let b410b = try #require(battles.first(where: { $0.file == "campaign4_10b.btl" }))
    let rows = NativeCampaignCore.rows(zone: 4, battles: battles)
    #expect(NativeCampaignCore.selectableCountryCodes(b410) == ["tur", "rus"])
    #expect(NativeCampaignCore.resolveVariant(baseBattle: b410, countryCode: "tur", battles: battles)?.battle.file == "campaign4_10.btl")
    #expect(NativeCampaignCore.resolveVariant(baseBattle: b410, countryCode: "rus", battles: battles)?.battle.file == "campaign4_10b.btl")
    #expect(NativeCampaignCore.hiddenUnlockFiles(rows: rows, currentBattle: b410, playerCode: "tur", yellowCleared: true) == ["campaign4_11.btl"])
    #expect(NativeCampaignCore.hiddenUnlockFiles(rows: rows, currentBattle: b410b, playerCode: "rus", yellowCleared: true) == ["campaign4_12.btl"])
}

@Test func campaignTargetManifestMatchesRecoveredTotalsAndRelations() throws {
    let manifest = try p49CampaignTargets()
    #expect(manifest.totals == NativeCampaignTargetTotals(battles: 101, mapType1: 349, mapType2: 5, unitType1: 185, unitType2: 6))
    let spec = try #require(manifest.battles["campaign1_18.btl"])
    #expect(NativeCampaignCore.relation(spec, 0, 2) == .ally)
    #expect(NativeCampaignCore.relation(spec, 0, 1) == .hostile)
    #expect(NativeCampaignCore.relation(spec, 0, 5) == .hostile)
    let s101 = try #require(manifest.battles["campaign1_01.btl"])
    #expect(NativeCampaignCore.relation(s101, 0, 4) == .neutral)
}

@Test func everyRecoveredCampaignMapTargetResolvesToAuthoredBTLObject() throws {
    let battles = Dictionary(uniqueKeysWithValues: try p49Battles().map { ($0.file, $0) })
    let manifest = try p49CampaignTargets()
    var checked = 0
    for (file, spec) in manifest.battles {
        guard let battle = battles[file] else { continue }
        for target in spec.mapTargets {
            #expect(battle.objects.contains(where: { $0.q == target.q && $0.r == target.r }))
            checked += 1
        }
    }
    #expect(checked == 354)
}

@Test func campaignAuthoredSnapshotUsesPristineBTLContract() throws {
    let battles = try p49Battles()
    let manifest = try p49CampaignTargets()
    let battle = try #require(battles.first(where: { $0.file == "campaign1_03.btl" }))
    let snapshot = NativeCampaignCore.authoredInitialTargetSnapshot(battle: battle, manifest: manifest)
    #expect(snapshot.type1 == NativeCampaignTargetCounts(friendly: 1, hostile: 3, neutral: 0, total: 4))
}
