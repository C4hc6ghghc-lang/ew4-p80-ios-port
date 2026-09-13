#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

public final class NativeOriginalHQShopScene: SKScene {
    public var backHandler: (() -> Void)?
    public var profileDidChangeHandler: ((NativePlayerProfile) -> Void)?
    public var statusHandler: ((String) -> Void)?
    public private(set) var profile: NativePlayerProfile

    private enum Selection: Equatable { case seller(Int), buyer(Int) }

    private let store: NativeResourceStore
    private let items: NativeItemEffectCatalog
    private let strings: [String: String]
    private let root = SKNode()
    private let inventoryCrop = SKCropNode()
    private let inventoryContent = SKNode()
    private var inventoryScroll = 0.0
    private var startY = 0.0
    private var startScroll = 0.0
    private var startedInInventory = false
    private var dragged = false
    private var selection: Selection?

    private let panel = NativeRect(x: 72, y: 30, width: 425, height: 259)
    private let closeRect = NativeRect(x: 480, y: 22, width: 25, height: 25)
    private let infoRect = NativeRect(x: 72, y: 159, width: 425, height: 31)
    private let confirmRect = NativeRect(x: 425, y: 161, width: 59, height: 26)

    public init(store: NativeResourceStore, profile: NativePlayerProfile) throws {
        self.store = store
        self.items = try store.items()
        self.strings = (try? store.stringsCN()) ?? [:]
        var normalized = profile
        _ = NativeHQShopCore.ensureStore(profile: &normalized, items: self.items)
        self.profile = normalized
        super.init(size: CGSize(width: EW4LogicalSpace.width, height: EW4LogicalSpace.height))
        scaleMode = .aspectFit
        anchorPoint = .zero
        backgroundColor = .black
        root.position = CGPoint(x: 0, y: EW4LogicalSpace.height)
        addChild(root)
        render()
    }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func render() {
        root.removeAllChildren()
        if let bg = textureNode("campaign_wide.png") { place(bg, NativeRect(x: 0, y: 0, width: 568, height: 320), z: 0); root.addChild(bg) }
        let shade = shape(NativeRect(x: 0, y: 0, width: 568, height: 320), fill: ui(0, 0, 0, 92), stroke: .clear); shade.zPosition = 1; root.addChild(shade)
        let board = shape(panel, fill: ui(218, 211, 198), stroke: ui(108, 99, 86)); board.zPosition = 2; root.addChild(board)
        let header = shape(NativeRect(x: 72, y: 30, width: 425, height: 27), fill: ui(227, 218, 201), stroke: ui(126, 116, 100)); header.zPosition = 3; root.addChild(header)
        if let icon = sprite("image_ui_hd", "image_shop.png") { place(icon, NativeRect(x: 247, y: 34, width: 20, height: 18), z: 5); root.addChild(icon) }
        label(strings["title_shop"] ?? "商  店", NativeRect(x: 216, y: 34, width: 136, height: 18), 10, ui(76, 69, 59), 5)
        if let close = sprite("image_ui_hd", "button_close.png") { place(close, closeRect, z: 12); root.addChild(close) }

        addMerchant()
        renderSeller()
        renderInfo()
        addBuyerBadge()
        renderInventory()
        statusHandler?("HQ Shop")
    }

    private func addMerchant() {
        let portrait = shape(NativeRect(x: 76, y: 58, width: 70, height: 78), fill: ui(157, 149, 135), stroke: ui(110, 102, 89)); portrait.zPosition = 4; root.addChild(portrait)
        if let shop = sprite("image_ui_hd", "image_shop.png") { place(shop, NativeRect(x: 94, y: 78, width: 34, height: 31), z: 5); root.addChild(shop) }
        if let board = sprite("image_ui_hd", "general_nameboard.png") { place(board, NativeRect(x: 74, y: 136, width: 75, height: 20), z: 4); root.addChild(board) }
        label(strings["name_Seller"] ?? "商人", NativeRect(x: 74, y: 136, width: 75, height: 20), 7, ui(242, 235, 221), 6)
    }

    private func addBuyerBadge() {
        let box = shape(NativeRect(x: 419, y: 191, width: 74, height: 96), fill: ui(176, 168, 153), stroke: ui(112, 103, 89)); box.zPosition = 4; root.addChild(box)
        if let board = sprite("image_ui_hd", "general_nameboard.png") { place(board, NativeRect(x: 418, y: 267, width: 75, height: 20), z: 5); root.addChild(board) }
        label("物品栏", NativeRect(x: 418, y: 267, width: 75, height: 20), 6, ui(242, 235, 221), 6)
    }

    private func renderInfo() {
        let info = shape(infoRect, fill: ui(205, 198, 185, 190), stroke: ui(131, 123, 112)); info.zPosition = 4; root.addChild(info)
        guard let selectedItem = selectedItem() else {
            label(strings["text_sellersays"] ?? "欢迎光临！", NativeRect(x: 172, y: 159, width: 225, height: 31), 7, ui(89, 78, 62), 5)
            return
        }
        label(selectedItem.item.name, NativeRect(x: 72, y: 159, width: 100, height: 15), 6.4, ui(64, 64, 64), 5)
        if let medal = sprite("image_ui_hd", "medals.png") { place(medal, NativeRect(x: 92, y: 176, width: 13, height: 13), z: 6); root.addChild(medal) }
        label("\(selectedItem.price)", NativeRect(x: 108, y: 174, width: 40, height: 15), 5.8, ui(64, 64, 64), 6)
        label(selectedItem.isSale ? (strings["text_sell"] ?? "卖出") : (strings["text_buy"] ?? "购买"), NativeRect(x: 172, y: 159, width: 225, height: 31), 7, ui(64, 64, 64), 5)
        if let button = sprite("image_ui_hd", "button_confirm_blue.png") { place(button, confirmRect, z: 8); root.addChild(button) }
        label(selectedItem.isSale ? (strings["text_sell"] ?? "卖出") : (strings["text_buy"] ?? "购买"), NativeRect(x: confirmRect.origin.x, y: confirmRect.origin.y, width: 52, height: 20), 6.5, ui(245, 239, 228), 9)
    }

    private func renderSeller() {
        let shop = NativeHQShopCore.decodeStore(profile.document["hqShop"])
        for index in 0..<NativeHQShopCore.sellerSize {
            guard let rect = NativeShopFormCore.sellerRect(index: index) else { continue }
            drawItemSlot(rect: rect, slot: shop.slots[index], inventoryCount: nil, z: 5)
            if selection == .seller(index), let select = sprite("image_ui_hd", "item_selected_ex.png") { place(select, rect, z: 9); root.addChild(select) }
        }
    }

    private func renderInventory() {
        inventoryCrop.removeFromParent(); inventoryCrop.maskNode = nil; inventoryContent.removeAllChildren()
        let viewport = NativeShopFormCore.buyerViewport
        let mask = SKShapeNode(rect: CGRect(x: viewport.origin.x, y: -(viewport.origin.y + viewport.size.height), width: viewport.size.width, height: viewport.size.height))
        mask.fillColor = .white; mask.strokeColor = .clear; inventoryCrop.maskNode = mask; inventoryCrop.zPosition = 5; root.addChild(inventoryCrop); inventoryCrop.addChild(inventoryContent)
        let bank = NativeHQItemInventoryCore.decode(profile.document["itemInventory"])
        for index in 0..<NativeItemInventoryBank.size {
            guard let rect = NativeShopFormCore.buyerRect(index: index, scroll: inventoryScroll) else { continue }
            let slot = bank.slots[index]
            let shopSlot: NativeHQShopSlot? = slot.isEmpty ? nil : .init(item: slot.item, count: slot.count)
            drawItemSlot(rect: rect, slot: shopSlot, inventoryCount: slot.isEmpty ? nil : slot.count, z: 1, parent: inventoryContent)
            if selection == .buyer(index), let select = sprite("image_ui_hd", "item_selected_ex.png") { place(select, rect, z: 4); inventoryContent.addChild(select) }
        }
    }

    private func drawItemSlot(rect: NativeRect, slot: NativeHQShopSlot?, inventoryCount: Int?, z: CGFloat, parent: SKNode? = nil) {
        let p = parent ?? root
        let box = shape(rect, fill: ui(201, 193, 180), stroke: ui(129, 121, 110)); box.zPosition = z; p.addChild(box)
        guard let slot, let item = items[String(slot.item)] ?? items.values.first(where: { $0.id == slot.item }) else { return }
        if let icon = itemNode(item) { place(icon, NativeRect(x: rect.origin.x + 7.5, y: rect.origin.y + 3, width: 30, height: 30), z: z + 1); p.addChild(icon) }
        let price = inventoryCount == nil ? NativeHQShopCore.buyPrice(item) : NativeHQShopCore.sellPrice(item)
        if let medal = sprite("image_ui_hd", "medals.png") { place(medal, NativeRect(x: rect.origin.x + 3, y: rect.origin.y + 34, width: 8, height: 8), z: z + 2); p.addChild(medal) }
        let text = inventoryCount == nil ? "\(price)" : "×\(inventoryCount!)   \(price)"
        label(text, NativeRect(x: rect.origin.x + 11, y: rect.origin.y + 33, width: 32, height: 10), 4.4, ui(84, 70, 56), z + 2, parent: p)
    }

    private func selectedItem() -> (item: NativeItemEffectDefinition, price: Int, isSale: Bool)? {
        switch selection {
        case .seller(let index):
            let shop = NativeHQShopCore.decodeStore(profile.document["hqShop"])
            guard shop.slots.indices.contains(index), let slot = shop.slots[index], let item = items[String(slot.item)] ?? items.values.first(where: { $0.id == slot.item }) else { return nil }
            return (item, NativeHQShopCore.buyPrice(item), false)
        case .buyer(let index):
            let bank = NativeHQItemInventoryCore.decode(profile.document["itemInventory"])
            guard bank.slots.indices.contains(index), !bank.slots[index].isEmpty, let item = items[String(bank.slots[index].item)] ?? items.values.first(where: { $0.id == bank.slots[index].item }) else { return nil }
            return (item, NativeHQShopCore.sellPrice(item), true)
        case nil: return nil
        }
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }; let p = nativePoint(t.location(in: self))
        startY = p.y; startScroll = inventoryScroll; startedInInventory = contains(NativeShopFormCore.buyerViewport, p); dragged = false
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard startedInInventory, let t = touches.first else { return }; let p = nativePoint(t.location(in: self))
        if abs(delta) > 3 { dragged = true }
        inventoryScroll = NativeShopFormCore.buyerScroll(startScroll: startScroll, startY: startY, currentY: p.y); render()
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }; let p = nativePoint(t.location(in: self)); defer { startedInInventory = false; dragged = false }
        if contains(closeRect, p) { backHandler?(); return }
        if dragged { return }
        if contains(confirmRect, p) {
            switch selection {
            case .seller(let seller):
                if let id = NativeHQShopCore.buy(profile: &profile, sellerIndex: seller, items: items) { profileDidChangeHandler?(profile); statusHandler?("Bought item \(id)"); selection = nil; render() }
            case .buyer(let bankIndex):
                if let id = NativeHQShopCore.sell(profile: &profile, inventoryIndex: bankIndex) { profileDidChangeHandler?(profile); statusHandler?("Sold item \(id)"); selection = nil; render() }
            case nil: break
            }
            return
        }
        if let seller = sellerIndex(at: p) { selection = .seller(seller); render(); return }
        if let bankIndex = inventoryIndex(at: p) { selection = .buyer(bankIndex); render(); return }
    }

    private func sellerIndex(at p: NativePoint) -> Int? {
        for i in 0..<NativeHQShopCore.sellerSize { if let rect = NativeShopFormCore.sellerRect(index: i), contains(rect, p) { return i } }
        return nil
    }
    private func inventoryIndex(at p: NativePoint) -> Int? {
        NativeShopFormCore.buyerIndex(at: p, scroll: inventoryScroll)
    }

    private func itemNode(_ item: NativeItemEffectDefinition) -> SKSpriteNode? {
        let file = item.name.replacingOccurrences(of: " ", with: "_") + ".png"
        guard let image = UIImage(contentsOfFile: store.url("Items", file).path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }
    private func textureNode(_ file: String) -> SKSpriteNode? { guard let image=UIImage(contentsOfFile: store.url("Textures",file).path)?.cgImage else{return nil}; return SKSpriteNode(texture: SKTexture(cgImage:image)) }
    private func sprite(_ folder: String, _ file: String) -> SKSpriteNode? { guard let image=UIImage(contentsOfFile: store.url("Sprites/\(folder)",file).path)?.cgImage else{return nil}; return SKSpriteNode(texture: SKTexture(cgImage:image)) }
    private func shape(_ rect: NativeRect, fill: UIColor, stroke: UIColor) -> SKShapeNode { let n=SKShapeNode(rect:CGRect(x:rect.origin.x,y:-(rect.origin.y+rect.size.height),width:rect.size.width,height:rect.size.height)); n.fillColor=fill; n.strokeColor=stroke; n.lineWidth=1; return n }
    private func place(_ node: SKSpriteNode, _ rect: NativeRect, z: CGFloat) { node.anchorPoint=CGPoint(x:0,y:1); node.position=CGPoint(x:rect.origin.x,y:-rect.origin.y); node.size=CGSize(width:rect.size.width,height:rect.size.height); node.zPosition=z }
    private func label(_ text:String,_ rect:NativeRect,_ size:CGFloat,_ color:UIColor,_ z:CGFloat,parent:SKNode?=nil){let n=SKLabelNode(fontNamed:"PingFangSC-Semibold");n.text=text;n.fontSize=size;n.fontColor=color;n.horizontalAlignmentMode = .center;n.verticalAlignmentMode = .center;n.position=CGPoint(x:rect.origin.x+rect.size.width/2,y:-(rect.origin.y+rect.size.height/2));n.zPosition=z;(parent ?? root).addChild(n)}
    private func nativePoint(_ p:CGPoint)->NativePoint{.init(x:p.x,y:EW4LogicalSpace.height-p.y)}
    private func contains(_ r:NativeRect,_ p:NativePoint)->Bool{p.x>=r.origin.x&&p.y>=r.origin.y&&p.x<=r.origin.x+r.size.width&&p.y<=r.origin.y+r.size.height}
    private func ui(_ r:CGFloat,_ g:CGFloat,_ b:CGFloat,_ a:CGFloat=255)->UIColor{UIColor(red:r/255,green:g/255,blue:b/255,alpha:a/255)}
}
#endif
