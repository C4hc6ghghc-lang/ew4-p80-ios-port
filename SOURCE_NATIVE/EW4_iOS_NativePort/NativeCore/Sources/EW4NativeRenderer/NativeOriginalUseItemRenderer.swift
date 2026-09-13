#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

final class NativeOriginalUseItemRenderer {
    enum Action: Equatable { case close, confirm, select(Int), none }

    private weak var parent: SKNode?
    private let store: NativeResourceStore
    private let strings: [String: String]
    private var root: SKNode?
    private var rows: [Int: NativeRect] = [:]
    private var items: [NativeItemEffectDefinition] = []
    private var unit: NativeBattleUnitState?
    private var round = 1
    private(set) var selectedRow = 0
    private let ids = [11, 12, 13, 14, 15]

    private let geometry = NativeOriginalFormGeometryCore.UseItem.self

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

    func show(catalog: NativeItemEffectCatalog, unit: NativeBattleUnitState, round: Int, resetSelection: Bool = true) {
        items = ids.compactMap { catalog[String($0)] }
        self.unit = unit
        self.round = round
        if resetSelection { selectedRow = 0 }
        render()
    }

    func select(row: Int) {
        guard items.indices.contains(row) else { return }
        selectedRow = row
        render()
    }

    func selectedItem() -> NativeItemEffectDefinition? {
        items.indices.contains(selectedRow) ? items[selectedRow] : nil
    }

    func rect(alias: String, row: Int?) -> NativeRect? {
        if alias == "lbox_item", let row { return rows[row] }
        if alias == "winbtn_close" { return geometry.closeButton }
        if alias == "winbtn_ok" { return geometry.okButton }
        return nil
    }

    func action(at point: NativePoint) -> Action {
        if contains(geometry.closeButton, point) { return .close }
        if contains(geometry.okButton, point) { return .confirm }
        for (index, rect) in rows where contains(rect, point) { return .select(index) }
        return .none
    }

    private func render() {
        hide()
        guard let parent, let unit else { return }

        let root = SKNode()
        root.position = CGPoint(x: 0, y: EW4LogicalSpace.height)
        root.zPosition = 25_000

        let dim = SKShapeNode(rect: CGRect(x: 0, y: -EW4LogicalSpace.height, width: EW4LogicalSpace.width, height: EW4LogicalSpace.height))
        dim.fillColor = UIColor(white: 0, alpha: 0.4)
        dim.strokeColor = .clear
        root.addChild(dim)

        root.addChild(shape(geometry.screenFrame, ui(231, 224, 210), ui(104, 94, 80)))
        root.addChild(shape(
            NativeRect(x: geometry.screenFrame.origin.x, y: geometry.screenFrame.origin.y, width: geometry.screenFrame.size.width, height: 27),
            ui(214, 204, 187), ui(124, 112, 95)
        ))
        label(strings["title_useitem"] ?? "物   品", NativeRect(x: geometry.screenFrame.origin.x, y: geometry.screenFrame.origin.y + 3, width: geometry.screenFrame.size.width, height: 20), 11, ui(75, 68, 58), 4, root)

        if let node = sprite("image_ui_hd", "button_close.png") {
            place(node, geometry.closeButton, 8)
            root.addChild(node)
        }
        if let node = sprite("image_ui_hd", "button_confrim.png") ?? sprite("image_ui_hd", "new_confirm.png") {
            place(node, geometry.okButton, 8)
            root.addChild(node)
        }

        for index in items.indices {
            let item = items[index]
            let rect = geometry.itemRect(index: index)
            rows[index] = rect
            let usable = NativeBattleConsumableCore.canUse(item: item, unit: unit, round: round)

            let slot = shape(rect, ui(222, 214, 199), ui(124, 113, 96))
            slot.alpha = usable ? 1 : 0.42
            root.addChild(slot)

            if let icon = itemNode(item) {
                place(icon, rect, 4)
                icon.alpha = usable ? 1 : 0.42
                root.addChild(icon)
            }
            if index == selectedRow, let selected = sprite("image_ui_hd", "item_selected_ex.png") {
                place(selected, rect, 6)
                root.addChild(selected)
            }
        }

        if let item = selectedItem() {
            let desc = geometry.descriptionScreen
            root.addChild(shape(desc, ui(224, 216, 201), ui(125, 114, 96)))
            let title = strings["name_\(item.name)"] ?? item.name
            label(title, NativeRect(x: desc.origin.x + geometry.descriptionTitle.origin.x, y: desc.origin.y + geometry.descriptionTitle.origin.y, width: geometry.descriptionTitle.size.width, height: geometry.descriptionTitle.size.height), 7, ui(70, 63, 54), 4, root)
            let fallback = item.function == 8 ? "恢复 HP \(item.value)" : (item.function == 6 ? "使部队士气高昂" : "恢复低落士气")
            let detail = strings["desc_\(item.name)"] ?? fallback
            label(detail, NativeRect(x: desc.origin.x + geometry.descriptionText.origin.x, y: desc.origin.y + geometry.descriptionText.origin.y, width: geometry.descriptionText.size.width, height: geometry.descriptionText.size.height), 6.2, ui(70, 63, 54), 4, root)
        }

        parent.addChild(root)
        self.root = root
    }

    private func itemNode(_ item: NativeItemEffectDefinition) -> SKSpriteNode? {
        let file = NativeOriginalItemArtCore.resourceFileName(for: item.name)
        guard let image = UIImage(contentsOfFile: store.url("Items", file).path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func sprite(_ folder: String, _ name: String) -> SKSpriteNode? {
        guard let image = UIImage(contentsOfFile: store.url("Sprites/\(folder)", name).path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func shape(_ rect: NativeRect, _ fill: UIColor, _ stroke: UIColor) -> SKShapeNode {
        let node = SKShapeNode(rect: CGRect(x: rect.origin.x, y: -(rect.origin.y + rect.size.height), width: rect.size.width, height: rect.size.height))
        node.fillColor = fill
        node.strokeColor = stroke
        node.lineWidth = 1
        return node
    }

    private func place(_ node: SKSpriteNode, _ rect: NativeRect, _ z: CGFloat) {
        node.anchorPoint = CGPoint(x: 0, y: 1)
        node.position = CGPoint(x: rect.origin.x, y: -rect.origin.y)
        node.size = CGSize(width: rect.size.width, height: rect.size.height)
        node.zPosition = z
    }

    private func label(_ text: String, _ rect: NativeRect, _ fontSize: CGFloat, _ color: UIColor, _ z: CGFloat, _ parent: SKNode) {
        let node = SKLabelNode(fontNamed: "PingFangSC-Semibold")
        node.text = text
        node.fontSize = fontSize
        node.fontColor = color
        node.horizontalAlignmentMode = .center
        node.verticalAlignmentMode = .center
        node.position = CGPoint(x: rect.origin.x + rect.size.width / 2, y: -(rect.origin.y + rect.size.height / 2))
        node.zPosition = z
        parent.addChild(node)
    }

    private func contains(_ rect: NativeRect, _ point: NativePoint) -> Bool {
        point.x >= rect.origin.x && point.y >= rect.origin.y && point.x <= rect.origin.x + rect.size.width && point.y <= rect.origin.y + rect.size.height
    }

    private func ui(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 255) -> UIColor {
        UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: a / 255)
    }
}
#endif
