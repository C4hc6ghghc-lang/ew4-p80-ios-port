#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

enum NativeActionResourceKind: Equatable {
    case upgrade(objectIndex: Int)
    case training(unitIndex: Int)
    case embark(unitIndex: Int)
}

enum NativeActionResourceAction: Equatable { case close, confirm, none }

@MainActor
final class NativeOriginalActionResourceRenderer {
    private weak var parent: SKNode?
    private let store: NativeResourceStore
    private let spriteManifest: [String: SpriteManifestEntry]
    private var root: SKNode?
    private(set) var kind: NativeActionResourceKind?
    private let panel = NativeRect(x: 161, y: 87, width: 246, height: 145)
    private let closeRect = NativeRect(x: 382, y: 79, width: 25, height: 25)
    private let confirmRect = NativeRect(x: 267, y: 181, width: 35, height: 35)

    init(parent: SKNode, store: NativeResourceStore, spriteManifest: [String: SpriteManifestEntry]) {
        self.parent = parent; self.store = store; self.spriteManifest = spriteManifest
    }

    var isVisible: Bool { root != nil }
    func hide() { root?.removeFromParent(); root = nil; kind = nil }

    func show(kind: NativeActionResourceKind, title: String, money: Int, secondary: Int, secondaryKind: String, detail: String, affordable: Bool) {
        hide(); guard let parent else { return }; self.kind = kind
        let root = SKNode(); root.zPosition = 23_000
        let shade = SKShapeNode(rect: CGRect(x: 0, y: 0, width: EW4LogicalSpace.width, height: EW4LogicalSpace.height)); shade.fillColor = UIColor(white: 0, alpha: 0.48); shade.strokeColor = .clear; root.addChild(shade)
        let board = SKShapeNode(rect: CGRect(x: panel.origin.x, y: EW4LogicalSpace.height-panel.origin.y-panel.size.height, width: panel.size.width, height: panel.size.height)); board.fillColor = UIColor(red: 238/255, green: 230/255, blue: 212/255, alpha: 1); board.strokeColor = UIColor(red: 110/255, green: 98/255, blue: 79/255, alpha: 1); board.lineWidth = 2; root.addChild(board)
        addText(title, x: panel.origin.x + panel.size.width/2, y: panel.origin.y + 8, size: 12, align: .center, root: root)
        addText(detail, x: panel.origin.x + panel.size.width/2, y: panel.origin.y + 42, size: 8, align: .center, root: root)
        addImage("marker_money.png", rect: NativeRect(x: panel.origin.x+48,y:panel.origin.y+72,width:20,height:20), root: root)
        addText(String(money), x: panel.origin.x+73, y:panel.origin.y+75,size:9,root:root)
        let icon = secondaryKind == "food" ? "marker_food.png" : "marker_industry.png"
        addImage(icon, rect: NativeRect(x: panel.origin.x+132,y:panel.origin.y+72,width:20,height:20), root: root)
        addText(String(secondary), x: panel.origin.x+157, y:panel.origin.y+75,size:9,root:root)
        addImage("button_close.png", rect: closeRect, root: root)
        addImage(affordable ? "button_ok.png" : "button_ok_gray_noshadow.png", rect: confirmRect, root: root)
        parent.addChild(root); self.root = root
    }

    func action(at p: NativePoint) -> NativeActionResourceAction {
        guard root != nil else { return .none }
        if closeRect.contains(p) { return .close }
        if confirmRect.contains(p) { return .confirm }
        return .none
    }

    func rect(alias: String) -> NativeRect? {
        switch alias { case "btn_done", "winbtn_ok": return confirmRect; case "winbtn_close": return closeRect; default: return nil }
    }

    private func addText(_ text: String, x: Double, y: Double, size: CGFloat, align: SKLabelHorizontalAlignmentMode = .left, root: SKNode) {
        let l=SKLabelNode(fontNamed:"PingFangSC-Semibold");l.text=text;l.fontSize=size;l.fontColor=UIColor(white:0.25,alpha:1);l.horizontalAlignmentMode=align;l.verticalAlignmentMode = .top;l.position=CGPoint(x:x,y:EW4LogicalSpace.height-y);l.zPosition=3;root.addChild(l)
    }
    private func addImage(_ key:String,rect:NativeRect,root:SKNode){guard let e=spriteManifest[key],let cg=UIImage(contentsOfFile:store.spriteURL(manifestPath:e.file).path)?.cgImage else{return};let n=SKSpriteNode(texture:SKTexture(cgImage:cg));n.anchorPoint=CGPoint(x:0,y:1);n.position=CGPoint(x:rect.origin.x,y:EW4LogicalSpace.height-rect.origin.y);n.size=CGSize(width:rect.size.width,height:rect.size.height);n.zPosition=4;root.addChild(n)}
}
#endif
