#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

final class NativeOriginalDefenseRenderer {
    enum Kind { case installation, fortress }
    enum Action: Equatable { case close, confirm, select(Int), none }

    private weak var parent: SKNode?
    private let store: NativeResourceStore
    private let strings: [String: String]
    private var root: SKNode?
    private var rows: [Int: NativeRect] = [:]
    private(set) var kind: Kind = .installation
    private var choices: [NativeDefenseChoice] = []
    private var resources = CountryResources(money: 0, industry: 0, food: 0)
    private(set) var selectedRow = 0
    private let geometry = NativeOriginalFormGeometryCore.Defense.self

    init(parent: SKNode, store: NativeResourceStore) {
        self.parent = parent
        self.store = store
        self.strings = (try? store.stringsCN()) ?? [:]
    }

    var isVisible: Bool { root != nil }

    func hide() {
        root?.removeFromParent()
        root = nil
        rows.removeAll()
    }

    func show(kind: Kind, choices: [NativeDefenseChoice], resources: CountryResources, resetSelection: Bool = true) {
        self.kind = kind
        self.choices = choices
        self.resources = resources
        if resetSelection { selectedRow = 0 }
        render()
    }

    func select(row: Int) {
        guard choices.indices.contains(row) else { return }
        selectedRow = row
        render()
    }

    func selectedChoice() -> NativeDefenseChoice? {
        choices.indices.contains(selectedRow) ? choices[selectedRow] : nil
    }

    func rect(alias: String, row: Int?) -> NativeRect? {
        if alias == "lbox_defense", let row { return rows[row] }
        if alias == "winbtn_close" { return geometry.closeButton }
        if alias == "winbtn_ok" { return geometry.okButton }
        return nil
    }

    func action(at p: NativePoint) -> Action {
        if contains(geometry.closeButton, p) { return .close }
        if contains(geometry.okButton, p) { return .confirm }
        for (i, r) in rows where contains(r, p) { return .select(i) }
        return .none
    }

    private func render() {
        hide()
        guard let parent, !choices.isEmpty else { return }

        let root = SKNode()
        root.position = CGPoint(x: 0, y: EW4LogicalSpace.height)
        root.zPosition = 25_000

        let dim = SKShapeNode(rect: CGRect(x: 0, y: -EW4LogicalSpace.height, width: EW4LogicalSpace.width, height: EW4LogicalSpace.height))
        dim.fillColor = UIColor(white: 0, alpha: 0.42)
        dim.strokeColor = .clear
        root.addChild(dim)

        root.addChild(shape(geometry.screenFrame, ui(231, 224, 210), ui(104, 94, 80)))
        root.addChild(shape(
            NativeRect(x: geometry.screenFrame.origin.x, y: geometry.screenFrame.origin.y, width: geometry.screenFrame.size.width, height: 27),
            ui(214, 204, 187), ui(124, 112, 95)
        ))
        label(
            kind == .installation ? (strings["title_defense"] ?? "防  御") : (strings["title_fortress"] ?? "要  塞"),
            NativeRect(x: geometry.screenFrame.origin.x, y: geometry.screenFrame.origin.y + 3, width: geometry.screenFrame.size.width, height: 20),
            11, ui(75, 68, 58), 4, root
        )

        if let n = sprite("image_ui_hd", "button_close.png") {
            place(n, geometry.closeButton, 8)
            root.addChild(n)
        }
        if let n = sprite("image_ui_hd", "button_confrim.png") ?? sprite("image_ui_hd", "new_confirm.png") {
            place(n, geometry.okButton, 8)
            root.addChild(n)
        }

        for i in choices.indices {
            let r = geometry.itemRect(index: i)
            rows[i] = r
            let choice = choices[i]
            let card = SKNode()
            card.alpha = resources.money >= choice.money && resources.industry >= choice.industry ? 1 : 0.42

            if let art = NativeOriginalDefenseArtCore.art(for: choice.key), let image = sprite(art.folder, art.fileName) {
                placeAspectFit(image, translated(geometry.itemImage, inside: r), 5)
                card.addChild(image)
            }

            label(
                strings["name_\(choice.key)"] ?? choice.key,
                translated(geometry.itemName, inside: r),
                5.6, ui(68, 61, 52), 5, card
            )

            let cost = translated(geometry.itemCost, inside: r)
            if let money = sprite("image_ui_hd", "marker_money.png") {
                place(money, NativeRect(x: cost.origin.x + 4, y: cost.origin.y + 2, width: 9, height: 9), 5)
                card.addChild(money)
            }
            label(
                "\(choice.money)",
                NativeRect(x: cost.origin.x + 14, y: cost.origin.y, width: 19, height: cost.size.height),
                4.8, ui(68, 61, 52), 5, card
            )
            if let industry = sprite("image_ui_hd", "marker_industry.png") {
                place(industry, NativeRect(x: cost.origin.x + 36, y: cost.origin.y + 2, width: 9, height: 9), 5)
                card.addChild(industry)
            }
            label(
                "\(choice.industry)",
                NativeRect(x: cost.origin.x + 46, y: cost.origin.y, width: 20, height: cost.size.height),
                4.8, ui(68, 61, 52), 5, card
            )

            if i == selectedRow, let selection = sprite("image_ui_hd", "item_selected_ex.png") {
                place(selection, r, 7)
                card.addChild(selection)
            }
            root.addChild(card)
        }

        if let choice = selectedChoice() {
            let d = geometry.descriptionScreen
            root.addChild(shape(d, ui(224, 216, 201), ui(125, 114, 96)))
            label(strings["name_\(choice.key)"] ?? choice.key, NativeRect(x: d.origin.x + 3, y: d.origin.y + 8, width: d.size.width - 6, height: 18), 7, ui(70, 63, 54), 4, root)
            label(strings["desc_\(choice.key)"] ?? "", NativeRect(x: d.origin.x + 3, y: d.origin.y + 38, width: d.size.width - 6, height: 18), 6.2, ui(70, 63, 54), 4, root)
        }

        parent.addChild(root)
        self.root = root
    }

    private func translated(_ local: NativeRect, inside item: NativeRect) -> NativeRect {
        NativeRect(x: item.origin.x + local.origin.x, y: item.origin.y + local.origin.y, width: local.size.width, height: local.size.height)
    }

    private func sprite(_ folder: String, _ name: String) -> SKSpriteNode? {
        guard let image = UIImage(contentsOfFile: store.url("Sprites/\(folder)", name).path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func shape(_ r: NativeRect, _ fill: UIColor, _ stroke: UIColor) -> SKShapeNode {
        let n = SKShapeNode(rect: CGRect(x: r.origin.x, y: -(r.origin.y + r.size.height), width: r.size.width, height: r.size.height))
        n.fillColor = fill
        n.strokeColor = stroke
        n.lineWidth = 1
        return n
    }

    private func place(_ n: SKSpriteNode, _ r: NativeRect, _ z: CGFloat) {
        n.anchorPoint = CGPoint(x: 0, y: 1)
        n.position = CGPoint(x: r.origin.x, y: -r.origin.y)
        n.size = CGSize(width: r.size.width, height: r.size.height)
        n.zPosition = z
    }

    private func placeAspectFit(_ n: SKSpriteNode, _ r: NativeRect, _ z: CGFloat) {
        let source = n.texture?.size() ?? .zero
        guard source.width > 0, source.height > 0 else {
            place(n, r, z)
            return
        }
        let scale = min(CGFloat(r.size.width) / source.width, CGFloat(r.size.height) / source.height)
        let width = source.width * scale
        let height = source.height * scale
        n.anchorPoint = CGPoint(x: 0, y: 1)
        n.position = CGPoint(x: CGFloat(r.origin.x) + (CGFloat(r.size.width) - width) / 2, y: -CGFloat(r.origin.y) - (CGFloat(r.size.height) - height) / 2)
        n.size = CGSize(width: width, height: height)
        n.zPosition = z
    }

    private func label(_ s: String, _ r: NativeRect, _ fs: CGFloat, _ c: UIColor, _ z: CGFloat, _ p: SKNode) {
        let n = SKLabelNode(fontNamed: "PingFangSC-Semibold")
        n.text = s
        n.fontSize = fs
        n.fontColor = c
        n.horizontalAlignmentMode = .center
        n.verticalAlignmentMode = .center
        n.position = CGPoint(x: r.origin.x + r.size.width / 2, y: -(r.origin.y + r.size.height / 2))
        n.zPosition = z
        p.addChild(n)
    }

    private func contains(_ r: NativeRect, _ p: NativePoint) -> Bool {
        p.x >= r.origin.x && p.y >= r.origin.y && p.x <= r.origin.x + r.size.width && p.y <= r.origin.y + r.size.height
    }

    private func ui(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 255) -> UIColor {
        UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: a / 255)
    }
}
#endif
