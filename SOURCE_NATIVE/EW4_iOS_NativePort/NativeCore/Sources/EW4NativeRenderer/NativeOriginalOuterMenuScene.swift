#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

/// Native 568x320 Campaign / Conquest outer shell.
/// It consumes the already-mature campaign/conquest rules and recovered original geometry;
/// it does not own battle rules or mutate the world/map rendering pipeline.
public final class NativeOriginalOuterMenuScene: SKScene {
    public struct BattleLaunch: Sendable {
        public let file: String
        public let mode: BattleMode
        public let playerOwner: Int
        public init(file: String, mode: BattleMode, playerOwner: Int) {
            self.file = file
            self.mode = mode
            self.playerOwner = playerOwner
        }
    }

    private struct CampaignEntry {
        let battle: BattleRecord
        let selectable: Bool
        let progress: Int
        let rating: Int
        let stage: Int
    }

    private enum Screen {
        case campaignSelect
        case campaignList(zone: Int)
        case campaignCountry(base: BattleRecord, codes: [String], selected: Int)
        case conquestSelect
        case conquestCountries(scenario: Int)
    }

    public var battleLaunchHandler: ((BattleLaunch) -> Void)?
    public var backToMainHandler: (() -> Void)?
    public var loadRequestedHandler: (() -> Void)?
    public var statusHandler: ((String) -> Void)?

    private let store: NativeResourceStore
    private var profile: NativePlayerProfile
    private let battles: [BattleRecord]
    private let commanders: [Int: Commander]
    private let strings: [String: String]
    private let sprites: [String: SpriteManifestEntry]

    private let uiRoot = SKNode()
    private var screen: Screen = .campaignSelect
    private var campaignInfoZone: Int?
    private var campaignEntries: [CampaignEntry] = []
    private var selectedCampaignRow = 0
    private var campaignFirstVisible = 0
    private var conquestCountries: [BattleCountry] = []
    private var selectedConquestCountry = 0
    private var conquestFirstVisible = 0
    private var touchStart: NativePoint?
    private var hasDragged = false

    public init(store: NativeResourceStore, profile: NativePlayerProfile, initialConquest: Bool = false) throws {
        self.store = store
        self.profile = profile
        self.battles = try store.battles().battles
        self.commanders = try store.commanders()
        self.strings = try store.stringsCN()
        self.sprites = try store.sprites()
        super.init(size: CGSize(width: EW4LogicalSpace.width, height: EW4LogicalSpace.height))
        scaleMode = .aspectFit
        anchorPoint = CGPoint(x: 0, y: 0)
        backgroundColor = .black
        uiRoot.position = CGPoint(x: 0, y: EW4LogicalSpace.height)
        addChild(uiRoot)
        if initialConquest { showConquestSelection() } else { showCampaignSelection() }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func replaceProfile(_ profile: NativePlayerProfile) {
        self.profile = profile
        rerenderCurrentScreen()
    }

    public func showCampaignSelection() {
        screen = .campaignSelect
        campaignInfoZone = nil
        campaignEntries = []
        renderCampaignSelection()
    }

    public func showConquestSelection() {
        screen = .conquestSelect
        conquestCountries = []
        renderConquestSelection()
    }

    public func showCampaignList(zone: Int, preferContinueBattle: Bool = false) {
        let z = max(1, min(6, zone))
        let rows = NativeCampaignCore.rows(zone: z, battles: battles)
        campaignEntries = rows.enumerated().compactMap { index, battle in
            let canonical = NativeCampaignCore.canonicalFile(battle)
            let hidden = NativeCampaignCore.originalHide(battle)
            let secret = secretUnlocked(canonical)
            if hidden && !secret { return nil }
            return CampaignEntry(
                battle: battle,
                selectable: NativeCampaignCore.stageSelectable(
                    rows: rows,
                    index: index,
                    progress: { NativeCampaignSessionCore.progressLevel(profile.document, file: $0) },
                    secretUnlocked: { secretUnlocked($0) }
                ),
                progress: NativeCampaignSessionCore.progressLevel(profile.document, file: canonical),
                rating: NativeCampaignSessionCore.bestRating(profile.document, file: canonical),
                stage: NativeCampaignCore.stageNumber(canonical)?.stage ?? index + 1
            )
        }

        if let preferred = campaignEntries.firstIndex(where: { $0.selectable && $0.progress == 0 }) {
            selectedCampaignRow = preferred
        } else if let last = campaignEntries.lastIndex(where: { $0.selectable }) {
            selectedCampaignRow = last
        } else {
            selectedCampaignRow = 0
        }
        if preferContinueBattle, let next = campaignEntries.firstIndex(where: { $0.selectable && $0.progress == 0 }) {
            selectedCampaignRow = next
        }
        campaignFirstVisible = max(0, min(selectedCampaignRow, max(0, campaignEntries.count - visibleListSlots)))
        screen = .campaignList(zone: z)
        renderCampaignList(zone: z)
    }

    private func showCampaignCountrySelector(base: BattleRecord, codes: [String], selected: Int = 0) {
        screen = .campaignCountry(base: base, codes: Array(codes.prefix(2)), selected: max(0, min(1, selected)))
        renderCampaignCountrySelector(base: base, codes: Array(codes.prefix(2)), selected: max(0, min(1, selected)))
    }

    private func showConquestCountries(scenario: Int) {
        guard let battle = battle(file: "conquest\(scenario).btl") else { return }
        conquestCountries = battle.countries.filter { $0.index != 255 }
        selectedConquestCountry = 0
        conquestFirstVisible = 0
        screen = .conquestCountries(scenario: scenario)
        renderConquestCountryList(scenario: scenario)
    }

    private var visibleListSlots: Int { 5 }

    private func rerenderCurrentScreen() {
        switch screen {
        case .campaignSelect: renderCampaignSelection()
        case .campaignList(let zone): showCampaignList(zone: zone)
        case .campaignCountry(let base, let codes, let selected): renderCampaignCountrySelector(base: base, codes: codes, selected: selected)
        case .conquestSelect: renderConquestSelection()
        case .conquestCountries(let scenario): renderConquestCountryList(scenario: scenario)
        }
    }

    private func renderCampaignSelection() {
        clearUI()
        addWideBackground()
        addTitleBar(strings["title_campaigns"] ?? "剧　本")
        addBackButton()
        addLoadButton()
        for (index, rect) in NativeOriginalOuterShellCore.CampaignSelect.zoneButtons.enumerated() {
            guard index < NativeOriginalOuterShellCore.CampaignSelect.zoneButtonImages.count else { continue }
            if let node = directSprite("image_menu_hd", NativeOriginalOuterShellCore.CampaignSelect.zoneButtonImages[index]) {
                place(node, rect, z: 5)
                uiRoot.addChild(node)
            }
        }
        if let zone = campaignInfoZone { renderCampaignInfo(zone: zone) }
    }

    private func openCampaignInfo(zone: Int) {
        guard NativeOriginalOuterShellCore.CampaignInfo.line(zone: zone) != nil else { showCampaignList(zone: zone); return }
        campaignInfoZone = zone
        renderCampaignSelection()
        statusHandler?("Native CampaignInfo zone \(zone)")
    }

    private func closeCampaignInfo() {
        guard campaignInfoZone != nil else { return }
        campaignInfoZone = nil
        renderCampaignSelection()
    }

    private func renderCampaignInfo(zone: Int) {
        guard let line = NativeOriginalOuterShellCore.CampaignInfo.line(zone: zone),
              let screen = NativeOriginalOuterShellCore.CampaignInfo.screenFrame(zone: zone) else { return }
        let C = NativeOriginalOuterShellCore.CampaignInfo.self
        func abs(_ rect: NativeRect) -> NativeRect {
            NativeRect(x: screen.origin.x + rect.origin.x, y: screen.origin.y + rect.origin.y, width: rect.size.width, height: rect.size.height)
        }
        if let back = directSprite("image_ui_hd", "button_choosebattlezoneinfo.png") {
            place(back, abs(C.back), z: 40)
            uiRoot.addChild(back)
        }
        if let arrow = directSprite("image_ui_hd", "arrow_choosebattlezoneinfo.png") {
            place(arrow, abs(C.arrow), z: 41)
            uiRoot.addChild(arrow)
        }
        addLabel(strings[line.titleStringKey] ?? NativeOriginalOuterShellCore.CampaignSelect.zoneNames[max(0, min(5, zone - 1))], x: screen.origin.x + C.title.origin.x, y: screen.origin.y + C.title.origin.y, width: C.title.size.width, height: C.title.size.height, size: 7, light: false, bold: true, center: true, z: 43)
        addLabel("\(line.start) - \(line.end)", x: screen.origin.x + C.age.origin.x, y: screen.origin.y + C.age.origin.y, width: C.age.size.width, height: C.age.size.height, size: 6.5, light: false, bold: false, center: true, z: 43)
        var flagX = screen.origin.x + C.nations.origin.x
        for code in line.countries {
            if let flag = flagNode(code) {
                place(flag, NativeRect(x: flagX, y: screen.origin.y + C.nations.origin.y, width: 25.5, height: 15), z: 43)
                uiRoot.addChild(flag)
                flagX += 28
            }
        }
        if let confirm = directSprite("image_ui_hd", "button_confrim.png") {
            place(confirm, abs(C.confirm), z: 44)
            uiRoot.addChild(confirm)
        }
    }

    private func renderConquestSelection() {
        clearUI()
        addWideBackground()
        addTitleBar(strings["title_conquest"] ?? "征　服")
        addBackButton()
        addLoadButton()
        for (idx, scenario) in NativeOriginalOuterShellCore.conquestScenarios.enumerated() {
            guard idx < NativeOriginalOuterShellCore.ConquestSelect.cards.count else { continue }
            let rect = NativeOriginalOuterShellCore.ConquestSelect.cards[idx]
            if let shadow = directSprite("image_ui_hd", "common_shadow.png") {
                place(shadow, NativeRect(x: rect.origin.x + 7, y: rect.origin.y + 9, width: rect.size.width, height: rect.size.height), z: 1)
                uiRoot.addChild(shadow)
            }
            if let card = textureNode("tex_conquest_\(scenario.textureYear).png") {
                place(card, rect, z: 2)
                uiRoot.addChild(card)
            }
            let locFile = "conquest_text_\(scenario.location).png"
            if let loc = directSprite("image_menu_hd", locFile) {
                let local = NativeOriginalOuterShellCore.ConquestSelect.imagePosition
                place(loc, NativeRect(x: rect.origin.x + local.origin.x, y: rect.origin.y + local.origin.y, width: local.size.width, height: local.size.height), z: 3)
                uiRoot.addChild(loc)
            }
            let yearFile = "conquest_text_\(scenario.displayYear).png"
            if let year = directSprite("image_menu_hd", yearFile) {
                let x = scenario.location == "america" ? NativeOriginalOuterShellCore.ConquestSelect.americaYearX : NativeOriginalOuterShellCore.ConquestSelect.europeYearX
                place(year, NativeRect(x: rect.origin.x + x, y: rect.origin.y + 47, width: 40, height: 11), z: 3)
                uiRoot.addChild(year)
            }
            if let line = directSprite("image_menu_hd", "button_conquest_whiteline.png") {
                place(line, NativeRect(x: rect.origin.x + 15, y: rect.origin.y + 61, width: 180, height: 2), z: 3)
                uiRoot.addChild(line)
            }
            if let battle = battle(file: "conquest\(scenario.index).btl") {
                var x = rect.origin.x + 15.0
                for country in battle.countries.prefix(10) {
                    if let flag = flagNode(country.code) {
                        place(flag, NativeRect(x: x, y: rect.origin.y + 65, width: 15, height: 10), z: 4)
                        uiRoot.addChild(flag)
                        x += 17
                    }
                }
            }
        }
    }

    private func renderCampaignList(zone: Int) {
        clearUI()
        addWideBackground()
        addTitleBar(NativeOriginalOuterShellCore.CampaignSelect.zoneNames[max(0, min(5, zone - 1))])
        addBackButton()
        addLabel("\(NativeOriginalOuterShellCore.CampaignSelect.zoneNames[max(0, min(5, zone - 1))])　\(campaignEntries.count) 个战役", x: 13, y: 34, width: 380, height: 18, size: 10, light: true, bold: true)

        let backRect = NativeOriginalOuterShellCore.CampaignList.listBack
        let panel = SKShapeNode(rect: CGRect(x: backRect.origin.x, y: -(backRect.origin.y + backRect.size.height), width: backRect.size.width, height: backRect.size.height))
        panel.fillColor = UIColor(red: 232 / 255, green: 228 / 255, blue: 218 / 255, alpha: 0.92)
        panel.strokeColor = UIColor(white: 0.48, alpha: 0.7)
        panel.zPosition = 3
        uiRoot.addChild(panel)

        for slot in 0..<visibleListSlots {
            let rowIndex = campaignFirstVisible + slot
            guard campaignEntries.indices.contains(rowIndex) else { continue }
            addCampaignRow(campaignEntries[rowIndex], rowIndex: rowIndex, slot: slot, zone: zone)
        }
        addScrollHints(first: campaignFirstVisible, count: campaignEntries.count, list: NativeOriginalOuterShellCore.CampaignList.list)
        if campaignEntries.indices.contains(selectedCampaignRow) {
            addCampaignIntro(campaignEntries[selectedCampaignRow])
        }
        addConfirmButton(rect: NativeOriginalOuterShellCore.CampaignList.confirm, enabled: campaignEntries.indices.contains(selectedCampaignRow) && campaignEntries[selectedCampaignRow].selectable)
    }

    private func addCampaignRow(_ entry: CampaignEntry, rowIndex: Int, slot: Int, zone: Int) {
        let list = NativeOriginalOuterShellCore.CampaignList.list
        let y = list.origin.y + Double(slot) * (NativeOriginalOuterShellCore.CampaignList.itemHeight + NativeOriginalOuterShellCore.CampaignList.itemInterval)
        let rect = NativeRect(x: list.origin.x, y: y, width: list.size.width, height: NativeOriginalOuterShellCore.CampaignList.itemHeight)
        let asset = ["france", "coalition", "holyroman", "east", "usa", "uk"][max(0, min(5, zone - 1))]
        if let row = directSprite("image_menu_hd", "button_choosestage_\(asset).png") {
            place(row, rect, z: rowIndex == selectedCampaignRow ? 6 : 5)
            row.alpha = entry.selectable ? (rowIndex == selectedCampaignRow ? 1.0 : 0.92) : 0.47
            uiRoot.addChild(row)
        }
        addLabel(String(entry.stage), x: rect.origin.x + 8, y: rect.origin.y + 13, width: 14, height: 14, size: 7, light: false, bold: true, z: 7)
        addLabel(entry.battle.nameCN, x: rect.origin.x + 28, y: rect.origin.y + 13, width: 92, height: 20, size: 7.5, light: false, bold: true, z: 7)
        if !entry.selectable, let lock = directSprite("image_ui_hd", "button_lock.png") {
            place(lock, NativeRect(x: rect.origin.x + 130, y: rect.origin.y + 12, width: 20, height: 20), z: 8)
            uiRoot.addChild(lock)
        } else {
            addStageStars(rating: entry.rating, progress: entry.progress, x: rect.origin.x + 126, y: rect.origin.y + 31)
        }
    }

    private func addCampaignIntro(_ entry: CampaignEntry) {
        let r = NativeOriginalOuterShellCore.CampaignList.intro
        let back = SKShapeNode(rect: CGRect(x: r.origin.x, y: -(r.origin.y + r.size.height), width: r.size.width, height: r.size.height))
        back.fillColor = UIColor(red: 238 / 255, green: 232 / 255, blue: 220 / 255, alpha: 0.94)
        back.strokeColor = UIColor(red: 139 / 255, green: 131 / 255, blue: 120 / 255, alpha: 1)
        back.zPosition = 4
        uiRoot.addChild(back)
        let limits = NativeResultCore.stageTurnLimits(entry.battle)
        let tail = limits.valid ? "　期限 \(limits.win) / 完美 \(limits.best)" : ""
        addLabel("\(entry.battle.nameCN)\(tail)", x: r.origin.x + 82, y: r.origin.y + 7, width: r.size.width - 90, height: 16, size: 8, light: false, bold: true, z: 7)
        addMultilineLabel(entry.battle.descCN ?? "", x: r.origin.x + 82, y: r.origin.y + 24, width: r.size.width - 90, height: 58, size: 6.5, z: 7)
        if let commanderID = introCommanderID(entry.battle), let commander = commanders[commanderID], let portrait = portraitNode(commander.name) {
            place(portrait, NativeRect(x: r.origin.x, y: r.origin.y + 2, width: 72, height: 78), z: 6)
            uiRoot.addChild(portrait)
            if let board = directSprite("image_ui_hd", "general_nameboard.png") {
                place(board, NativeRect(x: r.origin.x, y: r.origin.y + 70, width: 70, height: 18), z: 7)
                uiRoot.addChild(board)
            }
            addLabel(commander.name, x: r.origin.x, y: r.origin.y + 72, width: 70, height: 14, size: 6.5, light: true, bold: true, center: true, z: 8)
        }
    }

    private func renderCampaignCountrySelector(base: BattleRecord, codes: [String], selected: Int) {
        renderCampaignList(zone: NativeCampaignCore.stageNumber(NativeCampaignCore.canonicalFile(base))?.zone ?? 1)
        let shade = SKShapeNode(rect: CGRect(x: 0, y: -EW4LogicalSpace.height, width: EW4LogicalSpace.width, height: EW4LogicalSpace.height))
        shade.fillColor = UIColor(white: 0, alpha: 0.52)
        shade.strokeColor = .clear
        shade.zPosition = 90
        uiRoot.addChild(shade)
        let screen = NativeOriginalOuterShellCore.CountrySelect.screenFrame
        let root = SKNode()
        root.position = CGPoint(x: screen.origin.x, y: -screen.origin.y)
        root.zPosition = 100
        uiRoot.addChild(root)
        let panel = SKShapeNode(rect: CGRect(x: 0, y: -screen.size.height, width: screen.size.width, height: screen.size.height))
        panel.fillColor = UIColor(red: 224 / 255, green: 215 / 255, blue: 194 / 255, alpha: 1)
        panel.strokeColor = UIColor(red: 100 / 255, green: 89 / 255, blue: 72 / 255, alpha: 1)
        root.addChild(panel)
        addLocalLabel(strings["title_selcountry"] ?? "选择国家", rect: NativeRect(x: 0, y: 4, width: 234, height: 18), size: 9, root: root, center: true, bold: true)
        for side in 0..<min(2, codes.count) {
            let rect = side == 0 ? NativeOriginalOuterShellCore.CountrySelect.left : NativeOriginalOuterShellCore.CountrySelect.right
            let code = codes[side]
            let selectedSide = side == selected
            let frame = SKShapeNode(rect: CGRect(x: rect.origin.x, y: -(rect.origin.y + rect.size.height), width: rect.size.width, height: rect.size.height))
            frame.fillColor = UIColor(white: 1, alpha: selectedSide ? 0.18 : 0.04)
            frame.strokeColor = selectedSide ? UIColor(red: 150 / 255, green: 105 / 255, blue: 35 / 255, alpha: 1) : UIColor(white: 0.34, alpha: 1)
            frame.lineWidth = selectedSide ? 2 : 1
            root.addChild(frame)
            if let flag = flagNode(code) {
                let fr = NativeOriginalOuterShellCore.CountrySelect.flagInCard
                placeLocal(flag, NativeRect(x: rect.origin.x + fr.origin.x, y: rect.origin.y + fr.origin.y, width: fr.size.width, height: fr.size.height), z: 4)
                root.addChild(flag)
            }
            if let board = directSprite("image_ui_hd", "general_nameboard.png") {
                let br = NativeOriginalOuterShellCore.CountrySelect.nameBoardInCard
                placeLocal(board, NativeRect(x: rect.origin.x + br.origin.x, y: rect.origin.y + br.origin.y, width: br.size.width, height: br.size.height), z: 3)
                root.addChild(board)
            }
            let countryName = base.countries.first(where: { $0.code == code })?.nameCN ?? code.uppercased()
            let nr = NativeOriginalOuterShellCore.CountrySelect.nameInCard
            addLocalLabel(countryName, rect: NativeRect(x: rect.origin.x + nr.origin.x, y: rect.origin.y + nr.origin.y, width: nr.size.width, height: nr.size.height), size: 7, root: root, center: true, bold: true, light: true)
        }
        if let close = directSprite("image_ui_hd", "button_close.png") {
            placeLocal(close, NativeOriginalOuterShellCore.CountrySelect.closeButton, z: 5)
            root.addChild(close)
        }
        if let confirm = directSprite("image_ui_hd", "button_confrim.png") ?? directSprite("image_ui_hd", "new_confirm.png") {
            placeLocal(confirm, NativeOriginalOuterShellCore.CountrySelect.confirmButton, z: 5)
            root.addChild(confirm)
        }
    }

    private func renderConquestCountryList(scenario: Int) {
        clearUI()
        addWideBackground()
        let meta = NativeOriginalOuterShellCore.conquestScenarios.first(where: { $0.index == scenario })
        addTitleBar("\(strings["title_selcountry"] ?? "选择国家")　\(meta?.displayYear ?? "")")
        addBackButton()
        let listBack = NativeOriginalOuterShellCore.ConquestList.listBack
        let panel = SKShapeNode(rect: CGRect(x: listBack.origin.x, y: -(listBack.origin.y + listBack.size.height), width: listBack.size.width, height: listBack.size.height))
        panel.fillColor = UIColor(red: 232 / 255, green: 228 / 255, blue: 218 / 255, alpha: 0.93)
        panel.strokeColor = UIColor(white: 0.48, alpha: 0.7)
        panel.zPosition = 3
        uiRoot.addChild(panel)
        for slot in 0..<visibleListSlots {
            let index = conquestFirstVisible + slot
            guard conquestCountries.indices.contains(index) else { continue }
            addConquestCountryRow(conquestCountries[index], index: index, slot: slot)
        }
        addScrollHints(first: conquestFirstVisible, count: conquestCountries.count, list: NativeOriginalOuterShellCore.ConquestList.list)
        addConquestPreview(scenario: scenario)
        addConfirmButton(rect: NativeOriginalOuterShellCore.ConquestList.confirm, enabled: conquestCountries.indices.contains(selectedConquestCountry))
    }

    private func addConquestCountryRow(_ country: BattleCountry, index: Int, slot: Int) {
        let list = NativeOriginalOuterShellCore.ConquestList.list
        let y = list.origin.y + Double(slot) * (NativeOriginalOuterShellCore.ConquestList.itemHeight + NativeOriginalOuterShellCore.ConquestList.itemInterval)
        let rect = NativeRect(x: list.origin.x, y: y, width: list.size.width, height: NativeOriginalOuterShellCore.ConquestList.itemHeight)
        if let row = directSprite("image_menu_hd", "button_choosestage_conquest.png") {
            place(row, rect, z: index == selectedConquestCountry ? 6 : 5)
            row.alpha = index == selectedConquestCountry ? 1 : 0.9
            uiRoot.addChild(row)
        }
        if let flag = flagNode(country.code) {
            place(flag, NativeRect(x: rect.origin.x + 8, y: rect.origin.y + 10, width: 30, height: 22), z: 7)
            uiRoot.addChild(flag)
        }
        addLabel(country.nameCN ?? country.code.uppercased(), x: rect.origin.x + 43, y: rect.origin.y + 14, width: 100, height: 18, size: 8, light: false, bold: true, z: 7)
    }

    private func addConquestPreview(scenario: Int) {
        guard let meta = NativeOriginalOuterShellCore.conquestScenarios.first(where: { $0.index == scenario }) else { return }
        if let image = textureNode("tex_conquest_\(meta.textureYear).png") {
            place(image, NativeRect(x: 34, y: 64, width: 330, height: 124), z: 2)
            uiRoot.addChild(image)
        }
        addLabel(meta.location == "america" ? (strings["text2_american"] ?? "美洲") : (strings["text2_european"] ?? "欧洲"), x: 34, y: 196, width: 160, height: 20, size: 10, light: true, bold: true, z: 4)
        addLabel(meta.displayYear, x: 205, y: 196, width: 130, height: 20, size: 10, light: true, bold: true, center: true, z: 4)
        if conquestCountries.indices.contains(selectedConquestCountry) {
            let c = conquestCountries[selectedConquestCountry]
            if let flag = flagNode(c.code) {
                place(flag, NativeRect(x: 135, y: 230, width: 50, height: 34), z: 4)
                uiRoot.addChild(flag)
            }
            addLabel(c.nameCN ?? c.code.uppercased(), x: 195, y: 238, width: 150, height: 22, size: 10, light: true, bold: true, z: 4)
        }
    }

    private func addWideBackground() {
        if let bg = textureNode("campaign_wide.png") {
            place(bg, NativeRect(x: 0, y: 0, width: 568, height: 320), z: 0)
            uiRoot.addChild(bg)
        }
    }

    private func addTitleBar(_ title: String) {
        let bar = SKShapeNode(rect: CGRect(x: 0, y: -28, width: 568, height: 28))
        bar.fillColor = UIColor(red: 13 / 255, green: 19 / 255, blue: 19 / 255, alpha: 0.9)
        bar.strokeColor = .clear
        bar.zPosition = 20
        uiRoot.addChild(bar)
        addLabel(title, x: 0, y: 6, width: 568, height: 20, size: 13, light: true, bold: true, center: true, z: 21)
    }

    private func addBackButton() {
        if let back = directSprite("image_ui_hd", "button_back.png") {
            place(back, NativeRect(x: 3, y: 1, width: 31, height: 26), z: 30)
            back.name = "outer_back"
            uiRoot.addChild(back)
        }
    }

    private func addLoadButton() {
        if let load = directSprite("image_ui_hd", "button_load.png") {
            place(load, NativeRect(x: 532, y: 1, width: 31, height: 26), z: 30)
            load.name = "outer_load"
            uiRoot.addChild(load)
        }
    }

    private func addConfirmButton(rect: NativeRect, enabled: Bool) {
        let key = enabled ? "new_confirm.png" : "button_confrim_gray.png"
        if let button = directSprite("image_ui_hd", key) {
            place(button, rect, z: 12)
            button.alpha = enabled ? 1 : 0.66
            uiRoot.addChild(button)
        }
        addLabel(strings["text_confirm"] ?? "确定", x: rect.origin.x, y: rect.origin.y + 5, width: rect.size.width, height: 14, size: 8, light: true, bold: true, center: true, z: 13)
    }

    private func addStageStars(rating: Int, progress: Int, x: Double, y: Double) {
        for index in 0..<2 {
            let on = index == 0 ? progress >= 1 : rating >= 5
            let key = on ? "star_campaign.png" : "star_campaign_gray.png"
            if let star = directSprite("image_ui_hd", key) {
                place(star, NativeRect(x: x + Double(index * 11), y: y, width: 9, height: 9), z: 8)
                uiRoot.addChild(star)
            }
        }
    }

    private func addScrollHints(first: Int, count: Int, list: NativeRect) {
        guard count > visibleListSlots else { return }
        if first > 0 { addLabel("▲", x: list.origin.x + list.size.width - 18, y: list.origin.y + 2, width: 14, height: 14, size: 8, light: false, bold: true, center: true, z: 15) }
        if first + visibleListSlots < count { addLabel("▼", x: list.origin.x + list.size.width - 18, y: list.origin.y + list.size.height - 14, width: 14, height: 14, size: 8, light: false, bold: true, center: true, z: 15) }
    }

    private func clearUI() { uiRoot.removeAllChildren() }

    private func secretUnlocked(_ file: String) -> Bool {
        if NativeCampaignSessionCore.progressLevel(profile.document, file: file) > 0 { return true }
        if case .object(let secrets) = profile.document["campaignSecretUnlocks"], case .bool(true) = secrets[file] { return true }
        return false
    }

    private func battle(file: String) -> BattleRecord? { battles.first(where: { $0.file == file }) }

    private func introCommanderID(_ battle: BattleRecord) -> Int? {
        let owner = battle.playerOwnerDefault ?? 0
        return battle.units.first(where: { $0.owner == owner && ($0.commanderID ?? 0) > 0 })?.commanderID
            ?? battle.units.first(where: { ($0.commanderID ?? 0) > 0 })?.commanderID
    }

    private func launchCampaign(_ battle: BattleRecord) {
        let codes = NativeCampaignCore.selectableCountryCodes(battle)
        if codes.count >= 2 {
            showCampaignCountrySelector(base: battle, codes: codes)
            return
        }
        battleLaunchHandler?(BattleLaunch(file: battle.file, mode: .campaign, playerOwner: battle.playerOwnerDefault ?? 0))
    }

    private func confirmCampaignCountry(base: BattleRecord, codes: [String], selected: Int) {
        guard codes.indices.contains(selected), let variant = NativeCampaignCore.resolveVariant(baseBattle: base, countryCode: codes[selected], battles: battles) else { return }
        let owner = variant.battle.countries.first(where: { $0.code == variant.playerCode })?.index ?? variant.battle.playerOwnerDefault ?? 0
        battleLaunchHandler?(BattleLaunch(file: variant.battle.file, mode: .campaign, playerOwner: owner))
    }

    private func confirmConquestCountry(scenario: Int) {
        guard conquestCountries.indices.contains(selectedConquestCountry), let battle = battle(file: "conquest\(scenario).btl") else { return }
        battleLaunchHandler?(BattleLaunch(file: battle.file, mode: .conquest, playerOwner: conquestCountries[selectedConquestCountry].index))
    }

    private func handleTap(_ point: NativePoint) {
        if point.x <= 36 && point.y <= 30 {
            switch screen {
            case .campaignSelect, .conquestSelect: backToMainHandler?()
            case .campaignList: showCampaignSelection()
            case .campaignCountry(let base, _, _): showCampaignList(zone: NativeCampaignCore.stageNumber(NativeCampaignCore.canonicalFile(base))?.zone ?? 1)
            case .conquestCountries: showConquestSelection()
            }
            return
        }
        if point.x >= 530 && point.y <= 30, screenIsTopSelection { loadRequestedHandler?(); return }

        switch screen {
        case .campaignSelect:
            if let zone = campaignInfoZone {
                if NativeOriginalOuterShellCore.CampaignInfo.confirmContains(point, zone: zone) {
                    campaignInfoZone = nil
                    showCampaignList(zone: zone)
                    return
                }
                if case .campaignZone(let newZone) = NativeOriginalOuterShellCore.campaignSelectionAction(at: point) {
                    openCampaignInfo(zone: newZone)
                    return
                }
                if !NativeOriginalOuterShellCore.CampaignInfo.contains(point, zone: zone) { closeCampaignInfo() }
                return
            }
            if case .campaignZone(let zone) = NativeOriginalOuterShellCore.campaignSelectionAction(at: point) { openCampaignInfo(zone: zone) }
        case .conquestSelect:
            if case .conquestScenario(let scenario) = NativeOriginalOuterShellCore.conquestSelectionAction(at: point) { showConquestCountries(scenario: scenario) }
        case .campaignList(let zone):
            guard let action = NativeOriginalOuterShellCore.campaignListAction(at: point, firstVisibleRow: campaignFirstVisible, rowCount: campaignEntries.count) else { return }
            switch action {
            case .listRow(let row):
                if campaignEntries.indices.contains(row), campaignEntries[row].selectable { selectedCampaignRow = row; renderCampaignList(zone: zone) }
            case .listConfirm:
                if campaignEntries.indices.contains(selectedCampaignRow), campaignEntries[selectedCampaignRow].selectable { launchCampaign(campaignEntries[selectedCampaignRow].battle) }
            default: break
            }
        case .campaignCountry(let base, let codes, let selected):
            guard let action = NativeOriginalOuterShellCore.countrySelectionAction(at: point) else { return }
            switch action {
            case .countryLeft: showCampaignCountrySelector(base: base, codes: codes, selected: 0)
            case .countryRight: if codes.count > 1 { showCampaignCountrySelector(base: base, codes: codes, selected: 1) }
            case .countryClose: showCampaignList(zone: NativeCampaignCore.stageNumber(NativeCampaignCore.canonicalFile(base))?.zone ?? 1)
            case .countryConfirm: confirmCampaignCountry(base: base, codes: codes, selected: selected)
            default: break
            }
        case .conquestCountries(let scenario):
            guard let action = NativeOriginalOuterShellCore.conquestListAction(at: point, firstVisibleRow: conquestFirstVisible, rowCount: conquestCountries.count) else { return }
            switch action {
            case .listRow(let row): if conquestCountries.indices.contains(row) { selectedConquestCountry = row; renderConquestCountryList(scenario: scenario) }
            case .listConfirm: confirmConquestCountry(scenario: scenario)
            default: break
            }
        }
    }

    private var screenIsTopSelection: Bool {
        switch screen { case .campaignSelect, .conquestSelect: return true; default: return false }
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.count == 1, let touch = touches.first else { return }
        let p = touch.location(in: self)
        touchStart = NativePoint(x: p.x, y: EW4LogicalSpace.height - p.y)
        hasDragged = false
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let start = touchStart, let touch = touches.first else { return }
        let p = touch.location(in: self)
        let current = NativePoint(x: p.x, y: EW4LogicalSpace.height - p.y)
        let dy = current.y - start.y
        guard abs(dy) >= 28 else { return }
        switch screen {
        case .campaignList(let zone):
            let maxFirst = max(0, campaignEntries.count - visibleListSlots)
            let next = max(0, min(maxFirst, campaignFirstVisible + (dy < 0 ? 1 : -1)))
            if next != campaignFirstVisible { campaignFirstVisible = next; renderCampaignList(zone: zone) }
        case .conquestCountries(let scenario):
            let maxFirst = max(0, conquestCountries.count - visibleListSlots)
            let next = max(0, min(maxFirst, conquestFirstVisible + (dy < 0 ? 1 : -1)))
            if next != conquestFirstVisible { conquestFirstVisible = next; renderConquestCountryList(scenario: scenario) }
        default: break
        }
        touchStart = current
        hasDragged = true
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer { touchStart = nil; hasDragged = false }
        guard !hasDragged, let touch = touches.first else { return }
        let p = touch.location(in: self)
        handleTap(NativePoint(x: p.x, y: EW4LogicalSpace.height - p.y))
    }

    private func textureNode(_ file: String) -> SKSpriteNode? {
        guard let image = UIImage(contentsOfFile: store.url("Textures", file).path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func directSprite(_ folder: String, _ file: String) -> SKSpriteNode? {
        guard let image = UIImage(contentsOfFile: store.url("Sprites/\(folder)", file).path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func flagNode(_ code: String) -> SKSpriteNode? { directSprite("image_flag_hd", "\(code)1.png") }

    private func portraitNode(_ commanderName: String) -> SKSpriteNode? {
        let candidates = [commanderName, commanderName.replacingOccurrences(of: " ", with: ".")]
        for name in candidates {
            for ext in ["webp", "png"] {
                let url = store.url("Portraits", "\(name).\(ext)")
                if let image = UIImage(contentsOfFile: url.path)?.cgImage { return SKSpriteNode(texture: SKTexture(cgImage: image)) }
            }
        }
        return nil
    }

    private func place(_ node: SKSpriteNode, _ rect: NativeRect, z: CGFloat) {
        node.anchorPoint = CGPoint(x: 0, y: 1)
        node.position = CGPoint(x: rect.origin.x, y: -rect.origin.y)
        node.size = CGSize(width: rect.size.width, height: rect.size.height)
        node.zPosition = z
    }

    private func placeLocal(_ node: SKSpriteNode, _ rect: NativeRect, z: CGFloat) {
        node.anchorPoint = CGPoint(x: 0, y: 1)
        node.position = CGPoint(x: rect.origin.x, y: -rect.origin.y)
        node.size = CGSize(width: rect.size.width, height: rect.size.height)
        node.zPosition = z
    }

    private func addLabel(_ text: String, x: Double, y: Double, width: Double, height: Double, size: CGFloat, light: Bool, bold: Bool, center: Bool = false, z: CGFloat = 10) {
        let label = SKLabelNode(fontNamed: bold ? "PingFangSC-Semibold" : "PingFangSC-Regular")
        label.text = text
        label.fontSize = size
        label.fontColor = light ? UIColor(red: 242 / 255, green: 234 / 255, blue: 214 / 255, alpha: 1) : UIColor(red: 78 / 255, green: 71 / 255, blue: 62 / 255, alpha: 1)
        label.horizontalAlignmentMode = center ? .center : .left
        label.verticalAlignmentMode = .top
        label.position = CGPoint(x: center ? x + width / 2 : x, y: -y)
        label.zPosition = z
        uiRoot.addChild(label)
    }

    private func addLocalLabel(_ text: String, rect: NativeRect, size: CGFloat, root: SKNode, center: Bool = false, bold: Bool = false, light: Bool = false) {
        let label = SKLabelNode(fontNamed: bold ? "PingFangSC-Semibold" : "PingFangSC-Regular")
        label.text = text
        label.fontSize = size
        label.fontColor = light ? UIColor(red: 242 / 255, green: 234 / 255, blue: 214 / 255, alpha: 1) : UIColor(red: 78 / 255, green: 71 / 255, blue: 62 / 255, alpha: 1)
        label.horizontalAlignmentMode = center ? .center : .left
        label.verticalAlignmentMode = .top
        label.position = CGPoint(x: center ? rect.origin.x + rect.size.width / 2 : rect.origin.x, y: -rect.origin.y)
        label.zPosition = 8
        root.addChild(label)
    }

    private func addMultilineLabel(_ text: String, x: Double, y: Double, width: Double, height: Double, size: CGFloat, z: CGFloat) {
        let label = SKLabelNode(fontNamed: "PingFangSC-Regular")
        label.text = text
        label.fontSize = size
        label.fontColor = UIColor(red: 81 / 255, green: 75 / 255, blue: 66 / 255, alpha: 1)
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .top
        label.numberOfLines = 5
        label.preferredMaxLayoutWidth = width
        label.lineBreakMode = .byTruncatingTail
        label.position = CGPoint(x: x, y: -y)
        label.zPosition = z
        uiRoot.addChild(label)
    }
}
#endif
