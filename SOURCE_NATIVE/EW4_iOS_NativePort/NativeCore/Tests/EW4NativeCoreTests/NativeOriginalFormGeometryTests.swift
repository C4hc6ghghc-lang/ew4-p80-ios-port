import Testing
@testable import EW4NativeCore

@Test func originalFormsKeepRecoveredXMLDimensions() {
    #expect(NativeOriginalFormGeometryCore.StageIntro.frame == NativeRect(x: 0, y: 0, width: 360, height: 219))
    #expect(NativeOriginalFormGeometryCore.Talk.size == NativeSize(width: 325, height: 83))
    #expect(NativeOriginalFormGeometryCore.Pause.frame == NativeRect(x: 0, y: 0, width: 166, height: 272))
    #expect(NativeOriginalFormGeometryCore.RoundTurn.frame == NativeRect(x: 0, y: 0, width: 320, height: 175))
    #expect(NativeOriginalFormGeometryCore.Victory.frame == NativeRect(x: 0, y: 0, width: 346, height: 210))
    #expect(NativeOriginalFormGeometryCore.Save.frame == NativeRect(x: 0, y: 0, width: 352, height: 235))
}

@Test func talkUsesP39AdaptedBattlePlacementAndOriginalInternals() {
    #expect(NativeOriginalFormGeometryCore.Talk.leftFrame == NativeRect(x: 0, y: 225, width: 325, height: 83))
    #expect(NativeOriginalFormGeometryCore.Talk.rightFrame == NativeRect(x: 236, y: 225, width: 325, height: 83))
    #expect(NativeOriginalFormGeometryCore.Talk.portraitLeft == NativeRect(x: 10, y: 7, width: 78, height: 78))
    #expect(NativeOriginalFormGeometryCore.Talk.contentLeft == NativeRect(x: 88, y: 7, width: 220, height: 76))
    #expect(NativeOriginalFormGeometryCore.Talk.contentRight == NativeRect(x: 17, y: 7, width: 220, height: 76))
    #expect(NativeOriginalFormGeometryCore.Talk.nameInContent.origin == NativePoint(x: 4, y: 1))
    #expect(NativeOriginalFormGeometryCore.Talk.textInContent.origin == NativePoint(x: 2, y: 20))
}

@Test func pauseAndSaveHitGeometryMatchesRecoveredLayout() {
    #expect(NativeOriginalFormGeometryCore.Pause.saveButton == NativeRect(x: 42, y: 65, width: 83, height: 35))
    #expect(NativeOriginalFormGeometryCore.Pause.exitButton == NativeRect(x: 42, y: 215, width: 83, height: 35))
    #expect(NativeOriginalFormGeometryCore.Pause.separatorY == [58, 108, 158, 208])
    #expect(NativeOriginalFormGeometryCore.Save.manualSlots.count == 6)
    #expect(NativeOriginalFormGeometryCore.Save.manualSlots[0] == NativeRect(x: 4, y: 31, width: 114, height: 67))
    #expect(NativeOriginalFormGeometryCore.Save.manualSlots[5] == NativeRect(x: 235, y: 165, width: 114, height: 67))
    #expect(NativeOriginalFormGeometryCore.Save.autosaveSlot == NativeRect(x: 119, y: 88, width: 114, height: 87))
}

@Test func victoryGeometryKeepsOriginalButtonAndGeneralRows() {
    #expect(NativeOriginalFormGeometryCore.Victory.battleName == NativeRect(x: 2, y: 27, width: 240, height: 20))
    #expect(NativeOriginalFormGeometryCore.Victory.generals == NativeRect(x: 13, y: 95, width: 320, height: 59))
    #expect(NativeOriginalFormGeometryCore.Victory.continueButton == NativeRect(x: 40, y: 165, width: 70, height: 35))
    #expect(NativeOriginalFormGeometryCore.Victory.exitButton == NativeRect(x: 235, y: 165, width: 70, height: 35))
}

@Test func stageIntroUsesP39ScreenPlacementAndRecoveredCloseHitbox() {
    #expect(NativeOriginalFormGeometryCore.StageIntro.screenFrame == NativeRect(x: 104, y: 50, width: 360, height: 219))
    #expect(NativeOriginalFormGeometryCore.StageIntro.closeButton == NativeRect(x: 343, y: -8, width: 25, height: 25))
}

@Test func toulonStageIntroContentComesFromRecoveredP39BattleData() throws {
    let battles = try ResourceLoader.decode(BattlesRuntimeFile.self, from: TestResourcePaths.data("battles_runtime.json"))
    let raw = try ResourceLoader.decode([String: Commander].self, from: TestResourcePaths.data("commanders.json"))
    let commanders = Dictionary(uniqueKeysWithValues: raw.values.map { ($0.id, $0) })
    let battle = try #require(battles.battles.first { $0.file == "campaign1_01.btl" })
    let intro = NativeOriginalFormContentCore.stageIntro(battle: battle, commanders: commanders)
    #expect(intro.commanderID == 24)
    #expect(intro.commanderName == "Treville")
    #expect(intro.victoryRounds == 22)
    #expect(intro.bestVictoryRounds == 8)
    #expect(intro.description.hasPrefix("反法同盟已经在叛军的帮助下占领了我国多个城市"))
}

@Test func pauseAndSaveUseMatureP39BattleScreenPlacement() {
    #expect(NativeOriginalFormGeometryCore.Pause.screenFrame == NativeRect(x: 201, y: 24, width: 166, height: 272))
    #expect(NativeOriginalFormGeometryCore.Pause.hudButton == NativeRect(x: 535, y: 2, width: 27, height: 27))
    #expect(NativeOriginalFormGeometryCore.Pause.closeButton == NativeRect(x: 149, y: -8, width: 25, height: 25))
    #expect(NativeOriginalFormGeometryCore.Save.screenFrame == NativeRect(x: 108, y: 42, width: 352, height: 235))
    #expect(NativeOriginalFormGeometryCore.Save.closeButton == NativeRect(x: 335, y: -8, width: 25, height: 25))
}

@Test func saveSlotDisplaysKeepOneAutosavePlusSixManualAndResolveCountryFlag() throws {
    let battles = try ResourceLoader.decode(BattlesRuntimeFile.self, from: TestResourcePaths.data("battles_runtime.json"))
    let battle = try #require(battles.battles.first { $0.file == "campaign1_01.btl" })
    let state = NativeBattleSaveState(
        battleFile: battle.file, battleTitle: battle.titleCN, map: "europe", mode: "campaign",
        playerOwner: battle.playerOwnerDefault ?? 0, round: 1,
        resources: CountryResources(money: 0, industry: 0, food: 0),
        camera: NativeSaveCamera(x: 284, y: 160, zoom: 1)
    )
    let payload = try NativeBattleSaveCore.makePayload(from: state, savedAt: 1000)
    let meta = NativeBattleSaveSlotMetadata(slot: NativeBattleSaveSlot.autosave, payload: payload)
    let displays = NativeOriginalBattleModalCore.saveSlotDisplays(metadata: [meta], battles: battles.battles)
    #expect(displays.count == 7)
    #expect(displays[0].slot == NativeBattleSaveSlot.autosave)
    #expect(!displays[0].empty)
    #expect(displays[0].countryCode == "fra")
    #expect(displays.dropFirst().allSatisfy { $0.empty })
}

@Test func originalPauseAndSaveActionHitboxesDoNotDrift() {
    #expect(NativeOriginalBattleModalCore.pauseAction(at: NativePoint(x: 50, y: 75)) == .save)
    #expect(NativeOriginalBattleModalCore.pauseAction(at: NativePoint(x: 50, y: 125)) == .option)
    #expect(NativeOriginalBattleModalCore.pauseAction(at: NativePoint(x: 50, y: 175)) == .restart)
    #expect(NativeOriginalBattleModalCore.pauseAction(at: NativePoint(x: 50, y: 225)) == .exit)
    #expect(NativeOriginalBattleModalCore.pauseAction(at: NativePoint(x: 160, y: 0)) == .close)
    #expect(NativeOriginalBattleModalCore.saveSlotAction(at: NativePoint(x: 205, y: 150)) == .autosave)
    #expect(NativeOriginalBattleModalCore.saveSlotAction(at: NativePoint(x: 95, y: 75)) == .manual(1))
    #expect(NativeOriginalBattleModalCore.saveSlotAction(at: NativePoint(x: 326, y: 209)) == .manual(6))
}


@Test func roundTurnGeometryMatchesRecoveredXMLAndP39Placement() {
    #expect(NativeOriginalFormGeometryCore.RoundTurn.screenFrame == NativeRect(x: 124, y: 72, width: 320, height: 175))
    #expect(NativeOriginalFormGeometryCore.RoundTurn.closeButton == NativeRect(x: 303, y: -8, width: 25, height: 25))
    #expect(NativeOriginalFormGeometryCore.RoundTurn.verticalLines == [
        NativeRect(x: 106, y: 28, width: 1, height: 63),
        NativeRect(x: 213, y: 28, width: 1, height: 63),
    ])
    #expect(NativeOriginalFormGeometryCore.RoundTurn.generals == NativeRect(x: 11, y: 105, width: 299, height: 59))
    #expect(NativeOriginalBattleModalCore.roundTurnCloseHit(at: NativePoint(x: 310, y: 0)))
    #expect(!NativeOriginalBattleModalCore.roundTurnCloseHit(at: NativePoint(x: 150, y: 80)))
}

@Test func roundTurnContentUsesCompletedRoundSettlementAndLivingPlayerGenerals() throws {
    let battles = try ResourceLoader.decode(BattlesRuntimeFile.self, from: TestResourcePaths.data("battles_runtime.json"))
    let worlds = try ResourceLoader.decode(WorldMapsFile.self, from: TestResourcePaths.data("worldmaps.json"))
    let stats = try ResourceLoader.decode(ArmyStatsCatalog.self, from: TestResourcePaths.data("army_stats.json"))
    let raw = try ResourceLoader.decode([String: Commander].self, from: TestResourcePaths.data("commanders.json"))
    let commanders = Dictionary(uniqueKeysWithValues: raw.values.map { ($0.id, $0) })
    let session = try NativeBattleLoader.session(file: "campaign1_01.btl", battles: battles, worlds: worlds)
    var gameplay = NativeBattleGameplayState(
        session: session, terrainTypes: worlds.terrainTypes, armyStats: stats, commanders: commanders,
        mode: .campaign, playerOwner: session.battle.playerOwnerDefault
    )
    gameplay.restoreRuntimeState(
        round: 2, ended: false,
        restoredUnits: gameplay.unitOrder.compactMap { gameplay.units[$0] },
        restoredObjects: gameplay.objects.values.sorted { $0.index < $1.index }
    )
    let units = NativeRoundRuntimeAdapter.unitContexts(gameplay: gameplay)
    let settlement = NativePlayerRoundSettlement(
        money: 321, industry: 45, foodAdd: 67, foodDel: 12, healed: 0,
        trainingHealed: 0, facilityHealed: 0, playerSpecialHealed: 0,
        resources: CountryResources(money: 321, industry: 45, food: 55), units: units
    )
    let content = NativeOriginalFormContentCore.roundTurn(gameplay: gameplay, settlement: settlement, commanders: commanders)
    #expect(content.money == 321)
    #expect(content.industry == 45)
    #expect(content.foodAdd == 67)
    #expect(content.foodDel == 12)
    #expect(content.round == 2)
    #expect(content.bestRound == 8)
    #expect(content.winRound == 22)
    #expect(content.generals.count <= 6)
    #expect(Set(content.generals.map(\.commanderID)).count == content.generals.count)
    #expect(content.generals.allSatisfy { !$0.name.isEmpty })
}


@Test func roundTurnSceneOrderingKeepsSettlementModalDialogueAutosaveContract() throws {
    let source = try String(contentsOf: TestResourcePaths.projectRoot
        .appendingPathComponent("NativeCore/Sources/EW4NativeRenderer/NativeBattleScene.swift"), encoding: .utf8)
    let settle = try #require(source.range(of: "case .roundReadyToSettle:"))
    let complete = try #require(source.range(of: "completeRoundAfterSettlement", range: settle.lowerBound..<source.endIndex))
    let present = try #require(source.range(of: "presentNativeRoundTurn(content)", range: complete.upperBound..<source.endIndex))
    #expect(settle.lowerBound < complete.lowerBound)
    #expect(complete.lowerBound < present.lowerBound)

    let close = try #require(source.range(of: "public func closeNativeRoundTurn()"))
    let closeEnd = source.range(of: "public func openNativePause()", range: close.upperBound..<source.endIndex)?.lowerBound ?? source.endIndex
    let events = try #require(source.range(of: "fireNativeRoundEvents(round: gameplay.round)", range: close.upperBound..<closeEnd))
    let autosave = try #require(source.range(of: "autosaveIfDialogueIdle()", range: events.upperBound..<closeEnd))
    #expect(close.lowerBound < events.lowerBound)
    #expect(events.lowerBound < autosave.lowerBound)
}
