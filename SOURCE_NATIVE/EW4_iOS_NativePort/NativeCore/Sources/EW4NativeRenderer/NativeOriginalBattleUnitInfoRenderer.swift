#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

final class NativeOriginalBattleUnitInfoRenderer {
    enum Action: Equatable { case close, generalInfo, none }

    private weak var parent: SKNode?
    private let store: NativeResourceStore
    private let portraits: [String: String]
    private let strings: [String: String]
    private var root: SKNode?
    private var generalRect: NativeRect?

    private let form = NativeRect(x: 119, y: 66, width: 330, height: 187)
    private let closeRect = NativeRect(x: 432, y: 57, width: 25, height: 25)


    init(parent: SKNode, store: NativeResourceStore, portraits: [String: String]) {
        self.parent = parent
        self.store = store
        self.portraits = portraits
        self.strings = (try? store.stringsCN()) ?? [:]
    }

    var isVisible: Bool { root != nil }

    func hide() {
        root?.removeFromParent()
        root = nil
        generalRect = nil
    }

    func action(at point: NativePoint) -> Action {
        if contains(closeRect, point) { return .close }
        if let generalRect, contains(generalRect, point) { return .generalInfo }
        return .none
    }

    func show(_ model: NativeBattleUnitInfoModel) {
        hide()
        guard let parent else { return }
        let root = SKNode()
        root.position = CGPoint(x: 0, y: EW4LogicalSpace.height)
        root.zPosition = 25_000
        let dim = shape(.init(x: 0, y: 0, width: 568, height: 320), fill: ui(0,0,0,105), stroke: .clear)
        dim.zPosition = -2; root.addChild(dim)
        let panel = shape(form, fill: ui(235,228,211), stroke: ui(104,94,78)); panel.lineWidth = 2; root.addChild(panel)
        let title = NativeRect(x: form.origin.x, y: form.origin.y, width: form.size.width, height: 28)
        root.addChild(shape(title, fill: ui(225,216,198), stroke: ui(124,112,94)))
        label(strings["title_unitinfo"] ?? "信  息", title, 10, ui(70,62,51), 3, root)
        if let close = sprite("image_ui_hd", "button_close.png") { place(close, closeRect, z: 8); root.addChild(close) }

        let ox = form.origin.x, oy = form.origin.y
        drawUnit(model, ox: ox, oy: oy, root: root)
        drawAbilities(model, ox: ox, oy: oy, root: root)
        drawCommander(model, ox: ox, oy: oy, root: root)
        drawDescription(model, ox: ox, oy: oy, root: root)

        parent.addChild(root)
        self.root = root
    }

    private func drawUnit(_ model: NativeBattleUnitInfoModel, ox: Double, oy: Double, root: SKNode) {
        let group = NativeRect(x: ox + 2, y: oy + 30, width: 78, height: 78)
        let border = shape(group, fill: ui(204,195,178), stroke: ui(126,115,96)); border.zPosition=2; root.addChild(border)
        let art = NativeOriginalRecruitArtCore.art(for: model.armyName)
        if let unit = spritePath(art.unitPath) { place(unit, .init(x: ox+5,y:oy+37,width:72,height:52), z: 3); root.addChild(unit) }
        if let frame = sprite("image_recruit_hd", "build_frame.png") { place(frame,.init(x:ox+5,y:oy+36,width:72,height:65),z:4);root.addChild(frame) }
        for i in 0..<model.formationCount {
            let dx = Double(i) * 4
            if let back = sprite("image_recruit_hd", "buildmaker.png") { place(back,.init(x:ox+5+dx,y:oy+72,width:26,height:20),z:5+CGFloat(i));root.addChild(back) }
            if let mark = spritePath(art.markerPath) { place(mark,.init(x:ox+6+dx,y:oy+72,width:24,height:18),z:6+CGFloat(i));root.addChild(mark) }
        }
        if let money = sprite("image_ui_hd","marker_money.png") { place(money,.init(x:ox+6,y:oy+89,width:11,height:11),z:8);root.addChild(money) }
        label(String(model.moneyCost),.init(x:ox+17,y:oy+89,width:25,height:11),5,ui(75,65,52),8,root)
        if let ind = sprite("image_ui_hd","marker_industry.png") { place(ind,.init(x:ox+45,y:oy+89,width:11,height:11),z:8);root.addChild(ind) }
        label(String(model.industryCost),.init(x:ox+56,y:oy+89,width:20,height:11),5,ui(75,65,52),8,root)
    }

    private func drawAbilities(_ model: NativeBattleUnitInfoModel, ox: Double, oy: Double, root: SKNode) {
        let grid = NativeRect(x: ox+80,y:oy+33,width:165,height:72)
        let border=shape(grid,fill:ui(226,218,202),stroke:ui(123,112,94));border.zPosition=2;root.addChild(border)
        let cellW = 41.25, cellH = 24.0
        let entries:[(String?,String?)] = [
            ("infomarker_attack.png",nil),(nil,"\(model.attackMin)-\(model.attackMax)"),("button_upgrade_line.png",nil),(nil,"formation"),
            ("infomarker_hp.png",nil),(nil,"\(model.hp)/\(model.maxHP)"),("infomarker_food.png",nil),(nil,String(model.consumption)),
            ("infomarker_range.png",nil),(nil,"\(model.minRange)-\(model.maxRange)"),("infomarker_move.png",nil),(nil,String(model.movement))
        ]
        for i in 0..<entries.count {
            let col=i%4,row=i/4;let rect=NativeRect(x:grid.origin.x+Double(col)*cellW,y:grid.origin.y+Double(row)*cellH,width:cellW,height:cellH)
            if col > 0 { let line=shape(.init(x:rect.origin.x,y:rect.origin.y,width:0.5,height:cellH),fill:ui(151,141,122),stroke:.clear);line.zPosition=3;root.addChild(line) }
            if row > 0 { let line=shape(.init(x:rect.origin.x,y:rect.origin.y,width:cellW,height:0.5),fill:ui(151,141,122),stroke:.clear);line.zPosition=3;root.addChild(line) }
            if let icon=entries[i].0, let node=sprite("image_ui_hd",icon){place(node,.init(x:rect.origin.x+12,y:rect.origin.y+4,width:18,height:16),z:4);root.addChild(node)}
            else if entries[i].1 == "formation" {
                for n in 0..<model.formationCount { if let icon=sprite("image_ui_hd","infomarker_soldiernumber.png"){place(icon,.init(x:rect.origin.x+5+Double(n)*10,y:rect.origin.y+5,width:10,height:14),z:4);root.addChild(icon)} }
            } else if let text=entries[i].1 { label(text,rect,6.2,ui(67,60,49),4,root) }
        }
    }

    private func drawCommander(_ model: NativeBattleUnitInfoModel, ox: Double, oy: Double, root: SKNode) {
        let group=NativeRect(x:ox+249,y:oy+30,width:78,height:78);let box=shape(group,fill:ui(204,195,178),stroke:ui(126,115,96));box.zPosition=2;root.addChild(box)
        guard let id=model.commanderID else { label("无将领",group,6.5,ui(111,99,82),4,root);return }
        if let p=portrait(id){place(p,.init(x:ox+253,y:oy+36,width:52,height:58),z:4);root.addChild(p)}
        label(model.commanderName ?? "将领",.init(x:ox+250,y:oy+91,width:75,height:14),5.5,ui(70,60,49),5,root)
        let r=NativeRect(x:ox+304,y:oy+32,width:23,height:23);generalRect=r
        if let b=sprite("image_ui_hd","button_generalinfo_blue.png"){place(b,r,z:7);root.addChild(b)}
    }

    private func drawDescription(_ model: NativeBattleUnitInfoModel, ox: Double, oy: Double, root: SKNode) {
        let box=NativeRect(x:ox+4,y:oy+110,width:323,height:74);let panel=shape(box,fill:ui(226,218,202),stroke:ui(123,112,94));panel.zPosition=2;root.addChild(panel)
        label(model.displayName,.init(x:ox+8,y:oy+111,width:120,height:18),7,ui(66,58,47),4,root,alignment:.left)
        let text=SKLabelNode(fontNamed:"PingFangSC-Regular");text.text=model.description;text.fontSize=5.8;text.fontColor=ui(79,70,57);text.horizontalAlignmentMode = .left;text.verticalAlignmentMode = .top;text.numberOfLines=3;text.preferredMaxLayoutWidth=310;text.position=CGPoint(x:ox+10,y:-(oy+132));text.zPosition=4;root.addChild(text)
    }

    private func portrait(_ id:Int)->SKSpriteNode?{guard let raw=portraits[String(id)]else{return nil};let f=URL(fileURLWithPath:raw).lastPathComponent;guard let im=UIImage(contentsOfFile:store.url("Portraits",f).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:im))}
    private func spritePath(_ path:String)->SKSpriteNode?{let parts=path.split(separator:"/",maxSplits:1).map(String.init);guard parts.count==2 else{return nil};return sprite(parts[0],parts[1])}
    private func sprite(_ folder:String,_ file:String)->SKSpriteNode?{guard let im=UIImage(contentsOfFile:store.url("Sprites/\(folder)",file).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:im))}
    private func shape(_ r:NativeRect,fill:UIColor,stroke:UIColor)->SKShapeNode{let n=SKShapeNode(rect:CGRect(x:r.origin.x,y:-(r.origin.y+r.size.height),width:r.size.width,height:r.size.height));n.fillColor=fill;n.strokeColor=stroke;n.lineWidth=1;return n}
    private func place(_ n:SKSpriteNode,_ r:NativeRect,z:CGFloat){n.anchorPoint=CGPoint(x:0,y:1);n.position=CGPoint(x:r.origin.x,y:-r.origin.y);n.size=CGSize(width:r.size.width,height:r.size.height);n.zPosition=z}
    private func label(_ t:String,_ r:NativeRect,_ s:CGFloat,_ c:UIColor,_ z:CGFloat,_ parent:SKNode,alignment:SKLabelHorizontalAlignmentMode = .center){let n=SKLabelNode(fontNamed:"PingFangSC-Semibold");n.text=t;n.fontSize=s;n.fontColor=c;n.horizontalAlignmentMode=alignment;n.verticalAlignmentMode = .center;n.position=CGPoint(x: alignment == .left ? r.origin.x : r.origin.x+r.size.width/2,y:-(r.origin.y+r.size.height/2));n.zPosition=z;parent.addChild(n)}
    private func contains(_ r:NativeRect,_ p:NativePoint)->Bool{p.x>=r.origin.x&&p.y>=r.origin.y&&p.x<=r.origin.x+r.size.width&&p.y<=r.origin.y+r.size.height}
    private func ui(_ r:CGFloat,_ g:CGFloat,_ b:CGFloat,_ a:CGFloat=255)->UIColor{UIColor(red:r/255,green:g/255,blue:b/255,alpha:a/255)}
}

final class NativeOriginalBattleGeneralInfoRenderer {
    enum Action { case close, none }
    private weak var parent: SKNode?
    private let store: NativeResourceStore
    private let portraits: [String:String]
    private let strings: [String:String]
    private let items: NativeItemEffectCatalog
    private var root: SKNode?
    private let closeRect = NativeRect(x: 478, y: 43, width: 25, height: 25)

    init(parent: SKNode, store: NativeResourceStore, portraits: [String:String], strings: [String:String], items: NativeItemEffectCatalog) { self.parent=parent;self.store=store;self.portraits=portraits;self.strings=strings;self.items=items }
    var isVisible:Bool{root != nil}
    func hide(){root?.removeFromParent();root=nil}
    func action(at p:NativePoint)->Action{contains(closeRect,p) ? .close : .none}
    func show(raw:Commander,effective:NativeEffectiveCommander){
        hide();guard let parent else{return}
        let root=SKNode();root.position=CGPoint(x:0,y:EW4LogicalSpace.height);root.zPosition=26_000
        let dim=shape(.init(x:0,y:0,width:568,height:320),fill:ui(0,0,0,120),stroke:.clear);dim.zPosition = -2;root.addChild(dim)
        NativeOriginalGeneralInfoSurface.render(parent: root, store: store, portraits: portraits, strings: strings, items: items, commander: raw, effective: effective, z: 0)
        if let close=sprite("image_ui_hd","button_close.png"){place(close,closeRect,7);root.addChild(close)}
        parent.addChild(root);self.root=root
    }
    private func portrait(_ id:Int)->SKSpriteNode?{guard let raw=portraits[String(id)]else{return nil};let f=URL(fileURLWithPath:raw).lastPathComponent;guard let im=UIImage(contentsOfFile:store.url("Portraits",f).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:im))}
    private func sprite(_ folder:String,_ file:String)->SKSpriteNode?{guard let im=UIImage(contentsOfFile:store.url("Sprites/\(folder)",file).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:im))}
    private func shape(_ r:NativeRect,fill:UIColor,stroke:UIColor)->SKShapeNode{let n=SKShapeNode(rect:CGRect(x:r.origin.x,y:-(r.origin.y+r.size.height),width:r.size.width,height:r.size.height));n.fillColor=fill;n.strokeColor=stroke;n.lineWidth=1;return n}
    private func place(_ n:SKSpriteNode,_ r:NativeRect,_ z:CGFloat){n.anchorPoint=CGPoint(x:0,y:1);n.position=CGPoint(x:r.origin.x,y:-r.origin.y);n.size=CGSize(width:r.size.width,height:r.size.height);n.zPosition=z}
    private func label(_ t:String,_ r:NativeRect,_ s:CGFloat,_ c:UIColor,_ z:CGFloat,_ parent:SKNode,alignment:SKLabelHorizontalAlignmentMode = .center){let n=SKLabelNode(fontNamed:"PingFangSC-Semibold");n.text=t;n.fontSize=s;n.fontColor=c;n.horizontalAlignmentMode=alignment;n.verticalAlignmentMode = .center;n.position=CGPoint(x: alignment == .left ? r.origin.x : r.origin.x+r.size.width/2,y:-(r.origin.y+r.size.height/2));n.zPosition=z;parent.addChild(n)}
    private func contains(_ r:NativeRect,_ p:NativePoint)->Bool{p.x>=r.origin.x&&p.y>=r.origin.y&&p.x<=r.origin.x+r.size.width&&p.y<=r.origin.y+r.size.height}
    private func ui(_ r:CGFloat,_ g:CGFloat,_ b:CGFloat,_ a:CGFloat=255)->UIColor{UIColor(red:r/255,green:g/255,blue:b/255,alpha:a/255)}
}
#endif
