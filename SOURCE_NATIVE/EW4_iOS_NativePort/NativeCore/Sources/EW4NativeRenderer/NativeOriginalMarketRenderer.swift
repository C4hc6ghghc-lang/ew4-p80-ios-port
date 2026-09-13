#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

@MainActor
final class NativeOriginalMarketRenderer {
    enum Action: Equatable { case close, buy(Int), sell(Int), none }
    private weak var parent: SKNode?
    private let store: NativeResourceStore
    private let strings: [String: String]
    private var root: SKNode?
    private var buyRects: [Int: NativeRect] = [:]
    private var sellRects: [Int: NativeRect] = [:]

    private let screen = NativeRect(x: 64, y: 30, width: 440, height: 259)
    private let closeRect = NativeRect(x: 487, y: 22, width: 25, height: 25)

    init(parent: SKNode, store: NativeResourceStore) { self.parent = parent; self.store = store; self.strings = (try? store.stringsCN()) ?? [:] }

    func hide() { root?.removeFromParent(); root = nil; buyRects.removeAll(); sellRects.removeAll() }

    func rect(alias: String) -> NativeRect? {
        if alias.hasPrefix("btn_buy_"), let i = Int(alias.replacingOccurrences(of: "btn_buy_", with: "")) { return buyRects[i - 1] }
        if alias.hasPrefix("btn_sell_"), let i = Int(alias.replacingOccurrences(of: "btn_sell_", with: "")) { return sellRects[i - 1] }
        if alias == "winbtn_close" { return closeRect }
        return nil
    }

    func action(at point: NativePoint) -> Action {
        if contains(closeRect, point) { return .close }
        for (i, r) in buyRects where contains(r, point) { return .buy(i) }
        for (i, r) in sellRects where contains(r, point) { return .sell(i) }
        return .none
    }

    func show(business: Int, resources: CountryResources, commanderName: String?) {
        hide(); guard let parent else { return }
        let root = SKNode(); root.position = CGPoint(x: 0, y: EW4LogicalSpace.height); root.zPosition = 25_000
        let dim = SKShapeNode(rect: CGRect(x:0,y:-EW4LogicalSpace.height,width:EW4LogicalSpace.width,height:EW4LogicalSpace.height)); dim.fillColor = UIColor(white:0,alpha:0.46); dim.strokeColor = .clear; dim.zPosition = -2; root.addChild(dim)
        root.addChild(shape(screen, fill: ui(231,224,210), stroke: ui(104,94,80)))
        root.addChild(shape(NativeRect(x:64,y:30,width:440,height:27), fill: ui(214,204,187), stroke: ui(124,112,95)))
        label(strings["title_business"] ?? "交易所", NativeRect(x:64,y:33,width:440,height:20), 11, ui(75,68,58), 4, root)
        if let n = sprite("image_ui_hd", "button_close.png") { place(n,closeRect,8);root.addChild(n) }
        let rate = NativeBattleCommerceCore.tradeRate(business: business)
        let middle = NativeRect(x: 175, y: 140, width: 218, height: 38)
        root.addChild(shape(middle, fill: ui(218,210,195), stroke: ui(137,125,106)))
        label(commanderName?.isEmpty == false ? commanderName! : "驻城指挥官", NativeRect(x:180,y:144,width:95,height:14), 6.5, ui(76,69,59), 4, root)
        label("商业 \(NativeBattleCommerceCore.businessStars(business))/5   ×\(String(format:"%.1f",rate))", NativeRect(x:276,y:144,width:112,height:14), 6.5, ui(76,69,59), 4, root)
        resourceValue(.money, value: resources.money, x: 184, y: 158, root: root)
        resourceValue(.industry, value: resources.industry, x: 250, y: 158, root: root)
        resourceValue(.food, value: resources.food, x: 326, y: 158, root: root)

        for i in 0..<4 {
            let x = 72.0 + Double(i) * 107.0
            let buy = NativeRect(x:x,y:63,width:96,height:70)
            let sell = NativeRect(x:x,y:187,width:96,height:70)
            buyRects[i] = buy; sellRects[i] = sell
            if let quote = NativeBattleCommerceCore.buyQuote(index:i,business:business) { renderQuote(quote, rect:buy, enabled:NativeBattleCommerceCore.canApply(quote,to:resources), title:"买", root:root) }
            if let quote = NativeBattleCommerceCore.sellQuote(index:i,business:business) { renderQuote(quote, rect:sell, enabled:NativeBattleCommerceCore.canApply(quote,to:resources), title:"卖", root:root) }
        }
        parent.addChild(root); self.root = root
    }

    private func renderQuote(_ quote: NativeMarketQuote, rect: NativeRect, enabled: Bool, title: String, root: SKNode) {
        let node = shape(rect, fill: ui(222,214,199), stroke: ui(124,113,96)); node.alpha = enabled ? 1 : 0.42; node.zPosition = 2; root.addChild(node)
        label(title, NativeRect(x:rect.origin.x+2,y:rect.origin.y+2,width:18,height:14), 6, ui(89,80,66), 4, root)
        quoteResource(quote.payResource, value: quote.pay, x: rect.origin.x + 18, y: rect.origin.y + 19, root: root)
        label("↓", NativeRect(x:rect.origin.x+34,y:rect.origin.y+34,width:28,height:14), 8, ui(116,91,48), 4, root)
        quoteResource(quote.receiveResource, value: quote.receive, x: rect.origin.x + 18, y: rect.origin.y + 50, root: root)
    }

    private func resourceFile(_ r: NativeMarketResource) -> String {
        switch r { case .money: return "marker_money.png"; case .industry: return "marker_industry.png"; case .food: return "marker_food.png" }
    }
    private func resourceValue(_ kind: NativeMarketResource, value: Int, x: Double, y: Double, root: SKNode) {
        if let icon = sprite("image_ui_hd", resourceFile(kind)) { place(icon, NativeRect(x:x,y:y,width:11,height:11), 5); root.addChild(icon) }
        label("\(value)", NativeRect(x:x+13,y:y-1,width:43,height:13), 6, ui(76,69,59), 5, root)
    }
    private func quoteResource(_ kind: NativeMarketResource, value: Int, x: Double, y: Double, root: SKNode) {
        if let icon = sprite("image_ui_hd", resourceFile(kind)) { place(icon, NativeRect(x:x,y:y,width:12,height:12), 5); root.addChild(icon) }
        label("\(value)", NativeRect(x:x+15,y:y-1,width:45,height:14), 6.5, ui(70,64,55), 5, root)
    }
    private func sprite(_ folder:String,_ file:String)->SKSpriteNode?{guard let image=UIImage(contentsOfFile:store.url("Sprites/\(folder)",file).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:image))}
    private func shape(_ r:NativeRect,fill:UIColor,stroke:UIColor)->SKShapeNode{let n=SKShapeNode(rect:CGRect(x:r.origin.x,y:-(r.origin.y+r.size.height),width:r.size.width,height:r.size.height));n.fillColor=fill;n.strokeColor=stroke;n.lineWidth=1;return n}
    private func place(_ n:SKSpriteNode,_ r:NativeRect,_ z:CGFloat){n.anchorPoint=CGPoint(x:0,y:1);n.position=CGPoint(x:r.origin.x,y:-r.origin.y);n.size=CGSize(width:r.size.width,height:r.size.height);n.zPosition=z}
    private func label(_ s:String,_ r:NativeRect,_ fs:CGFloat,_ c:UIColor,_ z:CGFloat,_ parent:SKNode){let n=SKLabelNode(fontNamed:"PingFangSC-Semibold");n.text=s;n.fontSize=fs;n.fontColor=c;n.horizontalAlignmentMode = .center;n.verticalAlignmentMode = .center;n.position=CGPoint(x:r.origin.x+r.size.width/2,y:-(r.origin.y+r.size.height/2));n.zPosition=z;parent.addChild(n)}
    private func contains(_ r:NativeRect,_ p:NativePoint)->Bool{p.x>=r.origin.x&&p.y>=r.origin.y&&p.x<=r.origin.x+r.size.width&&p.y<=r.origin.y+r.size.height}
    private func ui(_ r:CGFloat,_ g:CGFloat,_ b:CGFloat,_ a:CGFloat=255)->UIColor{UIColor(red:r/255,green:g/255,blue:b/255,alpha:a/255)}
}
#endif
