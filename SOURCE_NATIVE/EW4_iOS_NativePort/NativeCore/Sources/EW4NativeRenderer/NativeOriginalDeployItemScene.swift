#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

/// Original-form binding for `form_deployitem`.
/// Presentation follows recovered 568h XML; equipment semantics remain in the mature HQ management core.
public final class NativeOriginalDeployItemScene: SKScene {
    public var backHandler: (() -> Void)?
    public var profileDidChangeHandler: ((NativePlayerProfile) -> Void)?
    public var statusHandler: ((String) -> Void)?
    public private(set) var profile: NativePlayerProfile

    private let store: NativeResourceStore
    private let commanders: [Int: Commander]
    private let portraits: [String: String]
    private let items: NativeItemEffectCatalog
    private let strings: [String:String]
    private let generalOverrides: NativePlayerGeneralOverrides
    private let princessOverrides: NativePlayerPrincessOverrides
    private var commanderIDs: [Int]
    private var commanderIndex: Int
    private var selectedEquipmentSlot = 0
    private var selectedBankIndex: Int? = nil
    private var inventoryScroll = 0.0
    private var dragStartY = 0.0
    private var dragStartScroll = 0.0
    private var draggingInventory = false
    private var dragged = false

    private let root = SKNode()
    private let inventoryCrop = SKCropNode()
    private let inventoryContent = SKNode()
    private typealias G = NativeOriginalFormGeometryCore.DeployItem

    public init(store: NativeResourceStore, profile: NativePlayerProfile, commanderID: Int) throws {
        self.store = store; self.profile = profile
        self.commanders = try store.commanders(); self.portraits = try store.portraitManifest(); self.items = try store.items(); self.strings = (try? store.stringsCN()) ?? [:]
        self.generalOverrides = try store.playerGeneralOverrides(); self.princessOverrides = try store.playerPrincessOverrides()
        self.commanderIDs = profile.ownedCommanderIDs.filter { self.commanders[$0] != nil }.sorted()
        self.commanderIndex = self.commanderIDs.firstIndex(of: commanderID) ?? 0
        super.init(size: CGSize(width: EW4LogicalSpace.width, height: EW4LogicalSpace.height))
        scaleMode = .aspectFit; anchorPoint = CGPoint(x: 0, y: 0); backgroundColor = .black
        root.position = CGPoint(x: 0, y: EW4LogicalSpace.height); addChild(root); render()
    }
    @available(*, unavailable) required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var commander: Commander? { guard commanderIDs.indices.contains(commanderIndex) else { return nil }; return commanders[commanderIDs[commanderIndex]] }

    private func render() {
        root.removeAllChildren()
        if let bg = textureNode("campaign_wide.png") { place(bg, .init(x: 0, y: 0, width: 568, height: 320), 0); root.addChild(bg) }
        let dim = shape(.init(x: 0, y: 0, width: 568, height: 320), fill: UIColor(white: 0, alpha: 0.35), stroke: .clear); dim.zPosition = 1; root.addChild(dim)
        if let board = sprite("image_ui_hd", "form_back.png") { place(board, G.screenFrame, 2); root.addChild(board) }
        else { let board = shape(G.screenFrame, fill: ui(222,216,203), stroke: ui(111,104,92)); board.zPosition = 2; root.addChild(board) }
        label(strings["title_deployitem"] ?? "物  品", .init(x:G.screenFrame.origin.x,y:G.screenFrame.origin.y+4,width:G.screenFrame.size.width,height:22), 9, ui(75,69,61), 4)
        if let close = sprite("image_ui_hd", "button_close.png") { place(close, G.closeButton, 8); root.addChild(close) }
        if let prev = sprite("image_ui_hd", "button_changegeneral_gray.png") { place(prev, G.prevButton, 5); root.addChild(prev) }
        if let next = sprite("image_ui_hd", "button_changegeneral_gray_2.png") { place(next, G.nextButton, 5); root.addChild(next) }
        guard let c = commander else { label(strings["text_empty"] ?? "无", .init(x:G.screenFrame.origin.x,y:120,width:G.screenFrame.size.width,height:30), 9, ui(70,65,57), 6); return }
        renderCommander(c)
        renderInventory()
        renderDescription(c)
    }

    private func renderCommander(_ c: Commander) {
        if let p = portraitNode(id: c.id) { place(p, G.commanderPortrait, 5); root.addChild(p); let border=shape(G.commanderPortrait,fill:.clear,stroke:ui(119,105,79));border.zPosition=5.1;root.addChild(border) }
        if let nameboard=sprite("image_ui_hd","general_nameboard.png"){place(nameboard,G.commanderName,5.2);root.addChild(nameboard)}
        label(strings["name_\(c.name)"] ?? c.name, G.commanderName, 6.2, ui(73,67,58), 6)

        if let frame=sprite("image_ui_hd","common_lineframe_bold.png"){place(frame,G.levelGroup,4);root.addChild(frame)}
        let growth = NativePlayerProfileCore.generalGrowthState(profile: profile, raw: c)
        let effective = NativePlayerProfileCore.effectiveCommander(raw:c,playerControlled:true,profile:profile,generalOverrides:generalOverrides,princessOverrides:princessOverrides)
        if growth.rank > 0, let rank=sprite("image_ui_hd","rank_\(min(14,growth.rank)).png"){placeAspectFit(rank,G.militaryRank,5);root.addChild(rank)}
        if growth.nobility > 0, let noble=sprite("image_ui_hd","class_\(min(9,growth.nobility)).png"){placeAspectFit(noble,G.nobilityRank,5);root.addChild(noble)}
        if let hp=sprite("image_ui_hd","marker_hp_dark.png"){place(hp,G.hpMarker,5);root.addChild(hp)}
        if let heal=sprite("image_ui_hd","marker_recover_dark.png"){place(heal,G.recoverMarker,5);root.addChild(heal)}
        label("+\(effective.rankHPBonus)",G.hpText,5.2,ui(64,64,64),6)
        let healValue=NativeRoundSettlementCore.nobilityHeal(level:effective.nobilityLevel,cap:effective.nobilityHealCap,maxLevel:max(1,generalOverrides.global.nobilityMaxLevel))
        label("+\(healValue)",G.recoverText,5.2,ui(64,64,64),6)

        label(strings["text_equipitem"] ?? "装备",G.equipmentTitle,6.2,ui(90,83,73),5)
        if let line=sprite("image_ui_hd","common_line_hor.png"){place(line,.init(x:G.equipmentGroup.origin.x,y:G.equipmentGroup.origin.y+23,width:G.equipmentGroup.size.width,height:1),4.5);root.addChild(line)}
        let pair = NativeHeadquartersManagementCore.equipmentPair(profile: profile, commander: c)
        for i in 0..<2 {
            let r = G.equipmentSlots[i]
            if let id = pair[i], let item = item(id), let icon = itemNode(item) { placeAspectFit(icon, .init(x:r.origin.x+2,y:r.origin.y+2,width:41,height:41), 6); root.addChild(icon) }
            if i == selectedEquipmentSlot, let sel=sprite("image_ui_hd","item_selected_ex.png"){place(sel,r,7);root.addChild(sel)}
        }
        if let frame=sprite("image_ui_hd","common_lineframe_bold.png"){place(frame,G.descriptionGroup,4);root.addChild(frame)}
        if let split=sprite("image_ui_hd","common_boldline.png"){place(split,G.split,4.5);root.addChild(split)}
        if let group=sprite("image_ui_hd","common_lineframe_bold.png"){place(group,G.itemsGroup,4);root.addChild(group)}
        let buttonText=equipButtonText(c)
        if let b=sprite("image_ui_hd", "button_confirm_blue.png") { place(b, G.equipButton, 7); root.addChild(b) }
        label(buttonText, G.equipButton, 6.5, .white, 8)
    }

    private func renderDescription(_ c: Commander) {
        let bank = NativeHQItemInventoryCore.decode(profile.document["itemInventory"])
        let selectedID: Int? = selectedBankIndex.flatMap { bank.slots.indices.contains($0) && !bank.slots[$0].isEmpty ? bank.slots[$0].item : nil }
        let current = NativeHeadquartersManagementCore.equipmentPair(profile: profile, commander: c)[selectedEquipmentSlot]
        let chosen: Int? = selectedBankIndex == nil ? current : selectedID
        guard let chosen, let def = item(chosen) else {
            label(strings["text_empty"] ?? "无",G.descriptionTitle,6.2,ui(70,64,56),6)
            label(selectedBankIndex == nil ? "选择物品\n或空格卸下" : "空槽\n确认后卸下", G.descriptionText, 5.8, ui(80,73,64), 6, lines: 2); return
        }
        let name=strings["name_\(def.name)"] ?? def.name
        let desc=strings["desc_\(def.name)"] ?? "效果 \(def.function)　数值 \(def.value)"
        label(name,G.descriptionTitle,6.4,ui(70,64,56),6)
        let flags = [NativeHQItemInventoryCore.isConsumable(def) ? "战场消耗品不能装备" : nil, def.flag != nil ? "需要“旗手”技能" : nil].compactMap{$0}
        let text=([desc]+flags).joined(separator:"\n")
        label(text,G.descriptionText,5.2,ui(87,79,69),6,lines:min(4,max(1,text.split(separator:"\n").count)))
    }

    private func renderInventory() {
        inventoryCrop.removeFromParent(); inventoryCrop.maskNode = nil; inventoryContent.removeAllChildren()
        let mask = SKShapeNode(rect: CGRect(x: G.itemGrid.origin.x, y: -(G.itemGrid.origin.y + G.itemGrid.size.height), width: G.itemGrid.size.width, height: G.itemGrid.size.height)); mask.fillColor = .white; mask.strokeColor = .clear
        inventoryCrop.maskNode = mask; inventoryCrop.zPosition = 5; root.addChild(inventoryCrop); inventoryCrop.addChild(inventoryContent)
        let bank = NativeHQItemInventoryCore.decode(profile.document["itemInventory"])
        for i in 0..<NativeItemInventoryBank.size {
            let r=G.itemRect(index:i,scroll:inventoryScroll)
            let slot=bank.slots[i]
            if !slot.isEmpty, let def=item(slot.item) {
                if let icon=itemNode(def){placeAspectFit(icon,.init(x:r.origin.x+2,y:r.origin.y+2,width:41,height:37),2);inventoryContent.addChild(icon)}
                if slot.count>1{label("×\(slot.count)",.init(x:r.origin.x+2,y:r.origin.y+35,width:41,height:9),4.5,ui(75,68,59),3,parent:inventoryContent)}
            }
            if selectedBankIndex == i, let sel=sprite("image_ui_hd","item_selected_ex.png"){place(sel,r,3.5);inventoryContent.addChild(sel)}
        }
        if let track=sprite("image_ui_hd","scrollbar_gray.png"){place(track,G.scrollbarTrack,7);root.addChild(track)}
        if let thumb=sprite("image_ui_hd","scrollbar_darkgray.png"){
            let r=NativeRect(x:G.scrollbarTrack.origin.x,y:G.scrollbarTrack.origin.y+G.thumbOffset(scroll:inventoryScroll),width:G.scrollbarTrack.size.width,height:G.thumbHeight)
            place(thumb,r,8);root.addChild(thumb)
        }
    }

    public override func touchesBegan(_ touches:Set<UITouch>,with event:UIEvent?){guard let t=touches.first else{return};let p=nativePoint(t.location(in:self));dragStartY=p.y;dragStartScroll=inventoryScroll;draggingInventory=contains(G.itemGrid,p);dragged=false}
    public override func touchesMoved(_ touches:Set<UITouch>,with event:UIEvent?){guard draggingInventory,let t=touches.first else{return};let p=nativePoint(t.location(in:self));let d=dragStartY-p.y;if abs(d)>3{dragged=true};inventoryScroll=G.clampedScroll(dragStartScroll+d);renderInventory()}
    public override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent?){
        guard let t=touches.first else{return};let p=nativePoint(t.location(in:self));defer{draggingInventory=false;dragged=false}
        if contains(G.closeButton,p){backHandler?();return};if dragged{return}
        if contains(G.prevButton,p){cycle(-1);return};if contains(G.nextButton,p){cycle(1);return}
        for i in 0..<2 where contains(G.equipmentSlots[i],p){selectedEquipmentSlot=i;selectedBankIndex=nil;render();return}
        if let idx=inventoryIndex(at:p){selectedBankIndex=idx;render();return}
        if contains(G.equipButton,p){applyEquipment()}
    }

    private func cycle(_ delta:Int){guard !commanderIDs.isEmpty else{return};commanderIndex=(commanderIndex+delta+commanderIDs.count)%commanderIDs.count;selectedEquipmentSlot=0;selectedBankIndex=nil;inventoryScroll=0;render()}
    private func equipButtonText(_ c:Commander)->String{
        guard let idx=selectedBankIndex else{return strings["btn_equip"] ?? "装备"}
        let bank=NativeHQItemInventoryCore.decode(profile.document["itemInventory"])
        let empty = !bank.slots.indices.contains(idx) || bank.slots[idx].isEmpty
        let current=NativeHeadquartersManagementCore.equipmentPair(profile:profile,commander:c)[selectedEquipmentSlot]
        return empty && current != nil ? (strings["btn_remove"] ?? "卸下") : (strings["btn_equip"] ?? "装备")
    }
    private func applyEquipment(){guard let c=commander else{return};guard selectedBankIndex != nil else{statusHandler?("请先选择物品，选择空槽可卸下");return};let r=NativeHeadquartersManagementCore.equip(profile:&profile,commander:c,slot:selectedEquipmentSlot,inventoryIndex:selectedBankIndex,items:items,generalOverrides:generalOverrides,princessOverrides:princessOverrides);if r.ok{profileDidChangeHandler?(profile);selectedBankIndex=nil;statusHandler?("装备已更新");render()}else{statusHandler?(managementMessage(r.reason))}}
    private func managementMessage(_ reason:NativeHQManagementFailure?)->String{switch reason{case .consumable:return"消耗品不能装备";case .flagSkill:return"需要旗手技能";case .full:return"物品栏已满，无法换下旧装备";case .inventory:return"物品槽无效";default:return"装备操作被阻止"}}
    private func inventoryIndex(at p:NativePoint)->Int?{guard contains(G.itemGrid,p)else{return nil};for i in 0..<NativeItemInventoryBank.size{if contains(G.itemRect(index:i,scroll:inventoryScroll),p){return i}};return nil}
    private func item(_ id:Int)->NativeItemEffectDefinition?{items[String(id)] ?? items.values.first(where:{$0.id==id})}
    private func itemNode(_ item:NativeItemEffectDefinition)->SKSpriteNode?{let file=item.name.replacingOccurrences(of:" ",with:"_")+".png";guard let image=UIImage(contentsOfFile:store.url("Items",file).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:image))}
    private func portraitNode(id:Int)->SKSpriteNode?{guard let raw=portraits[String(id)] else{return nil};let file=URL(fileURLWithPath:raw).lastPathComponent;guard let image=UIImage(contentsOfFile:store.url("Portraits",file).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:image))}
    private func textureNode(_ file:String)->SKSpriteNode?{guard let image=UIImage(contentsOfFile:store.url("Textures",file).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:image))}
    private func sprite(_ folder:String,_ file:String)->SKSpriteNode?{guard let image=UIImage(contentsOfFile:store.url("Sprites/\(folder)",file).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:image))}
    private func shape(_ rect:NativeRect,fill:UIColor,stroke:UIColor)->SKShapeNode{let n=SKShapeNode(rect:CGRect(x:rect.origin.x,y:-(rect.origin.y+rect.size.height),width:rect.size.width,height:rect.size.height));n.fillColor=fill;n.strokeColor=stroke;n.lineWidth=1;return n}
    private func place(_ n:SKSpriteNode,_ r:NativeRect,_ z:CGFloat){n.anchorPoint=CGPoint(x:0,y:1);n.position=CGPoint(x:r.origin.x,y:-r.origin.y);n.size=CGSize(width:r.size.width,height:r.size.height);n.zPosition=z}
    private func placeAspectFit(_ n:SKSpriteNode,_ r:NativeRect,_ z:CGFloat){let s=n.texture?.size() ?? .zero;guard s.width>0 && s.height>0 else{place(n,r,z);return};let scale=min(CGFloat(r.size.width)/s.width,CGFloat(r.size.height)/s.height),w=s.width*scale,h=s.height*scale;n.anchorPoint=CGPoint(x:0,y:1);n.position=CGPoint(x:r.origin.x+(r.size.width-Double(w))/2,y:-(r.origin.y+(r.size.height-Double(h))/2));n.size=CGSize(width:w,height:h);n.zPosition=z}
    private func label(_ text:String,_ r:NativeRect,_ size:CGFloat,_ color:UIColor,_ z:CGFloat,parent:SKNode?=nil,lines:Int=1){if lines>1||text.contains("\n"){let a=text.split(separator:"\n",omittingEmptySubsequences:false);let count=max(1,min(lines,a.count));let h=r.size.height/Double(count);for i in 0..<count{label(String(a[i]),.init(x:r.origin.x,y:r.origin.y+Double(i)*h,width:r.size.width,height:h),size,color,z,parent:parent)};return};let n=SKLabelNode(fontNamed:"PingFangSC-Semibold");n.text=text;n.fontSize=size;n.fontColor=color;n.horizontalAlignmentMode = .center;n.verticalAlignmentMode = .center;n.position=CGPoint(x:r.origin.x+r.size.width/2,y:-(r.origin.y+r.size.height/2));n.zPosition=z;(parent ?? root).addChild(n)}
    private func nativePoint(_ p:CGPoint)->NativePoint{.init(x:p.x,y:EW4LogicalSpace.height-p.y)}
    private func contains(_ r:NativeRect,_ p:NativePoint)->Bool{p.x>=r.origin.x&&p.y>=r.origin.y&&p.x<=r.origin.x+r.size.width&&p.y<=r.origin.y+r.size.height}
    private func ui(_ r:CGFloat,_ g:CGFloat,_ b:CGFloat,_ a:CGFloat=255)->UIColor{UIColor(red:r/255,green:g/255,blue:b/255,alpha:a/255)}
}
#endif
