import SwiftUI
import Combine
import SpriteKit
import UIKit
import OSLog
import EW4NativeCore
import EW4NativeRenderer

private let startupLog = Logger(subsystem: "local.ew4.nativeport", category: "startup")

@main
struct EW4NativePortApp: App {
    var body: some Scene {
        WindowGroup { NativeGameHost() }
    }
}

struct NativeGameHost: View {
    @StateObject private var coordinator = NativeGameCoordinator()

    var body: some View {
        ZStack(alignment: .topLeading) {
            NativeSceneView(scene: coordinator.scene)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            if let error = coordinator.startupError {
                VStack(spacing: 16) {
                    Text("游戏启动失败").font(.headline)
                    Text(error).multilineTextAlignment(.center)
                    Button("重新尝试") { coordinator.retryBoot() }
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .foregroundStyle(.white)
                .accessibilityIdentifier("native.startup.error")
            }
            #if DEBUG
            Text(coordinator.debugMessage)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .padding(4)
                .background(.black.opacity(0.45))
                .foregroundStyle(.white)
            #endif
        }
        .task {
            startupLog.notice("SwiftUI host task started")
            coordinator.bootIfNeeded()
        }
    }
}

// Keep a single SKView and explicitly present each newly selected scene.
// SwiftUI state changes must reach SpriteKit's presentation layer, including
// the first transition from the placeholder scene to the main menu.
@MainActor
struct NativeSceneView: UIViewRepresentable {
    let scene: SKScene

    func makeUIView(context: Context) -> SKView {
        let view = NativePresentationView(frame: .zero)
        startupLog.notice("Created native SKView")
        view.backgroundColor = .black
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 60
        view.isAccessibilityElement = true
        view.accessibilityIdentifier = "native.game.surface"
        view.accessibilityLabel = "欧陆战争4游戏画面"
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {
        if view.scene !== scene {
            startupLog.notice("Presenting scene \(String(describing: type(of: scene)), privacy: .public), nodes=\(scene.children.count)")
            view.presentScene(scene)
            startupLog.notice("Scene attached=\(scene.view === view)")
        }
        view.accessibilityValue = String(describing: type(of: scene))
    }
}

@MainActor
final class NativePresentationView: SKView {
    private var lastLoggedSize: CGSize = .zero
    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != lastLoggedSize {
            lastLoggedSize = bounds.size
            let width = Double(bounds.width)
            let height = Double(bounds.height)
            let selectedScene = String(describing: scene.map { type(of: $0) })
            startupLog.notice("SKView layout \(width) x \(height), scene=\(selectedScene, privacy: .public)")
        }
    }
}

@MainActor
final class NativeGameCoordinator: ObservableObject {
    @Published var startupError: String?
    @Published var scene: SKScene = {
        let scene = SKScene(size: CGSize(width: EW4LogicalSpace.width, height: EW4LogicalSpace.height))
        scene.scaleMode = .aspectFit
        scene.backgroundColor = .black
        return scene
    }()
    #if DEBUG
    @Published var debugMessage = "Native boot"
    #endif

    private var booted = false
    private var store: NativeResourceStore?
    private var profileStore: NativePlayerProfileStore?
    private var battleSaveStore: NativeBattleSaveSlotStore?
    private var currentLaunch: NativeOriginalOuterMenuScene.BattleLaunch?
    private var audioController: NativeAudioController?

    func retryBoot() {
        booted = false
        startupError = nil
        bootIfNeeded()
    }

    func bootIfNeeded() {
        startupLog.notice("Bootstrap entered; alreadyBooted=\(self.booted)")
        guard !booted else { return }
        booted = true
        do {
            let store = try NativeResourceStore()
            startupLog.notice("Resources resolved: \(store.resourceRoot.path, privacy: .public)")
            let support = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let profileStore = NativePlayerProfileStore(directory: support.appendingPathComponent("EW4NativePort", isDirectory: true))
            let battleSaveStore = try NativeBattleSaveSlotStore.applicationSupport()
            self.store = store
            self.profileStore = profileStore
            self.battleSaveStore = battleSaveStore
            self.audioController = NativeAudioController(resourceRoot: store.resourceRoot)
            startupLog.notice("Storage and audio initialized")
            #if DEBUG
            let report = try NativeResourceAuditor.audit(resourceRoot: store.resourceRoot)
            guard report.passed else { debugMessage = "Native resource audit failed"; return }
            #endif
            showMainMenu()
        } catch {
            startupLog.error("Bootstrap failed: \(String(describing: error), privacy: .public)")
            startupError = "无法读取游戏资源或存档目录：\(error.localizedDescription)"
            #if DEBUG
            debugMessage = "Native boot error: \(error.localizedDescription)"
            #endif
        }
    }

    private var currentProfile: NativePlayerProfile { profileStore?.load() ?? .fresh() }

    private func showMainMenu() {
        startupLog.notice("showMainMenu entered")
        guard let store else { return }
        let menu = NativeOriginalMainMenuScene(store: store)
        menu.achievementHandler = { [weak self] in self?.showAchievement() }
        menu.actionHandler = { [weak self] action in
            guard let self else { return }
            switch action {
            case .campaign: self.showCampaignSelection()
            case .conquest: self.showConquestSelection()
            case .tutorial: self.showTutorial()
            case .headquarters:
                self.showHeadquarters()
            case .options: self.showOptions()
            }
        }
        scene = menu
        startupLog.notice("Main menu selected; top-level nodes=\(menu.children.count)")
        setStatus("Native main menu")
    }

    private func showAchievement() {
        guard let store else { return }
        do {
            let achievement = try NativeOriginalAchievementScene(store: store, profile: currentProfile)
            achievement.backHandler = { [weak self] in self?.showMainMenu() }
            achievement.soundEffectHandler = { [weak self] file in guard let self else{return}; self.audioController?.playSFX(file, settings: NativeOptionsCore.settings(from:self.currentProfile)) }
            achievement.statusHandler = { [weak self] text in self?.setStatus(text) }
            audioController?.playFormOpen("form_achivement", settings: NativeOptionsCore.settings(from: currentProfile))
            scene = achievement; setStatus("Native Achievement")
        } catch { setStatus("Achievement shell error: \(error.localizedDescription)") }
    }

    private func showTutorial() {
        guard let store else { return }
        do {
            let tutorial = try NativeOriginalTutorialScene(store: store)
            tutorial.backHandler = { [weak self] in self?.showMainMenu() }
            tutorial.launchHandler = { [weak self] file in
                self?.startBattle(.init(file: file, mode: .tutorial, playerOwner: 0))
            }
            tutorial.soundEffectHandler = { [weak self] file in guard let self else{return}; self.audioController?.playSFX(file, settings: NativeOptionsCore.settings(from:self.currentProfile)) }
            scene = tutorial; setStatus("Native Tutorial")
        } catch { setStatus("Tutorial shell error: \(error.localizedDescription)") }
    }

    private func showOptions(returnScene: SKScene? = nil) {
        guard let store else { return }
        let options = NativeOriginalOptionsScene(store: store, profile: currentProfile)
        let returnAction: () -> Void = { [weak self, weak returnScene] in
            guard let self else { return }
            if let returnScene { self.scene = returnScene; self.setStatus("Native battle") } else { self.showMainMenu() }
        }
        options.cancelHandler = returnAction
        options.commitHandler = { [weak self] profile, settings in
            guard let self else { return }
            do { try self.profileStore?.save(profile) } catch { self.setStatus("Options save error: \(error.localizedDescription)") }
            if let battle = returnScene as? NativeBattleScene { battle.applyOptionsProfile(profile) }
            self.audioController?.apply(settings); returnAction()
        }
        options.soundEffectHandler = { [weak self] file in guard let self else{return}; self.audioController?.playSFX(file,settings:NativeOptionsCore.settings(from:self.currentProfile)) }
        audioController?.playFormOpen("form_option", settings: NativeOptionsCore.settings(from:currentProfile))
        scene = options; setStatus("Native Options")
    }

    private func showHeadquarters() {
        guard let store else { return }
        do {
            let hq = try NativeOriginalHeadquartersScene(store: store, profile: currentProfile)
            hq.backHandler = { [weak self] in self?.showMainMenu() }
            hq.shopHandler = { [weak self] in self?.showHQShop() }
            hq.academyHandler = { [weak self] in self?.showMilitaryAcademy() }
            hq.equipmentHandler = { [weak self] id in self?.showDeployItem(commanderID: id) }
            hq.upgradeHandler = { [weak self] id in self?.showGeneralUpgrade(commanderID: id) }
            hq.regroupHandler = { [weak self] id in self?.showRegroup(targetID: id) }
            hq.dismissHandler = { [weak self] id in self?.showDismiss(commanderID: id) }
            hq.statusHandler = { [weak self] text in self?.setStatus(text) }
            scene = hq
            setStatus("Native Headquarters")
        } catch { setStatus("Headquarters shell error: \(error.localizedDescription)") }
    }

    private func showHQShop() {
        guard let store else { return }
        do {
            let shop = try NativeOriginalHQShopScene(store: store, profile: currentProfile)
            try profileStore?.save(shop.profile)
            shop.backHandler = { [weak self] in self?.showHeadquarters() }
            shop.profileDidChangeHandler = { [weak self] profile in
                do { try self?.profileStore?.save(profile) }
                catch { self?.setStatus("HQ Shop save error: \(error.localizedDescription)") }
            }
            shop.statusHandler = { [weak self] text in self?.setStatus(text) }
            scene = shop
            setStatus("Native HQ Shop")
        } catch { setStatus("HQ Shop shell error: \(error.localizedDescription)") }
    }

    private func showMilitaryAcademy(returnScene: SKScene? = nil) {
        guard let store else { return }
        do {
            let academy = try NativeOriginalAcademyScene(store: store, profile: currentProfile)
            try profileStore?.save(academy.profile)
            academy.backHandler = { [weak self, weak returnScene] in
                guard let self else { return }
                if let returnScene { self.scene = returnScene; self.setStatus("Native battle") }
                else { self.showHeadquarters() }
            }
            academy.profileDidChangeHandler = { [weak self, weak returnScene] profile in
                do { try self?.profileStore?.save(profile) }
                catch { self?.setStatus("Military Academy save error: \(error.localizedDescription)") }
                if let battle = returnScene as? NativeBattleScene { battle.applyOptionsProfile(profile) }
            }
            academy.statusHandler = { [weak self] text in self?.setStatus(text) }
            scene = academy
            setStatus("Native Military Academy")
        } catch { setStatus("Military Academy shell error: \(error.localizedDescription)") }
    }

    private func showGeneralUpgrade(commanderID: Int) {
        guard let store else { return }
        do {
            let form = try NativeOriginalGeneralUpgradeScene(store: store, profile: currentProfile, commanderID: commanderID)
            form.backHandler = { [weak self] in self?.showHeadquarters() }
            form.profileDidChangeHandler = { [weak self] updated in
                do { try self?.profileStore?.save(updated) }
                catch { self?.setStatus("General upgrade save error: \(error.localizedDescription)") }
            }
            form.soundEffectHandler = { [weak self] file in
                guard let self else { return }
                self.audioController?.playSFX(file, settings: NativeOptionsCore.settings(from: self.currentProfile))
            }
            form.statusHandler = { [weak self] text in self?.setStatus(text) }
            audioController?.playFormOpen("form_generalupgrade", settings: NativeOptionsCore.settings(from: currentProfile))
            scene = form; setStatus("Native General Upgrade")
        } catch { setStatus("General upgrade error: \(error.localizedDescription)") }
    }

    private func showDeployItem(commanderID: Int) {
        guard let store else { return }
        do {
            let form = try NativeOriginalDeployItemScene(store: store, profile: currentProfile, commanderID: commanderID)
            form.backHandler = { [weak self] in self?.showHeadquarters() }
            form.profileDidChangeHandler = { [weak self] updated in try? self?.profileStore?.save(updated) }
            form.statusHandler = { [weak self] text in self?.setStatus(text) }
            scene = form; setStatus("Native DeployItem")
        } catch { setStatus("DeployItem error: \(error.localizedDescription)") }
    }

    private func showRegroup(targetID: Int) {
        guard let store else { return }
        do {
            let form = try NativeOriginalRegroupScene(store: store, profile: currentProfile, targetID: targetID)
            form.backHandler = { [weak self] in self?.showHeadquarters() }
            form.completedHandler = { [weak self] in self?.showHeadquarters() }
            form.profileDidChangeHandler = { [weak self] updated in try? self?.profileStore?.save(updated) }
            form.statusHandler = { [weak self] text in self?.setStatus(text) }
            scene = form; setStatus("Native Regroup")
        } catch { setStatus("Regroup error: \(error.localizedDescription)") }
    }

    private func showDismiss(commanderID: Int) {
        guard let store else { return }
        do {
            let form = try NativeOriginalDismissScene(store: store, profile: currentProfile, commanderID: commanderID)
            form.backHandler = { [weak self] in self?.showHeadquarters() }
            form.completedHandler = { [weak self] in self?.showHeadquarters() }
            form.profileDidChangeHandler = { [weak self] updated in try? self?.profileStore?.save(updated) }
            form.statusHandler = { [weak self] text in self?.setStatus(text) }
            scene = form; setStatus("Native Dismiss General")
        } catch { setStatus("Dismiss error: \(error.localizedDescription)") }
    }

    private func showCampaignSelection() {
        guard let store else { return }
        do {
            let outer = try NativeOriginalOuterMenuScene(store: store, profile: currentProfile)
            wireOuter(outer)
            outer.showCampaignSelection()
            scene = outer
            setStatus("Native Campaign")
        } catch { setStatus("Campaign shell error: \(error.localizedDescription)") }
    }

    private func showCampaignList(zone: Int, preferContinueBattle: Bool = false) {
        guard let store else { return }
        do {
            let outer = try NativeOriginalOuterMenuScene(store: store, profile: currentProfile)
            wireOuter(outer)
            outer.showCampaignList(zone: zone, preferContinueBattle: preferContinueBattle)
            scene = outer
            setStatus("Campaign zone \(zone)")
        } catch { setStatus("Campaign list error: \(error.localizedDescription)") }
    }

    private func showConquestSelection() {
        guard let store else { return }
        do {
            let outer = try NativeOriginalOuterMenuScene(store: store, profile: currentProfile, initialConquest: true)
            wireOuter(outer)
            scene = outer
            setStatus("Native Conquest")
        } catch { setStatus("Conquest shell error: \(error.localizedDescription)") }
    }

    private func wireOuter(_ outer: NativeOriginalOuterMenuScene) {
        outer.backToMainHandler = { [weak self] in self?.showMainMenu() }
        outer.battleLaunchHandler = { [weak self] launch in self?.startBattle(launch) }
        outer.loadRequestedHandler = { [weak self] in self?.restoreAutosave() }
        outer.statusHandler = { [weak self] text in self?.setStatus(text) }
    }

    private func startBattle(_ launch: NativeOriginalOuterMenuScene.BattleLaunch) {
        guard let store else { return }
        let battle = NativeBattleScene()
        wireBattle(battle, launch: launch)
        do {
            try battle.loadBattle(file: launch.file, store: store, profile: currentProfile, mode: launch.mode, playerOwner: launch.playerOwner)
            currentLaunch = launch
            audioController?.startBattleMusic(settings: NativeOptionsCore.settings(from: currentProfile))
            scene = battle
            setStatus("Native battle · \(launch.file)")
        } catch { setStatus("Battle load error: \(error.localizedDescription)") }
    }

    private func wireBattle(_ battle: NativeBattleScene, launch: NativeOriginalOuterMenuScene.BattleLaunch?) {
        battle.statusHandler = { [weak self] text in self?.setStatus(text) }
        battle.playerProfileDidChangeHandler = { [weak self] updated in try? self?.profileStore?.save(updated) }
        battle.autosavePayloadHandler = { [weak self] payload in try? self?.battleSaveStore?.write(payload, to: .autosave) }
        battle.saveSlotMetadataProvider = { [weak self] in self?.battleSaveStore?.allMetadata() ?? [] }
        battle.battleSaveWriteHandler = { [weak self] slot, payload in try? self?.battleSaveStore?.write(payload, to: slot) }
        battle.battleSaveReadProvider = { [weak self] slot in self?.battleSaveStore?.read(slot) }
        battle.pauseOptionHandler = { [weak self, weak battle] in guard let battle else{return}; self?.showOptions(returnScene: battle) }
        battle.tutorialCompletedHandler = { [weak self] in self?.audioController?.stopBattleMusic(); self?.showTutorial() }
        battle.pauseRestartHandler = { [weak self] in if let launch = self?.currentLaunch { self?.startBattle(launch) } }
        battle.battleResultPresentedHandler = { [weak self] content in guard let self else{return}; self.audioController?.playResult(content.kind.rawValue, settings: NativeOptionsCore.settings(from:self.currentProfile)) }
        battle.pauseExitHandler = { [weak self] in self?.routeBackFromBattle(launch: launch) }
        battle.battleResultRestartHandler = { [weak self] _ in if let launch = self?.currentLaunch { self?.startBattle(launch) } }
        battle.battleResultExitHandler = { [weak self] _ in self?.routeBackFromBattle(launch: launch) }
        battle.battleResultContinueHandler = { [weak self] _ in self?.routeBackFromBattle(launch: launch) }
        battle.campaignContinueRouteHandler = { [weak self] route in
            guard let self else { return }
            switch route {
            case .campaignList(let zone, let prefer): self.showCampaignList(zone: zone, preferContinueBattle: prefer)
            case .zoneComplete(let zone, _, _): self.showCampaignList(zone: zone)
            }
        }
        battle.conquestSummaryHandler = { [weak self] _ in self?.showConquestSelection() }
        battle.generalDeploymentAcademyHandler = { [weak self, weak battle] in
            guard let battle else { return }
            self?.showMilitaryAcademy(returnScene: battle)
        }
    }

    private func routeBackFromBattle(launch: NativeOriginalOuterMenuScene.BattleLaunch?) {
        audioController?.stopBattleMusic()
        guard let launch else { showMainMenu(); return }
        switch launch.mode {
        case .campaign:
            if let stage = NativeCampaignCore.stageNumber(launch.file) { showCampaignList(zone: stage.zone) }
            else { showCampaignSelection() }
        case .conquest: showConquestSelection()
        case .tutorial: showTutorial()
        default: showMainMenu()
        }
    }

    private func restoreAutosave() {
        guard let store, let payload = battleSaveStore?.read(.autosave) else {
            setStatus("No autosave")
            return
        }
        let battle = NativeBattleScene()
        wireBattle(battle, launch: nil)
        do {
            let restored = try battle.restoreBattle(from: payload, store: store, profile: currentProfile)
            currentLaunch = .init(file: restored.gameplay.battle.file, mode: restored.gameplay.mode, playerOwner: restored.gameplay.playerOwner)
            audioController?.startBattleMusic(settings: NativeOptionsCore.settings(from:currentProfile))
            scene = battle
            setStatus("Loaded autosave · \(restored.gameplay.battle.file)")
        } catch { setStatus("Autosave load error: \(error.localizedDescription)") }
    }

    private func setStatus(_ text: String) {
        #if DEBUG
        debugMessage = text
        #endif
    }
}
