#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

private struct ActiveUnitAnimation {
    let unitIndex: Int
    let animationUnitName: String
    let sequence: NativeAnimationSequence
    let startMilliseconds: Double
    var lastAssetID: String?
    var lastFrameIndex: Int
}

private struct ActiveUnitMoveAnimation {
    let unitIndex: Int
    let path: [HexCell]
    let startMilliseconds: Double
    let durationMilliseconds: Double
    let capturedObjectIndices: [Int]
}

private enum NativeBattleResultPresentationPhase {
    case none
    case narration
    case victoryText
    case form
}

private enum NativeOuterCompletionState {
    case none
    case campaign(route: NativeCampaignContinueRoute, content: NativeCampaignCompleteContent)
    case challenge(prepared: NativeConquestVictoryPrepared, content: NativeConquestChallengeContent)
    case summary(result: NativeConquestAchievementResult, content: NativeConquestSummaryContent)
}

private enum PendingActionCameraContinuation {
    case playerMove(unitIndex: Int, target: HexCell)
    case playerAttack(attackerIndex: Int, defenderIndex: Int)
    case ai(driver: NativeAIPresentationDriver, gameplay: NativeBattleGameplayState, action: NativeAIPresentationAction)
}

public final class NativeBattleScene: SKScene {
    public let worldLayer = SKNode()
    public let interactionLayer = SKNode()
    public let hudLayer = SKNode()
    public let formLayer = SKNode()
    private let nativeGridLayer = SKShapeNode()
    private let tutorialWorldLayer = SKNode()
    private let tutorialOverlayLayer = SKNode()

    public private(set) var cameraState = NativeCameraState(x: 284, y: 160, zoom: 1)
    private var programmaticCameraMotion: NativeProgrammaticCameraMotion?
    private var pendingActionCameraContinuation: PendingActionCameraContinuation?
    private var lastSceneUpdateTime: TimeInterval?
    public private(set) var activeSession: NativeBattleSession?
    public private(set) var gameplayState: NativeBattleGameplayState?
    public private(set) var persistenceContext: NativeBattlePersistenceContext?
    public private(set) var playerProfile: NativePlayerProfile = .fresh()
    public var statusHandler: ((String) -> Void)?
    public var playerProfileDidChangeHandler: ((NativePlayerProfile) -> Void)?
    public var commanderRoundProjectionProvider: NativeRoundRuntimeAdapter.ProjectionProvider?
    public var roundSettlementHandler: ((NativePlayerRoundSettlement) -> Void)?
    public var autosavePayloadHandler: ((NativeBattleSavePayload) -> Void)?
    public var nativeDialogueEventHandler: ((NativeBattleScriptEvent) -> Void)?
    public var nativeDialogueDidDrainHandler: (() -> Void)?
    public var saveSlotMetadataProvider: (() -> [NativeBattleSaveSlotMetadata])?
    public var battleSaveWriteHandler: ((NativeBattleSaveSlot, NativeBattleSavePayload) -> Void)?
    public var battleSaveReadProvider: ((NativeBattleSaveSlot) -> NativeBattleSavePayload?)?
    public var pauseOptionHandler: (() -> Void)?
    public var tutorialCompletedHandler: (() -> Void)?
    public var pauseRestartHandler: (() -> Void)?
    public var pauseExitHandler: (() -> Void)?
    public var battleResultContinueHandler: ((NativeOriginalBattleResultContent) -> Void)?
    public var battleResultPresentedHandler: ((NativeOriginalBattleResultContent) -> Void)?
    public var battleResultRestartHandler: ((NativeOriginalBattleResultContent) -> Void)?
    public var battleResultExitHandler: ((NativeOriginalBattleResultContent) -> Void)?
    public var campaignContinueRouteHandler: ((NativeCampaignContinueRoute) -> Void)?
    public var conquestCountryDefeatedHandler: ((Int, NativeConquestCountryStatus) -> Void)?
    public var conquestChallengeHandler: ((NativeConquestVictoryPrepared) -> Void)?
    public var conquestSummaryHandler: ((NativeConquestAchievementResult) -> Void)?
    public var generalDeploymentAcademyHandler: (() -> Void)?
    public private(set) var activeBattleResult: NativeOriginalBattleResultContent?
    public var activeNativeDialogue: NativeBattleScriptEvent? { nativeDialogueQueueCore.active }
    public private(set) var stageIntroActive = false
    public private(set) var battleModalState: NativeBattleModalState = .none
    public var nativeDialogueQueue: [NativeBattleScriptEvent] {
        var events: [NativeBattleScriptEvent] = []
        if let active = nativeDialogueQueueCore.active { events.append(active) }
        events.append(contentsOf: nativeDialogueQueueCore.pending)
        return events
    }

    private var panStart: NativePoint?
    private var touchStart: NativePoint?
    private var hasPanned = false

    private let rasterizer = BILEFrameRasterizer()
    private var bileCache: [String: CompactBILE] = [:]
    private var atlasCache: [String: CGImage] = [:]
    private var tacticalUnitContainers: [Int: SKNode] = [:]
    private var strategicUnitContainers: [Int: SKNode] = [:]
    private var objectNodes: [Int: SKSpriteNode] = [:]
    private var installationNodes: [String: SKSpriteNode] = [:]
    private var activeUnitAnimations: [Int: ActiveUnitAnimation] = [:]
    private var activeUnitMoves: [Int: ActiveUnitMoveAnimation] = [:]
    private var damagePresentationQueue = NativeDamagePresentationQueue()
    private var aiPresentationDriver: NativeAIPresentationDriver?
    private var aiResumeAtMilliseconds = 0.0
    private var aiNeedsCountryAdvance = false
    private var aiFastForward = false
    private var animationFrameCache: [String: [Int: BILERasterizedFrame]] = [:]
    private var battlefieldTextureCache: [String: SKTexture] = [:]
    private var unitFlagFrameState: [Int: Int] = [:]
    private var unitMoralePresentationState: [Int: Int] = [:]
    private var fireEffectNodes: [String: SKSpriteNode] = [:]
    private var fireFrameState: [String: Int] = [:]
    private var fireAtlasTexture: SKTexture?
    private var unitFacing: [Int: String] = [:]
    private var readyFrameState: [Int: (assetID: String, frameIndex: Int)] = [:]
    private var lastReadyTickMilliseconds = 0.0
    private var undoButtonNode: SKSpriteNode?
    private var roundButtonNode: SKSpriteNode?
    private var pauseButtonNode: SKSpriteNode?

    private var resourceStore: NativeResourceStore?
    private var playerProfileRuntime: NativePlayerProfileRuntime?
    private var animationsManifest: NativeAnimationManifest?
    private var spriteManifest: [String: SpriteManifestEntry] = [:]
    private var constructionCatalog: NativeConstructionCatalog = [:]
    private var recruitCardCatalog: NativeRecruitCardCatalog = [:]
    private var buildCardCatalog: NativeBuildCardCatalog = [:]
    private var itemEffectCatalog: NativeItemEffectCatalog = [:]
    private var battleEventCatalog: NativeBattleEventCatalogFile?
    private var triggerTargetCatalog: NativeTriggerTargetCatalogFile?
    private var commanderCatalog: [Int: Commander] = [:]
    private var playerGeneralOverrides: NativePlayerGeneralOverrides?
    private var playerPrincessOverrides: NativePlayerPrincessOverrides?
    private var originalTalkRenderer: NativeOriginalTalkRenderer?
    private var originalStageIntroRenderer: NativeOriginalStageIntroRenderer?
    private var originalBattleModalRenderer: NativeOriginalBattleModalRenderer?
    private var originalTavernRenderer: NativeOriginalTavernRenderer?
    private var originalMarketRenderer: NativeOriginalMarketRenderer?
    private var originalBattleShopRenderer: NativeOriginalBattleShopRenderer?
    private var originalBattleUnitInfoRenderer: NativeOriginalBattleUnitInfoRenderer?
    private var originalBattleGeneralInfoRenderer: NativeOriginalBattleGeneralInfoRenderer?
    private var originalGeneralDeploymentRenderer: NativeOriginalBattleGeneralDeploymentRenderer?
    private var originalActionResourceRenderer: NativeOriginalActionResourceRenderer?
    private var originalRecruitUnitRenderer: NativeOriginalRecruitUnitRenderer?
    private var originalUseItemRenderer: NativeOriginalUseItemRenderer?
    private var originalDefenseRenderer: NativeOriginalDefenseRenderer?
    private var battleActionStripRenderer: NativeBattleActionStripRenderer?
    private var activeTavernObjectIndex: Int?
    private var activeMarketObjectIndex: Int?
    private var activeShopObjectIndex: Int?
    private var activeUnitInfoUnitIndex: Int?
    private var activeGeneralInfoUnitIndex: Int?
    private var activeGeneralTargetUnitIndex: Int?
    private var activeRecruitObjectIndex: Int?
    private var activeUseItemUnitIndex: Int?
    private var activeDefenseUnitIndex: Int?
    private var selectedGeneralDeploymentID: Int?
    private var selectedFacilityObjectIndex: Int?
    private var selectedEmptyCell: HexCell?
    private var originalBattleResultRenderer: NativeOriginalBattleResultRenderer?
    private var originalOuterCompletionRenderer: NativeOriginalOuterCompletionRenderer?
    private var outerCompletionState: NativeOuterCompletionState = .none
    private var stringCatalog: [String: String] = [:]
    private var tutorialRunner: NativeTutorialRunner?
    private var tutorialScriptFile: String?
    private var battleResultPresentationPhase: NativeBattleResultPresentationPhase = .none
    private var nativeDialogueQueueCore = NativeBattleDialogueQueueCore()
    private var pendingRoundTurnContent: NativeRoundTurnContent?
    private var campaignTargetManifest: NativeCampaignTargetManifestFile?
    private var campaignInitialTargets: NativeCampaignInitialTargetSnapshot?
    private var campaignBattles: [BattleRecord] = []
    private var announcedConquestDefeatedOwners = Set<Int>()
    private var pendingConquestVictory: NativeConquestVictoryPrepared?

    public override init(size: CGSize = CGSize(width: EW4LogicalSpace.width, height: EW4LogicalSpace.height)) {
        super.init(size: size)
        scaleMode = .aspectFit
        backgroundColor = .black
        anchorPoint = CGPoint(x: 0, y: 0)
        addChild(worldLayer)
        addChild(hudLayer)
        formLayer.zPosition = 10_000
        addChild(formLayer)
        applyCamera()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // worldLayer local coordinates are (x, -yDown). This keeps textures upright without flipping the scene.
    private func worldScenePoint(_ point: NativePoint) -> CGPoint {
        CGPoint(x: point.x, y: -point.y)
    }

    public func loadBattle(
        file: String = "campaign1_01.btl",
        store: NativeResourceStore,
        profile: NativePlayerProfile = .fresh(),
        mode: BattleMode = .campaign,
        playerOwner explicitPlayerOwner: Int? = nil
    ) throws {
        let battles = try store.battles()
        let worlds = try store.worlds()
        let animations = try store.animations()
        let sprites = try store.sprites()
        let armyStats = try store.armyStats()
        let items = try store.items()
        let constructions = try store.constructions()
        let recruitCards = try store.recruitCards()
        let buildCards = try store.buildCards()
        let installations = try store.installations()
        let commanders = try store.commanders()
        let generalOverrides = try store.playerGeneralOverrides()
        let princessOverrides = try store.playerPrincessOverrides()
        playerGeneralOverrides = generalOverrides
        playerPrincessOverrides = princessOverrides
        let profileRuntime = NativePlayerProfileRuntime(profile)
        let effectiveProvider = NativePlayerProfileCore.makeRuntimeProvider(
            runtime: profileRuntime,
            commanders: commanders,
            generalOverrides: generalOverrides,
            princessOverrides: princessOverrides
        )
        let growthHandler: NativeCombatGrowthHandler = { commanderID, damage, killed, victimGrade, victimHasCommander in
            guard let raw = commanders[commanderID] else { return nil }
            return profileRuntime.applyCombatGrowth(
                commander: raw, damage: damage, killed: killed,
                victimGrade: victimGrade, victimHasCommander: victimHasCommander,
                itemEffects: items, generalOverrides: generalOverrides, princessOverrides: princessOverrides
            )
        }
        let roundProvider: NativeRoundRuntimeAdapter.ProjectionProvider = { id, playerControlled in
            effectiveProvider(id, playerControlled)?.roundProjection
        }
        let session = try NativeBattleLoader.session(file: file, battles: battles, worlds: worlds)
        var gameplay = NativeBattleGameplayState(
            session: session,
            terrainTypes: worlds.terrainTypes,
            armyStats: armyStats,
            commanders: commanders,
            itemEffects: items,
            constructions: constructions,
            installationCatalog: installations,
            effectiveCommanderProvider: effectiveProvider,
            combatGrowthHandler: growthHandler,
            mode: mode,
            playerOwner: explicitPlayerOwner ?? session.battle.playerOwnerDefault
        )
        gameplay.selectUnit(nil)

        let focusIndex = session.units.first(where: { $0.commanderID != nil })?.index ?? session.units.first?.index
        let openingCamera: NativeCameraState
        if let focusIndex, let focus = gameplay.units[focusIndex] {
            let p = NativeHexGeometry.cellCenter(focus.cell)
            openingCamera = NativeCameraState(x: p.x, y: p.y, zoom: 1)
        } else {
            openingCamera = NativeCameraState(x: 284, y: 160, zoom: 1)
        }
        try installBattleRuntime(
            session: session,
            gameplay: gameplay,
            camera: openingCamera,
            store: store,
            animations: animations,
            sprites: sprites,
            persistenceContext: NativeBattlePersistenceContext.fresh(gameplay: gameplay),
            profileRuntime: profileRuntime,
            roundProjectionProvider: roundProvider
        )
        presentNativeStageIntroIfNeeded()
        statusHandler?("Native battle ready · \(gameplay.units.count) units")
    }

    /// Restores a schema 1...6 BattleSave into the same native SpriteKit scene path
    /// used by a fresh battle. The complete restored runtime is returned so the
    /// app coordinator retains sidecar state (stores/taverns/events/tech/etc.)
    /// instead of silently discarding it inside the renderer.
    @discardableResult
    public func restoreBattle(
        from payload: NativeBattleSavePayload,
        store: NativeResourceStore,
        profile: NativePlayerProfile = .fresh()
    ) throws -> NativeRestoredBattleRuntime {
        let battles = try store.battles()
        let worlds = try store.worlds()
        let animations = try store.animations()
        let sprites = try store.sprites()
        let armyStats = try store.armyStats()
        let items = try store.items()
        let constructions = try store.constructions()
        let recruitCards = try store.recruitCards()
        let buildCards = try store.buildCards()
        let installations = try store.installations()
        let commanders = try store.commanders()
        let generalOverrides = try store.playerGeneralOverrides()
        let princessOverrides = try store.playerPrincessOverrides()
        let profileRuntime = NativePlayerProfileRuntime(profile)
        let effectiveProvider = NativePlayerProfileCore.makeRuntimeProvider(
            runtime: profileRuntime,
            commanders: commanders,
            generalOverrides: generalOverrides,
            princessOverrides: princessOverrides
        )
        let growthHandler: NativeCombatGrowthHandler = { commanderID, damage, killed, victimGrade, victimHasCommander in
            guard let raw = commanders[commanderID] else { return nil }
            return profileRuntime.applyCombatGrowth(
                commander: raw, damage: damage, killed: killed,
                victimGrade: victimGrade, victimHasCommander: victimHasCommander,
                itemEffects: items, generalOverrides: generalOverrides, princessOverrides: princessOverrides
            )
        }
        let roundProvider: NativeRoundRuntimeAdapter.ProjectionProvider = { id, playerControlled in
            effectiveProvider(id, playerControlled)?.roundProjection
        }
        let restored = try NativeBattleRehydrationCore.rehydrate(
            payload,
            battles: battles,
            worlds: worlds,
            terrainTypes: worlds.terrainTypes,
            armyStats: armyStats,
            commanders: commanders,
            itemEffects: items,
            constructions: constructions,
            installationCatalog: installations,
            effectiveCommanderProvider: effectiveProvider,
            combatGrowthHandler: growthHandler
        )
        let session = NativeBattleSession(
            battle: restored.gameplay.battle,
            worldName: restored.worldName,
            world: restored.gameplay.world
        )
        try installBattleRuntime(
            session: session,
            gameplay: restored.gameplay,
            camera: restored.camera,
            store: store,
            animations: animations,
            sprites: sprites,
            persistenceContext: NativeBattlePersistenceContext.restored(restored),
            profileRuntime: profileRuntime,
            roundProjectionProvider: roundProvider
        )
        statusHandler?("Native battle restored · round \(restored.gameplay.round)")
        return restored
    }

    private func installBattleRuntime(
        session: NativeBattleSession,
        gameplay: NativeBattleGameplayState,
        camera: NativeCameraState,
        store: NativeResourceStore,
        animations: NativeAnimationManifest,
        sprites: [String: SpriteManifestEntry],
        persistenceContext: NativeBattlePersistenceContext,
        profileRuntime: NativePlayerProfileRuntime,
        roundProjectionProvider: @escaping NativeRoundRuntimeAdapter.ProjectionProvider
    ) throws {
        activeSession = session
        gameplayState = gameplay
        var installedContext = persistenceContext
        if installedContext.taverns == nil, let catalog = try? store.battleTaverns() {
            installedContext.taverns = NativeBattleTavernCore.initialState(catalog: catalog, battleFile: session.battle.file)
        }
        if installedContext.itemStores == nil, let catalog = try? store.battleItemStores() {
            installedContext.itemStores = NativeBattleShopCore.initialState(catalog: catalog, battleFile: session.battle.file)
        }
        self.persistenceContext = installedContext
        self.playerProfileRuntime = profileRuntime
        self.playerProfile = profileRuntime.snapshot()
        commanderRoundProjectionProvider = roundProjectionProvider
        resourceStore = store
        animationsManifest = animations
        spriteManifest = sprites
        constructionCatalog = try store.constructions()
        recruitCardCatalog = try store.recruitCards()
        buildCardCatalog = try store.buildCards()
        itemEffectCatalog = try store.items()
        battleEventCatalog = try store.battleEvents()
        triggerTargetCatalog = try store.triggerTargets()
        commanderCatalog = try store.commanders()
        stringCatalog = try store.stringsCN()
        campaignTargetManifest = try? store.campaignTargets()
        campaignBattles = (try? store.battles().battles) ?? []
        if gameplay.mode == .campaign, let manifest = campaignTargetManifest {
            campaignInitialTargets = NativeCampaignCore.authoredInitialTargetSnapshot(
                battle: session.battle, manifest: manifest, playerOwner: gameplay.playerOwner
            )
        } else {
            campaignInitialTargets = nil
        }

        resetPresentationRuntime()

        try addMap(session.worldName == "america" ? "america.png" : "europe.png", store: store)
        installNativeGrid(for: session.battle)
        refreshNativeGridVisibility(profile: self.playerProfile)
        try addObjects(gameplay: gameplay, session: session, sprites: sprites, store: store)
        refreshInstallationNodes(gameplay: gameplay, store: store)
        worldLayer.addChild(interactionLayer)
        tutorialWorldLayer.zPosition = 9_000
        worldLayer.addChild(tutorialWorldLayer)
        try addReadyUnits(gameplay: gameplay, animations: animations, store: store)
        addNativeBattleHUD(store: store)
        originalTalkRenderer = NativeOriginalTalkRenderer(
            parent: formLayer, store: store, spriteManifest: sprites, commanders: commanderCatalog
        )
        originalStageIntroRenderer = NativeOriginalStageIntroRenderer(
            parent: formLayer, store: store, spriteManifest: sprites, commanders: commanderCatalog
        )
        let portraitManifest = (try? store.portraitManifest()) ?? [:]
        originalTavernRenderer = NativeOriginalTavernRenderer(parent: formLayer, store: store, portraits: portraitManifest, items: itemEffectCatalog)
        originalMarketRenderer = NativeOriginalMarketRenderer(parent: formLayer, store: store)
        originalBattleShopRenderer = NativeOriginalBattleShopRenderer(parent: formLayer, store: store)
        originalBattleUnitInfoRenderer = NativeOriginalBattleUnitInfoRenderer(parent: formLayer, store: store, portraits: portraitManifest)
        originalBattleGeneralInfoRenderer = NativeOriginalBattleGeneralInfoRenderer(parent: formLayer, store: store, portraits: portraitManifest, strings: stringCatalog, items: itemEffectCatalog)
        originalGeneralDeploymentRenderer = NativeOriginalBattleGeneralDeploymentRenderer(parent: formLayer, store: store, portraits: portraitManifest)
        originalActionResourceRenderer = NativeOriginalActionResourceRenderer(parent: formLayer, store: store, spriteManifest: sprites)
        originalRecruitUnitRenderer = NativeOriginalRecruitUnitRenderer(parent: formLayer, store: store)
        originalUseItemRenderer = NativeOriginalUseItemRenderer(parent: formLayer, store: store)
        originalDefenseRenderer = NativeOriginalDefenseRenderer(parent: formLayer, store: store)
        battleActionStripRenderer = NativeBattleActionStripRenderer(parent: hudLayer, store: store)
        originalBattleModalRenderer = NativeOriginalBattleModalRenderer(
            parent: formLayer, store: store, spriteManifest: sprites
        )
        originalBattleResultRenderer = NativeOriginalBattleResultRenderer(
            parent: formLayer, store: store, spriteManifest: sprites,
            commanders: commanderCatalog, strings: stringCatalog
        )
        originalOuterCompletionRenderer = NativeOriginalOuterCompletionRenderer(
            parent: formLayer, store: store, spriteManifest: sprites, strings: stringCatalog
        )
        tutorialOverlayLayer.zPosition = 50_000
        formLayer.addChild(tutorialOverlayLayer)
        setCamera(camera)
        if gameplay.mode == .tutorial { startNativeTutorial(file: session.battle.file, store: store) }
        refreshInteractionOverlay()
        refreshNativeBattleHUD(gameplay: gameplay)
    }

    private func resetPresentationRuntime() {
        worldLayer.removeAllChildren()
        interactionLayer.removeAllChildren()
        hudLayer.removeAllChildren()
        formLayer.removeAllChildren()
        tutorialWorldLayer.removeAllChildren()
        tutorialOverlayLayer.removeAllChildren()
        nativeGridLayer.removeFromParent()
        nativeGridLayer.path = nil
        tutorialRunner = nil
        tutorialScriptFile = nil
        originalTalkRenderer = nil
        originalStageIntroRenderer = nil
        originalBattleModalRenderer = nil
        originalBattleResultRenderer = nil
        originalOuterCompletionRenderer = nil
        outerCompletionState = .none
        activeBattleResult = nil
        battleResultPresentationPhase = .none
        stageIntroActive = false
        battleModalState = .none
        undoButtonNode = nil
        roundButtonNode = nil
        pauseButtonNode = nil
        tacticalUnitContainers.removeAll(keepingCapacity: true)
        strategicUnitContainers.removeAll(keepingCapacity: true)
        objectNodes.removeAll(keepingCapacity: true)
        installationNodes.removeAll(keepingCapacity: true)
        activeUnitAnimations.removeAll(keepingCapacity: true)
        activeUnitMoves.removeAll(keepingCapacity: true)
        damagePresentationQueue = NativeDamagePresentationQueue()
        aiPresentationDriver = nil
        aiResumeAtMilliseconds = 0
        aiNeedsCountryAdvance = false
        aiFastForward = false
        animationFrameCache.removeAll(keepingCapacity: true)
        battlefieldTextureCache.removeAll(keepingCapacity: true)
        unitFlagFrameState.removeAll(keepingCapacity: true)
        unitMoralePresentationState.removeAll(keepingCapacity: true)
        fireEffectNodes.removeAll(keepingCapacity: true)
        fireFrameState.removeAll(keepingCapacity: true)
        fireAtlasTexture = nil
        unitFacing.removeAll(keepingCapacity: true)
        readyFrameState.removeAll(keepingCapacity: true)
        lastReadyTickMilliseconds = 0
        programmaticCameraMotion = nil
        pendingActionCameraContinuation = nil
        lastSceneUpdateTime = nil
        bileCache.removeAll(keepingCapacity: true)
        atlasCache.removeAll(keepingCapacity: true)
        nativeDialogueQueueCore.reset()
        originalTavernRenderer?.hide()
        originalMarketRenderer?.hide()
        originalBattleShopRenderer?.hide()
        originalBattleUnitInfoRenderer?.hide()
        originalBattleGeneralInfoRenderer?.hide()
        originalGeneralDeploymentRenderer?.hide()
        originalActionResourceRenderer?.hide()
        originalRecruitUnitRenderer?.hide()
        originalUseItemRenderer?.hide()
        originalDefenseRenderer?.hide()
        battleActionStripRenderer?.hide()
        activeTavernObjectIndex = nil
        selectedFacilityObjectIndex = nil
        activeMarketObjectIndex = nil
        activeShopObjectIndex = nil
        activeUnitInfoUnitIndex = nil
        activeGeneralInfoUnitIndex = nil
        activeGeneralTargetUnitIndex = nil
        activeRecruitObjectIndex = nil
        activeUseItemUnitIndex = nil
        activeDefenseUnitIndex = nil
        selectedGeneralDeploymentID = nil
        selectedEmptyCell = nil
        pendingRoundTurnContent = nil
        announcedConquestDefeatedOwners.removeAll(keepingCapacity: true)
        pendingConquestVictory = nil
    }

    /// Serializes the authoritative live native battle state back into the same
    /// schema-6 envelope used by the mature P39 implementation. Presentation-only
    /// state (move/attack animations, pending visual frames) is never persisted.
    public func makeBattleSavePayload(
        savedAt: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) throws -> NativeBattleSavePayload {
        guard let gameplay = gameplayState,
              let session = activeSession,
              let context = persistenceContext else {
            throw NativeBattleSaveError.noActiveBattle
        }
        return try NativeBattleSnapshotCore.makePayload(
            gameplay: gameplay,
            worldName: session.worldName,
            camera: cameraState,
            context: context,
            savedAt: savedAt
        )
    }

    public func applyOptionsProfile(_ profile: NativePlayerProfile) {
        self.playerProfile = profile
        playerProfileRuntime?.replace(with: profile)
        refreshNativeGridVisibility(profile: profile)
        if let target = activeGeneralTargetUnitIndex,
           let gameplay = gameplayState,
           let renderer = originalGeneralDeploymentRenderer {
            renderer.show(
                ids: eligibleGeneralDeploymentIDs(targetUnitIndex: target, gameplay: gameplay),
                commanders: commanderCatalog,
                selectedID: selectedGeneralDeploymentID,
                deployedCount: deployedGeneralCount(gameplay: gameplay)
            )
        }
    }

    private func installNativeGrid(for battle: BattleRecord) {
        nativeGridLayer.removeFromParent()
        let h = battle.header
        let path = CGMutablePath()
        for r in h.originY..<(h.originY + h.height) {
            for q in h.originX..<(h.originX + h.width) {
                let c = NativeHexGeometry.cellCenter(.init(q:q,r:r))
                let pts = [(-32.0,-18.0),(0.0,-36.0),(32.0,-18.0),(32.0,18.0),(0.0,36.0),(-32.0,18.0)]
                path.move(to: CGPoint(x:c.x+pts[0].0,y:-(c.y+pts[0].1)))
                for p in pts.dropFirst() { path.addLine(to:CGPoint(x:c.x+p.0,y:-(c.y+p.1))) }
                path.closeSubpath()
            }
        }
        nativeGridLayer.path = path
        nativeGridLayer.strokeColor = UIColor(red:30/255,green:42/255,blue:37/255,alpha:0.30)
        nativeGridLayer.fillColor = .clear
        nativeGridLayer.lineWidth = 0.65
        nativeGridLayer.zPosition = -900
        worldLayer.addChild(nativeGridLayer)
    }

    private func refreshNativeGridVisibility(profile: NativePlayerProfile) {
        nativeGridLayer.isHidden = !NativeOptionsCore.settings(from: profile).showGrids
    }

    private func addMap(_ fileName: String, store: NativeResourceStore) throws {
        let data = try Data(contentsOf: store.url("Maps", fileName))
        guard let image = UIImage(data: data)?.cgImage else {
            throw CocoaError(.fileReadCorruptFile)
        }
        // The coast/river map is transparent on land. As in the reference
        // renderer, repeat map_pt underneath it instead of exposing black.
        let groundData = try Data(contentsOf: store.url("Maps", "map_pt.png"))
        guard let groundImage = UIImage(data: groundData)?.cgImage else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let ground = SKNode()
        ground.name = "native-map-ground"
        ground.zPosition = -1001
        let groundTexture = SKTexture(cgImage: groundImage)
        for y in stride(from: 0, to: image.height, by: groundImage.height) {
            for x in stride(from: 0, to: image.width, by: groundImage.width) {
                let width = min(groundImage.width, image.width - x)
                let height = min(groundImage.height, image.height - y)
                let texture: SKTexture
                if width == groundImage.width && height == groundImage.height {
                    texture = groundTexture
                } else {
                    guard let edge = groundImage.cropping(to: CGRect(x: 0, y: 0, width: width, height: height)) else {
                        throw CocoaError(.fileReadCorruptFile)
                    }
                    texture = SKTexture(cgImage: edge)
                }
                let tile = SKSpriteNode(texture: texture)
                tile.anchorPoint = CGPoint(x: 0, y: 1)
                tile.position = CGPoint(x: x, y: -y)
                tile.size = CGSize(width: width, height: height)
                ground.addChild(tile)
            }
        }
        worldLayer.addChild(ground)
        let node = SKSpriteNode(texture: SKTexture(cgImage: image))
        node.anchorPoint = CGPoint(x: 0, y: 1)
        node.position = .zero
        node.size = CGSize(width: image.width, height: image.height)
        node.name = "native-map"
        node.zPosition = -1000
        worldLayer.addChild(node)
    }

    private func addObjects(
        gameplay: NativeBattleGameplayState,
        session: NativeBattleSession,
        sprites: [String: SpriteManifestEntry],
        store: NativeResourceStore
    ) throws {
        for source in session.objects {
            guard let object = gameplay.objects[source.index] else { continue }
            try renderObject(object, gameplay: gameplay, sprites: sprites, store: store)
        }
    }

    private func renderObject(
        _ object: NativeBattleObjectState,
        gameplay: NativeBattleGameplayState,
        sprites: [String: SpriteManifestEntry],
        store: NativeResourceStore
    ) throws {
        objectNodes[object.index]?.removeFromParent()
        objectNodes[object.index] = nil
        let code = gameplay.countryCode(owner: object.owner)
        guard let spec = NativeBattlePresentationBuilder.objectSpec(object: object, countryCode: code, sprites: sprites) else {
            return
        }
        let url = store.spriteURL(manifestPath: spec.spriteFile)
        guard let data = try? Data(contentsOf: url), let image = UIImage(data: data)?.cgImage else { return }
        let node = SKSpriteNode(texture: SKTexture(cgImage: image))
        node.anchorPoint = CGPoint(x: 0, y: 1)
        node.position = CGPoint(x: spec.drawX, y: -spec.drawY)
        node.size = CGSize(width: spec.width, height: spec.height)
        node.name = "object-\(object.index)"
        node.zPosition = 10 + CGFloat(object.r) / 1000
        objectNodes[object.index] = node
        worldLayer.addChild(node)
    }

    private func installationNodeKey(_ installation: NativeBattleInstallationState) -> String {
        "\(installation.q),\(installation.r)"
    }

    private func refreshInstallationNodes(gameplay: NativeBattleGameplayState, store: NativeResourceStore) {
        let liveKeys = Set(gameplay.installations.map(installationNodeKey))
        for (key, node) in installationNodes where !liveKeys.contains(key) {
            node.removeFromParent()
            installationNodes[key] = nil
        }

        for installation in gameplay.installations {
            let key = installationNodeKey(installation)
            installationNodes[key]?.removeFromParent()
            installationNodes[key] = nil

            guard let definition = gameplay.installationCatalog[installation.type],
                  let imageName = definition.image else { continue }
            let url = store.url("Sprites/buildings_hd", imageName)
            guard let data = try? Data(contentsOf: url), let cgImage = UIImage(data: data)?.cgImage else { continue }

            let node = SKSpriteNode(texture: SKTexture(cgImage: cgImage))
            node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            node.position = worldScenePoint(NativeHexGeometry.cellCenter(installation.cell))
            node.size = CGSize(width: cgImage.width, height: cgImage.height)
            node.name = "installation-\(installation.q)-\(installation.r)"
            node.zPosition = 50 + CGFloat(installation.r) / 1000
            worldLayer.addChild(node)
            installationNodes[key] = node
        }
    }

    private func addReadyUnits(
        gameplay: NativeBattleGameplayState,
        animations: NativeAnimationManifest,
        store: NativeResourceStore
    ) throws {
        for index in gameplay.unitOrder {
            guard let unit = gameplay.units[index], !unit.dead else { continue }
            try renderReadyUnit(unit, gameplay: gameplay, animations: animations, store: store)
        }
    }

    private func renderReadyUnit(
        _ unit: NativeBattleUnitState,
        gameplay: NativeBattleGameplayState,
        animations: NativeAnimationManifest,
        store: NativeResourceStore
    ) throws {
        tacticalUnitContainers[unit.index]?.removeFromParent()
        strategicUnitContainers[unit.index]?.removeFromParent()
        tacticalUnitContainers[unit.index] = nil
        strategicUnitContainers[unit.index] = nil

        let code = gameplay.countryCode(owner: unit.owner)
        let statType = gameplay.stat(for: unit)?.type
        if unit.embarked && statType != "warship" {
            renderTransportUnit(unit, gameplay: gameplay, store: store)
            return
        }
        let readyDirection = (statType == "warship" || statType == "fort")
            ? (unitFacing[unit.index] ?? "right")
            : nil
        guard let spec = NativeBattlePresentationBuilder.unitSpec(
            unit: unit,
            countryCode: code,
            readyDirection: readyDirection,
            manifest: animations
        ), let asset = animations.assets[spec.readyAssetID] else {
            return
        }
        let bile = try bileResource(spec.resource, store: store)
        let atlas = try atlasResource(spec.resource, store: store)
        guard let itemIndex = try? bile.itemIndex(named: spec.motionName) else { return }
        let frameIndex = NativeAnimationTiming.frame(at: spec.phaseOffsetMilliseconds, asset: asset)
        let rendered = try rasterizer.frame(bile: bile, itemIndex: itemIndex, frame: frameIndex, atlas: atlas)
        readyFrameState[unit.index] = (spec.readyAssetID, frameIndex)
        let scale = spec.drawOrigin.scale
        let drawX = spec.drawOrigin.x + rendered.bounds.origin.x * scale
        let drawY = spec.drawOrigin.y + rendered.bounds.origin.y * scale
        let center = spec.worldPoint

        let tactical = SKNode()
        tactical.name = "tactical-unit-\(unit.index)"
        tactical.position = worldScenePoint(center)
        tactical.zPosition = 100 + CGFloat(unit.r) / 1000

        let model = SKSpriteNode(texture: rendered.texture)
        model.anchorPoint = CGPoint(x: 0, y: 1)
        model.position = CGPoint(x: drawX - center.x, y: center.y - drawY)
        model.size = CGSize(
            width: rendered.bounds.size.width * scale,
            height: rendered.bounds.size.height * scale
        )
        model.name = "unit-model-\(unit.index)"
        model.zPosition = 1
        tactical.addChild(model)
        addUnitStatus(to: tactical, unit: unit, gameplay: gameplay, store: store, assetScale: 0.5, zBase: 10)
        addNativeBattlefieldOverlays(to: tactical, unit: unit, gameplay: gameplay, store: store)

        let strategic = SKNode()
        strategic.name = "strategic-unit-\(unit.index)"
        strategic.position = worldScenePoint(center)
        strategic.zPosition = 150 + CGFloat(unit.r) / 1000
        addUnitStatus(to: strategic, unit: unit, gameplay: gameplay, store: store, assetScale: 1.0, zBase: 0)

        tacticalUnitContainers[unit.index] = tactical
        strategicUnitContainers[unit.index] = strategic
        worldLayer.addChild(tactical)
        worldLayer.addChild(strategic)
        applyUnitLOD()
    }

    private func renderTransportUnit(
        _ unit: NativeBattleUnitState,
        gameplay: NativeBattleGameplayState,
        store: NativeResourceStore
    ) {
        let armored = gameplay.hasEquipmentFunction(unit, function: 12)
        let profile = NativeTransportPresentationCore.profile(armoredCarrier: armored)
        guard let entry = spriteManifest[profile.spriteKey],
              let data = try? Data(contentsOf: store.spriteURL(manifestPath: entry.file)),
              let image = UIImage(data: data)?.cgImage else {
            return
        }
        let desiredFacing = unitFacing[unit.index] ?? profile.naturalFacing
        let placement = NativeTransportPresentationCore.placement(
            refX: entry.refx, refY: entry.refy, width: entry.w, height: entry.h,
            desiredFacing: desiredFacing, naturalFacing: profile.naturalFacing
        )
        let center = NativeHexGeometry.cellCenter(unit.cell)

        let tactical = SKNode()
        tactical.name = "tactical-unit-\(unit.index)"
        tactical.position = worldScenePoint(center)
        tactical.zPosition = 100 + CGFloat(unit.r) / 1000

        let model = SKSpriteNode(texture: SKTexture(cgImage: image))
        model.anchorPoint = CGPoint(x: 0, y: 1)
        model.position = CGPoint(x: CGFloat(placement.x), y: CGFloat(placement.y))
        model.size = CGSize(width: CGFloat(placement.width), height: CGFloat(placement.height))
        model.xScale = placement.mirrored ? -1 : 1
        model.name = "transport-model-\(unit.index)"
        model.zPosition = 1
        tactical.addChild(model)
        addUnitStatus(to: tactical, unit: unit, gameplay: gameplay, store: store, assetScale: 0.5, zBase: 10)
        addNativeBattlefieldOverlays(to: tactical, unit: unit, gameplay: gameplay, store: store)

        let strategic = SKNode()
        strategic.name = "strategic-unit-\(unit.index)"
        strategic.position = worldScenePoint(center)
        strategic.zPosition = 150 + CGFloat(unit.r) / 1000
        addUnitStatus(to: strategic, unit: unit, gameplay: gameplay, store: store, assetScale: 1.0, zBase: 0)

        readyFrameState[unit.index] = nil
        tacticalUnitContainers[unit.index] = tactical
        strategicUnitContainers[unit.index] = strategic
        worldLayer.addChild(tactical)
        worldLayer.addChild(strategic)
        applyUnitLOD()
    }

    private func updateTransportFacing(unitIndex: Int, desiredFacing: String, gameplay: NativeBattleGameplayState) {
        guard let unit = gameplay.units[unitIndex],
              let model = tacticalUnitContainers[unitIndex]?.childNode(withName: "transport-model-\(unitIndex)") as? SKSpriteNode else { return }
        let profile = NativeTransportPresentationCore.profile(armoredCarrier: gameplay.hasEquipmentFunction(unit, function: 12))
        guard let entry = spriteManifest[profile.spriteKey] else { return }
        let placement = NativeTransportPresentationCore.placement(
            refX: entry.refx, refY: entry.refy, width: entry.w, height: entry.h,
            desiredFacing: desiredFacing, naturalFacing: profile.naturalFacing
        )
        model.position = CGPoint(x: CGFloat(placement.x), y: CGFloat(placement.y))
        model.xScale = placement.mirrored ? -1 : 1
    }

    private func battlefieldTexture(key: String, store: NativeResourceStore) -> (SKTexture, SpriteManifestEntry)? {
        guard let entry = spriteManifest[key] else { return nil }
        if let cached = battlefieldTextureCache[key] { return (cached, entry) }
        let url = store.spriteURL(manifestPath: entry.file)
        guard let data = try? Data(contentsOf: url), let image = UIImage(data: data)?.cgImage else { return nil }
        let texture = SKTexture(cgImage: image)
        battlefieldTextureCache[key] = texture
        return (texture, entry)
    }

    private func addNativeBattlefieldOverlays(
        to container: SKNode,
        unit: NativeBattleUnitState,
        gameplay: NativeBattleGameplayState,
        store: NativeResourceStore
    ) {
        addNativeBattleFlag(to: container, unit: unit, gameplay: gameplay, store: store)
        addNativeCommanderBubble(to: container, unit: unit, store: store)
        installNativeMoraleMarker(to: container, unit: unit, gameplay: gameplay, store: store)
    }

    private func addNativeBattleFlag(
        to container: SKNode,
        unit: NativeBattleUnitState,
        gameplay: NativeBattleGameplayState,
        store: NativeResourceStore
    ) {
        let code = NativeBattlefieldOverlayCore.flagCountryCode(gameplay.countryCode(owner: unit.owner))
        let frame = NativeBattlefieldOverlayCore.flagFrame(unitIndex: unit.index, nowMilliseconds: animationNowMilliseconds())
        let flagKey = "\(code)\(frame).png"
        guard let (poleTexture, poleEntry) = battlefieldTexture(key: "flagpole.png", store: store),
              let (flagTexture, flagEntry) = battlefieldTexture(key: flagKey, store: store) else { return }

        let root = SKNode()
        root.name = "battle-flag-\(unit.index)"
        root.zPosition = 0

        let polePlacement = NativeBattlefieldOverlayCore.flagPolePlacement(
            refX: poleEntry.refx, refY: poleEntry.refy, width: poleEntry.w, height: poleEntry.h
        )
        let pole = SKSpriteNode(texture: poleTexture)
        pole.anchorPoint = CGPoint(x: 0, y: 1)
        pole.position = CGPoint(x: polePlacement.x, y: polePlacement.y)
        pole.size = CGSize(width: polePlacement.width, height: polePlacement.height)
        pole.zPosition = 0
        root.addChild(pole)

        let clothPlacement = NativeBattlefieldOverlayCore.flagClothPlacement(width: flagEntry.w, height: flagEntry.h)
        let cloth = SKSpriteNode(texture: flagTexture)
        cloth.name = "battle-flag-cloth-\(unit.index)"
        cloth.anchorPoint = CGPoint(x: 0, y: 1)
        cloth.position = CGPoint(x: clothPlacement.x, y: clothPlacement.y)
        cloth.size = CGSize(width: clothPlacement.width, height: clothPlacement.height)
        cloth.zPosition = 1
        root.addChild(cloth)

        container.addChild(root)
        unitFlagFrameState[unit.index] = frame
    }

    private func addNativeCommanderBubble(
        to container: SKNode,
        unit: NativeBattleUnitState,
        store: NativeResourceStore
    ) {
        guard let commanderID = unit.commanderID, commanderID > 0,
              let commander = commanderCatalog[commanderID],
              let (boardTexture, boardEntry) = battlefieldTexture(key: "board_smallgenerals.png", store: store),
              let (portraitTexture, portraitEntry) = battlefieldTexture(key: "\(commander.name).png", store: store) else { return }

        let boardPlacement = NativeBattlefieldOverlayCore.commanderBoardPlacement(
            refX: boardEntry.refx, refY: boardEntry.refy, width: boardEntry.w, height: boardEntry.h
        )
        let board = SKSpriteNode(texture: boardTexture)
        board.name = "battle-commander-board-\(unit.index)"
        board.anchorPoint = CGPoint(x: 0, y: 1)
        board.position = CGPoint(x: boardPlacement.x, y: boardPlacement.y)
        board.size = CGSize(width: boardPlacement.width, height: boardPlacement.height)
        board.zPosition = 20
        container.addChild(board)

        let portraitPlacement = NativeBattlefieldOverlayCore.commanderPortraitPlacement(
            board: boardPlacement, width: portraitEntry.w, height: portraitEntry.h
        )
        let portrait = SKSpriteNode(texture: portraitTexture)
        portrait.name = "battle-commander-portrait-\(unit.index)"
        portrait.anchorPoint = CGPoint(x: 0, y: 1)
        portrait.position = CGPoint(x: portraitPlacement.x, y: portraitPlacement.y)
        portrait.size = CGSize(width: portraitPlacement.width, height: portraitPlacement.height)
        portrait.zPosition = 21
        container.addChild(portrait)
    }

    private func installNativeMoraleMarker(
        to container: SKNode,
        unit: NativeBattleUnitState,
        gameplay: NativeBattleGameplayState,
        store: NativeResourceStore
    ) {
        container.childNode(withName: "battle-morale-\(unit.index)")?.removeFromParent()
        let morale = gameplay.moraleState(for: unit)
        unitMoralePresentationState[unit.index] = morale
        guard let key = NativeBattlefieldOverlayCore.moraleSprite(morale),
              let (texture, entry) = battlefieldTexture(key: key, store: store) else { return }
        let placement = NativeBattlefieldOverlayCore.moralePlacement(width: entry.w, height: entry.h)
        let marker = SKSpriteNode(texture: texture)
        marker.name = "battle-morale-\(unit.index)"
        marker.anchorPoint = CGPoint(x: 0, y: 1)
        marker.position = CGPoint(x: placement.x, y: placement.y)
        marker.size = CGSize(width: placement.width, height: placement.height)
        marker.zPosition = 22
        container.addChild(marker)
    }

    private func nativeFireAtlasTexture(store: NativeResourceStore) -> SKTexture? {
        if let fireAtlasTexture { return fireAtlasTexture }
        let url = store.url("Effects", "anim_fire_hd.png")
        guard let data = try? Data(contentsOf: url), let image = UIImage(data: data)?.cgImage else { return nil }
        let texture = SKTexture(cgImage: image)
        fireAtlasTexture = texture
        return texture
    }

    private func nativeFireCell(_ key: String) -> HexCell? {
        let parts = key.split(separator: ",", omittingEmptySubsequences: false)
        guard parts.count == 2, let q = Int(parts[0]), let r = Int(parts[1]) else { return nil }
        return HexCell(q: q, r: r)
    }

    private func updateNativeFirePresentation(nowMilliseconds: Double) {
        guard let store = resourceStore, let context = persistenceContext else { return }
        let liveKeys = context.fireCells
        for (key, node) in fireEffectNodes where !liveKeys.contains(key) {
            node.removeFromParent()
            fireEffectNodes[key] = nil
            fireFrameState[key] = nil
        }
        guard !liveKeys.isEmpty, let atlas = nativeFireAtlasTexture(store: store) else { return }

        for (ordinal, key) in liveKeys.sorted().enumerated() {
            guard let cell = nativeFireCell(key) else { continue }
            let frameIndex = NativeBattleFirePresentationCore.frameIndex(
                cellOrdinal: ordinal, nowMilliseconds: nowMilliseconds
            )
            let frame = NativeBattleFirePresentationCore.frames[frameIndex]
            let placement = NativeBattleFirePresentationCore.placement(frame: frame)
            let normalized = NativeBattleFirePresentationCore.normalizedTextureRect(frame: frame)

            let node: SKSpriteNode
            if let existing = fireEffectNodes[key] {
                node = existing
            } else {
                node = SKSpriteNode()
                node.name = "battle-fire-\(key)"
                node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                node.alpha = CGFloat(NativeBattleFirePresentationCore.alpha)
                worldLayer.addChild(node)
                fireEffectNodes[key] = node
            }
            if fireFrameState[key] != frameIndex {
                node.texture = SKTexture(
                    rect: CGRect(
                        x: normalized.origin.x, y: normalized.origin.y,
                        width: normalized.size.width, height: normalized.size.height
                    ),
                    in: atlas
                )
                fireFrameState[key] = frameIndex
            }
            let center = worldScenePoint(NativeHexGeometry.cellCenter(cell))
            node.position = CGPoint(
                x: center.x + CGFloat(placement.offsetX),
                y: center.y + CGFloat(placement.offsetY)
            )
            node.size = CGSize(width: placement.width, height: placement.height)
            node.zPosition = 75 + CGFloat(cell.r) / 1000
        }
    }

    private func updateNativeBattlefieldOverlays(nowMilliseconds: Double) {
        guard let gameplay = gameplayState, let store = resourceStore else { return }
        for unitIndex in gameplay.unitOrder {
            guard let unit = gameplay.units[unitIndex], !unit.dead,
                  let tactical = tacticalUnitContainers[unitIndex] else { continue }

            let code = NativeBattlefieldOverlayCore.flagCountryCode(gameplay.countryCode(owner: unit.owner))
            let frame = NativeBattlefieldOverlayCore.flagFrame(unitIndex: unitIndex, nowMilliseconds: nowMilliseconds)
            if unitFlagFrameState[unitIndex] != frame,
               let root = tactical.childNode(withName: "battle-flag-\(unitIndex)"),
               let cloth = root.childNode(withName: "battle-flag-cloth-\(unitIndex)") as? SKSpriteNode,
               let (texture, entry) = battlefieldTexture(key: "\(code)\(frame).png", store: store) {
                let placement = NativeBattlefieldOverlayCore.flagClothPlacement(width: entry.w, height: entry.h)
                cloth.texture = texture
                cloth.size = CGSize(width: placement.width, height: placement.height)
                unitFlagFrameState[unitIndex] = frame
            }

            let morale = gameplay.moraleState(for: unit)
            if unitMoralePresentationState[unitIndex] != morale {
                installNativeMoraleMarker(to: tactical, unit: unit, gameplay: gameplay, store: store)
            }
        }
    }

    private func addUnitStatus(
        to container: SKNode,
        unit: NativeBattleUnitState,
        gameplay: NativeBattleGameplayState,
        store: NativeResourceStore,
        assetScale: CGFloat,
        zBase: CGFloat
    ) {
        let relation = NativeUnitStatusCore.relationVisual(
            owner: unit.owner,
            playerOwner: gameplay.playerOwner,
            relation: gameplay.relation(gameplay.playerOwner, unit.owner)
        )
        let ringKey = NativeUnitStatusCore.relationSprite(relation)
        if let ring = spriteNode(key: ringKey, scale: assetScale, store: store) {
            ring.zPosition = zBase
            container.addChild(ring)
        }

        let ratio = Double(max(0, unit.hp)) / Double(max(1, unit.maxHP))
        let arc = NativeUnitStatusCore.hpArc(ratio: ratio)
        if arc.sweep > 0 {
            let path = CGMutablePath()
            path.addArc(
                center: .zero,
                radius: CGFloat(arc.radius) * assetScale,
                startAngle: CGFloat(-arc.start),
                endAngle: CGFloat(-arc.end),
                clockwise: true
            )
            let hp = SKShapeNode(path: path)
            hp.strokeColor = UIColor(
                red: CGFloat(arc.color.r) / 255,
                green: CGFloat(arc.color.g) / 255,
                blue: CGFloat(arc.color.b) / 255,
                alpha: 1
            )
            hp.lineWidth = CGFloat(arc.width) * assetScale
            hp.lineCap = .butt
            hp.zPosition = zBase + 1
            container.addChild(hp)
        }

        if let markerID = NativeUnitStatusCore.armyMarkerID(unit.armyID),
           let marker = spriteNode(key: "mark_unit_\(markerID).png", scale: assetScale, store: store) {
            marker.zPosition = zBase + 2
            container.addChild(marker)
        }
    }

    private func spriteNode(key: String, scale: CGFloat, store: NativeResourceStore) -> SKSpriteNode? {
        guard let entry = spriteManifest[key] else { return nil }
        let url = store.spriteURL(manifestPath: entry.file)
        guard let data = try? Data(contentsOf: url), let image = UIImage(data: data)?.cgImage else { return nil }
        let node = SKSpriteNode(texture: SKTexture(cgImage: image))
        node.anchorPoint = CGPoint(x: 0, y: 1)
        node.position = CGPoint(x: -entry.refx * scale, y: entry.refy * scale)
        node.size = CGSize(width: entry.w * scale, height: entry.h * scale)
        return node
    }

    private func updateUnitNodePosition(_ unit: NativeBattleUnitState) {
        let center = worldScenePoint(NativeHexGeometry.cellCenter(unit.cell))
        if let tactical = tacticalUnitContainers[unit.index] {
            tactical.position = center
            tactical.zPosition = 100 + CGFloat(unit.r) / 1000
        }
        if let strategic = strategicUnitContainers[unit.index] {
            strategic.position = center
            strategic.zPosition = 150 + CGFloat(unit.r) / 1000
        }
    }

    private func removeDeadUnitNodes(gameplay: NativeBattleGameplayState) {
        for index in gameplay.unitOrder where gameplay.units[index]?.dead == true {
            // P33 parity: a logically dead unit stays visible until its authored
            // attack-impact presentation commits. Attack/reload playback may also
            // still own the node, so neither condition is allowed to remove early.
            if damagePresentationQueue.isVisible(unitIndex: index, logicalDead: true) { continue }
            if activeUnitAnimations[index] != nil { continue }
            tacticalUnitContainers[index]?.removeFromParent()
            strategicUnitContainers[index]?.removeFromParent()
            tacticalUnitContainers[index] = nil
            strategicUnitContainers[index] = nil
        }
    }

    private func refreshUnitNode(_ unitIndex: Int, gameplay: NativeBattleGameplayState) {
        guard let store = resourceStore,
              let animations = animationsManifest,
              let unit = gameplay.units[unitIndex] else {
            return
        }
        if unit.dead {
            tacticalUnitContainers[unitIndex]?.removeFromParent()
            strategicUnitContainers[unitIndex]?.removeFromParent()
            tacticalUnitContainers[unitIndex] = nil
            strategicUnitContainers[unitIndex] = nil
            return
        }
        try? renderReadyUnit(unit, gameplay: gameplay, animations: animations, store: store)
    }

    private func addNativeBattleHUD(store: NativeResourceStore) {
        let pauseRect = NativeOriginalFormGeometryCore.Pause.hudButton
        if let button = spriteNode(key: "button_pause.png", scale: 0.5, store: store) {
            button.name = "native-pause-button"
            button.anchorPoint = CGPoint(x: 0, y: 1)
            button.position = CGPoint(x: pauseRect.origin.x, y: EW4LogicalSpace.height - pauseRect.origin.y)
            button.size = CGSize(width: pauseRect.size.width, height: pauseRect.size.height)
            button.zPosition = 1000
            hudLayer.addChild(button)
            pauseButtonNode = button
        }
        if let button = spriteNode(key: "button_return.png", scale: 0.5, store: store) {
            button.name = "native-undo-button"
            button.anchorPoint = CGPoint(x: 0, y: 1)
            button.position = CGPoint(
                x: NativeBattleHUDCore.undo.x,
                y: EW4LogicalSpace.height - NativeBattleHUDCore.undo.y
            )
            button.size = CGSize(
                width: NativeBattleHUDCore.undo.width,
                height: NativeBattleHUDCore.undo.height
            )
            button.zPosition = 1000
            hudLayer.addChild(button)
            undoButtonNode = button
        }
        if let button = spriteNode(key: "button_round.png", scale: 0.5, store: store) {
            button.name = "native-round-button"
            button.anchorPoint = CGPoint(x: 0, y: 1)
            button.position = CGPoint(
                x: NativeBattleHUDCore.next.x,
                y: EW4LogicalSpace.height - NativeBattleHUDCore.next.y
            )
            button.size = CGSize(
                width: NativeBattleHUDCore.next.width,
                height: NativeBattleHUDCore.next.height
            )
            button.zPosition = 1000
            hudLayer.addChild(button)
            roundButtonNode = button
        }
    }

    private func startNativeTutorial(file: String, store: NativeResourceStore) {
        guard let catalog = try? store.tutorials(), let script = catalog.scripts[file] else { statusHandler?("Tutorial script missing"); return }
        tutorialScriptFile = file
        var runner = NativeTutorialRunner(commands: script.commands, mapWidth: catalog.mapWidth)
        let effects = runner.start(); tutorialRunner = runner; applyTutorialEffects(effects)
        statusHandler?("Native tutorial · \(file) · \(script.commandCount) commands")
    }

    private func applyTutorialEffects(_ effects: [NativeTutorialEffect]) {
        for effect in effects {
            switch effect {
            case .showText(let id): showTutorialText(stringCatalog["desc_tutorials_word_\(id)"] ?? "教程 \(id)")
            case .hideText: tutorialOverlayLayer.childNode(withName:"tutorial_text")?.removeFromParent()
            case .drawWorldRect(let command, let cell): drawTutorialWorldRect(command, cell:cell)
            case .drawUIRect(let command): drawTutorialUIRect(command)
            case .clearRect: tutorialWorldLayer.removeAllChildren(); tutorialOverlayLayer.childNode(withName:"tutorial_rect")?.removeFromParent()
            case .moveToArea(let cell): if let cell { focusProgrammatically(on: cell) }
            case .selectArea(let cell): if let cell, var gameplay=gameplayState, let unit=gameplay.unit(at:cell) { gameplay.selectUnit(unit.index); gameplayState=gameplay; refreshInteractionOverlay() }
            case .unselectArea: if var gameplay=gameplayState { gameplay.selectUnit(nil); gameplayState=gameplay; refreshInteractionOverlay() }
            case .exit: tutorialCompletedHandler?()
            default: break
            }
        }
    }

    private func showTutorialText(_ text: String) {
        tutorialOverlayLayer.childNode(withName:"tutorial_text")?.removeFromParent()
        let box=SKShapeNode(rect:CGRect(x:18,y:12,width:532,height:56),cornerRadius:6);box.name="tutorial_text";box.fillColor=UIColor(white:0.08,alpha:0.88);box.strokeColor=UIColor(red:0.84,green:0.72,blue:0.42,alpha:1);box.lineWidth=1.5
        let label=SKLabelNode(fontNamed:"PingFangSC-Semibold");label.text=text;label.fontSize=10;label.fontColor = .white;label.numberOfLines=3;label.preferredMaxLayoutWidth=500;label.horizontalAlignmentMode = .center;label.verticalAlignmentMode = .center;label.position=CGPoint(x:266,y:28);box.addChild(label);tutorialOverlayLayer.addChild(box)
    }

    private func drawTutorialWorldRect(_ command: NativeTutorialCommand, cell: HexCell?) {
        tutorialWorldLayer.removeAllChildren();guard let cell else{return};let center=NativeHexGeometry.cellCenter(cell);let x=Double(command.x ?? -24),y=Double(command.y ?? -24),w=Double(command.w ?? 48),h=Double(command.h ?? 48)
        let node=SKShapeNode(rect:CGRect(x:x,y:-(y+h),width:w,height:h));node.strokeColor=UIColor(red:1,green:0.82,blue:0.18,alpha:1);node.fillColor=UIColor(red:1,green:0.82,blue:0.18,alpha:0.08);node.lineWidth=2;node.position=worldScenePoint(center);tutorialWorldLayer.addChild(node)
    }

    private func drawTutorialUIRect(_ command: NativeTutorialCommand) {
        tutorialOverlayLayer.childNode(withName:"tutorial_rect")?.removeFromParent()
        let base: NativeRect?
        switch command.string ?? "" {
        case "group_res": base = .init(x:0,y:0,width:208,height:23)
        case "group_incom": base = .init(x:0,y:31,width:110,height:48)
        case "btn_next": let r = NativeBattleHUDCore.next; base = .init(x: r.x, y: r.y, width: r.width, height: r.height)
        case "btn_undo": let r = NativeBattleHUDCore.undo; base = .init(x: r.x, y: r.y, width: r.width, height: r.height)
        case "btn_bar", "btn_trading", "btn_general", "btn_item", "btn_training", "btn_upgrade", "btn_city", "btn_factory", "btn_defense", "btn_fortress", "btn_ship": base = battleActionStripRenderer?.rect(for: command.string ?? "")
        case "btn_buy_1", "btn_buy_2", "btn_buy_3", "btn_buy_4", "btn_sell_1", "btn_sell_2", "btn_sell_3", "btn_sell_4": base = originalMarketRenderer?.rect(alias: command.string ?? "")
        case "lbox_unit": base = originalRecruitUnitRenderer?.rect(alias: "lbox_unit", row: command.row)
        case "lbox_item": base = originalUseItemRenderer?.rect(alias: "lbox_item", row: command.row)
        case "lbox_defense": base = originalDefenseRenderer?.rect(alias: "lbox_defense", row: command.row)
        case "grid_general", "winbtn_back": base = originalGeneralDeploymentRenderer?.rect(alias: command.string ?? "", row: command.row)
        case "winbtn_close":
            if originalRecruitUnitRenderer?.isVisible == true { base = originalRecruitUnitRenderer?.rect(alias: "winbtn_close", row: nil) }
            else if originalUseItemRenderer?.isVisible == true { base = originalUseItemRenderer?.rect(alias: "winbtn_close", row: nil) }
            else if originalDefenseRenderer?.isVisible == true { base = originalDefenseRenderer?.rect(alias: "winbtn_close", row: nil) }
            else { base = originalMarketRenderer?.rect(alias: "winbtn_close") }
        case "winbtn_ok":
            if originalRecruitUnitRenderer?.isVisible == true { base = originalRecruitUnitRenderer?.rect(alias: "winbtn_ok", row: nil) }
            else if originalUseItemRenderer?.isVisible == true { base = originalUseItemRenderer?.rect(alias: "winbtn_ok", row: nil) }
            else if originalDefenseRenderer?.isVisible == true { base = originalDefenseRenderer?.rect(alias: "winbtn_ok", row: nil) }
            else { base = originalActionResourceRenderer?.rect(alias: "winbtn_ok") }
        case "btn_done": base = originalActionResourceRenderer?.rect(alias: "btn_done")
        default: base = nil
        }
        guard let base else { return }
        let dx=Double(command.w ?? 0),dy=Double(command.h ?? 0);let r=NativeRect(x:base.origin.x+min(0,dx),y:base.origin.y+min(0,dy),width:base.size.width+abs(dx),height:base.size.height+abs(dy))
        let node=SKShapeNode(rect:CGRect(x:r.origin.x,y:EW4LogicalSpace.height-r.origin.y-r.size.height,width:r.size.width,height:r.size.height));node.name="tutorial_rect";node.strokeColor=UIColor(red:1,green:0.82,blue:0.18,alpha:1);node.fillColor = .clear;node.lineWidth=2;tutorialOverlayLayer.addChild(node)
    }

    private func advanceTutorialTouch() -> Bool {
        guard var runner=tutorialRunner, runner.wait == .touch else{return false};let effects=runner.notifyTouch();tutorialRunner=runner;applyTutorialEffects(effects);return true
    }
    private func advanceTutorialArea(_ cell: HexCell) {
        guard var runner=tutorialRunner else{return};let effects=runner.notifyArea(q:cell.q,r:cell.r);tutorialRunner=runner;applyTutorialEffects(effects)
    }
    private func advanceTutorialUI(_ name:String,row:Int?=nil) {
        guard var runner=tutorialRunner else{return};let effects=runner.notifyUI(name,row:row);tutorialRunner=runner;applyTutorialEffects(effects)
    }
    private func advanceTutorialAction() {
        guard var runner=tutorialRunner else{return};let effects=runner.notifyAction();tutorialRunner=runner;applyTutorialEffects(effects)
    }

    private func refreshBattleActionStrip(gameplay: NativeBattleGameplayState) {
        guard gameplay.phase == .player,
              !presentationBusy,
              aiPresentationDriver == nil,
              activeTavernObjectIndex == nil,
              activeMarketObjectIndex == nil,
              activeShopObjectIndex == nil,
              activeUnitInfoUnitIndex == nil,
              activeGeneralInfoUnitIndex == nil,
              activeGeneralTargetUnitIndex == nil,
              activeRecruitObjectIndex == nil,
              activeUseItemUnitIndex == nil,
              activeDefenseUnitIndex == nil,
              originalActionResourceRenderer?.isVisible != true,
              battleModalState == .none,
              !stageIntroActive,
              activeNativeDialogue == nil,
              battleResultPresentationPhase == .none,
              isOuterCompletionIdle else {
            battleActionStripRenderer?.hide()
            return
        }

        var buttons: [NativeBattleActionButton] = []
        if let index = gameplay.selectedUnitIndex, let unit = gameplay.units[index] {
            if unit.owner == gameplay.playerOwner {
                // P55 exposes the recovered original strip immediately. Only actions
                // whose native form/commit path is already bound are enabled.
                buttons.append(.init(.items, enabled: !unit.attacked))
                buttons.append(.init(.buyship, enabled: gameplay.canEmbark(index)))
                if gameplay.canBuildInstallation(index) { buttons.append(.init(.buildDefense, enabled: !unit.attacked)) }
                if unit.commanderID != nil { buttons.append(.init(.training, enabled: gameplay.canManualTrain(index))) }
                buttons.append(.init(.generals, enabled: true))
            }
            if unit.commanderID != nil { buttons.append(.init(.generalInfo, enabled: true)) }
            buttons.append(.init(.info, enabled: true))
        } else if let objectIndex = selectedFacilityObjectIndex, let object = gameplay.objects[objectIndex] {
            let mine = object.owner == gameplay.playerOwner
            if mine {
                switch object.extra {
                case 1: buttons.append(.init(.trade, enabled: true))
                case 2:
                    let exists = NativeBattleShopCore.record(itemStores: persistenceContext?.itemStores, objectIndex: objectIndex) != nil
                    buttons.append(.init(.shop, enabled: exists))
                case 3:
                    let exists = NativeBattleTavernCore.record(taverns: persistenceContext?.taverns, objectIndex: objectIndex) != nil
                    buttons.append(.init(.bar, enabled: exists))
                default: break
                }
                buttons.append(.init(.upgrade, enabled: gameplay.canUpgradeConstruction(objectIndex)))
                switch object.constructionType?.lowercased() {
                case "industry": buttons.append(.init(.factory, enabled: gameplay.canRecruit(at: objectIndex)))
                case "stable": buttons.append(.init(.stable, enabled: gameplay.canRecruit(at: objectIndex)))
                case "port": buttons.append(.init(.dock, enabled: gameplay.canRecruit(at: objectIndex)))
                case "city", "capital": buttons.append(.init(.city, enabled: gameplay.canRecruit(at: objectIndex)))
                default: break
                }
            }
        } else if let cell = selectedEmptyCell, let ownership = persistenceContext?.ownership, gameplay.canBuildFortress(at: cell, ownership: ownership) {
            buttons.append(.init(.buildFortress, enabled: true))
        }
        battleActionStripRenderer?.show(buttons)
    }

    private func selectFacility(_ objectIndex: Int, gameplay: inout NativeBattleGameplayState) {
        gameplay.selectUnit(nil)
        selectedEmptyCell = nil
        selectedFacilityObjectIndex = objectIndex
        gameplayState = gameplay
        refreshInteractionOverlay()
        refreshNativeBattleHUD(gameplay: gameplay)
        if let object = gameplay.objects[objectIndex] {
            statusHandler?("设施 · \(object.constructionType ?? "#\(object.constructionID)")")
        }
    }

    private func handleBattleAction(_ action: NativeBattleActionID, gameplay: inout NativeBattleGameplayState) {
        switch action {
        case .trade:
            guard let objectIndex = selectedFacilityObjectIndex else { return }
            advanceTutorialUI(action.tutorialAlias)
            openNativeMarket(objectIndex: objectIndex)
        case .bar:
            guard let objectIndex = selectedFacilityObjectIndex else { return }
            advanceTutorialUI(action.tutorialAlias)
            openNativeTavern(objectIndex: objectIndex)
        case .shop:
            guard let objectIndex = selectedFacilityObjectIndex else { return }
            openNativeBattleShop(objectIndex: objectIndex)
        case .generals:
            guard let unitIndex = gameplay.selectedUnitIndex else { return }
            advanceTutorialUI(action.tutorialAlias)
            openNativeGeneralDeployment(unitIndex: unitIndex)
        case .training:
            guard let unitIndex = gameplay.selectedUnitIndex else { return }
            advanceTutorialUI(action.tutorialAlias)
            openNativeActionResource(.training(unitIndex: unitIndex), gameplay: gameplay)
        case .buyship:
            guard let unitIndex = gameplay.selectedUnitIndex else { return }
            advanceTutorialUI("btn_ship")
            openNativeActionResource(.embark(unitIndex: unitIndex), gameplay: gameplay)
        case .upgrade:
            guard let objectIndex = selectedFacilityObjectIndex else { return }
            advanceTutorialUI(action.tutorialAlias)
            openNativeActionResource(.upgrade(objectIndex: objectIndex), gameplay: gameplay)
        case .city, .factory, .stable, .dock:
            guard let objectIndex = selectedFacilityObjectIndex else { return }
            advanceTutorialUI(action.tutorialAlias)
            openNativeRecruitUnit(objectIndex: objectIndex)
        case .items:
            guard let unitIndex = gameplay.selectedUnitIndex else { return }
            advanceTutorialUI(action.tutorialAlias)
            openNativeUseItem(unitIndex: unitIndex)
        case .buildDefense:
            guard let unitIndex = gameplay.selectedUnitIndex else { return }
            advanceTutorialUI(action.tutorialAlias)
            openNativeDefenseInstallation(unitIndex: unitIndex)
        case .buildFortress:
            guard let cell = selectedEmptyCell else { return }
            advanceTutorialUI(action.tutorialAlias)
            openNativeDefenseFortress(cell: cell)
        case .generalInfo:
            guard let unitIndex = gameplay.selectedUnitIndex else { return }
            advanceTutorialUI(action.tutorialAlias)
            openNativeBattleGeneralInfo(unitIndex: unitIndex)
        case .info:
            guard let unitIndex = gameplay.selectedUnitIndex else { return }
            advanceTutorialUI(action.tutorialAlias)
            openNativeBattleUnitInfo(unitIndex: unitIndex)
        }
    }

    private var presentationBusy: Bool {
        !activeUnitMoves.isEmpty || !damagePresentationQueue.isEmpty || pendingActionCameraContinuation != nil
    }

    private func refreshNativeBattleHUD(gameplay: NativeBattleGameplayState) {
        let aiActive = aiPresentationDriver != nil
        let formBlocking = activeTavernObjectIndex != nil || activeMarketObjectIndex != nil || activeShopObjectIndex != nil || activeUnitInfoUnitIndex != nil || activeGeneralInfoUnitIndex != nil || activeGeneralTargetUnitIndex != nil || activeRecruitObjectIndex != nil || activeUseItemUnitIndex != nil || activeDefenseUnitIndex != nil || originalActionResourceRenderer?.isVisible == true || stageIntroActive || activeNativeDialogue != nil || battleModalState != .none || battleResultPresentationPhase != .none || !isOuterCompletionIdle
        undoButtonNode?.isHidden = gameplay.phase != .player || gameplay.undo == nil || presentationBusy || aiActive || formBlocking
        let aiFastForwardAvailable = gameplay.phase == .ai && aiActive && !formBlocking
        roundButtonNode?.isHidden = formBlocking || (!aiFastForwardAvailable && (gameplay.phase != .player || presentationBusy || !activeUnitAnimations.isEmpty || aiActive))
        pauseButtonNode?.isHidden = gameplay.phase != .player || presentationBusy || !activeUnitAnimations.isEmpty || aiActive || formBlocking
        refreshBattleActionStrip(gameplay: gameplay)
    }

    private func handleNativeHUDTap(_ screen: NativePoint) -> Bool {
        guard var gameplay = gameplayState else { return false }
        if NativeBattleHUDCore.next.contains(screen) {
            if gameplay.phase == .ai, aiPresentationDriver != nil {
                aiFastForward = true
                if case .ai = pendingActionCameraContinuation {
                    programmaticCameraMotion = nil
                    resumeActionAfterCameraFocus()
                }
                if let live = gameplayState { refreshNativeBattleHUD(gameplay: live) }
                statusHandler?("快进敌军行动")
                return true
            }
            advanceTutorialUI("btn_next")
            guard gameplay.phase == .player, !presentationBusy, activeUnitAnimations.isEmpty, aiPresentationDriver == nil else { return true }
            aiFastForward = false
            aiPresentationDriver = NativeAIPresentationDriver()
            aiResumeAtMilliseconds = animationNowMilliseconds()
            aiNeedsCountryAdvance = false
            gameplayState = gameplay
            refreshNativeBattleHUD(gameplay: gameplay)
            statusHandler?("AI round starting")
            return true
        }
        guard gameplay.phase == .player, aiPresentationDriver == nil else { return false }
        if let action = battleActionStripRenderer?.action(at: screen) {
            handleBattleAction(action, gameplay: &gameplay)
            return true
        }
        if rectContains(NativeOriginalFormGeometryCore.Pause.hudButton, screen) {
            openNativePause()
            return true
        }
        guard NativeBattleHUDCore.undo.contains(screen) else { return false }
        advanceTutorialUI("btn_undo")
        guard gameplay.undo != nil, gameplay.phase == .player, !presentationBusy, activeUnitAnimations.isEmpty else { return true }
        do {
            let result = try gameplay.undoLastMove()
            gameplayState = gameplay
            if result.path.count > 1 {
                startMovePresentation(result, nowMilliseconds: animationNowMilliseconds(), fastAI: false)
            } else if let unit = gameplay.units[result.unitIndex] {
                updateUnitNodePosition(unit)
            }
            refreshInteractionOverlay()
            refreshNativeBattleHUD(gameplay: gameplay)
            statusHandler?("Move undone")
        } catch {
            statusHandler?("Undo blocked · \(error)")
        }
        return true
    }

    private func animationNowMilliseconds() -> Double {
        ProcessInfo.processInfo.systemUptime * 1000
    }

    private func cachedAnimationFrame(
        assetID: String,
        frameIndex: Int,
        manifest: NativeAnimationManifest,
        store: NativeResourceStore
    ) throws -> BILERasterizedFrame {
        if let cached = animationFrameCache[assetID]?[frameIndex] {
            return cached
        }
        guard let asset = manifest.assets[assetID] else {
            throw NativeAnimationSequenceError.missingAsset(assetID)
        }
        let bile = try bileResource(asset.resource, store: store)
        let atlas = try atlasResource(asset.resource, store: store)
        let itemIndex = try bile.itemIndex(named: asset.motionName)
        let rendered = try rasterizer.frame(
            bile: bile,
            itemIndex: itemIndex,
            frame: frameIndex,
            atlas: atlas
        )
        var frames = animationFrameCache[assetID] ?? [:]
        frames[frameIndex] = rendered
        animationFrameCache[assetID] = frames
        return rendered
    }

    private func applyAnimationFrame(
        unitIndex: Int,
        animationUnitName: String,
        assetID: String,
        frameIndex: Int
    ) throws {
        guard let gameplay = gameplayState,
              let unit = gameplay.units[unitIndex],
              let manifest = animationsManifest,
              let animationUnit = manifest.units[animationUnitName],
              let store = resourceStore,
              let model = tacticalUnitContainers[unitIndex]?.childNode(withName: "unit-model-\(unitIndex)") as? SKSpriteNode else {
            return
        }
        let rendered = try cachedAnimationFrame(
            assetID: assetID,
            frameIndex: frameIndex,
            manifest: manifest,
            store: store
        )
        let center = NativeHexGeometry.cellCenter(unit.cell)
        let origin = NativeAnimationTiming.compactDrawOrigin(
            unit: animationUnit,
            worldPoint: center,
            unitZoom: 1
        )
        let scale = origin.scale
        let drawX = origin.x + rendered.bounds.origin.x * scale
        let drawY = origin.y + rendered.bounds.origin.y * scale
        model.texture = rendered.texture
        model.position = CGPoint(x: drawX - center.x, y: center.y - drawY)
        model.size = CGSize(
            width: rendered.bounds.size.width * scale,
            height: rendered.bounds.size.height * scale
        )
    }

    @discardableResult
    private func startAttackAnimation(
        attacker: NativeBattleUnitState,
        target: NativeBattleUnitState,
        gameplay: NativeBattleGameplayState,
        startMilliseconds: Double
    ) -> NativeAnimationSequence? {
        guard let manifest = animationsManifest,
              !(attacker.embarked && gameplay.stat(for: attacker)?.type != "warship"),
              let name = NativeUnitVisualResolver.animationUnitName(
                unit: attacker,
                countryCode: gameplay.countryCode(owner: attacker.owner),
                manifest: manifest
              ),
              let stat = gameplay.stat(for: attacker) else {
            return nil
        }
        let a = NativeHexGeometry.cellCenter(attacker.cell)
        let b = NativeHexGeometry.cellCenter(target.cell)
        let direction = b.x < a.x ? "left" : "right"
        unitFacing[attacker.index] = direction
        let targetClass = gameplay.stat(for: target)?.type ?? ""
        do {
            let sequence = try NativeAnimationSequenceCore.buildAttackSequence(
                manifest: manifest,
                unitName: name,
                context: NativeAttackAnimationContext(
                    weapon: stat.weapon,
                    targetClass: targetClass,
                    direction: direction
                )
            )
            activeUnitAnimations[attacker.index] = ActiveUnitAnimation(
                unitIndex: attacker.index,
                animationUnitName: name,
                sequence: sequence,
                startMilliseconds: startMilliseconds,
                lastAssetID: nil,
                lastFrameIndex: -1
            )
            return sequence
        } catch {
            statusHandler?("Native animation fallback · \(error)")
            return nil
        }
    }

    private func setUnitPresentationPosition(unitIndex: Int, point: NativePoint) {
        let scenePoint = worldScenePoint(point)
        tacticalUnitContainers[unitIndex]?.position = scenePoint
        strategicUnitContainers[unitIndex]?.position = scenePoint
    }

    private func startMovePresentation(
        _ result: NativeBattleMoveResult,
        nowMilliseconds: Double,
        fastAI: Bool
    ) {
        guard result.path.count > 1 else {
            if let gameplay = gameplayState, let unit = gameplay.units[result.unitIndex] {
                updateUnitNodePosition(unit)
            }
            return
        }
        let duration = NativeMovementPresentationCore.durationMilliseconds(path: result.path, fastAI: fastAI)
        activeUnitMoves[result.unitIndex] = ActiveUnitMoveAnimation(
            unitIndex: result.unitIndex,
            path: result.path,
            startMilliseconds: nowMilliseconds,
            durationMilliseconds: duration,
            capturedObjectIndices: result.capturedObjectIndices
        )
        if let first = result.path.first {
            setUnitPresentationPosition(unitIndex: result.unitIndex, point: NativeHexGeometry.cellCenter(first))
        }
    }

    private func updateMoveAnimations(nowMilliseconds: Double) {
        guard !activeUnitMoves.isEmpty else { return }
        for unitIndex in Array(activeUnitMoves.keys) {
            guard let move = activeUnitMoves[unitIndex],
                  let sample = NativeMovementPresentationCore.sample(
                    path: move.path,
                    elapsedMilliseconds: nowMilliseconds - move.startMilliseconds,
                    durationMilliseconds: move.durationMilliseconds
                  ) else {
                activeUnitMoves[unitIndex] = nil
                continue
            }
            setUnitPresentationPosition(unitIndex: unitIndex, point: sample.point)
            unitFacing[unitIndex] = sample.facing
            if let gameplay = gameplayState { updateTransportFacing(unitIndex: unitIndex, desiredFacing: sample.facing, gameplay: gameplay) }
            if sample.completed {
                activeUnitMoves[unitIndex] = nil
                if let gameplay = gameplayState, let unit = gameplay.units[unitIndex] {
                    updateUnitNodePosition(unit)
                    refreshUnitNode(unitIndex, gameplay: gameplay)
                    if let store = resourceStore {
                        for objectIndex in move.capturedObjectIndices {
                            if let object = gameplay.objects[objectIndex] {
                                try? renderObject(object, gameplay: gameplay, sprites: spriteManifest, store: store)
                            }
                        }
                    }
                    refreshInteractionOverlay()
                    refreshNativeBattleHUD(gameplay: gameplay)
                    if !move.capturedObjectIndices.isEmpty { _ = evaluateNativeBattleOutcomeIfNeeded() }
                }
            }
        }
    }

    private func spawnDamageFloat(_ event: NativeDamagePresentationEvent) {
        guard let gameplay = gameplayState, let target = gameplay.units[event.targetIndex] else { return }
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text = "-\(event.damage)"
        label.fontSize = 12
        label.fontColor = UIColor(white: 0.96, alpha: 1)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        let center = NativeHexGeometry.cellCenter(target.cell)
        label.position = CGPoint(x: center.x, y: -center.y + 18)
        label.zPosition = 900
        worldLayer.addChild(label)
        label.run(.sequence([
            .group([.moveBy(x: 0, y: 18, duration: 0.55), .fadeOut(withDuration: 0.55)]),
            .removeFromParent()
        ]))
    }

    private func updateDamagePresentations(nowMilliseconds: Double) {
        let applied = damagePresentationQueue.drain(nowMilliseconds: nowMilliseconds)
        guard !applied.isEmpty, let gameplay = gameplayState else { return }
        for event in applied {
            spawnDamageFloat(event)
            refreshUnitNode(event.targetIndex, gameplay: gameplay)
        }
        removeDeadUnitNodes(gameplay: gameplay)
        refreshInteractionOverlay()
        refreshNativeBattleHUD(gameplay: gameplay)
        if damagePresentationQueue.isEmpty { _ = evaluateNativeBattleOutcomeIfNeeded() }
    }

    @discardableResult
    private func startAttackPresentation(
        beforeAttacker: NativeBattleUnitState,
        beforeDefender: NativeBattleUnitState,
        afterAttacker: NativeBattleUnitState,
        afterDefender: NativeBattleUnitState,
        result: NativeBattleAttackResult,
        gameplay: NativeBattleGameplayState,
        nowMilliseconds: Double,
        fastAI: Bool = false
    ) -> NativeAttackPresentationPlan? {
        guard let manifest = animationsManifest else {
            refreshUnitNode(afterDefender.index, gameplay: gameplay)
            if result.counterDamage != nil { refreshUnitNode(afterAttacker.index, gameplay: gameplay) }
            return nil
        }
        let attackerSequence = startAttackAnimation(
            attacker: beforeAttacker,
            target: beforeDefender,
            gameplay: gameplay,
            startMilliseconds: nowMilliseconds
        )
        let counterSequence: NativeAnimationSequence? = result.counterDamage == nil ? nil : startAttackAnimation(
            attacker: beforeDefender,
            target: beforeAttacker,
            gameplay: gameplay,
            startMilliseconds: nowMilliseconds
        )
        var plan = NativeImpactPresentationCore.plan(
            beforeAttacker: beforeAttacker,
            afterAttacker: afterAttacker,
            beforeDefender: beforeDefender,
            afterDefender: afterDefender,
            result: result,
            attackerSequence: attackerSequence,
            counterSequence: counterSequence,
            manifest: manifest
        )
        if fastAI {
            plan = NativeImpactPresentationCore.fastAI(plan)
            activeUnitAnimations[beforeAttacker.index] = nil
            if result.counterDamage != nil { activeUnitAnimations[beforeDefender.index] = nil }
        }
        damagePresentationQueue.enqueue(plan: plan, nowMilliseconds: nowMilliseconds)
        return plan
    }

    private func applyBattleAttackSidecars(_ result: NativeBattleAttackResult) {
        if var context = persistenceContext {
            let delta = NativeBattleSidecarCore.applyAttackResult(result, context: &context)
            persistenceContext = context
            if delta > 0 { statusHandler?("Battle medal +\(delta)") }
        }
        syncLivePlayerProfile(after: result)
    }

    private func absorbNativeEventApplication(_ application: NativeBattleEventApplication) {
        guard !application.newlyQueuedDialogues.isEmpty else { return }
        let update = nativeDialogueQueueCore.enqueue(application.newlyQueuedDialogues)
        if update.activeChanged, let active = update.active { presentNativeDialogue(active) }
    }

    private func presentNativeRoundTurn(_ content: NativeRoundTurnContent) {
        guard battleResultPresentationPhase == .none, activeNativeDialogue == nil, !stageIntroActive else { return }
        pendingRoundTurnContent = content
        battleModalState = .roundTurn
        originalBattleModalRenderer?.showRoundTurn(content)
        if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
        statusHandler?("Round turn · \(content.round)")
    }

    public func closeNativeRoundTurn() {
        guard battleModalState == .roundTurn else { return }
        pendingRoundTurnContent = nil
        battleModalState = .none
        originalBattleModalRenderer?.hide()
        guard let gameplay = gameplayState, !gameplay.ended else {
            if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
            return
        }
        let result = fireNativeRoundEvents(round: gameplay.round)
        if result.appliedEvents.isEmpty && result.newlyQueuedDialogues.isEmpty {
            autosaveIfDialogueIdle()
        }
        if let updated = gameplayState { refreshNativeBattleHUD(gameplay: updated) }
    }

    public func openNativePause() {
        guard let gameplay = gameplayState, !gameplay.ended, activeNativeDialogue == nil, !stageIntroActive, battleResultPresentationPhase == .none else { return }
        battleModalState = .pause
        originalBattleModalRenderer?.showPause(round: gameplay.round)
        refreshNativeBattleHUD(gameplay: gameplay)
    }

    public func openNativeSavePanel(mode: NativeSavePanelMode = .save) {
        guard activeNativeDialogue == nil, !stageIntroActive, let store = resourceStore else { return }
        let metadata = saveSlotMetadataProvider?() ?? []
        let battles = (try? store.battles().battles) ?? []
        let displays = NativeOriginalBattleModalCore.saveSlotDisplays(metadata: metadata, battles: battles)
        battleModalState = .save(mode)
        originalBattleModalRenderer?.showSave(mode: mode, slots: displays)
        if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
    }

    public func closeNativeBattleModal(returnToPause: Bool = false) {
        if returnToPause, gameplayState != nil {
            battleModalState = .pause
            originalBattleModalRenderer?.showPause(round: gameplayState?.round ?? 1)
        } else {
            battleModalState = .none
            originalBattleModalRenderer?.hide()
        }
        if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
    }

    private func handleNativeBattleModalTap(_ point: NativePoint) {
        switch battleModalState {
        case .none: return
        case .roundTurn:
            let screen = NativeOriginalFormGeometryCore.RoundTurn.screenFrame
            let local = NativePoint(x: point.x - screen.origin.x, y: point.y - screen.origin.y)
            if NativeOriginalBattleModalCore.roundTurnCloseHit(at: local) { closeNativeRoundTurn() }
        case .pause:
            let screen = NativeOriginalFormGeometryCore.Pause.screenFrame
            let local = NativePoint(x: point.x - screen.origin.x, y: point.y - screen.origin.y)
            guard let action = NativeOriginalBattleModalCore.pauseAction(at: local) else { return }
            switch action {
            case .close: closeNativeBattleModal()
            case .save: openNativeSavePanel(mode: .save)
            case .option: closeNativeBattleModal(); pauseOptionHandler?()
            case .restart: closeNativeBattleModal(); pauseRestartHandler?()
            case .exit: autosaveIfDialogueIdle(); closeNativeBattleModal(); pauseExitHandler?()
            }
        case .save(let mode):
            let screen = NativeOriginalFormGeometryCore.Save.screenFrame
            let local = NativePoint(x: point.x - screen.origin.x, y: point.y - screen.origin.y)
            if NativeOriginalBattleModalCore.saveCloseHit(at: local) { closeNativeBattleModal(returnToPause: true); return }
            guard let slot = NativeOriginalBattleModalCore.saveSlotAction(at: local) else { return }
            switch mode {
            case .save:
                if slot == .autosave { return }
                guard let payload = try? makeBattleSavePayload() else { return }
                battleSaveWriteHandler?(slot, payload)
                openNativeSavePanel(mode: .save)
            case .load:
                guard let payload = battleSaveReadProvider?(slot), let store = resourceStore else { return }
                do {
                    _ = try restoreBattle(from: payload, store: store, profile: playerProfile)
                    battleModalState = .none
                } catch { statusHandler?("Load failed · \(error)") }
            }
        }
    }

    @discardableResult
    private func evaluateNativeBattleOutcomeIfNeeded() -> Bool {
        guard let gameplay = gameplayState, !gameplay.ended else { return false }
        switch gameplay.mode {
        case .campaign: return evaluateNativeCampaignOutcomeIfNeeded()
        case .conquest: return evaluateNativeConquestOutcomeIfNeeded()
        case .tutorial: return false
        }
    }

    private func syncNativeConquestDefeatedOwners(_ gameplay: NativeBattleGameplayState) {
        guard gameplay.mode == .conquest else { return }
        for owner in NativeConquestExtinctionCore.defeatedOwners(gameplay) where !announcedConquestDefeatedOwners.contains(owner) {
            announcedConquestDefeatedOwners.insert(owner)
            conquestCountryDefeatedHandler?(owner, NativeConquestExtinctionCore.countryStatus(gameplay, owner: owner))
            statusHandler?("Conquest country defeated · \(gameplay.countryCode(owner: owner).uppercased())")
        }
    }

    @discardableResult
    private func evaluateNativeConquestOutcomeIfNeeded() -> Bool {
        guard battleResultPresentationPhase == .none,
              var gameplay = gameplayState,
              gameplay.mode == .conquest,
              !gameplay.ended else { return false }
        syncNativeConquestDefeatedOwners(gameplay)
        guard let decision = NativeConquestBattleFlowCore.outcome(gameplay: gameplay) else { return false }

        if decision.kind == .victory {
            let baseProfile = playerProfileRuntime?.snapshot() ?? playerProfile
            let resources = persistenceContext?.countryResources[gameplay.playerOwner]
                ?? persistenceContext?.resources
                ?? CountryResources(money: 0, industry: 0, food: 0)
            pendingConquestVictory = NativeConquestBattleFlowCore.prepareVictory(
                gameplay: gameplay,
                map: activeSession?.worldName ?? "europe",
                resources: resources,
                profile: baseProfile,
                commanders: commanderCatalog
            )
        } else {
            pendingConquestVictory = nil
        }

        gameplay.markEnded()
        gameplayState = gameplay
        aiPresentationDriver = nil
        aiNeedsCountryAdvance = false
        aiResumeAtMilliseconds = 0
        nativeDialogueQueueCore.reset()
        originalTalkRenderer?.hide()
        battleModalState = .none
        originalBattleModalRenderer?.hide()
        presentNativeBattleResult(
            kind: decision.kind == .victory ? .victory : .defeat,
            reason: .combat,
            previousBestScore: 0
        )
        return true
    }

    @discardableResult
    private func evaluateNativeCampaignOutcomeIfNeeded() -> Bool {
        guard battleResultPresentationPhase == .none,
              let manifest = campaignTargetManifest,
              let initial = campaignInitialTargets,
              var gameplay = gameplayState,
              gameplay.mode == .campaign,
              !gameplay.ended,
              let decision = NativeCampaignBattleFlowCore.outcome(
                  gameplay: gameplay, manifest: manifest, initial: initial
              ) else { return false }

        let previousBest: Int
        if decision.kind == .victory {
            let baseProfile = playerProfileRuntime?.snapshot() ?? playerProfile
            let commit = NativeCampaignBattleFlowCore.commitVictory(
                profile: baseProfile, gameplay: gameplay, manifest: manifest, battles: campaignBattles
            )
            previousBest = commit.previousBestScore
            playerProfileRuntime?.replace(with: commit.profile)
            playerProfile = commit.profile
            playerProfileDidChangeHandler?(commit.profile)
            if !commit.unlockedSecretFiles.isEmpty {
                statusHandler?("Campaign secret unlocked · \(commit.unlockedSecretFiles.joined(separator: ","))")
            }
        } else {
            previousBest = 0
        }

        gameplay.markEnded()
        gameplayState = gameplay
        aiPresentationDriver = nil
        aiNeedsCountryAdvance = false
        aiResumeAtMilliseconds = 0
        nativeDialogueQueueCore.reset()
        originalTalkRenderer?.hide()
        battleModalState = .none
        originalBattleModalRenderer?.hide()

        let resultKind: NativeOriginalBattleResultKind = decision.kind == .victory ? .victory : .defeat
        let resultReason: NativeOriginalBattleResultReason = decision.reason == .turnLimit ? .turnLimit : .combat
        presentNativeBattleResult(kind: resultKind, reason: resultReason, previousBestScore: previousBest)
        return true
    }

    private func continueNativeCampaignResult(_ content: NativeOriginalBattleResultContent) -> Bool {
        guard content.kind == .victory,
              let gameplay = gameplayState,
              gameplay.mode == .campaign else { return false }
        let baseProfile = playerProfileRuntime?.snapshot() ?? playerProfile
        let commit = NativeCampaignBattleFlowCore.continueAfterVictory(
            profile: baseProfile, battle: gameplay.battle, battles: campaignBattles
        )
        playerProfileRuntime?.replace(with: commit.profile)
        playerProfile = commit.profile
        playerProfileDidChangeHandler?(commit.profile)
        dismissNativeBattleResult()
        switch commit.route {
        case .zoneComplete(let zone, let reward, _):
            let content = NativeOriginalOuterShellCore.campaignComplete(zone: zone, reward: reward)
            outerCompletionState = .campaign(route: commit.route, content: content)
            originalOuterCompletionRenderer?.showCampaignComplete(content)
        case .campaignList:
            campaignContinueRouteHandler?(commit.route)
        }
        refreshNativeBattleHUD(gameplay: gameplay)
        return true
    }

    private func applyNativeConquestContinueCommit(_ commit: NativeConquestContinueCommit) {
        playerProfileRuntime?.replace(with: commit.profile)
        playerProfile = commit.profile
        playerProfileDidChangeHandler?(commit.profile)
        switch commit.route {
        case .challenge(let prepared):
            pendingConquestVictory = prepared
            dismissNativeBattleResult()
            let content = NativeOriginalOuterShellCore.conquestChallenge(prepared, map: activeSession?.worldName ?? "europe")
            outerCompletionState = .challenge(prepared: prepared, content: content)
            originalOuterCompletionRenderer?.showChallenge(content)
            conquestChallengeHandler?(prepared)
        case .summary(let result):
            pendingConquestVictory = nil
            dismissNativeBattleResult()
            let file = gameplayState?.battle.file ?? ""
            let round = gameplayState?.round ?? 0
            let medals = persistenceContext?.collectMedal ?? 0
            if let content = NativeOriginalOuterShellCore.conquestSummary(file: file, result: result, round: round, collectedMedal: medals) {
                outerCompletionState = .summary(result: result, content: content)
                originalOuterCompletionRenderer?.showConquestSummary(content)
            } else {
                conquestSummaryHandler?(result)
            }
        }
        if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
    }

    private func continueNativeConquestResult(_ content: NativeOriginalBattleResultContent) -> Bool {
        guard content.kind == .victory,
              gameplayState?.mode == .conquest,
              let prepared = pendingConquestVictory else { return false }
        let profile = playerProfileRuntime?.snapshot() ?? playerProfile
        applyNativeConquestContinueCommit(
            NativeConquestBattleFlowCore.continueAfterVictory(profile: profile, prepared: prepared)
        )
        return true
    }

    public func resolveNativeConquestChallenge(chooseAsia: Bool) {
        guard let prepared = pendingConquestVictory else { return }
        let profile = playerProfileRuntime?.snapshot() ?? playerProfile
        applyNativeConquestContinueCommit(
            NativeConquestBattleFlowCore.resolveChallenge(
                profile: profile, prepared: prepared, chooseAsia: chooseAsia
            )
        )
    }

    public func presentNativeBattleResult(
        kind: NativeOriginalBattleResultKind,
        reason: NativeOriginalBattleResultReason = .combat,
        previousBestScore: Int = 0
    ) {
        guard battleResultPresentationPhase == .none,
              battleModalState == .none,
              activeNativeDialogue == nil,
              let gameplay = gameplayState else { return }
        let content = NativeOriginalBattleResultCore.content(
            kind: kind, reason: reason, gameplay: gameplay,
            previousBestScore: previousBestScore,
            collectedMedal: persistenceContext?.collectMedal ?? 0
        )
        activeBattleResult = content
        battleResultPresentedHandler?(content)
        battleResultPresentationPhase = .narration
        if var context = persistenceContext {
            context.ended = .string(kind.rawValue)
            persistenceContext = context
        }
        originalBattleResultRenderer?.hide()
        let narration = stringCatalog[content.narrationKey] ?? content.narrationKey
        originalTalkRenderer?.showSystem(text: narration)
        refreshNativeBattleHUD(gameplay: gameplay)
        statusHandler?(kind == .victory ? "Victory narration" : "Defeat narration")
    }

    public func dismissNativeBattleResult() {
        originalTalkRenderer?.hide()
        originalBattleResultRenderer?.hide()
        activeBattleResult = nil
        battleResultPresentationPhase = .none
        if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
    }

    private func advanceNativeBattleResult(at point: NativePoint) {
        guard let content = activeBattleResult else { return }
        switch battleResultPresentationPhase {
        case .none:
            return
        case .narration:
            originalTalkRenderer?.hide()
            if content.kind == .victory {
                battleResultPresentationPhase = .victoryText
                originalBattleResultRenderer?.showVictoryText { [weak self] in
                    guard let self, self.activeBattleResult != nil else { return }
                    self.battleResultPresentationPhase = .form
                    self.originalBattleResultRenderer?.show(content)
                }
            } else {
                battleResultPresentationPhase = .form
                originalBattleResultRenderer?.show(content)
            }
        case .victoryText:
            return
        case .form:
            let screen = content.kind == .victory
                ? NativeOriginalFormGeometryCore.Victory.screenFrame
                : NativeOriginalFormGeometryCore.Failure.screenFrame
            let local = NativePoint(x: point.x - screen.origin.x, y: point.y - screen.origin.y)
            guard let action = NativeOriginalBattleResultCore.action(kind: content.kind, at: local) else { return }
            switch action {
            case .continueBattle:
                if !continueNativeCampaignResult(content),
                   !continueNativeConquestResult(content) {
                    battleResultContinueHandler?(content)
                }
            case .restart:
                battleResultRestartHandler?(content)
            case .exit:
                battleResultExitHandler?(content)
            }
        }
    }

    private var isOuterCompletionIdle: Bool {
        if case .none = outerCompletionState { return true }
        return false
    }

    private func handleNativeOuterCompletionTap(_ point: NativePoint) {
        let screen = NativeOriginalOuterShellCore.Complete.screenFrame
        let local = NativePoint(x: point.x - screen.origin.x, y: point.y - screen.origin.y)
        switch outerCompletionState {
        case .none:
            return
        case .campaign(let route, _):
            guard NativeOriginalOuterShellCore.campaignCompleteAction(at: local) == .campaignOK else { return }
            originalOuterCompletionRenderer?.hide()
            outerCompletionState = .none
            campaignContinueRouteHandler?(route)
        case .challenge:
            guard let action = NativeOriginalOuterShellCore.conquestChallengeAction(at: local) else { return }
            originalOuterCompletionRenderer?.hide()
            outerCompletionState = .none
            switch action {
            case .challengeAsia: resolveNativeConquestChallenge(chooseAsia: true)
            case .challengeHome: resolveNativeConquestChallenge(chooseAsia: false)
            default: break
            }
        case .summary(let result, _):
            guard NativeOriginalOuterShellCore.conquestSummaryAction(at: local) == .conquestOK else { return }
            originalOuterCompletionRenderer?.hide()
            outerCompletionState = .none
            conquestSummaryHandler?(result)
        }
        if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
    }

    private func rectContains(_ rect: NativeRect, _ point: NativePoint) -> Bool {
        point.x >= rect.origin.x && point.x <= rect.origin.x + rect.size.width &&
        point.y >= rect.origin.y && point.y <= rect.origin.y + rect.size.height
    }

    private func presentNativeStageIntroIfNeeded() {
        guard let battle = activeSession?.battle, gameplayState?.mode == .campaign else { return }
        let content = NativeOriginalFormContentCore.stageIntro(battle: battle, commanders: commanderCatalog)
        stageIntroActive = true
        originalStageIntroRenderer?.show(content)
        statusHandler?("Stage intro · \(battle.file)")
    }

    public func closeNativeStageIntro() {
        guard stageIntroActive else { return }
        stageIntroActive = false
        originalStageIntroRenderer?.hide()
        let result = fireNativeRoundEvents(round: 1)
        if result.appliedEvents.isEmpty && result.newlyQueuedDialogues.isEmpty {
            autosaveIfDialogueIdle()
        }
    }

    private func stageIntroCloseContains(_ point: NativePoint) -> Bool {
        let screen = NativeOriginalFormGeometryCore.StageIntro.screenFrame
        let local = NativePoint(x: point.x - screen.origin.x, y: point.y - screen.origin.y)
        let rect = NativeOriginalFormGeometryCore.StageIntro.closeButton
        return local.x >= rect.origin.x && local.x <= rect.origin.x + rect.size.width &&
            local.y >= rect.origin.y && local.y <= rect.origin.y + rect.size.height
    }

    private func presentNativeDialogue(_ event: NativeBattleScriptEvent) {
        originalTalkRenderer?.show(event)
        nativeDialogueEventHandler?(event)
        if let dialogue = event.dialogue {
            let side = dialogue.left == true ? "left" : "right"
            statusHandler?("Dialogue · \(side) · event \(event.eventID)")
        }
    }

    @discardableResult
    public func advanceNativeDialogue() -> NativeBattleScriptEvent? {
        let update = nativeDialogueQueueCore.advance()
        if update.activeChanged, let active = update.active {
            presentNativeDialogue(active)
        } else if update.drained {
            originalTalkRenderer?.hide()
            nativeDialogueDidDrainHandler?()
            autosaveIfDialogueIdle()
        }
        return update.active
    }

    private func autosaveIfDialogueIdle() {
        guard activeNativeDialogue == nil, let payload = try? makeBattleSavePayload() else { return }
        autosavePayloadHandler?(payload)
    }

    private func applyCaptureEvents(_ objectIndices: [Int], gameplay: inout NativeBattleGameplayState) {
        guard !objectIndices.isEmpty, let catalog = battleEventCatalog, let targets = triggerTargetCatalog, var context = persistenceContext else { return }
        var combined = NativeBattleEventApplication()
        for index in objectIndices {
            let events = NativeBattleEventCore.captureEvents(
                battleFile: gameplay.battle.file, objectIndex: index, catalog: catalog, targets: targets
            )
            combined.merge(NativeBattleEventCore.applyScriptEvents(events, gameplay: &gameplay, context: &context))
        }
        persistenceContext = context
        absorbNativeEventApplication(combined)
    }

    private func applyDeathEvents(_ result: NativeBattleAttackResult, gameplay: inout NativeBattleGameplayState) {
        guard let catalog = battleEventCatalog, let targets = triggerTargetCatalog, var context = persistenceContext else { return }
        var combined = NativeBattleEventApplication()
        if result.defenderKilled {
            let events = NativeBattleEventCore.deathEvents(
                battleFile: gameplay.battle.file, unitIndex: result.defenderIndex, catalog: catalog, targets: targets
            )
            combined.merge(NativeBattleEventCore.applyScriptEvents(events, gameplay: &gameplay, context: &context))
        }
        if result.attackerKilled {
            let events = NativeBattleEventCore.deathEvents(
                battleFile: gameplay.battle.file, unitIndex: result.attackerIndex, catalog: catalog, targets: targets
            )
            combined.merge(NativeBattleEventCore.applyScriptEvents(events, gameplay: &gameplay, context: &context))
        }
        persistenceContext = context
        absorbNativeEventApplication(combined)
    }

    private func clearFireUnderFireproofUnit(_ unitIndex: Int, gameplay: NativeBattleGameplayState) {
        guard let unit = gameplay.units[unitIndex], gameplay.isFireproof(at: unit.cell), var context = persistenceContext else { return }
        context.fireCells.remove("\(unit.q),\(unit.r)")
        persistenceContext = context
    }

    @discardableResult
    public func fireNativeRoundEvents(round explicitRound: Int? = nil) -> NativeBattleEventApplication {
        guard var gameplay = gameplayState, let catalog = battleEventCatalog, var context = persistenceContext else { return NativeBattleEventApplication() }
        let result = NativeBattleEventCore.applyRoundEvents(
            battleFile: gameplay.battle.file, round: explicitRound ?? gameplay.round, catalog: catalog, gameplay: &gameplay, context: &context
        )
        gameplayState = gameplay
        persistenceContext = context
        absorbNativeEventApplication(result)
        if !result.appliedEvents.isEmpty || !result.newlyQueuedDialogues.isEmpty {
            autosaveIfDialogueIdle()
        }
        return result
    }

    private func syncLivePlayerProfile(after result: NativeBattleAttackResult) {
        guard !result.generalGrowth.isEmpty, let runtime = playerProfileRuntime else { return }
        let snapshot = runtime.snapshot()
        playerProfile = snapshot
        playerProfileDidChangeHandler?(snapshot)
        let leveled = result.generalGrowth.filter { $0.award.rankLeveled || $0.award.nobilityLeveled }
        if let first = leveled.first {
            statusHandler?("General growth · #\(first.commanderID) rank \(first.award.after.rank) nobility \(first.award.after.nobility)")
        }
    }

    private func advanceAIIfReady(nowMilliseconds: Double) {
        guard pendingActionCameraContinuation == nil,
              nowMilliseconds >= aiResumeAtMilliseconds,
              activeUnitMoves.isEmpty,
              damagePresentationQueue.isEmpty,
              var driver = aiPresentationDriver,
              var gameplay = gameplayState,
              !gameplay.ended else { return }
        do {
            if aiNeedsCountryAdvance {
                try driver.advanceAfterCountryEnd(gameplay: &gameplay)
                aiNeedsCountryAdvance = false
            }
            let action = try driver.next(gameplay: &gameplay)

            if !aiFastForward {
                switch action {
                case .move(let move):
                    if queueActionCameraFocus(
                        source: move.from,
                        target: move.to,
                        continuation: .ai(driver: driver, gameplay: gameplay, action: action)
                    ) { return }
                case .attack(let attack):
                    if queueActionCameraFocus(
                        source: attack.beforeAttacker.cell,
                        target: attack.beforeDefender.cell,
                        continuation: .ai(driver: driver, gameplay: gameplay, action: action)
                    ) { return }
                default:
                    break
                }
            }

            gameplayState = gameplay
            switch action {
            case .countryBegan(let owner):
                statusHandler?("AI country \(gameplay.countryCode(owner: owner).uppercased())")
                aiResumeAtMilliseconds = nowMilliseconds + (aiFastForward ? 10 : 80)
            case .move, .attack:
                commitFocusedAIAction(action, driver: driver, gameplay: &gameplay, nowMilliseconds: nowMilliseconds)
                return
            case .countryEnded(let owner):
                if var context = persistenceContext {
                    _ = NativeRoundRuntimeAdapter.settleCountryEconomy(
                        owner: owner,
                        gameplay: gameplay,
                        context: &context,
                        constructions: constructionCatalog,
                        items: itemEffectCatalog,
                        projectionProvider: commanderRoundProjectionProvider
                    )
                    persistenceContext = context
                }
                statusHandler?("AI country complete · \(gameplay.countryCode(owner: owner).uppercased())")
                aiNeedsCountryAdvance = true
                aiResumeAtMilliseconds = nowMilliseconds + (aiFastForward ? 10 : 100)
            case .roundReadyToSettle:
                var playerSettlement: NativePlayerRoundSettlement?
                if var context = persistenceContext {
                    let settlement = NativeRoundRuntimeAdapter.settlePlayerRound(
                        gameplay: &gameplay,
                        context: &context,
                        constructions: constructionCatalog,
                        items: itemEffectCatalog,
                        projectionProvider: commanderRoundProjectionProvider
                    )
                    persistenceContext = context
                    playerSettlement = settlement
                    roundSettlementHandler?(settlement)
                }
                let completed = try driver.completeRoundAfterSettlement(gameplay: &gameplay)
                gameplayState = gameplay
                aiPresentationDriver = nil
                aiNeedsCountryAdvance = false
                aiResumeAtMilliseconds = 0
                aiFastForward = false
                for index in gameplay.unitOrder { refreshUnitNode(index, gameplay: gameplay) }
                removeDeadUnitNodes(gameplay: gameplay)
                refreshInteractionOverlay()
                refreshNativeBattleHUD(gameplay: gameplay)
                if case .roundCompleted(_, let roundAfter) = completed {
                    statusHandler?("Round \(roundAfter) · player")
                }
                _ = evaluateNativeBattleOutcomeIfNeeded()
                if !gameplay.ended, let settlement = playerSettlement {
                    let content = NativeOriginalFormContentCore.roundTurn(
                        gameplay: gameplay, settlement: settlement, commanders: commanderCatalog
                    )
                    presentNativeRoundTurn(content)
                } else if !gameplay.ended {
                    let events = fireNativeRoundEvents(round: gameplay.round)
                    if events.appliedEvents.isEmpty && events.newlyQueuedDialogues.isEmpty { autosaveIfDialogueIdle() }
                }
                return
            case .roundCompleted(_, let roundAfter):
                aiPresentationDriver = nil
                aiNeedsCountryAdvance = false
                aiResumeAtMilliseconds = 0
                aiFastForward = false
                for index in gameplay.unitOrder { refreshUnitNode(index, gameplay: gameplay) }
                removeDeadUnitNodes(gameplay: gameplay)
                refreshInteractionOverlay()
                refreshNativeBattleHUD(gameplay: gameplay)
                statusHandler?("Round \(roundAfter) · player")
                return
            }
            aiPresentationDriver = driver
            refreshInteractionOverlay()
            refreshNativeBattleHUD(gameplay: gameplay)
        } catch {
            pendingActionCameraContinuation = nil
            aiPresentationDriver = nil
            aiNeedsCountryAdvance = false
            aiFastForward = false
            statusHandler?("AI presentation halted · \(error)")
            if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
        }
    }

    private func commitFocusedAIAction(
        _ action: NativeAIPresentationAction,
        driver: NativeAIPresentationDriver,
        gameplay: inout NativeBattleGameplayState,
        nowMilliseconds: Double
    ) {
        gameplayState = gameplay
        switch action {
        case .move(let move):
            applyCaptureEvents(move.capturedObjectIndices, gameplay: &gameplay)
            clearFireUnderFireproofUnit(move.unitIndex, gameplay: gameplay)
            gameplayState = gameplay
            startMovePresentation(
                NativeBattleMoveResult(
                    unitIndex: move.unitIndex,
                    path: move.path,
                    capturedObjectIndices: move.capturedObjectIndices,
                    undoAvailable: false
                ),
                nowMilliseconds: nowMilliseconds,
                fastAI: aiFastForward
            )
            let moveDuration = NativeMovementPresentationCore.durationMilliseconds(path: move.path, fastAI: aiFastForward)
            aiResumeAtMilliseconds = nowMilliseconds + moveDuration + (aiFastForward ? 10 : 20)
        case .attack(let attack):
            applyDeathEvents(attack.result, gameplay: &gameplay)
            gameplayState = gameplay
            let plan = startAttackPresentation(
                beforeAttacker: attack.beforeAttacker,
                beforeDefender: attack.beforeDefender,
                afterAttacker: attack.afterAttacker,
                afterDefender: attack.afterDefender,
                result: attack.result,
                gameplay: gameplay,
                nowMilliseconds: nowMilliseconds,
                fastAI: aiFastForward
            )
            applyBattleAttackSidecars(attack.result)
            let impact = max(plan?.primaryImpactMilliseconds ?? 1, plan?.counterImpactMilliseconds ?? 0)
            aiResumeAtMilliseconds = nowMilliseconds + impact + (aiFastForward ? 10 : 40)
        default:
            return
        }
        aiPresentationDriver = driver
        refreshInteractionOverlay()
        refreshNativeBattleHUD(gameplay: gameplay)
    }

    private func updateActiveAnimations(nowMilliseconds: Double) {
        guard let manifest = animationsManifest, !activeUnitAnimations.isEmpty else { return }
        let indices = Array(activeUnitAnimations.keys)
        for unitIndex in indices {
            guard var playback = activeUnitAnimations[unitIndex] else { continue }
            do {
                let sample = try NativeAnimationSequenceCore.sample(
                    sequence: playback.sequence,
                    manifest: manifest,
                    elapsedMilliseconds: nowMilliseconds - playback.startMilliseconds
                )
                if playback.lastAssetID != sample.assetID || playback.lastFrameIndex != sample.frameIndex {
                    try applyAnimationFrame(
                        unitIndex: unitIndex,
                        animationUnitName: playback.animationUnitName,
                        assetID: sample.assetID,
                        frameIndex: sample.frameIndex
                    )
                    playback.lastAssetID = sample.assetID
                    playback.lastFrameIndex = sample.frameIndex
                    activeUnitAnimations[unitIndex] = playback
                }
                if sample.terminal && sample.completedAttackChain {
                    activeUnitAnimations[unitIndex] = nil
                    if let gameplay = gameplayState {
                        refreshUnitNode(unitIndex, gameplay: gameplay)
                    }
                }
            } catch {
                activeUnitAnimations[unitIndex] = nil
                if let gameplay = gameplayState {
                    refreshUnitNode(unitIndex, gameplay: gameplay)
                }
                statusHandler?("Animation decode fallback · \(error)")
            }
        }
        if activeUnitAnimations.isEmpty {
            if animationFrameCache.values.reduce(0, { $0 + $1.count }) > 768 {
                animationFrameCache.removeAll(keepingCapacity: true)
            }
            if let gameplay = gameplayState {
                removeDeadUnitNodes(gameplay: gameplay)
                refreshInteractionOverlay()
            }
        }
    }

    public override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        let dt = lastSceneUpdateTime.map { max(0, min(0.1, currentTime - $0)) } ?? 0
        lastSceneUpdateTime = currentTime
        if activeTavernObjectIndex != nil || battleModalState != .none || battleResultPresentationPhase != .none || !isOuterCompletionIdle { return }
        updateProgrammaticCamera(dtSeconds: dt)
        let now = animationNowMilliseconds()
        updateMoveAnimations(nowMilliseconds: now)
        updateDamagePresentations(nowMilliseconds: now)
        updateActiveAnimations(nowMilliseconds: now)
        updateReadyAnimations(nowMilliseconds: now)
        updateNativeFirePresentation(nowMilliseconds: now)
        updateNativeBattlefieldOverlays(nowMilliseconds: now)
        advanceAIIfReady(nowMilliseconds: now)
    }

    private func updateReadyAnimations(nowMilliseconds: Double) {
        guard activeUnitAnimations.isEmpty,
              activeUnitMoves.isEmpty,
              damagePresentationQueue.isEmpty,
              NativeCamera.detailInteractionEnabled(cameraState.zoom),
              nowMilliseconds - lastReadyTickMilliseconds >= 41,
              let gameplay = gameplayState,
              let manifest = animationsManifest else {
            return
        }
        lastReadyTickMilliseconds = nowMilliseconds
        for unitIndex in gameplay.unitOrder {
            guard let unit = gameplay.units[unitIndex], !unit.dead else { continue }
            let code = gameplay.countryCode(owner: unit.owner)
            let statType = gameplay.stat(for: unit)?.type
            if unit.embarked && statType != "warship" { continue }
            guard let unitName = NativeUnitVisualResolver.animationUnitName(
                unit: unit,
                countryCode: code,
                manifest: manifest
            ), let animationUnit = manifest.units[unitName] else {
                continue
            }
            let direction = (statType == "warship" || statType == "fort")
                ? (unitFacing[unit.index] ?? "right")
                : "all"
            guard let motion = NativeUnitVisualResolver.readyMotion(
                for: unitName,
                direction: direction,
                manifest: manifest
            ), let asset = manifest.assets[motion.asset] else {
                continue
            }
            let duration = max(1, NativeAnimationTiming.rawDurationMilliseconds(asset))
            let phase = Double((unit.index * 97) % max(1, Int(duration)))
            let elapsed = (nowMilliseconds + phase).truncatingRemainder(dividingBy: duration)
            let frameIndex = NativeAnimationTiming.frame(at: elapsed, asset: asset)
            if let previous = readyFrameState[unit.index],
               previous.assetID == motion.asset,
               previous.frameIndex == frameIndex {
                continue
            }
            do {
                try applyAnimationFrame(
                    unitIndex: unit.index,
                    animationUnitName: unitName,
                    assetID: motion.asset,
                    frameIndex: frameIndex
                )
                readyFrameState[unit.index] = (motion.asset, frameIndex)
            } catch {
                // READY animation is presentation-only; retain the last valid frame on decode failure.
                _ = animationUnit
            }
        }
    }

    private func applyUnitLOD() {
        let tacticalVisible = NativePresentationLODCore.tacticalVisible(cameraZoom: cameraState.zoom)
        let tacticalScale = NativePresentationLODCore.tacticalContainerScale(cameraZoom: cameraState.zoom)
        let strategicScale = NativePresentationLODCore.strategicContainerScale(cameraZoom: cameraState.zoom)

        for node in tacticalUnitContainers.values {
            node.isHidden = !tacticalVisible
            node.setScale(tacticalScale)
        }
        for node in strategicUnitContainers.values {
            node.isHidden = tacticalVisible
            node.setScale(strategicScale)
        }
    }

    private func bileResource(_ name: String, store: NativeResourceStore) throws -> CompactBILE {
        if let cached = bileCache[name] { return cached }
        let value = try store.bile(resource: name)
        bileCache[name] = value
        return value
    }

    private func atlasResource(_ name: String, store: NativeResourceStore) throws -> CGImage {
        if let cached = atlasCache[name] { return cached }
        let data = try Data(contentsOf: store.bileAtlasURL(resource: name))
        guard let image = UIImage(data: data)?.cgImage else {
            throw CocoaError(.fileReadCorruptFile)
        }
        atlasCache[name] = image
        return image
    }

    public func setCamera(_ next: NativeCameraState) {
        programmaticCameraMotion = nil
        cameraState = next
        applyCamera()
        if !NativeCamera.detailInteractionEnabled(next.zoom), gameplayState?.selectedUnitIndex != nil {
            gameplayState?.selectUnit(nil)
            refreshInteractionOverlay()
        }
    }

    @discardableResult
    private func startProgrammaticCameraMove(target: NativePoint, targetZoom: Double? = nil) -> Bool {
        let settings = NativeOptionsCore.settings(from: playerProfile)
        let started = NativeCamera.startProgrammaticMove(
            cameraState, target: target, gameSpeed: settings.gameSpeed, targetZoom: targetZoom
        )
        cameraState = started.camera
        programmaticCameraMotion = started.motion.active ? started.motion : nil
        applyCamera()
        return started.motion.active
    }

    private func focusProgrammatically(on cell: HexCell) {
        let rect = NativeHexGeometry.cellRect(cell)
        if cameraState.zoom >= NativeCamera.detailZoom, NativeCamera.focusRectVisible(cameraState, rect: rect) { return }
        let targetZoom = cameraState.zoom < NativeCamera.detailZoom ? 1.0 : cameraState.zoom
        startProgrammaticCameraMove(target: NativeHexGeometry.cellCenter(cell), targetZoom: targetZoom)
    }

    private func updateProgrammaticCamera(dtSeconds: Double) {
        guard let motion = programmaticCameraMotion else { return }
        let step = NativeCamera.stepProgrammaticMove(cameraState, motion: motion, dtSeconds: dtSeconds)
        cameraState = step.camera
        programmaticCameraMotion = step.active ? step.motion : nil
        applyCamera()
        if !NativeCamera.detailInteractionEnabled(cameraState.zoom), gameplayState?.selectedUnitIndex != nil {
            gameplayState?.selectUnit(nil)
            refreshInteractionOverlay()
        }
        if !step.active { resumeActionAfterCameraFocus() }
    }

    private func queueActionCameraFocus(
        source: HexCell,
        target: HexCell,
        continuation: PendingActionCameraContinuation
    ) -> Bool {
        guard pendingActionCameraContinuation == nil else { return true }
        let plan = NativeActionCameraFocusCore.plan(camera: cameraState, source: source, target: target)
        guard plan.required else { return false }
        pendingActionCameraContinuation = continuation
        let moving = startProgrammaticCameraMove(target: plan.target, targetZoom: plan.targetZoom)
        if !moving {
            pendingActionCameraContinuation = nil
            return false
        }
        if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
        return true
    }

    private func resumeActionAfterCameraFocus() {
        guard let continuation = pendingActionCameraContinuation else { return }
        pendingActionCameraContinuation = nil
        switch continuation {
        case .playerMove(let unitIndex, let target):
            resolvePlayerMove(unitIndex: unitIndex, target: target)
        case .playerAttack(let attackerIndex, let defenderIndex):
            resolvePlayerAttack(attackerIndex: attackerIndex, defenderIndex: defenderIndex)
        case .ai(let driver, var gameplay, let action):
            commitFocusedAIAction(action, driver: driver, gameplay: &gameplay, nowMilliseconds: animationNowMilliseconds())
        }
    }

    private func applyCamera() {
        worldLayer.setScale(cameraState.zoom)
        worldLayer.position = CGPoint(
            x: NativeCamera.viewCenter.x - cameraState.x * cameraState.zoom,
            y: (EW4LogicalSpace.height - NativeCamera.viewCenter.y) + cameraState.y * cameraState.zoom
        )
        applyUnitLOD()
    }

    private func refreshInteractionOverlay() {
        interactionLayer.removeAllChildren()
        guard let gameplay = gameplayState,
              NativeCamera.detailInteractionEnabled(cameraState.zoom) else {
            return
        }

        for cell in gameplay.reachable.keys {
            let p = NativeHexGeometry.cellCenter(cell)
            let dot = SKShapeNode(circleOfRadius: 3)
            dot.fillColor = UIColor(white: 1, alpha: 0.82)
            dot.strokeColor = UIColor(white: 0.12, alpha: 0.9)
            dot.lineWidth = 0.8
            dot.position = worldScenePoint(p)
            dot.zPosition = 60
            interactionLayer.addChild(dot)
        }

        guard let selectedIndex = gameplay.selectedUnitIndex,
              let selected = gameplay.units[selectedIndex],
              !selected.dead else {
            return
        }

        let selectedRing = SKShapeNode(circleOfRadius: 14)
        selectedRing.fillColor = .clear
        selectedRing.strokeColor = UIColor(red: 1.0, green: 0.86, blue: 0.32, alpha: 0.95)
        selectedRing.lineWidth = 1.5
        selectedRing.position = worldScenePoint(NativeHexGeometry.cellCenter(selected.cell))
        selectedRing.zPosition = 59
        interactionLayer.addChild(selectedRing)

        for unit in gameplay.units.values where gameplay.canAttack(selected, unit) {
            let ring = SKShapeNode(circleOfRadius: 13)
            ring.fillColor = .clear
            ring.strokeColor = UIColor(red: 0.88, green: 0.15, blue: 0.12, alpha: 0.88)
            ring.lineWidth = 1.4
            ring.position = worldScenePoint(NativeHexGeometry.cellCenter(unit.cell))
            ring.zPosition = 58
            interactionLayer.addChild(ring)
        }
    }

    private func handleNativeTap(_ screen: NativePoint) {
        guard activeNativeDialogue == nil, !stageIntroActive, battleModalState == .none, battleResultPresentationPhase == .none, isOuterCompletionIdle else { return }
        if handleNativeHUDTap(screen) { return }
        guard aiPresentationDriver == nil,
              !presentationBusy,
              activeUnitAnimations.isEmpty,
              gameplayState?.phase == .player else {
            statusHandler?("Action presentation in progress")
            return
        }
        guard NativeCamera.detailInteractionEnabled(cameraState.zoom), var gameplay = gameplayState else {
            return
        }
        let world = NativeCamera.screenToWorld(cameraState, point: screen)
        let cell = NativeHexGeometry.worldToCell(x: world.x, y: world.y)
        advanceTutorialArea(cell)

        if let selectedIndex = gameplay.selectedUnitIndex,
           let selected = gameplay.units[selectedIndex],
           let target = gameplay.unit(at: cell),
           target.index != selected.index,
           gameplay.canAttack(selected, target) {
            if queueActionCameraFocus(
                source: selected.cell,
                target: target.cell,
                continuation: .playerAttack(attackerIndex: selected.index, defenderIndex: target.index)
            ) { return }
            resolvePlayerAttack(attackerIndex: selected.index, defenderIndex: target.index)
            return
        }

        if gameplay.reachable[cell] != nil,
           let selectedIndex = gameplay.selectedUnitIndex,
           let selected = gameplay.units[selectedIndex] {
            if queueActionCameraFocus(
                source: selected.cell,
                target: cell,
                continuation: .playerMove(unitIndex: selected.index, target: cell)
            ) { return }
            resolvePlayerMove(unitIndex: selected.index, target: cell)
            return
        }

        if let tapped = gameplay.unit(at: cell),
           gameplay.selectedUnitIndex == tapped.index,
           let object = gameplay.objects.values.first(where: { $0.cell == cell }) {
            selectFacility(object.index, gameplay: &gameplay)
            return
        }

        if let tapped = gameplay.unit(at: cell) {
            selectedFacilityObjectIndex = nil
            selectedEmptyCell = nil
            gameplay.selectUnit(tapped.index)
            gameplayState = gameplay
            refreshInteractionOverlay(); refreshNativeBattleHUD(gameplay: gameplay)
            statusHandler?("Selected · \(tapped.armyName) · HP \(tapped.hp)/\(tapped.maxHP)")
            return
        }

        if let object = gameplay.objects.values.first(where: { $0.cell == cell }) {
            selectFacility(object.index, gameplay: &gameplay)
            return
        }

        selectedFacilityObjectIndex = nil
        selectedEmptyCell = cell
        gameplay.selectUnit(nil)
        gameplayState = gameplay
        refreshInteractionOverlay(); refreshNativeBattleHUD(gameplay: gameplay)
    }

    private func resolvePlayerAttack(attackerIndex: Int, defenderIndex: Int) {
        guard var gameplay = gameplayState,
              gameplay.phase == .player,
              gameplay.selectedUnitIndex == attackerIndex,
              let selected = gameplay.units[attackerIndex],
              let target = gameplay.units[defenderIndex],
              !selected.dead, !target.dead,
              gameplay.canAttack(selected, target) else {
            statusHandler?("Attack blocked · state changed during camera focus")
            if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
            return
        }
        do {
            let preAttackAttacker = selected
            let preAttackDefender = target
            let result = try gameplay.attackSelected(target: target.index)
            applyDeathEvents(result, gameplay: &gameplay)
            let postAttackAttacker = gameplay.units[result.attackerIndex] ?? preAttackAttacker
            let postAttackDefender = gameplay.units[result.defenderIndex] ?? preAttackDefender
            gameplayState = gameplay
            applyBattleAttackSidecars(result)
            _ = startAttackPresentation(
                beforeAttacker: preAttackAttacker,
                beforeDefender: preAttackDefender,
                afterAttacker: postAttackAttacker,
                afterDefender: postAttackDefender,
                result: result,
                gameplay: gameplay,
                nowMilliseconds: animationNowMilliseconds()
            )
            refreshInteractionOverlay()
            refreshNativeBattleHUD(gameplay: gameplay)
            let counterText = result.counterDamage.map { " · counter \($0)" } ?? ""
            let extraText = result.cavalryExtraAction ? " · extra action" : ""
            statusHandler?("Damage \(result.damage)\(counterText)\(extraText)")
            advanceTutorialAction()
        } catch {
            statusHandler?("Attack blocked · \(error)")
            if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
        }
    }

    private func resolvePlayerMove(unitIndex: Int, target: HexCell) {
        guard var gameplay = gameplayState,
              gameplay.phase == .player,
              gameplay.selectedUnitIndex == unitIndex,
              gameplay.units[unitIndex] != nil,
              gameplay.reachable[target] != nil else {
            statusHandler?("Move blocked · state changed during camera focus")
            if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
            return
        }
        do {
            let result = try gameplay.moveSelected(to: target)
            applyCaptureEvents(result.capturedObjectIndices, gameplay: &gameplay)
            clearFireUnderFireproofUnit(result.unitIndex, gameplay: gameplay)
            gameplayState = gameplay
            if result.path.count > 1 {
                startMovePresentation(result, nowMilliseconds: animationNowMilliseconds(), fastAI: false)
            } else {
                if let moved = gameplay.units[result.unitIndex] { updateUnitNodePosition(moved) }
                if let store = resourceStore {
                    for index in result.capturedObjectIndices {
                        if let object = gameplay.objects[index] {
                            try? renderObject(object, gameplay: gameplay, sprites: spriteManifest, store: store)
                        }
                    }
                }
            }
            refreshInteractionOverlay()
            refreshNativeBattleHUD(gameplay: gameplay)
            if result.path.count <= 1 && !result.capturedObjectIndices.isEmpty { _ = evaluateNativeBattleOutcomeIfNeeded() }
            statusHandler?(result.capturedObjectIndices.isEmpty ? "Move · \(result.path.count) hexes" : "Facility captured")
            advanceTutorialAction()
        } catch {
            statusHandler?("Move blocked · \(error)")
            if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
        }
    }

    private func openNativeTavern(objectIndex: Int) {
        guard let renderer = originalTavernRenderer, let gameplay = gameplayState, let context = persistenceContext,
              let record = NativeBattleTavernCore.record(taverns: context.taverns, objectIndex: objectIndex) else { return }
        activeTavernObjectIndex = objectIndex
        let resources = context.countryResources[gameplay.playerOwner] ?? context.resources
        renderer.show(record: record, round: gameplay.round, resources: resources, profile: playerProfileRuntime?.snapshot() ?? playerProfile, commanders: commanderCatalog)
        refreshNativeBattleHUD(gameplay: gameplay)
        statusHandler?("Native Tavern")
    }

    private func closeNativeTavern() {
        originalTavernRenderer?.hide(); activeTavernObjectIndex = nil
        if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
        statusHandler?("Native battle")
    }

    private func handleNativeTavernTap(_ point: NativePoint) {
        guard let objectIndex = activeTavernObjectIndex, let renderer = originalTavernRenderer, var gameplay = gameplayState, var context = persistenceContext else { return }
        switch renderer.action(at: point) {
        case .close:
            closeNativeTavern()
        case .info(let index):
            if let record = NativeBattleTavernCore.record(taverns: context.taverns, objectIndex: objectIndex) {
                renderer.showCandidateInfo(index: index, record: record, commanders: commanderCatalog)
            }
        case .recruit(let index):
            var profile = playerProfileRuntime?.snapshot() ?? playerProfile
            var resources = context.countryResources[gameplay.playerOwner] ?? context.resources
            let result = NativeBattleTavernCore.recruit(taverns: &context.taverns, objectIndex: objectIndex, candidateIndex: index, round: gameplay.round, resources: &resources, profile: &profile, commanders: commanderCatalog)
            if result.ok {
                context.resources = resources
                context.countryResources[gameplay.playerOwner] = resources
                persistenceContext = context
                playerProfileRuntime?.replace(with: profile); playerProfile = profile; playerProfileDidChangeHandler?(profile)
                gameplayState = gameplay
                refreshNativeBattleHUD(gameplay: gameplay)
                autosaveIfDialogueIdle()
                if let record = NativeBattleTavernCore.record(taverns: context.taverns, objectIndex: objectIndex) {
                    renderer.show(record: record, round: gameplay.round, resources: resources, profile: profile, commanders: commanderCatalog)
                }
                let name = result.commanderID.flatMap { commanderCatalog[$0]?.name } ?? "将领"
                statusHandler?("\(name) 已加入指挥部")
            } else {
                switch result.availability {
                case .owned: statusHandler?("该将领已经在指挥部")
                case .roundLocked: statusHandler?("尚未到可招募回合")
                case .resources: statusHandler?("资源不足，无法招募")
                default: statusHandler?("当前候选不可招募")
                }
            }
        case .none:
            break
        }
    }

    private func marketBusinessContext(objectIndex: Int, gameplay: NativeBattleGameplayState) -> (business: Int, commanderName: String?) {
        guard let object = gameplay.objects[objectIndex],
              let unit = gameplay.unit(at: object.cell),
              unit.owner == gameplay.playerOwner,
              let commanderID = unit.commanderID else { return (0, nil) }
        let business = gameplay.effectiveCommander(for: unit)?.business ?? commanderCatalog[commanderID]?.business ?? 0
        return (NativeBattleCommerceCore.businessStars(business), commanderCatalog[commanderID]?.name)
    }

    private func openNativeMarket(objectIndex: Int) {
        guard let renderer = originalMarketRenderer,
              let gameplay = gameplayState,
              let object = gameplay.objects[objectIndex],
              object.owner == gameplay.playerOwner,
              object.extra == 1,
              let context = persistenceContext else { return }
        activeMarketObjectIndex = objectIndex
        let info = marketBusinessContext(objectIndex: objectIndex, gameplay: gameplay)
        let resources = context.countryResources[gameplay.playerOwner] ?? context.resources
        renderer.show(business: info.business, resources: resources, commanderName: info.commanderName)
        refreshNativeBattleHUD(gameplay: gameplay)
        statusHandler?("Native Market · 商业 \(info.business)/5")
    }

    private func closeNativeMarket() {
        originalMarketRenderer?.hide()
        activeMarketObjectIndex = nil
        if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
        statusHandler?("Native battle")
    }

    private func handleNativeMarketTap(_ point: NativePoint) {
        guard let objectIndex = activeMarketObjectIndex,
              let renderer = originalMarketRenderer,
              let gameplay = gameplayState,
              var context = persistenceContext else { return }
        let info = marketBusinessContext(objectIndex: objectIndex, gameplay: gameplay)
        switch renderer.action(at: point) {
        case .close:
            advanceTutorialUI("winbtn_close")
            closeNativeMarket()
        case .buy(let index):
            guard let quote = NativeBattleCommerceCore.buyQuote(index: index, business: info.business) else { return }
            var resources = context.countryResources[gameplay.playerOwner] ?? context.resources
            guard NativeBattleCommerceCore.apply(quote, to: &resources) else { statusHandler?("资源不足，无法交易"); return }
            context.resources = resources
            context.countryResources[gameplay.playerOwner] = resources
            persistenceContext = context
            autosaveIfDialogueIdle()
            advanceTutorialUI("btn_buy_\(index + 1)")
            renderer.show(business: info.business, resources: resources, commanderName: info.commanderName)
            statusHandler?("贸易完成 · -\(quote.pay) \(quote.payResource.rawValue) +\(quote.receive) \(quote.receiveResource.rawValue)")
        case .sell(let index):
            guard let quote = NativeBattleCommerceCore.sellQuote(index: index, business: info.business) else { return }
            var resources = context.countryResources[gameplay.playerOwner] ?? context.resources
            guard NativeBattleCommerceCore.apply(quote, to: &resources) else { statusHandler?("资源不足，无法交易"); return }
            context.resources = resources
            context.countryResources[gameplay.playerOwner] = resources
            persistenceContext = context
            autosaveIfDialogueIdle()
            advanceTutorialUI("btn_sell_\(index + 1)")
            renderer.show(business: info.business, resources: resources, commanderName: info.commanderName)
            statusHandler?("贸易完成 · -\(quote.pay) \(quote.payResource.rawValue) +\(quote.receive) \(quote.receiveResource.rawValue)")
        case .none:
            break
        }
    }

    private func openNativeBattleShop(objectIndex: Int) {
        guard let renderer = originalBattleShopRenderer,
              let gameplay = gameplayState,
              let object = gameplay.objects[objectIndex],
              object.owner == gameplay.playerOwner, object.extra == 2,
              let context = persistenceContext,
              let record = NativeBattleShopCore.record(itemStores: context.itemStores, objectIndex: objectIndex) else { return }
        activeShopObjectIndex = objectIndex
        let info = marketBusinessContext(objectIndex: objectIndex, gameplay: gameplay)
        renderer.show(record: record, profile: playerProfileRuntime?.snapshot() ?? playerProfile, items: itemEffectCatalog, business: info.business, buyerName: info.commanderName)
        refreshNativeBattleHUD(gameplay: gameplay)
        statusHandler?("Native Shop · 商业 \(info.business)/5")
    }

    private func closeNativeBattleShop() {
        originalBattleShopRenderer?.hide()
        activeShopObjectIndex = nil
        if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
        statusHandler?("Native battle")
    }

    private func handleNativeBattleShopTap(_ point: NativePoint) {
        guard let objectIndex = activeShopObjectIndex,
              let renderer = originalBattleShopRenderer,
              let gameplay = gameplayState,
              var context = persistenceContext else { return }
        let info = marketBusinessContext(objectIndex: objectIndex, gameplay: gameplay)
        var profile = playerProfileRuntime?.snapshot() ?? playerProfile
        switch renderer.action(at: point) {
        case .close:
            closeNativeBattleShop()
        case .buy(let index):
            guard let itemID = NativeBattleShopCore.buy(itemStores: &context.itemStores, objectIndex: objectIndex, sellerIndex: index, profile: &profile, items: itemEffectCatalog) else {
                statusHandler?("物品栏已满或当前物品不可购买")
                return
            }
            persistenceContext = context
            playerProfileRuntime?.replace(with: profile)
            playerProfile = profile
            playerProfileDidChangeHandler?(profile)
            autosaveIfDialogueIdle()
            if let record = NativeBattleShopCore.record(itemStores: context.itemStores, objectIndex: objectIndex) {
                renderer.show(record: record, profile: profile, items: itemEffectCatalog, business: info.business, buyerName: info.commanderName)
            }
            let item = NativeBattleShopCore.item(itemEffectCatalog, id: itemID)
            statusHandler?("\(item?.name ?? "物品") 已购入 · 勋章 \(NativeBattleShopCore.buyPrice(item, business: info.business))")
        case .sell(let index):
            guard let itemID = NativeBattleShopCore.sell(inventoryIndex: index, profile: &profile) else { return }
            playerProfileRuntime?.replace(with: profile)
            playerProfile = profile
            playerProfileDidChangeHandler?(profile)
            autosaveIfDialogueIdle()
            if let record = NativeBattleShopCore.record(itemStores: context.itemStores, objectIndex: objectIndex) {
                renderer.show(record: record, profile: profile, items: itemEffectCatalog, business: info.business, buyerName: info.commanderName)
            }
            let item = NativeBattleShopCore.item(itemEffectCatalog, id: itemID)
            statusHandler?("\(item?.name ?? "物品") 已出售 · 勋章 \(NativeBattleShopCore.sellPrice(item, business: info.business))")
        case .none:
            break
        }
    }

    private func unitInfoCost(_ unit: NativeBattleUnitState) -> (money: Int, industry: Int) {
        if let card = recruitCardCatalog["\(unit.armyName)|\(unit.grade)"] {
            return (card.price, card.industry)
        }
        if let card = buildCardCatalog.values.first(where: { $0.army == unit.armyName && $0.grade == unit.grade }) {
            return (card.price, card.industry)
        }
        return (0, 0)
    }

    private func commanderDisplayName(_ raw: Commander) -> String {
        stringCatalog["name_\(raw.name)"] ?? raw.name
    }

    private func openNativeBattleUnitInfo(unitIndex: Int) {
        guard let renderer = originalBattleUnitInfoRenderer,
              let gameplay = gameplayState,
              let unit = gameplay.units[unitIndex],
              let stat = gameplay.stat(for: unit) else { return }
        let effective = gameplay.effectiveCommander(for: unit)
        let raw = unit.commanderID.flatMap { commanderCatalog[$0] }
        let cost = unitInfoCost(unit)
        let model = NativeBattleUnitInfoCore.model(
            unit: unit,
            stat: stat,
            effectiveCommander: effective,
            movement: gameplay.effectiveMovement(for: unit),
            moneyCost: cost.money,
            industryCost: cost.industry,
            isPlayer: unit.owner == gameplay.playerOwner,
            commanderName: raw.map(commanderDisplayName),
            strings: stringCatalog
        )
        activeUnitInfoUnitIndex = unitIndex
        renderer.show(model)
        refreshNativeBattleHUD(gameplay: gameplay)
        statusHandler?("\(model.displayName) · HP \(model.hp)/\(model.maxHP) · 攻 \(model.attackMin)-\(model.attackMax)")
    }

    private func closeNativeBattleUnitInfo() {
        originalBattleUnitInfoRenderer?.hide()
        activeUnitInfoUnitIndex = nil
        if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
        statusHandler?("Native battle")
    }

    private func handleNativeBattleUnitInfoTap(_ point: NativePoint) {
        guard let unitIndex = activeUnitInfoUnitIndex,
              let renderer = originalBattleUnitInfoRenderer else { return }
        switch renderer.action(at: point) {
        case .close:
            closeNativeBattleUnitInfo()
        case .generalInfo:
            openNativeBattleGeneralInfo(unitIndex: unitIndex)
        case .none:
            break
        }
    }

    private func openNativeBattleGeneralInfo(unitIndex: Int) {
        guard let renderer = originalBattleGeneralInfoRenderer,
              let gameplay = gameplayState,
              let unit = gameplay.units[unitIndex],
              let commanderID = unit.commanderID,
              let raw = commanderCatalog[commanderID],
              let effective = gameplay.effectiveCommander(for: unit) else { return }
        activeGeneralInfoUnitIndex = unitIndex
        renderer.show(raw: raw, effective: effective)
        refreshNativeBattleHUD(gameplay: gameplay)
        statusHandler?("\(commanderDisplayName(raw)) · 将领信息")
    }

    private func closeNativeBattleGeneralInfo() {
        originalBattleGeneralInfoRenderer?.hide()
        activeGeneralInfoUnitIndex = nil
        if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
        statusHandler?("Native battle")
    }

    private func handleNativeBattleGeneralInfoTap(_ point: NativePoint) {
        guard let renderer = originalBattleGeneralInfoRenderer else { return }
        if case .close = renderer.action(at: point) { closeNativeBattleGeneralInfo() }
    }

    private func battlePlayerResources(gameplay: NativeBattleGameplayState, context: NativeBattlePersistenceContext) -> CountryResources {
        context.countryResources[gameplay.playerOwner] ?? context.resources
    }

    private func openNativeActionResource(_ kind: NativeActionResourceKind, gameplay: NativeBattleGameplayState) {
        guard let renderer = originalActionResourceRenderer, let context = persistenceContext else { return }
        let resources = battlePlayerResources(gameplay: gameplay, context: context)
        switch kind {
        case .upgrade(let objectIndex):
            guard let object = gameplay.objects[objectIndex] else { return }
            let occupant = gameplay.unit(at: object.cell)
            let architecture = occupant.flatMap { gameplay.effectiveCommander(for: $0) }?.skillIDs.contains(30) == true
            guard let cost = NativeBattleConstructionCore.upgradeCost(type: object.constructionType, architecture: architecture) else { return }
            renderer.show(kind: kind, title: "升级建筑", money: cost.money, secondary: cost.industry, secondaryKind: "industry", detail: "等级 \(object.level) → \(object.level + 1)", affordable: resources.money >= cost.money && resources.industry >= cost.industry)
        case .training(let unitIndex):
            guard let unit = gameplay.units[unitIndex], let stat = gameplay.stat(for: unit) else { return }
            let state = NativeTrainingUnitState(trainingLevel: unit.trainingLevel, trainingExp: unit.trainingExp, hp: unit.hp, maxHP: unit.maxHP, dead: unit.dead, commanderID: unit.commanderID)
            guard let cost = NativeTrainingParityCore.manualCost(unit: state, consumption: stat.consumption) else { return }
            renderer.show(kind: kind, title: "训练部队", money: cost.money, secondary: cost.food, secondaryKind: "food", detail: "训练 \(unit.trainingLevel) → \(unit.trainingLevel + 1)", affordable: NativeTrainingParityCore.canAfford(resources: resources, cost: cost))
        case .embark:
            guard let card = buildCardCatalog["Troopship"] else { return }
            renderer.show(kind: kind, title: "建造运输船", money: card.price, secondary: card.industry, secondaryKind: "industry", detail: "部队进入海运状态", affordable: resources.money >= card.price && resources.industry >= card.industry)
        }
        refreshNativeBattleHUD(gameplay: gameplay)
    }

    private func closeNativeActionResource() {
        originalActionResourceRenderer?.hide()
        if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
    }

    private func handleNativeActionResourceTap(_ point: NativePoint) {
        guard let renderer = originalActionResourceRenderer, let kind = renderer.kind, var gameplay = gameplayState, var context = persistenceContext else { return }
        switch renderer.action(at: point) {
        case .close:
            closeNativeActionResource()
        case .confirm:
            var resources = battlePlayerResources(gameplay: gameplay, context: context)
            var success = false
            switch kind {
            case .upgrade(let objectIndex):
                if let cost = gameplay.upgradeConstruction(objectIndex, resources: &resources), let object = gameplay.objects[objectIndex] {
                    if let store = resourceStore { try? renderObject(object, gameplay: gameplay, sprites: spriteManifest, store: store) }
                    statusHandler?("建筑升级完成　金币-\(cost.money) 工业-\(cost.industry)")
                    success = true
                }
            case .training(let unitIndex):
                let result = gameplay.manualTrain(unitIndex, resources: &resources)
                if result.ok {
                    if let unit = gameplay.units[unitIndex] { updateUnitNodePosition(unit) }
                    statusHandler?("训练提升至 \(result.after ?? 0) 级　金币-\(result.moneyCost) 粮食-\(result.foodCost)")
                    success = true
                }
            case .embark(let unitIndex):
                if let cost = gameplay.embark(unitIndex, resources: &resources, buildCards: buildCardCatalog) {
                    refreshUnitNode(unitIndex, gameplay: gameplay)
                    statusHandler?("运输船准备完成　金币-\(cost.money)")
                    success = true
                }
            }
            guard success else { statusHandler?("资源不足或当前操作不可用"); return }
            context.resources = resources
            context.countryResources[gameplay.playerOwner] = resources
            gameplayState = gameplay
            persistenceContext = context
            advanceTutorialUI("btn_done")
            advanceTutorialAction()
            autosaveIfDialogueIdle()
            closeNativeActionResource()
            refreshInteractionOverlay()
        case .none:
            break
        }
    }

    private func openNativeRecruitUnit(objectIndex: Int) {
        guard let renderer = originalRecruitUnitRenderer, let gameplay = gameplayState, let object = gameplay.objects[objectIndex], object.owner == gameplay.playerOwner, let context = persistenceContext else { return }
        let definitions = NativeBattleConstructionCore.recruitDefinitions(object: object, constructions: constructionCatalog).filter {
            NativeBattleRecruitCore.initialTrainingLevel(name: $0.name, mode: gameplay.mode, campaignTech: context.campaignTech) != nil
        }
        guard !definitions.isEmpty else { statusHandler?("当前战区科技尚未解锁可征募兵种"); return }
        activeRecruitObjectIndex = objectIndex
        renderer.show(definitions: definitions, cards: recruitCardCatalog, resources: battlePlayerResources(gameplay: gameplay, context: context), countryCode: gameplay.countryCode(owner: gameplay.playerOwner))
        refreshNativeBattleHUD(gameplay: gameplay)
        statusHandler?("征募部队")
    }

    private func closeNativeRecruitUnit() {
        originalRecruitUnitRenderer?.hide(); activeRecruitObjectIndex = nil
        if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
    }

    private func handleNativeRecruitUnitTap(_ point: NativePoint) {
        guard let objectIndex = activeRecruitObjectIndex, let renderer = originalRecruitUnitRenderer, var gameplay = gameplayState, var context = persistenceContext else { return }
        switch renderer.action(at: point) {
        case .close:
            advanceTutorialUI("winbtn_close"); closeNativeRecruitUnit()
        case .select(let row):
            advanceTutorialUI("lbox_unit", row: row); renderer.select(row: row)
        case .confirm:
            guard let selected = renderer.selectedRecruit(), let training = NativeBattleRecruitCore.initialTrainingLevel(name: selected.0.name, mode: gameplay.mode, campaignTech: context.campaignTech) else { return }
            var resources = battlePlayerResources(gameplay: gameplay, context: context)
            guard let index = gameplay.recruit(at: objectIndex, recruit: selected.0, grade: selected.0.grade, card: selected.1, trainingLevel: training, resources: &resources) else { statusHandler?("资源不足、设施被占用或征募数据无效"); return }
            context.resources = resources; context.countryResources[gameplay.playerOwner] = resources
            gameplayState = gameplay; persistenceContext = context
            refreshUnitNode(index, gameplay: gameplay)
            advanceTutorialUI("winbtn_ok"); advanceTutorialAction(); autosaveIfDialogueIdle()
            closeNativeRecruitUnit(); refreshInteractionOverlay()
            statusHandler?("\(selected.0.name) \(selected.0.grade + 1)编 已征募")
        case .none: break
        }
    }

    private func openNativeUseItem(unitIndex: Int) {
        guard let renderer = originalUseItemRenderer, let gameplay = gameplayState, let unit = gameplay.units[unitIndex], unit.owner == gameplay.playerOwner, !unit.dead, !unit.attacked else { return }
        activeUseItemUnitIndex = unitIndex
        renderer.show(catalog: itemEffectCatalog, unit: unit, round: gameplay.round)
        refreshNativeBattleHUD(gameplay: gameplay)
        statusHandler?("使用物品")
    }

    private func closeNativeUseItem() {
        originalUseItemRenderer?.hide(); activeUseItemUnitIndex = nil
        if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
    }

    private func handleNativeUseItemTap(_ point: NativePoint) {
        guard let unitIndex = activeUseItemUnitIndex, let renderer = originalUseItemRenderer, var gameplay = gameplayState else { return }
        switch renderer.action(at: point) {
        case .close:
            advanceTutorialUI("winbtn_close"); closeNativeUseItem()
        case .select(let row):
            advanceTutorialUI("lbox_item", row: row); renderer.select(row: row)
        case .confirm:
            guard let item = renderer.selectedItem(), gameplay.useBattleConsumable(item, on: unitIndex) else { statusHandler?("当前状态无法使用该物品"); return }
            gameplayState = gameplay
            refreshUnitNode(unitIndex, gameplay: gameplay)
            // P55 preserves the locked modification: IDs 11...15 are unlimited and never removed from inventory.
            advanceTutorialUI("winbtn_ok"); advanceTutorialAction(); autosaveIfDialogueIdle()
            closeNativeUseItem(); refreshInteractionOverlay()
            statusHandler?("\(item.name) 已使用")
        case .none: break
        }
    }

    private func syncInstallationSidecar(_ gameplay: NativeBattleGameplayState, context: inout NativeBattlePersistenceContext) {
        context.installations = gameplay.installations.map { value in
            ["q": .int(value.q), "r": .int(value.r), "type": .string(value.type), "owner": .int(value.owner)]
        }
    }

    private func openNativeDefenseInstallation(unitIndex: Int) {
        guard let renderer = originalDefenseRenderer, let gameplay = gameplayState, gameplay.canBuildInstallation(unitIndex), let context = persistenceContext else { return }
        let choices = NativeBattleDefenseCore.installationChoices(cards: buildCardCatalog)
        guard !choices.isEmpty else { return }
        activeDefenseUnitIndex = unitIndex
        renderer.show(kind: .installation, choices: choices, resources: battlePlayerResources(gameplay: gameplay, context: context))
        refreshNativeBattleHUD(gameplay: gameplay)
        statusHandler?("修筑工事")
    }

    private func openNativeDefenseFortress(cell: HexCell) {
        guard let renderer = originalDefenseRenderer, let gameplay = gameplayState, let context = persistenceContext, gameplay.canBuildFortress(at: cell, ownership: context.ownership) else { return }
        let choices = NativeBattleDefenseCore.fortressChoices(cards: buildCardCatalog, coastal: gameplay.hasAdjacentSea(cell)).filter {
            guard let name = $0.armyName else { return false }
            return NativeBattleRecruitCore.initialTrainingLevel(name: name, mode: gameplay.mode, campaignTech: context.campaignTech) != nil
        }
        guard !choices.isEmpty else { return }
        activeDefenseUnitIndex = -1
        renderer.show(kind: .fortress, choices: choices, resources: battlePlayerResources(gameplay: gameplay, context: context))
        refreshNativeBattleHUD(gameplay: gameplay)
        statusHandler?("建造要塞")
    }

    private func closeNativeDefense() {
        originalDefenseRenderer?.hide(); activeDefenseUnitIndex = nil
        if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
    }

    private func handleNativeDefenseTap(_ point: NativePoint) {
        guard let renderer = originalDefenseRenderer, var gameplay = gameplayState, var context = persistenceContext else { return }
        switch renderer.action(at: point) {
        case .close:
            advanceTutorialUI("winbtn_close"); closeNativeDefense()
        case .select(let row):
            advanceTutorialUI("lbox_defense", row: row); renderer.select(row: row)
        case .confirm:
            guard let choice = renderer.selectedChoice() else { return }
            var resources = battlePlayerResources(gameplay: gameplay, context: context)
            var success = false
            switch renderer.kind {
            case .installation:
                guard let unitIndex = activeDefenseUnitIndex, unitIndex >= 0 else { return }
                if gameplay.buildInstallation(unitIndex, choice: choice, resources: &resources) != nil {
                    syncInstallationSidecar(gameplay, context: &context)
                    if let store = resourceStore { refreshInstallationNodes(gameplay: gameplay, store: store) }
                    refreshUnitNode(unitIndex, gameplay: gameplay)
                    success = true
                }
            case .fortress:
                guard let cell = selectedEmptyCell, let name = choice.armyName,
                      let training = NativeBattleRecruitCore.initialTrainingLevel(name: name, mode: gameplay.mode, campaignTech: context.campaignTech),
                      let index = gameplay.buildFortress(at: cell, choice: choice, ownership: context.ownership, trainingLevel: training, resources: &resources) else { return }
                refreshUnitNode(index, gameplay: gameplay); selectedEmptyCell = nil; success = true
            }
            guard success else { statusHandler?("资源不足或当前地点不可建造"); return }
            context.resources = resources; context.countryResources[gameplay.playerOwner] = resources
            gameplayState = gameplay; persistenceContext = context
            advanceTutorialUI("winbtn_ok"); advanceTutorialAction(); autosaveIfDialogueIdle()
            closeNativeDefense(); refreshInteractionOverlay()
            statusHandler?(renderer.kind == .installation ? "防御设施已修筑" : "要塞开始施工")
        case .none: break
        }
    }

    private func eligibleGeneralDeploymentIDs(targetUnitIndex: Int, gameplay: NativeBattleGameplayState) -> [Int] {
        let units = gameplay.unitOrder.compactMap { gameplay.units[$0] }
        let current = gameplay.units[targetUnitIndex]?.commanderID
        let include = current.map { Set([$0]) } ?? []
        return NativeGeneralDeploymentCore.eligibleCommanderIDs(
            ownedCommanderIDs: playerProfileRuntime?.snapshot().ownedCommanderIDs ?? playerProfile.ownedCommanderIDs,
            units: units,
            playerOwner: gameplay.playerOwner,
            targetUnitIndex: targetUnitIndex,
            include: include
        )
    }

    private func deployedGeneralCount(gameplay: NativeBattleGameplayState, exceptUnitIndex: Int? = nil) -> Int {
        let units = gameplay.unitOrder.compactMap { gameplay.units[$0] }
        return NativeGeneralDeploymentCore.deployedIDs(units: units, playerOwner: gameplay.playerOwner, exceptUnitIndex: exceptUnitIndex).count
    }

    private func openNativeGeneralDeployment(unitIndex: Int) {
        guard let renderer = originalGeneralDeploymentRenderer,
              let gameplay = gameplayState,
              let unit = gameplay.units[unitIndex],
              unit.owner == gameplay.playerOwner, !unit.dead else { return }
        activeGeneralTargetUnitIndex = unitIndex
        selectedGeneralDeploymentID = unit.commanderID
        renderer.show(
            ids: eligibleGeneralDeploymentIDs(targetUnitIndex: unitIndex, gameplay: gameplay),
            commanders: commanderCatalog,
            selectedID: selectedGeneralDeploymentID,
            deployedCount: deployedGeneralCount(gameplay: gameplay)
        )
        refreshNativeBattleHUD(gameplay: gameplay)
        statusHandler?("Native General Deployment")
    }

    private func closeNativeGeneralDeployment() {
        originalGeneralDeploymentRenderer?.hide()
        activeGeneralTargetUnitIndex = nil
        selectedGeneralDeploymentID = nil
        if let gameplay = gameplayState { refreshNativeBattleHUD(gameplay: gameplay) }
        statusHandler?("Native battle")
    }

    private func handleNativeGeneralDeploymentTap(_ point: NativePoint) {
        guard let targetIndex = activeGeneralTargetUnitIndex,
              let renderer = originalGeneralDeploymentRenderer,
              var gameplay = gameplayState else { return }
        let eligible = eligibleGeneralDeploymentIDs(targetUnitIndex: targetIndex, gameplay: gameplay)
        switch renderer.action(at: point) {
        case .close:
            advanceTutorialUI("winbtn_back")
            closeNativeGeneralDeployment()
        case .princess:
            advanceTutorialUI("btn_princess")
            renderer.openPrincess()
        case .princessClose:
            renderer.closePrincess()
        case .princessSelect(let id):
            guard eligible.contains(id), NativePlayerProfile.princessIDs.contains(id) else { return }
            selectedGeneralDeploymentID = id
            renderer.select(id)
        case .academy:
            advanceTutorialUI("btn_college")
            generalDeploymentAcademyHandler?()
        case .shop:
            // Mature P39/Web battle context leaves SceneShop disabled here.
            statusHandler?("战斗部署中不可打开商店")
        case .select(let id):
            guard eligible.contains(id), !NativePlayerProfile.princessIDs.contains(id) else { return }
            selectedGeneralDeploymentID = id
            let generalIDs = eligible.filter { !NativePlayerProfile.princessIDs.contains($0) }
            if let row = generalIDs.firstIndex(of: id) { advanceTutorialUI("grid_general", row: row) }
            renderer.select(id)
        case .confirm:
            guard let commanderID = selectedGeneralDeploymentID, eligible.contains(commanderID), let store = resourceStore, let raw = commanderCatalog[commanderID] else { return }
            let profile = playerProfileRuntime?.snapshot() ?? playerProfile
            guard let generalOverrides = playerGeneralOverrides, let princessOverrides = playerPrincessOverrides else { return }
            let effective = NativePlayerProfileCore.effectiveCommander(
                raw: raw,
                playerControlled: true,
                profile: profile,
                generalOverrides: generalOverrides,
                princessOverrides: princessOverrides
            )
            guard let result = gameplay.deployCommander(to: targetIndex, commanderID: commanderID, hpBonus: effective.rankHPBonus) else { return }
            gameplayState = gameplay
            if var context = persistenceContext {
                for index in result.clearedUnitIndices { context.assignments.removeValue(forKey: index) }
                context.assignments[targetIndex] = commanderID
                persistenceContext = context
            }
            refreshUnitNode(targetIndex, gameplay: gameplay)
            for index in result.clearedUnitIndices { refreshUnitNode(index, gameplay: gameplay) }
            refreshInteractionOverlay()
            autosaveIfDialogueIdle()
            statusHandler?("\(raw.name) 已部署到该部队")
            closeNativeGeneralDeployment()
        case .none:
            break
        }
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.count == 1, let touch = touches.first else { return }
        let p = touch.location(in: self)
        let logical = NativePoint(x: p.x, y: EW4LogicalSpace.height - p.y)
        touchStart = logical
        panStart = logical
        hasPanned = false
        if activeShopObjectIndex != nil {
            originalBattleShopRenderer?.beginInteraction(at: logical)
        } else if activeGeneralTargetUnitIndex != nil {
            originalGeneralDeploymentRenderer?.beginInteraction(at: logical)
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if activeShopObjectIndex != nil, touches.count == 1, let touch = touches.first {
            let p = touch.location(in: self)
            let logical = NativePoint(x: p.x, y: EW4LogicalSpace.height - p.y)
            _ = originalBattleShopRenderer?.moveInteraction(to: logical)
            return
        }
        if activeGeneralTargetUnitIndex != nil, touches.count == 1, let touch = touches.first {
            let p = touch.location(in: self)
            let logical = NativePoint(x: p.x, y: EW4LogicalSpace.height - p.y)
            _ = originalGeneralDeploymentRenderer?.moveInteraction(to: logical)
            return
        }
        guard pendingActionCameraContinuation == nil, activeTavernObjectIndex == nil, activeMarketObjectIndex == nil, activeShopObjectIndex == nil, activeUnitInfoUnitIndex == nil, activeGeneralInfoUnitIndex == nil, activeGeneralTargetUnitIndex == nil, activeRecruitObjectIndex == nil, activeUseItemUnitIndex == nil, activeDefenseUnitIndex == nil, originalActionResourceRenderer?.isVisible != true, activeNativeDialogue == nil, !stageIntroActive, battleModalState == .none, battleResultPresentationPhase == .none else { return }
        guard touches.count == 1,
              let touch = touches.first,
              let previous = panStart,
              let start = touchStart else {
            return
        }
        let p = touch.location(in: self)
        let current = NativePoint(x: p.x, y: EW4LogicalSpace.height - p.y)
        if !NativeCamera.isNativeTap(start: start, end: current) {
            hasPanned = true
        }
        if hasPanned {
            setCamera(NativeCamera.panStep(cameraState, previous: previous, current: current))
        }
        panStart = current
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer {
            panStart = nil
            touchStart = nil
            hasPanned = false
        }
        guard touches.count == 1,
              let touch = touches.first,
              let start = touchStart else {
            return
        }
        let p = touch.location(in: self)
        let end = NativePoint(x: p.x, y: EW4LogicalSpace.height - p.y)
        if activeShopObjectIndex != nil, originalBattleShopRenderer?.endInteraction(at: end) == true {
            return
        }
        if activeGeneralTargetUnitIndex != nil, originalGeneralDeploymentRenderer?.endInteraction(at: end) == true {
            return
        }
        if !hasPanned && NativeCamera.isNativeTap(start: start, end: end) {
            if advanceTutorialTouch() { return }
            if activeTavernObjectIndex != nil {
                handleNativeTavernTap(end)
            } else if activeMarketObjectIndex != nil {
                handleNativeMarketTap(end)
            } else if activeShopObjectIndex != nil {
                handleNativeBattleShopTap(end)
            } else if activeGeneralInfoUnitIndex != nil {
                handleNativeBattleGeneralInfoTap(end)
            } else if activeUnitInfoUnitIndex != nil {
                handleNativeBattleUnitInfoTap(end)
            } else if activeGeneralTargetUnitIndex != nil {
                handleNativeGeneralDeploymentTap(end)
            } else if activeRecruitObjectIndex != nil {
                handleNativeRecruitUnitTap(end)
            } else if activeUseItemUnitIndex != nil {
                handleNativeUseItemTap(end)
            } else if activeDefenseUnitIndex != nil || originalDefenseRenderer?.isVisible == true {
                handleNativeDefenseTap(end)
            } else if originalActionResourceRenderer?.isVisible == true {
                handleNativeActionResourceTap(end)
            } else if !isOuterCompletionIdle {
                handleNativeOuterCompletionTap(end)
            } else if battleResultPresentationPhase != .none {
                advanceNativeBattleResult(at: end)
            } else if battleModalState != .none {
                handleNativeBattleModalTap(end)
            } else if stageIntroActive {
                if stageIntroCloseContains(end) { closeNativeStageIntro() }
            } else if activeNativeDialogue != nil {
                _ = advanceNativeDialogue()
            } else {
                handleNativeTap(end)
            }
        }
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        panStart = nil
        touchStart = nil
        hasPanned = false
    }
}
#endif
