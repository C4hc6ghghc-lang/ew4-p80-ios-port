#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

final class NativeOriginalRecruitUnitRenderer {
    enum Action: Equatable { case close, confirm, select(Int), none }
    private weak var parent: SKNode?
    private let store: NativeResourceStore
    private let strings: [String:String]
    private let armyStats: ArmyStatsCatalog
    private var root: SKNode?
    private var rows: [Int: NativeRect] = [:]
    private var definitions: [NativeRecruitDefinition] = []
    private var cards: NativeRecruitCardCatalog = [:]
    private var resources = CountryResources(money: 0, industry: 0, food: 0)
    private var countryCode = "others"
    private(set) var selectedRow = 0
    private(set) var selectedGrade = 0

    private let screen = NativeOriginalFormGeometryCore.Recruit.screenFrame
    private let closeRect = NativeOriginalFormGeometryCore.Recruit.closeButton
    private let okRect = NativeOriginalFormGeometryCore.Recruit.okButton

    init(parent: SKNode, store: NativeResourceStore) { self.parent = parent; self.store = store; self.strings = (try? store.stringsCN()) ?? [:]; self.armyStats = (try? store.armyStats()) ?? [:] }
    var isVisible: Bool { root != nil }
    func hide() { root?.removeFromParent(); root = nil; rows.removeAll() }

    func show(definitions: [NativeRecruitDefinition], cards: NativeRecruitCardCatalog, resources: CountryResources, countryCode: String, resetSelection: Bool = true) {
        self.definitions = definitions; self.cards = cards; self.resources = resources; self.countryCode = countryCode
        if resetSelection { selectedRow = 0; selectedGrade = 0 }
        if selectedRow >= definitions.count { selectedRow = max(0, definitions.count - 1); selectedGrade = 0 }
        render()
    }

    func select(row: Int) {
        guard definitions.indices.contains(row) else { return }
        if row == selectedRow { selectedGrade = min(definitions[row].grade, selectedGrade + 1) }
        else { selectedRow = row; selectedGrade = 0 }
        render()
    }

    func selectedRecruit() -> (NativeRecruitDefinition, NativeRecruitCardDefinition)? {
        guard definitions.indices.contains(selectedRow) else { return nil }
        let cap = definitions[selectedRow]
        let rec = NativeRecruitDefinition(name: cap.name, grade: max(0, min(cap.grade, selectedGrade)))
        guard let card = NativeBattleConstructionCore.card(cap, grade: rec.grade, cards: cards) else { return nil }
        return (rec, card)
    }

    func rect(alias: String, row: Int?) -> NativeRect? {
        if alias == "lbox_unit", let row { return rows[row] }
        if alias == "winbtn_close" { return closeRect }
        if alias == "winbtn_ok" { return okRect }
        return nil
    }

    func action(at point: NativePoint) -> Action {
        if contains(closeRect, point) { return .close }
        if contains(okRect, point) { return .confirm }
        for (i, r) in rows where contains(r, point) { return .select(i) }
        return .none
    }

    private func render() {
        hide(); guard let parent, !definitions.isEmpty else { return }
        let root = SKNode(); root.position = CGPoint(x: 0, y: EW4LogicalSpace.height); root.zPosition = 25_000
        let dim = SKShapeNode(rect: CGRect(x:0,y:-EW4LogicalSpace.height,width:EW4LogicalSpace.width,height:EW4LogicalSpace.height)); dim.fillColor=UIColor(white:0,alpha:0.38); dim.strokeColor = .clear; dim.zPosition = -2; root.addChild(dim)
        root.addChild(shape(screen, fill: ui(231,224,210), stroke: ui(104,94,80)))
        root.addChild(shape(NativeRect(x:screen.origin.x,y:screen.origin.y,width:screen.size.width,height:27), fill:ui(214,204,187), stroke:ui(124,112,95)))
        label(strings["title_recruitunit"] ?? strings["title_recruit"] ?? "雇  佣", NativeRect(x:screen.origin.x,y:screen.origin.y+3,width:screen.size.width,height:20), 11, ui(75,68,58), 4, root)
        if let n=sprite("image_ui_hd","button_close.png"){place(n,closeRect,8);root.addChild(n)}
        if let n=sprite("image_ui_hd","button_confrim.png") ?? sprite("image_ui_hd","new_confirm.png"){place(n,okRect,8);root.addChild(n)}
        let listLocal = NativeOriginalFormGeometryCore.Recruit.list
        let listX = screen.origin.x + listLocal.origin.x
        let listY = screen.origin.y + listLocal.origin.y
        let cardW = NativeOriginalFormGeometryCore.Recruit.listItemWidth
        let gap = NativeOriginalFormGeometryCore.Recruit.listInterval
        for (i,cap) in definitions.enumerated() {
            let r=NativeRect(x:listX+Double(i)*(cardW+gap),y:listY,width:cardW,height:listLocal.size.height); rows[i]=r
            let selected=i==selectedRow
            let bg=shape(r, fill:ui(204,195,178), stroke:ui(126,115,96)); bg.zPosition=2; root.addChild(bg)
            let art = NativeOriginalRecruitArtCore.art(for: cap.name)
            if let unit=spritePath(art.unitPath){place(unit,NativeRect(x:r.origin.x+8.5,y:r.origin.y+2,width:55,height:46),3);root.addChild(unit)}
            if let frame=sprite("image_recruit_hd","build_frame.png"){place(frame,r,4);root.addChild(frame)}
            if selected, let sel=sprite("image_ui_hd","item_selected_ex.png"){place(sel,r,5);root.addChild(sel)}
            label(strings["name_\(cap.name)"] ?? cap.name, NativeRect(x:r.origin.x+2,y:r.origin.y+48,width:r.size.width-4,height:8), 5.2, ui(69,62,53),6,root)
            label("最多 \(cap.grade+1)编", NativeRect(x:r.origin.x+2,y:r.origin.y+56,width:r.size.width-4,height:8),4.7,ui(87,78,65),6,root)
        }
        if let selected=selectedRecruit() {
            let rec=selected.0, card=selected.1
            let infoLocal=NativeOriginalFormGeometryCore.Recruit.infoGrid
            let descLocal=NativeOriginalFormGeometryCore.Recruit.description
            let info=NativeRect(x:screen.origin.x+infoLocal.origin.x,y:screen.origin.y+infoLocal.origin.y,width:infoLocal.size.width,height:infoLocal.size.height)
            let desc=NativeRect(x:screen.origin.x+descLocal.origin.x,y:screen.origin.y+descLocal.origin.y,width:descLocal.size.width,height:descLocal.size.height)
            root.addChild(shape(info,fill:ui(224,216,201),stroke:ui(125,114,96))); root.addChild(shape(desc,fill:ui(224,216,201),stroke:ui(125,114,96)))
            label("\(strings["name_\(rec.name)"] ?? rec.name) · \(rec.grade+1)编",NativeRect(x:desc.origin.x+4,y:desc.origin.y+1,width:desc.size.width-8,height:15),7,ui(70,63,54),4,root)
            paragraph(strings["desc_\(rec.name)"] ?? card.intro ?? "",NativeRect(x:desc.origin.x+2,y:desc.origin.y+19,width:desc.size.width-4,height:51),5.5,ui(70,63,54),4,root)
            drawInfoGrid(recruit: rec, maxGrade: definitions[selectedRow].grade, card: card, rect: info, root: root)
        }
        parent.addChild(root); self.root=root
    }

    private func drawInfoGrid(recruit: NativeRecruitDefinition, maxGrade: Int, card: NativeRecruitCardDefinition, rect: NativeRect, root: SKNode) {
        guard let stat = ArmyStatsCore.resolve(catalog: armyStats, countryCode: countryCode, armyName: recruit.name, grade: recruit.grade) else { return }
        let interval = CombatCore.effectiveAttackInterval(min: stat.minatk, max: stat.maxatk, isPlayer: true)
        let hp = PlayerUnitRules.effectiveBaseHP(strength: stat.strength, isPlayer: true)
        let movement = PlayerUnitRules.effectiveMovement(stat.movement, type: stat.type, isPlayer: true)
        let columns = NativeOriginalFormGeometryCore.Recruit.infoColumns
        let cellW = rect.size.width / Double(columns)
        let cellH = NativeOriginalFormGeometryCore.Recruit.infoRowHeight
        for row in 1..<3 {
            if let line = sprite("image_ui_hd", "common_line_hor.png") { place(line, .init(x:rect.origin.x,y:rect.origin.y+Double(row)*cellH,width:rect.size.width,height:1), 4); root.addChild(line) }
        }
        let cells: [(String, String)] = [
            ("infomarker_hp.png", String(hp)),
            ("infomarker_attack.png", "\(interval.min)-\(interval.max)"),
            ("infomarker_move.png", String(movement)),
            ("infomarker_food.png", String(stat.consumption)),
            ("infomarker_range.png", "\(stat.minatkrange)-\(stat.maxatkrange)"),
            ("marker_money.png", String(card.price)),
            ("marker_industry.png", String(card.industry)),
            ("infomarker_soldiernumber.png", "\(recruit.grade+1)/\(maxGrade+1)"),
        ]
        for i in 0..<(columns * 3) {
            let col=i%columns,row=i/columns
            let r=NativeRect(x:rect.origin.x+Double(col)*cellW,y:rect.origin.y+Double(row)*cellH,width:cellW,height:cellH)
            if col > 0 { let v=shape(.init(x:r.origin.x,y:r.origin.y,width:0.5,height:cellH),fill:ui(151,141,122),stroke:.clear);v.zPosition=4;root.addChild(v) }
            guard i < cells.count else { continue }
            let entry = cells[i]
            if let icon=sprite("image_ui_hd",entry.0) { place(icon,.init(x:r.origin.x+2,y:r.origin.y+5,width:13,height:13),5);root.addChild(icon) }
            label(entry.1,.init(x:r.origin.x+15,y:r.origin.y,width:r.size.width-16,height:r.size.height),5.2,ui(67,60,49),5,root)
        }
    }

    private func spritePath(_ path:String)->SKSpriteNode?{let parts=path.split(separator:"/",maxSplits:1).map(String.init);guard parts.count==2 else{return nil};return sprite(parts[0],parts[1])}
    private func sprite(_ folder:String,_ file:String)->SKSpriteNode?{guard let image=UIImage(contentsOfFile:store.url("Sprites/\(folder)",file).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:image))}
    private func shape(_ r:NativeRect,fill:UIColor,stroke:UIColor)->SKShapeNode{let n=SKShapeNode(rect:CGRect(x:r.origin.x,y:-(r.origin.y+r.size.height),width:r.size.width,height:r.size.height));n.fillColor=fill;n.strokeColor=stroke;n.lineWidth=1;return n}
    private func place(_ n:SKSpriteNode,_ r:NativeRect,_ z:CGFloat){n.anchorPoint=CGPoint(x:0,y:1);n.position=CGPoint(x:r.origin.x,y:-r.origin.y);n.size=CGSize(width:r.size.width,height:r.size.height);n.zPosition=z}
    private func label(_ s:String,_ r:NativeRect,_ fs:CGFloat,_ c:UIColor,_ z:CGFloat,_ p:SKNode){let n=SKLabelNode(fontNamed:"PingFangSC-Semibold");n.text=s;n.fontSize=fs;n.fontColor=c;n.horizontalAlignmentMode = .center;n.verticalAlignmentMode = .center;n.position=CGPoint(x:r.origin.x+r.size.width/2,y:-(r.origin.y+r.size.height/2));n.zPosition=z;p.addChild(n)}
    private func paragraph(_ s:String,_ r:NativeRect,_ fs:CGFloat,_ c:UIColor,_ z:CGFloat,_ p:SKNode){let n=SKLabelNode(fontNamed:"PingFangSC-Regular");n.text=s;n.fontSize=fs;n.fontColor=c;n.horizontalAlignmentMode = .left;n.verticalAlignmentMode = .top;n.numberOfLines=3;n.preferredMaxLayoutWidth=CGFloat(r.size.width);n.position=CGPoint(x:r.origin.x,y:-r.origin.y);n.zPosition=z;p.addChild(n)}
    private func contains(_ r:NativeRect,_ p:NativePoint)->Bool{p.x>=r.origin.x&&p.y>=r.origin.y&&p.x<=r.origin.x+r.size.width&&p.y<=r.origin.y+r.size.height}
    private func ui(_ r:CGFloat,_ g:CGFloat,_ b:CGFloat,_ a:CGFloat=255)->UIColor{UIColor(red:r/255,green:g/255,blue:b/255,alpha:a/255)}
}
#endif
