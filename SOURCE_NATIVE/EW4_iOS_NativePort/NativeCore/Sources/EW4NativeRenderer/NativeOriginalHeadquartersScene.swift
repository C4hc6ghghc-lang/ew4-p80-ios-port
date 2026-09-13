#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

/// Native binding for the original main-menu Headquarters route.
/// It reuses the recovered `form_deploygeneral` geometry in HQ context and does
/// not expose battle-only commander assignment from the main menu.
public final class NativeOriginalHeadquartersScene: SKScene {
    public var backHandler: (() -> Void)?
    public var shopHandler: (() -> Void)?
    public var academyHandler: (() -> Void)?
    public var equipmentHandler: ((Int) -> Void)?
    public var upgradeHandler: ((Int) -> Void)?
    public var regroupHandler: ((Int) -> Void)?
    public var dismissHandler: ((Int) -> Void)?
    public var statusHandler: ((String) -> Void)?

    private enum Overlay: Equatable {
        case none
        case princess
        case general(Int)
    }

    private let store: NativeResourceStore
    private let profile: NativePlayerProfile
    private let commanders: [Int: Commander]
    private let portraits: [String: String]
    private let items: NativeItemEffectCatalog
    private let strings: [String: String]
    private let generalOverrides: NativePlayerGeneralOverrides
    private let princessOverrides: NativePlayerPrincessOverrides
    private let generalIDs: [Int]

    private let root = SKNode()
    private let gridCrop = SKCropNode()
    private let gridContent = SKNode()
    private let overlayLayer = SKNode()
    private var overlay: Overlay = .none
    private var scroll = 0.0
    private var touchStartY = 0.0
    private var scrollStart = 0.0
    private var touchBeganInGrid = false
    private var dragged = false

    public init(store: NativeResourceStore, profile: NativePlayerProfile) throws {
        self.store = store
        self.profile = profile
        self.commanders = try store.commanders()
        self.portraits = try store.portraitManifest()
        self.items = try store.items()
        self.strings = try store.stringsCN()
        self.generalOverrides = try store.playerGeneralOverrides()
        self.princessOverrides = try store.playerPrincessOverrides()
        self.generalIDs = NativeHeadquartersCore.ownedGeneralIDs(profile: profile, commanders: commanders)
        super.init(size: CGSize(width: EW4LogicalSpace.width, height: EW4LogicalSpace.height))
        scaleMode = .aspectFit
        anchorPoint = CGPoint(x: 0, y: 0)
        backgroundColor = .black
        root.position = CGPoint(x: 0, y: EW4LogicalSpace.height)
        addChild(root)
        renderBase()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func renderBase() {
        if let bg = textureNode("campaign_wide.png") {
            place(bg, NativeRect(x: 0, y: 0, width: 568, height: 320), z: 0)
            root.addChild(bg)
        }

        if let back = directSprite("image_ui_hd", "button_back.png") {
            place(back, NativeHeadquartersCore.backButton, z: 8)
            root.addChild(back)
        }

        addShortcut(rect: NativeHeadquartersCore.princessButton, label: strings["btn_princess"] ?? "公主", blue: false)
        addShortcut(rect: NativeHeadquartersCore.shopButton, label: "商　店", blue: true)
        addShortcut(rect: NativeHeadquartersCore.academyButton, label: strings["btn_college"] ?? "军事学院", blue: false)

        if let count = directSprite("image_ui_hd", "generalnumber.png") {
            place(count, NativeHeadquartersCore.countIcon, z: 5)
            root.addChild(count)
        }
        addLabel("\(generalIDs.count)", rect: NativeRect(x: 290, y: 43, width: 60, height: 21), size: 10, color: ui(64, 59, 53), z: 6, alignment: .left)

        addLine(y: 73)
        addLine(y: 298)

        let mask = SKShapeNode(rect: CGRect(
            x: NativeHeadquartersCore.generalGrid.origin.x,
            y: -(NativeHeadquartersCore.generalGrid.origin.y + NativeHeadquartersCore.generalGrid.size.height),
            width: NativeHeadquartersCore.generalGrid.size.width,
            height: NativeHeadquartersCore.generalGrid.size.height
        ))
        mask.fillColor = .white
        mask.strokeColor = .clear
        gridCrop.maskNode = mask
        gridCrop.zPosition = 4
        root.addChild(gridCrop)
        gridCrop.addChild(gridContent)
        renderGrid()

        if let pattern = directSprite("image_ui_hd", "pattern_bg_bottom.png") {
            place(pattern, NativeRect(x: 230, y: 303, width: 108, height: 14), z: 4)
            root.addChild(pattern)
        }
        if let disabledDeploy = directSprite("image_ui_hd", "button_confirm_blue.png") {
            place(disabledDeploy, NativeHeadquartersCore.deployButton, z: 4)
            disabledDeploy.alpha = 0.35
            root.addChild(disabledDeploy)
        }

        overlayLayer.zPosition = 100
        root.addChild(overlayLayer)
    }

    private func addShortcut(rect: NativeRect, label: String, blue: Bool) {
        let file = blue ? "btn_common_blue.png" : "btn_common_green.png"
        if let button = directSprite("image_ui_hd", file) {
            place(button, rect, z: 4)
            root.addChild(button)
        }
        addLabel(label, rect: rect, size: 9, color: ui(247, 237, 218), z: 5)
    }

    private func addLine(y: Double) {
        if let line = directSprite("image_ui_hd", "common_boldline.png") {
            place(line, NativeRect(x: 0, y: y, width: 568, height: 1), z: 3)
            root.addChild(line)
        }
    }

    private func renderGrid() {
        gridContent.removeAllChildren()
        for (index, id) in generalIDs.enumerated() {
            guard let commander = commanders[id] else { continue }
            let rect = NativeHeadquartersCore.cardRect(index: index, scroll: scroll)
            let frameRect = NativeRect(x: rect.origin.x + 10, y: rect.origin.y, width: 58, height: 79)
            if let frame = directSprite("image_ui_hd", "board_smallgenerals.png") {
                place(frame, frameRect, z: 1)
                gridContent.addChild(frame)
            }
            if let portrait = portraitNode(id: id) {
                place(portrait, NativeRect(x: frameRect.origin.x + 7, y: frameRect.origin.y + 5, width: 44, height: 55), z: 2)
                gridContent.addChild(portrait)
            }
            addLabel(commander.name, rect: NativeRect(x: rect.origin.x + 1, y: rect.origin.y + 80, width: 76, height: 12), size: 7, color: ui(64, 58, 50), z: 3, parent: gridContent)
            let stars = String(repeating: "★", count: max(1, min(6, commander.star)))
            addLabel(stars, rect: NativeRect(x: rect.origin.x, y: rect.origin.y + 91, width: 78, height: 8), size: 6, color: ui(184, 121, 23), z: 3, parent: gridContent)
            if let upgrade = directSprite("image_ui_hd", "button_rank.png") {
                place(upgrade, NativeHeadquartersCore.upgradeHotspotRect(index: index, scroll: scroll), z: 5)
                gridContent.addChild(upgrade)
            }
        }
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard overlay == .none, let touch = touches.first else { return }
        let p = nativePoint(touch.location(in: self))
        touchStartY = p.y
        scrollStart = scroll
        touchBeganInGrid = contains(NativeHeadquartersCore.generalGrid, p)
        dragged = false
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard overlay == .none, touchBeganInGrid, let touch = touches.first else { return }
        let p = nativePoint(touch.location(in: self))
        let delta = touchStartY - p.y
        if abs(delta) > 3 { dragged = true }
        let next = NativeHeadquartersCore.clampedScroll(scrollStart + delta, count: generalIDs.count)
        if abs(next - scroll) > 0.1 {
            scroll = next
            renderGrid()
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = nativePoint(touch.location(in: self))
        switch overlay {
        case .princess:
            if contains(NativeRect(x: 501, y: 2, width: 25, height: 25), point) { hideOverlay() }
            return
        case .general(let id):
            if contains(NativeRect(x: 487, y: 43, width: 25, height: 25), point) { hideOverlay(); return }
            if contains(NativeRect(x: 253, y: 84, width: 83, height: 31), point) { regroupHandler?(id); return }
            if contains(NativeRect(x: 253, y: 119, width: 83, height: 31), point) { equipmentHandler?(id); return }
            if contains(NativeRect(x: 78, y: 231, width: 54, height: 20), point) { dismissHandler?(id); return }
            return
        case .none: break
        }
        defer {
            touchBeganInGrid = false
            dragged = false
        }
        if dragged { return }
        for index in generalIDs.indices {
            let hotspot = NativeHeadquartersCore.upgradeHotspotRect(index: index, scroll: NativeHeadquartersCore.clampedScroll(scroll, count: generalIDs.count))
            if contains(hotspot, point), contains(NativeHeadquartersCore.generalGrid, point) {
                upgradeHandler?(generalIDs[index])
                return
            }
        }
        guard let action = NativeHeadquartersCore.action(at: point, generalCount: generalIDs.count, scroll: scroll) else { return }
        switch action {
        case .back: backHandler?()
        case .princess: showPrincesses()
        case .shop: shopHandler?()
        case .academy: academyHandler?()
        case .generalAt(let index):
            guard generalIDs.indices.contains(index) else { return }
            showGeneral(id: generalIDs[index])
        }
    }

    private func showPrincesses() {
        overlay = .princess
        overlayLayer.removeAllChildren()
        addDimmer()
        addPanel(NativeHeadquartersCore.princessPanel, title: "公　主")
        addClose(rect: NativeRect(x: 501, y: 2, width: 25, height: 25))
        for (index, id) in NativeHeadquartersCore.princessOrder.enumerated() {
            guard let commander = commanders[id] else { continue }
            let rect = NativeHeadquartersCore.princessRect(index: index)
            if let portrait = portraitNode(id: id) {
                place(portrait, NativeRect(x: rect.origin.x + 4, y: rect.origin.y, width: 70, height: 78), z: 104)
                overlayLayer.addChild(portrait)
            }
            if let board = directSprite("image_ui_hd", "general_nameboard.png") {
                place(board, NativeRect(x: rect.origin.x + 1.5, y: rect.origin.y + 79, width: 75, height: 15), z: 104)
                overlayLayer.addChild(board)
            }
            addLabel(commander.name, rect: NativeRect(x: rect.origin.x, y: rect.origin.y + 79, width: 78, height: 16), size: 7, color: ui(73, 67, 58), z: 105, parent: overlayLayer)
            if let owned = directSprite("image_ui_hd", "button_confirm_blue.png") {
                place(owned, NativeRect(x: rect.origin.x + 11, y: rect.origin.y + 100, width: 55, height: 22), z: 104)
                owned.alpha = 0.45
                overlayLayer.addChild(owned)
            }
            addLabel("已拥有", rect: NativeRect(x: rect.origin.x + 11, y: rect.origin.y + 100, width: 55, height: 22), size: 7, color: ui(246, 236, 212), z: 105, parent: overlayLayer)
        }
        statusHandler?("HQ Princess · 8/8")
    }

    private func showGeneral(id: Int) {
        guard let raw = commanders[id] else { return }
        overlay = .general(id)
        overlayLayer.removeAllChildren()
        addDimmer()
        let panel = NativeRect(x: 64, y: 51, width: 440, height: 217)
        addPanel(panel, title: strings["title_headquarters"] ?? "指挥部")
        addClose(rect: NativeRect(x: 487, y: 43, width: 25, height: 25))

        if let portrait = portraitNode(id: id) {
            place(portrait, NativeRect(x: 70, y: 81, width: 70, height: 75), z: 104)
            overlayLayer.addChild(portrait)
        }
        if let nameboard = directSprite("image_ui_hd", "general_nameboard.png") {
            place(nameboard, NativeRect(x: 67, y: 142, width: 75, height: 15), z: 104)
            overlayLayer.addChild(nameboard)
        }
        addLabel(raw.name, rect: NativeRect(x: 66, y: 142, width: 78, height: 15), size: 7, color: ui(73, 67, 58), z: 105, parent: overlayLayer)
        addLabel(raw.country.uppercased(), rect: NativeRect(x: 66, y: 158, width: 78, height: 12), size: 6, color: ui(90, 83, 73), z: 105, parent: overlayLayer)

        let effective = NativePlayerProfileCore.effectiveCommander(
            raw: raw,
            playerControlled: true,
            profile: profile,
            generalOverrides: generalOverrides,
            princessOverrides: princessOverrides
        )
        let growth = NativePlayerProfileCore.generalGrowthState(profile: profile, raw: raw)
        addBox(NativeRect(x: 146, y: 81, width: 194, height: 74), title: strings["text_equipitem"] ?? "装备")
        addBox(NativeRect(x: 342, y: 81, width: 160, height: 74), title: "技　能")
        addBox(NativeRect(x: 146, y: 157, width: 356, height: 109), title: nil)
        addBox(NativeRect(x: 66, y: 170, width: 78, height: 85), title: nil)

        let equipmentPair = NativeHeadquartersManagementCore.equipmentPair(profile: profile, commander: raw)
        for slot in 0..<2 {
            let rect = NativeRect(x: 151 + Double(slot) * 50, y: 105, width: 45, height: 43)
            let box = shape(rect, fill: ui(199, 192, 180), stroke: ui(128, 120, 108), width: 1); box.zPosition = 104; overlayLayer.addChild(box)
            if let iid = equipmentPair[slot], let item = items[String(iid)] ?? items.values.first(where: { $0.id == iid }), let icon = itemNode(item) {
                place(icon, NativeRect(x: rect.origin.x + 7, y: rect.origin.y + 5, width: 31, height: 31), z: 105); overlayLayer.addChild(icon)
            }
        }
        addManagementButton(NativeRect(x: 253, y: 84, width: 83, height: 31), title: strings["btn_regroup"] ?? "整编", blue: false)
        addManagementButton(NativeRect(x: 253, y: 119, width: 83, height: 31), title: strings["btn_equip"] ?? "装备", blue: true)
        if !NativePlayerProfile.princessIDs.contains(id) { addManagementButton(NativeRect(x: 78, y: 231, width: 54, height: 20), title: "解　雇", blue: false) }
        let skills = raw.skillIDs.sorted().union(Array(effective.skillIDs.subtracting(raw.skillIDs)).sorted())
        addLabel(skills.isEmpty ? "—" : skills.prefix(4).map { "技能 \($0 + 1)" }.joined(separator: "\n"), rect: NativeRect(x: 347, y: 105, width: 150, height: 44), size: 6, color: ui(74, 68, 59), z: 105, parent: overlayLayer, lines: 4)

        addLabel("军衔 \(growth.rank)\n进度 \(growth.militaryProgress)\n爵位 \(growth.nobility)\n进度 \(growth.nobilityProgress)", rect: NativeRect(x: 69, y: 178, width: 72, height: 68), size: 5.5, color: ui(74, 68, 59), z: 105, parent: overlayLayer, lines: 4)

        let stats: [(String, Int)] = [
            (strings["btn_infantry"] ?? "步兵", effective.infantry), (strings["btn_cavalry"] ?? "骑兵", effective.cavalry),
            (strings["btn_artillery"] ?? "炮兵", effective.artillery), (strings["btn_navy"] ?? "海军", effective.warship),
            (strings["btn_fortress"] ?? "要塞", effective.fort), (strings["text_economy"] ?? "经济", effective.business),
            ("行军", effective.movement), ("训练", effective.training),
        ]
        for (index, value) in stats.enumerated() {
            let col = index % 2, row = index / 2
            let rect = NativeRect(x: 146 + Double(col) * 178, y: 157 + Double(row) * 27, width: 178, height: 27)
            addLabel("\(value.0)    \(value.1)", rect: rect, size: 7, color: ui(74, 68, 59), z: 105, parent: overlayLayer, alignment: .center)
        }
        statusHandler?("HQ General · \(raw.name)")
    }


    private func addManagementButton(_ rect: NativeRect, title: String, blue: Bool) {
        let file = blue ? "btn_common_blue.png" : "btn_common_green.png"
        if let button = directSprite("image_ui_hd", file) { place(button, rect, z: 106); overlayLayer.addChild(button) }
        addLabel(title, rect: rect, size: 7, color: ui(247, 237, 218), z: 107, parent: overlayLayer)
    }

    private func itemNode(_ item: NativeItemEffectDefinition) -> SKSpriteNode? {
        let file = item.name.replacingOccurrences(of: " ", with: "_") + ".png"
        guard let image = UIImage(contentsOfFile: store.url("Items", file).path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func hideOverlay() {
        overlay = .none
        overlayLayer.removeAllChildren()
        statusHandler?("Native Headquarters")
    }

    private func addDimmer() {
        let dim = SKShapeNode(rect: CGRect(x: 0, y: -320, width: 568, height: 320))
        dim.fillColor = UIColor(white: 0, alpha: 0.34)
        dim.strokeColor = .clear
        dim.zPosition = 100
        overlayLayer.addChild(dim)
    }

    private func addPanel(_ rect: NativeRect, title: String) {
        let panel = shape(rect, fill: ui(222, 216, 203), stroke: ui(113, 106, 93), width: 1)
        panel.zPosition = 101
        overlayLayer.addChild(panel)
        let header = shape(NativeRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: 28), fill: ui(220, 211, 195), stroke: ui(129, 119, 105), width: 1)
        header.zPosition = 102
        overlayLayer.addChild(header)
        addLabel(title, rect: NativeRect(x: rect.origin.x, y: rect.origin.y + 4, width: rect.size.width, height: 20), size: 10, color: ui(81, 75, 65), z: 103, parent: overlayLayer)
    }

    private func addClose(rect: NativeRect) {
        if let node = directSprite("image_ui_hd", "button_close.png") {
            place(node, rect, z: 110)
            overlayLayer.addChild(node)
        }
    }

    private func addBox(_ rect: NativeRect, title: String?) {
        let box = shape(rect, fill: .clear, stroke: ui(131, 123, 112), width: 1)
        box.zPosition = 103
        overlayLayer.addChild(box)
        if let title {
            addLabel(title, rect: NativeRect(x: rect.origin.x, y: rect.origin.y + 1, width: rect.size.width, height: 20), size: 7, color: ui(101, 93, 82), z: 105, parent: overlayLayer)
        }
    }

    private func shape(_ rect: NativeRect, fill: UIColor, stroke: UIColor, width: CGFloat) -> SKShapeNode {
        let node = SKShapeNode(rect: CGRect(x: rect.origin.x, y: -(rect.origin.y + rect.size.height), width: rect.size.width, height: rect.size.height))
        node.fillColor = fill
        node.strokeColor = stroke
        node.lineWidth = width
        return node
    }

    private func portraitNode(id: Int) -> SKSpriteNode? {
        guard let raw = portraits[String(id)] else { return nil }
        let file = URL(fileURLWithPath: raw).lastPathComponent
        guard let image = UIImage(contentsOfFile: store.url("Portraits", file).path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func textureNode(_ file: String) -> SKSpriteNode? {
        guard let image = UIImage(contentsOfFile: store.url("Textures", file).path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func directSprite(_ folder: String, _ file: String) -> SKSpriteNode? {
        guard let image = UIImage(contentsOfFile: store.url("Sprites/\(folder)", file).path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func place(_ node: SKSpriteNode, _ rect: NativeRect, z: CGFloat) {
        node.anchorPoint = CGPoint(x: 0, y: 1)
        node.position = CGPoint(x: rect.origin.x, y: -rect.origin.y)
        node.size = CGSize(width: rect.size.width, height: rect.size.height)
        node.zPosition = z
    }

    private func addLabel(
        _ text: String,
        rect: NativeRect,
        size: CGFloat,
        color: UIColor,
        z: CGFloat,
        parent: SKNode? = nil,
        alignment: SKLabelHorizontalAlignmentMode = .center,
        lines: Int = 1
    ) {
        if lines > 1 || text.contains("\n") {
            let parts = text.split(separator: "\n", omittingEmptySubsequences: false)
            let count = max(1, min(lines, parts.count))
            let h = rect.size.height / Double(count)
            for i in 0..<count {
                addLabel(String(parts[i]), rect: NativeRect(x: rect.origin.x, y: rect.origin.y + Double(i) * h, width: rect.size.width, height: h), size: size, color: color, z: z, parent: parent, alignment: alignment)
            }
            return
        }
        let label = SKLabelNode(fontNamed: "PingFangSC-Semibold")
        label.text = text
        label.fontSize = size
        label.fontColor = color
        label.horizontalAlignmentMode = alignment
        label.verticalAlignmentMode = .center
        let x: Double
        switch alignment {
        case .left: x = rect.origin.x
        case .right: x = rect.origin.x + rect.size.width
        default: x = rect.origin.x + rect.size.width / 2
        }
        label.position = CGPoint(x: x, y: -(rect.origin.y + rect.size.height / 2))
        label.zPosition = z
        (parent ?? root).addChild(label)
    }

    private func nativePoint(_ p: CGPoint) -> NativePoint {
        NativePoint(x: p.x, y: EW4LogicalSpace.height - p.y)
    }

    private func contains(_ rect: NativeRect, _ point: NativePoint) -> Bool {
        point.x >= rect.origin.x && point.y >= rect.origin.y && point.x <= rect.origin.x + rect.size.width && point.y <= rect.origin.y + rect.size.height
    }

    private func ui(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 255) -> UIColor {
        UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: a / 255)
    }
}

private extension Array where Element == Int {
    func union(_ other: [Int]) -> [Int] {
        Array(Set(self).union(other)).sorted()
    }
}
#endif
