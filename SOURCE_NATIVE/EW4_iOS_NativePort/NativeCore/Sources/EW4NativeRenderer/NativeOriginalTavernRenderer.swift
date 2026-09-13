#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

/// Native binding for original `form_recruitgeneral` (300x275).
/// Recruitment semantics remain in `NativeBattleTavernCore`; this renderer only
/// restores the original four-row presentation and hit geometry.
final class NativeOriginalTavernRenderer {
    enum Action: Equatable { case close, recruit(Int), info(Int), none }
    private weak var parent: SKNode?
    private let store: NativeResourceStore
    private let portraits: [String: String]
    private let strings: [String:String]
    private let items: NativeItemEffectCatalog
    private var root: SKNode?
    private var detailRoot: SKNode?
    private typealias G = NativeOriginalFormGeometryCore.Tavern

    private let detailClose = NativeRect(x: 478, y: 43, width: 25, height: 25)

    init(parent: SKNode, store: NativeResourceStore, portraits: [String: String], items: NativeItemEffectCatalog) {
        self.parent = parent; self.store = store; self.portraits = portraits; self.items = items; self.strings = (try? store.stringsCN()) ?? [:]
    }

    func hide() { detailRoot?.removeFromParent(); detailRoot = nil; root?.removeFromParent(); root = nil }

    func action(at point: NativePoint) -> Action {
        if detailRoot != nil {
            if contains(detailClose, point) { detailRoot?.removeFromParent(); detailRoot = nil }
            return .none
        }
        if contains(G.closeButton, point) { return .close }
        for index in 0..<NativeBattleTavernCore.visibleCandidateCount {
            if contains(G.info(index), point) { return .info(index) }
            if contains(G.recruitButton(index), point) { return .recruit(index) }
        }
        return .none
    }

    func show(record: NativeBattleTavernRecord, round: Int, resources: CountryResources, profile: NativePlayerProfile, commanders: [Int: Commander]) {
        hide(); guard let parent else { return }
        let root = SKNode(); root.position = CGPoint(x: 0, y: EW4LogicalSpace.height); root.zPosition = 25_000
        let dim = SKShapeNode(rect: CGRect(x: 0, y: -EW4LogicalSpace.height, width: EW4LogicalSpace.width, height: EW4LogicalSpace.height))
        dim.fillColor = UIColor(white: 0, alpha: 0.50); dim.strokeColor = .clear; dim.zPosition = -2; root.addChild(dim)
        if let panel = sprite("image_ui_hd", "form_back.png") { place(panel, G.screenFrame, 0); root.addChild(panel) }
        else { let panel = shape(G.screenFrame, fill: ui(237,229,211), stroke: ui(108,97,79)); panel.zPosition = 0; root.addChild(panel) }
        label(strings["title_tavern"] ?? "酒  馆", NativeRect(x:G.screenFrame.origin.x,y:G.screenFrame.origin.y+3,width:G.screenFrame.size.width,height:22), 11, ui(76,69,57), 2, root)
        if let n = sprite("image_ui_hd", "button_close.png") { place(n, G.closeButton, 8); root.addChild(n) }

        let owned = Set(profile.ownedCommanderIDs)
        for index in 0..<NativeBattleTavernCore.visibleCandidateCount {
            if let frame = sprite("image_ui_hd", "common_lineframe_bold.png") { place(frame, G.row(index), 1); root.addChild(frame) }
            else { let box = shape(G.row(index), fill:ui(228,220,203), stroke:ui(127,116,98)); box.zPosition=1; root.addChild(box) }
            guard index < record.count, record.slots.indices.contains(index), let slot = record.slots[index], let c = commanders[slot.commander] else {
                label("—", NativeRect(x:G.row(index).origin.x+10,y:G.row(index).origin.y+15,width:200,height:22), 8, ui(130,120,103), 3, root); continue
            }
            if let p = portrait(c.id) { placeAspectFit(p, G.portrait(index), 3); root.addChild(p) }
            if let info = sprite("image_ui_hd", "button_generalinfo_blue.png") { place(info, G.info(index), 6); root.addChild(info) }
            if let nameboard = sprite("image_ui_hd", "general_nameboard.png") { place(nameboard, G.nameBoard(index), 3); root.addChild(nameboard) }
            label(strings["name_\(c.name)"] ?? c.name, G.nameBoard(index), 6.5, ui(71,65,56), 4, root)
            if c.rank > 0, let rank = sprite("image_ui_hd", "rank_\(min(14,c.rank)).png") { placeAspectFit(rank, G.militaryRank(index), 4.5); root.addChild(rank) }
            if c.nobilityrank > 0, let noble = sprite("image_ui_hd", "class_\(min(9,c.nobilityrank)).png") { placeAspectFit(noble, G.nobilityRank(index), 4.5); root.addChild(noble) }
            if let costFrame = sprite("image_ui_hd", "common_lineframe.png") { place(costFrame, G.costGroup(index), 3); root.addChild(costFrame) }
            renderCost(index:index,row:0,file:"medals.png",value:slot.medal,root:root)
            renderCost(index:index,row:1,file:"marker_money.png",value:slot.money,root:root)
            renderCost(index:index,row:2,file:"marker_industry.png",value:slot.industry,root:root)
            let state = NativeBattleTavernCore.availability(slot:slot, round:round, resources:resources, ownedCommanderIDs:owned, commanders:commanders)
            if let n = sprite("image_ui_hd", "btn_common_green.png") { place(n,G.recruitButton(index),4); n.alpha = state == .available ? 1 : 0.38; root.addChild(n) }
            label(strings["btn_recruit"] ?? "雇佣", G.recruitButton(index), 7, .white, 5, root)
        }
        parent.addChild(root); self.root = root
    }

    func showCandidateInfo(index: Int, record: NativeBattleTavernRecord, commanders: [Int: Commander]) {
        guard detailRoot == nil,
              index >= 0, index < record.count,
              record.slots.indices.contains(index),
              let slot = record.slots[index],
              let commander = commanders[slot.commander],
              let parent else { return }
        let overlay = SKNode()
        overlay.position = CGPoint(x: 0, y: EW4LogicalSpace.height)
        overlay.zPosition = 27_000
        let dim = shape(.init(x:0,y:0,width:568,height:320), fill:ui(0,0,0,120), stroke:.clear)
        dim.zPosition = -2; overlay.addChild(dim)
        NativeOriginalGeneralInfoSurface.render(parent: overlay, store: store, portraits: portraits, strings: strings, items: items, commander: commander, z: 0)
        if let close = sprite("image_ui_hd", "button_close.png") { place(close, detailClose, 8); overlay.addChild(close) }
        parent.addChild(overlay)
        detailRoot = overlay
    }

    private func renderCost(index:Int,row:Int,file:String,value:Int,root:SKNode){
        if let n=sprite("image_ui_hd",file){placeAspectFit(n,G.costIcon(index,row:row),5);root.addChild(n)}
        label("\(value)",G.costText(index,row:row),5.1,ui(73,67,58),5,root)
    }
    private func portrait(_ id:Int)->SKSpriteNode? { guard let raw=portraits[String(id)] else { return nil }; let file=URL(fileURLWithPath:raw).lastPathComponent; guard let image=UIImage(contentsOfFile:store.url("Portraits",file).path)?.cgImage else{return nil}; return SKSpriteNode(texture:SKTexture(cgImage:image)) }
    private func sprite(_ folder:String,_ file:String)->SKSpriteNode? { guard let image=UIImage(contentsOfFile:store.url("Sprites/\(folder)",file).path)?.cgImage else{return nil}; return SKSpriteNode(texture:SKTexture(cgImage:image)) }
    private func shape(_ r:NativeRect, fill:UIColor, stroke:UIColor)->SKShapeNode { let n=SKShapeNode(rect:CGRect(x:r.origin.x,y:-(r.origin.y+r.size.height),width:r.size.width,height:r.size.height)); n.fillColor=fill;n.strokeColor=stroke;n.lineWidth=1;return n }
    private func place(_ n:SKSpriteNode,_ r:NativeRect,_ z:CGFloat){n.anchorPoint=CGPoint(x:0,y:1);n.position=CGPoint(x:r.origin.x,y:-r.origin.y);n.size=CGSize(width:r.size.width,height:r.size.height);n.zPosition=z}
    private func placeAspectFit(_ n:SKSpriteNode,_ r:NativeRect,_ z:CGFloat){let s=n.texture?.size() ?? .zero;guard s.width>0&&s.height>0 else{place(n,r,z);return};let scale=min(CGFloat(r.size.width)/s.width,CGFloat(r.size.height)/s.height),w=s.width*scale,h=s.height*scale;n.anchorPoint=CGPoint(x:0,y:1);n.position=CGPoint(x:r.origin.x+(r.size.width-Double(w))/2,y:-(r.origin.y+(r.size.height-Double(h))/2));n.size=CGSize(width:w,height:h);n.zPosition=z}
    private func label(_ s:String,_ r:NativeRect,_ fs:CGFloat,_ c:UIColor,_ z:CGFloat,_ parent:SKNode){let n=SKLabelNode(fontNamed:"PingFangSC-Semibold");n.text=s;n.fontSize=fs;n.fontColor=c;n.horizontalAlignmentMode = .center;n.verticalAlignmentMode = .center;n.position=CGPoint(x:r.origin.x+r.size.width/2,y:-(r.origin.y+r.size.height/2));n.zPosition=z;parent.addChild(n)}
    private func contains(_ r:NativeRect,_ p:NativePoint)->Bool{p.x>=r.origin.x&&p.y>=r.origin.y&&p.x<=r.origin.x+r.size.width&&p.y<=r.origin.y+r.size.height}
    private func ui(_ r:CGFloat,_ g:CGFloat,_ b:CGFloat,_ a:CGFloat=255)->UIColor{UIColor(red:r/255,green:g/255,blue:b/255,alpha:a/255)}
}
#endif
