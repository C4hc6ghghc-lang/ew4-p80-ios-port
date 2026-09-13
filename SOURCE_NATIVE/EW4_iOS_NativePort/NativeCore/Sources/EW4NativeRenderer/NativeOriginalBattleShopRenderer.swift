#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

@MainActor
final class NativeOriginalBattleShopRenderer {
    enum Action: Equatable { case close, buy(Int), sell(Int), none }
    private enum Selection: Equatable { case seller(Int), buyer(Int) }

    private weak var parent: SKNode?
    private let store: NativeResourceStore
    private let strings: [String: String]
    private var root: SKNode?
    private var buyRects: [Int: NativeRect] = [:]
    private var sellRects: [Int: NativeRect] = [:]
    private var selection: Selection?
    private var selectedAction: Action = .none
    private var selectedOutline: SKSpriteNode?
    private var infoNodes: [SKNode] = []
    private let inventoryCrop = SKCropNode()
    private let inventoryContent = SKNode()
    private var inventoryScroll = 0.0
    private var interactionStartY = 0.0
    private var interactionStartScroll = 0.0
    private var startedInInventory = false
    private var draggedInventory = false

    private let panel = NativeRect(x: 72, y: 30, width: 425, height: 259)
    private let closeRect = NativeRect(x: 480, y: 22, width: 25, height: 25)
    private let confirmRect = NativeRect(x: 425, y: 161, width: 59, height: 26)

    private var currentRecord: NativeBattleShopRecord?
    private var currentProfile: NativePlayerProfile?
    private var currentItems: NativeItemEffectCatalog = [:]
    private var currentBusiness = 0

    init(parent: SKNode, store: NativeResourceStore) {
        self.parent = parent
        self.store = store
        self.strings = (try? store.stringsCN()) ?? [:]
    }

    var isVisible: Bool { root != nil }

    func hide() {
        root?.removeFromParent()
        root = nil
        buyRects.removeAll()
        sellRects.removeAll()
        selection = nil
        selectedAction = .none
        selectedOutline = nil
        infoNodes.removeAll()
        inventoryCrop.removeFromParent()
        inventoryCrop.maskNode = nil
        inventoryContent.removeAllChildren()
        inventoryScroll = 0
        startedInInventory = false
        draggedInventory = false
    }

    func beginInteraction(at point: NativePoint) {
        interactionStartY = point.y
        interactionStartScroll = inventoryScroll
        startedInInventory = contains(NativeShopFormCore.buyerViewport, point)
        draggedInventory = false
    }

    @discardableResult
    func moveInteraction(to point: NativePoint) -> Bool {
        guard startedInInventory else { return false }
        if abs(point.y - interactionStartY) > 3 { draggedInventory = true }
        let next = NativeShopFormCore.buyerScroll(
            startScroll: interactionStartScroll,
            startY: interactionStartY,
            currentY: point.y
        )
        if next != inventoryScroll {
            inventoryScroll = next
            renderInventory()
        }
        return draggedInventory
    }

    @discardableResult
    func endInteraction(at point: NativePoint) -> Bool {
        _ = point
        let wasDragged = draggedInventory
        startedInInventory = false
        draggedInventory = false
        return wasDragged
    }

    func action(at point: NativePoint) -> Action {
        if contains(closeRect, point) { return .close }
        if contains(confirmRect, point) { return selectedAction }
        for (index, rect) in buyRects where contains(rect, point) {
            select(.seller(index), rect: rect)
            return .none
        }
        if let index = NativeShopFormCore.buyerIndex(at: point, scroll: inventoryScroll),
           let rect = sellRects[index] {
            select(.buyer(index), rect: rect)
            return .none
        }
        return .none
    }

    func show(
        record: NativeBattleShopRecord,
        profile: NativePlayerProfile,
        items: NativeItemEffectCatalog,
        business: Int,
        buyerName: String?
    ) {
        hide()
        currentRecord = record
        currentProfile = profile
        currentItems = items
        currentBusiness = business
        guard let parent else { return }
        let root = SKNode()
        root.position = CGPoint(x: 0, y: EW4LogicalSpace.height)
        root.zPosition = 25_000
        let dim = SKShapeNode(rect: CGRect(x: 0, y: -EW4LogicalSpace.height, width: EW4LogicalSpace.width, height: EW4LogicalSpace.height))
        dim.fillColor = UIColor(white: 0, alpha: 0.46)
        dim.strokeColor = .clear
        dim.zPosition = -2
        root.addChild(dim)

        root.addChild(shape(panel, fill: ui(218, 211, 198), stroke: ui(108, 99, 86)))
        root.addChild(shape(NativeRect(x: 72, y: 30, width: 425, height: 27), fill: ui(227, 218, 201), stroke: ui(126, 116, 100)))
        if let icon = sprite("image_ui_hd", "image_shop.png") { place(icon, NativeRect(x: 247, y: 34, width: 20, height: 18), z: 5); root.addChild(icon) }
        label(strings["title_shop"] ?? "商  店", NativeRect(x: 216, y: 34, width: 136, height: 18), 10, ui(76, 69, 59), 5, root)
        if let close = sprite("image_ui_hd", "button_close.png") { place(close, closeRect, z: 12); root.addChild(close) }

        addMerchant(root)
        for index in 0..<NativeBattleShopCore.sellerSize {
            guard let rect = NativeShopFormCore.sellerRect(index: index) else { continue }
            buyRects[index] = rect
            drawSellerSlot(rect: rect, slot: record.slots[index], items: items, business: business, root: root)
        }

        let info = shape(NativeRect(x: 72, y: 159, width: 425, height: 31), fill: ui(205, 198, 185, 190), stroke: ui(131, 123, 112))
        info.zPosition = 4
        root.addChild(info)
        label(strings["text_sellersays"] ?? "欢迎光临！", NativeRect(x: 172, y: 159, width: 225, height: 31), 6.5, ui(89, 78, 62), 5, root)
        addBusinessStars(root, business: business)
        addBuyerBadge(root, name: buyerName)

        parent.addChild(root)
        self.root = root
        renderInventory()
    }

    private func select(_ newSelection: Selection, rect: NativeRect) {
        selection = newSelection
        switch newSelection {
        case .seller(let index): selectedAction = .buy(index)
        case .buyer(let index): selectedAction = .sell(index)
        }
        selectedOutline?.removeFromParent()
        if let select = sprite("image_ui_hd", "item_selected_ex.png"), let root {
            place(select, rect, z: 20)
            switch newSelection {
            case .seller: root.addChild(select)
            case .buyer: inventoryContent.addChild(select)
            }
            selectedOutline = select
        }
        renderInfo()
    }

    private func renderInfo() {
        guard let root else { return }
        for node in infoNodes { node.removeFromParent() }
        infoNodes.removeAll()
        guard let selection else { return }
        let item: NativeItemEffectDefinition?
        let price: Int
        let verb: String
        switch selection {
        case .seller(let index):
            guard let record = currentRecord, record.slots.indices.contains(index), let slot = record.slots[index] else { return }
            item = NativeBattleShopCore.item(currentItems, id: slot.item)
            price = NativeBattleShopCore.buyPrice(item, business: currentBusiness)
            verb = strings["text_buy"] ?? "购买"
        case .buyer(let index):
            guard let profile = currentProfile else { return }
            let bank = NativeHQItemInventoryCore.decode(profile.document["itemInventory"])
            guard bank.slots.indices.contains(index), !bank.slots[index].isEmpty else { return }
            item = NativeBattleShopCore.item(currentItems, id: bank.slots[index].item)
            price = NativeBattleShopCore.sellPrice(item, business: currentBusiness)
            verb = strings["text_sell"] ?? "卖出"
        }
        guard let item else { return }
        addInfoLabel(item.name, NativeRect(x: 72, y: 159, width: 100, height: 15), 6.2, ui(64, 64, 64), 12, root)
        if let medal = sprite("image_ui_hd", "medals.png") {
            place(medal, NativeRect(x: 92, y: 176, width: 13, height: 13), z: 12); root.addChild(medal); infoNodes.append(medal)
        }
        addInfoLabel("\(price)", NativeRect(x: 108, y: 174, width: 40, height: 15), 5.8, ui(64, 64, 64), 12, root)
        addInfoLabel(verb, NativeRect(x: 172, y: 159, width: 225, height: 31), 6.6, ui(64, 64, 64), 12, root)
        if let button = sprite("image_ui_hd", "button_confirm_blue.png") {
            place(button, confirmRect, z: 13); root.addChild(button); infoNodes.append(button)
        }
        addInfoLabel(verb, NativeRect(x: confirmRect.origin.x, y: confirmRect.origin.y, width: 52, height: 20), 6.4, ui(245, 239, 228), 14, root)
    }

    private func addInfoLabel(_ text: String, _ rect: NativeRect, _ size: CGFloat, _ color: UIColor, _ z: CGFloat, _ root: SKNode) {
        let node = makeLabel(text, rect, size, color, z)
        root.addChild(node)
        infoNodes.append(node)
    }

    private func addBusinessStars(_ root: SKNode, business: Int) {
        if let icon = sprite("image_ui_hd", "skill_39.png") { place(icon, NativeRect(x: 399, y: 165, width: 18, height: 18), z: 6); root.addChild(icon) }
        label("\(NativeBattleCommerceCore.businessStars(business))/5", NativeRect(x: 420, y: 165, width: 55, height: 18), 5.8, ui(89, 78, 62), 6, root)
    }

    private func addMerchant(_ root: SKNode) {
        let portrait = shape(NativeRect(x: 76, y: 58, width: 70, height: 78), fill: ui(157, 149, 135), stroke: ui(110, 102, 89))
        portrait.zPosition = 4
        root.addChild(portrait)
        if let shop = sprite("image_ui_hd", "image_shop.png") { place(shop, NativeRect(x: 94, y: 78, width: 34, height: 31), z: 5); root.addChild(shop) }
        if let board = sprite("image_ui_hd", "general_nameboard.png") { place(board, NativeRect(x: 74, y: 136, width: 75, height: 20), z: 4); root.addChild(board) }
        label(strings["name_Seller"] ?? "商人", NativeRect(x: 74, y: 136, width: 75, height: 20), 7, ui(242, 235, 221), 6, root)
    }

    private func addBuyerBadge(_ root: SKNode, name: String?) {
        let box = shape(NativeRect(x: 419, y: 191, width: 74, height: 96), fill: ui(176, 168, 153), stroke: ui(112, 103, 89))
        box.zPosition = 4
        root.addChild(box)
        if let board = sprite("image_ui_hd", "general_nameboard.png") { place(board, NativeRect(x: 418, y: 267, width: 75, height: 20), z: 5); root.addChild(board) }
        label(name?.isEmpty == false ? name! : "物品栏", NativeRect(x: 418, y: 267, width: 75, height: 20), 6, ui(242, 235, 221), 6, root)
    }

    private func drawSellerSlot(rect: NativeRect, slot: NativeHQShopSlot?, items: NativeItemEffectCatalog, business: Int, root: SKNode) {
        let box = shape(rect, fill: ui(201, 193, 180), stroke: ui(129, 121, 110))
        box.zPosition = 5
        root.addChild(box)
        guard let slot, slot.active, slot.count > 0, let item = NativeBattleShopCore.item(items, id: slot.item) else { return }
        if let icon = itemNode(item) { place(icon, NativeRect(x: rect.origin.x + 10, y: rect.origin.y + 2, width: 25, height: 25), z: 6); root.addChild(icon) }
        label("×\(slot.count)", NativeRect(x: rect.origin.x + 1, y: rect.origin.y + 27, width: 18, height: 8), 4.3, ui(84, 70, 56), 7, root)
        if let medal = sprite("image_ui_hd", "medals.png") { place(medal, NativeRect(x: rect.origin.x + 18, y: rect.origin.y + 29, width: 7, height: 7), z: 7); root.addChild(medal) }
        label("\(NativeBattleShopCore.buyPrice(item, business: business))", NativeRect(x: rect.origin.x + 25, y: rect.origin.y + 27, width: 19, height: 8), 4.1, ui(84, 70, 56), 7, root)
    }

    private func renderInventory() {
        guard let root, let profile = currentProfile else { return }
        inventoryCrop.removeFromParent()
        inventoryCrop.maskNode = nil
        inventoryContent.removeAllChildren()
        sellRects.removeAll()

        let viewport = NativeShopFormCore.buyerViewport
        let mask = SKShapeNode(rect: CGRect(
            x: viewport.origin.x,
            y: -(viewport.origin.y + viewport.size.height),
            width: viewport.size.width,
            height: viewport.size.height
        ))
        mask.fillColor = .white
        mask.strokeColor = .clear
        inventoryCrop.maskNode = mask
        inventoryCrop.zPosition = 5
        root.addChild(inventoryCrop)
        inventoryCrop.addChild(inventoryContent)

        let bank = NativeHQItemInventoryCore.decode(profile.document["itemInventory"])
        for index in 0..<NativeItemInventoryBank.size {
            guard let rect = NativeShopFormCore.buyerRect(index: index, scroll: inventoryScroll) else { continue }
            sellRects[index] = rect
            drawInventorySlot(
                rect: rect,
                slot: bank.slots[index],
                items: currentItems,
                business: currentBusiness,
                parent: inventoryContent
            )
            if selection == .buyer(index), let select = sprite("image_ui_hd", "item_selected_ex.png") {
                place(select, rect, z: 20)
                inventoryContent.addChild(select)
                selectedOutline = select
            }
        }
    }

    private func drawInventorySlot(rect: NativeRect, slot: NativeItemInventorySlot, items: NativeItemEffectCatalog, business: Int, parent: SKNode) {
        let box = shape(rect, fill: ui(201, 193, 180), stroke: ui(129, 121, 110))
        box.zPosition = 5
        parent.addChild(box)
        guard !slot.isEmpty, let item = NativeBattleShopCore.item(items, id: slot.item) else { return }
        if let icon = itemNode(item) {
            place(icon, NativeRect(x: rect.origin.x + 7.5, y: rect.origin.y + 3, width: 30, height: 30), z: 6)
            parent.addChild(icon)
        }
        if let medal = sprite("image_ui_hd", "medals.png") {
            place(medal, NativeRect(x: rect.origin.x + 3, y: rect.origin.y + 34, width: 8, height: 8), z: 7)
            parent.addChild(medal)
        }
        label(
            "×\(slot.count)   \(NativeBattleShopCore.sellPrice(item, business: business))",
            NativeRect(x: rect.origin.x + 11, y: rect.origin.y + 33, width: 32, height: 10),
            4.4,
            ui(84, 70, 56),
            7,
            parent
        )
    }

    private func itemNode(_ item: NativeItemEffectDefinition) -> SKSpriteNode? {
        let file = item.name.replacingOccurrences(of: " ", with: "_") + ".png"
        guard let image = UIImage(contentsOfFile: store.url("Items", file).path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func sprite(_ folder: String, _ file: String) -> SKSpriteNode? {
        guard let image = UIImage(contentsOfFile: store.url("Sprites/\(folder)", file).path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func shape(_ rect: NativeRect, fill: UIColor, stroke: UIColor) -> SKShapeNode {
        let node = SKShapeNode(rect: CGRect(x: rect.origin.x, y: -(rect.origin.y + rect.size.height), width: rect.size.width, height: rect.size.height))
        node.fillColor = fill
        node.strokeColor = stroke
        node.lineWidth = 1
        return node
    }

    private func place(_ node: SKSpriteNode, _ rect: NativeRect, z: CGFloat) {
        node.anchorPoint = CGPoint(x: 0, y: 1)
        node.position = CGPoint(x: rect.origin.x, y: -rect.origin.y)
        node.size = CGSize(width: rect.size.width, height: rect.size.height)
        node.zPosition = z
    }

    private func makeLabel(_ text: String, _ rect: NativeRect, _ size: CGFloat, _ color: UIColor, _ z: CGFloat) -> SKLabelNode {
        let node = SKLabelNode(fontNamed: "PingFangSC-Semibold")
        node.text = text
        node.fontSize = size
        node.fontColor = color
        node.horizontalAlignmentMode = .center
        node.verticalAlignmentMode = .center
        node.position = CGPoint(x: rect.origin.x + rect.size.width / 2, y: -(rect.origin.y + rect.size.height / 2))
        node.zPosition = z
        return node
    }

    private func label(_ text: String, _ rect: NativeRect, _ size: CGFloat, _ color: UIColor, _ z: CGFloat, _ parent: SKNode) {
        parent.addChild(makeLabel(text, rect, size, color, z))
    }

    private func contains(_ rect: NativeRect, _ point: NativePoint) -> Bool {
        point.x >= rect.origin.x && point.y >= rect.origin.y && point.x <= rect.origin.x + rect.size.width && point.y <= rect.origin.y + rect.size.height
    }

    private func ui(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 255) -> UIColor {
        UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: a / 255)
    }
}
#endif
