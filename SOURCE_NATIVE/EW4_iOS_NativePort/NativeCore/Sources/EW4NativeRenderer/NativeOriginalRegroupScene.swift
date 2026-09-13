#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

/// Native binding for the mature Regroup flow. The source commander is consumed permanently;
/// its equipment is intentionally not returned, matching the frozen controller contract.
public final class NativeOriginalRegroupScene: SKScene {
    public var backHandler:(()->Void)?
    public var profileDidChangeHandler:((NativePlayerProfile)->Void)?
    public var completedHandler:(()->Void)?
    public var statusHandler:((String)->Void)?
    public private(set) var profile:NativePlayerProfile
    private let store:NativeResourceStore; private let commanders:[Int:Commander]; private let portraits:[String:String]; private let items:NativeItemEffectCatalog; private let strings:[String:String]
    private let generalOverrides:NativePlayerGeneralOverrides; private let princessOverrides:NativePlayerPrincessOverrides
    private let targetID:Int; private var sourceID:Int?; private var scroll=0.0; private var startX=0.0; private var startScroll=0.0; private var dragging=false; private var dragged=false; private var confirm=false
    private let root=SKNode(); private let listCrop=SKCropNode(); private let listContent=SKNode(); private let overlay=SKNode()
    private let listViewport=NativeOriginalFormGeometryCore.Regroup.generalList; private let cardW=78.0; private let gap=10.0
    private let backRect=NativeRect(x:0,y:275,width:45,height:45); private let commitRect=NativeOriginalFormGeometryCore.Regroup.regroupButton
    private let confirmRect=NativeOriginalFormGeometryCore.RegroupConfirm.confirmButton; private let cancelRect=NativeOriginalFormGeometryCore.RegroupConfirm.cancelButton
    public init(store:NativeResourceStore,profile:NativePlayerProfile,targetID:Int)throws{
        self.store=store;self.profile=profile;self.targetID=targetID;commanders=try store.commanders();portraits=try store.portraitManifest();items=try store.items();strings=(try? store.stringsCN()) ?? [:];generalOverrides=try store.playerGeneralOverrides();princessOverrides=try store.playerPrincessOverrides()
        let choices=profile.ownedCommanderIDs.filter{$0 != targetID && !NativePlayerProfile.princessIDs.contains($0) && commanders[$0] != nil}.sorted();sourceID=choices.first
        super.init(size:CGSize(width:568,height:320));scaleMode = .aspectFit;anchorPoint=CGPoint(x:0,y:0);backgroundColor = .black;root.position=CGPoint(x:0,y:320);addChild(root);render()
    }
    @available(*,unavailable) required init?(coder:NSCoder){fatalError()}
    private var sources:[Int]{profile.ownedCommanderIDs.filter{$0 != targetID && !NativePlayerProfile.princessIDs.contains($0) && commanders[$0] != nil}.sorted()}
    private func render(){root.removeAllChildren();if let bg=texture("campaign_wide.png"){place(bg,.init(x:0,y:0,width:568,height:320),0);root.addChild(bg)};let veil=shape(.init(x:0,y:0,width:568,height:320),ui(220,214,202),ui(111,104,92));veil.zPosition=1;veil.alpha=0.94;root.addChild(veil);label(strings["title_regroup"] ?? "整  编",.init(x:0,y:8,width:568,height:25),11,ui(72,66,58),3);if let b=sprite("image_ui_hd","button_back.png"){place(b,backRect,8);root.addChild(b)};renderCards();renderList();overlay.zPosition=50;root.addChild(overlay);if confirm{renderConfirm()}}
    private func renderCards(){
        guard let target=commanders[targetID] else{return}
        let G=NativeOriginalFormGeometryCore.Regroup.self
        drawCommander(target,rect:G.targetCommander)
        if let sid=sourceID,let source=commanders[sid]{
            drawCommander(source,rect:G.sourceCommander)
            if let p=NativeHeadquartersManagementCore.regroupPreview(profile:profile,target:target,source:source,generalOverrides:generalOverrides,princessOverrides:princessOverrides){renderPreviewGroup(target:target,preview:p)}
            renderMainEquipment(source)
        }else{
            label(strings["text_empty"] ?? "无",G.sourceCommander,7,ui(100,90,77),4)
            renderPreviewShell()
            renderEquipmentShell()
        }
        if let arrow=sprite("image_ui_hd","arrow_reoganizion.png"){place(arrow,G.arrow,6);root.addChild(arrow)}
        if let b=sprite("image_ui_hd","btn_common_red.png"){place(b,commitRect,7);b.alpha=sourceID == nil ? 0.35:1;root.addChild(b)}
        label(strings["btn_regroup"] ?? "整编",commitRect,7,.white,8)
        label(strings["text_notice"] ?? "注意：被整编的将领和物品会消失",G.notice,5.8,ui(84,76,66),6)
        if let line=sprite("image_ui_hd","common_line_hor.png"){place(line,G.middleLine,5.5);root.addChild(line)}
        if let line=sprite("image_ui_hd","common_line_hor.png"){place(line,G.lowerLine,5.5);root.addChild(line)}
        if let pattern=sprite("image_ui_hd","pattern_bg_bottom.png"){place(pattern,G.bottomPattern,5.2);root.addChild(pattern)}
        if let line=sprite("image_ui_hd","common_boldline.png"){place(line,G.bottomBoldLine,5.6);root.addChild(line)}
    }

    private func drawCommander(_ c:Commander,rect:NativeRect,parent:SKNode?=nil,selected:Bool=false){
        let holder=parent ?? root
        if selected,let sel=sprite("image_ui_hd","item_selected_ex.png"){place(sel,rect,3.05);holder.addChild(sel)}
        if let p=portrait(c.id){place(p,.init(x:rect.origin.x+3,y:rect.origin.y,width:72,height:72),4);holder.addChild(p);let border=shape(.init(x:rect.origin.x+3,y:rect.origin.y,width:72,height:72),.clear,ui(119,105,79));border.zPosition=4.2;holder.addChild(border)}
        label(strings["name_\(c.name)"] ?? c.name,.init(x:rect.origin.x,y:rect.origin.y+72,width:78,height:13),6.2,ui(70,64,56),5,parent:holder)
        let g=NativePlayerProfileCore.generalGrowthState(profile:profile,raw:c)
        label("军\(g.rank) · 爵\(g.nobility)",.init(x:rect.origin.x,y:rect.origin.y+85,width:78,height:13),5.1,ui(84,76,66),5,parent:holder)
    }

    private func renderPreviewShell(){
        let G=NativeOriginalFormGeometryCore.Regroup.self
        if let frame=sprite("image_ui_hd","common_lineframe_bold.png"){place(frame,G.previewGroup,3);root.addChild(frame)}else{let n=shape(G.previewGroup,.clear,ui(126,118,106));n.zPosition=3;root.addChild(n)}
        if let title=sprite("image_ui_hd","infomarker_board.png"){place(title,G.previewTitle,3.2);root.addChild(title)}
        label(strings["text_preview"] ?? "预览",G.previewTitle,6.5,ui(82,75,65),4)
        if let box=sprite("image_ui_hd","common_lineframe.png"){place(box,G.previewGridFrame,3.1);root.addChild(box)}
        if let line=sprite("image_ui_hd","common_line_hor.png"){place(line,G.previewGridSplit,3.4);root.addChild(line)}
    }

    private func renderPreviewGroup(target:Commander,preview:NativeHQRegroupPreview){
        renderPreviewShell()
        let G=NativeOriginalFormGeometryCore.Regroup.self
        label("军\(preview.rank)",G.previewMilitary,5.2,ui(75,69,61),4)
        label("爵\(preview.nobility)",G.previewNobility,5.2,ui(75,69,61),4)
        if let hp=sprite("image_ui_hd","marker_hp_dark.png"){place(hp,G.previewHPMarker,3.5);root.addChild(hp)}
        if let heal=sprite("image_ui_hd","marker_recover_dark.png"){place(heal,G.previewRecoverMarker,3.5);root.addChild(heal)}
        let hpValue=previewRankHP(target:target,rank:preview.rank), healValue=previewNobilityHeal(target:target,nobility:preview.nobility)
        label("+\(hpValue)",G.previewHPText,4.7,ui(64,64,64),4)
        label("+\(healValue)",G.previewRecoverText,4.7,ui(64,64,64),4)
        let labels=["infantry":strings["btn_infantry"] ?? "步兵","cavalry":strings["btn_cavalry"] ?? "骑兵","artillery":strings["btn_artillery"] ?? "炮兵","warship":strings["btn_navy"] ?? "海军","fort":strings["btn_fortress"] ?? "要塞","business":strings["text_economy"] ?? "经济","movement":"行军"]
        let rows=preview.teachingBonuses.sorted{$0.key<$1.key}.prefix(4)
        for(i,e) in rows.enumerated(){label("\(labels[e.key] ?? e.key)+\(e.value)",G.previewGridCells[i],4.6,ui(78,71,62),4)}
    }

    private func previewRankHP(target:Commander,rank:Int)->Int{
        let record=NativePlayerProfile.princessIDs.contains(target.id) ? princessOverrides.princesses[String(target.id)] : generalOverrides.generals[String(target.id)]
        let cap=max(0,record?.rankHpBonusCap ?? generalOverrides.global.rankHpBonusCap), maxLevel=max(1,generalOverrides.global.rankMaxLevel)
        return Int((Double(cap * max(0,min(maxLevel,rank))) / Double(maxLevel)).rounded())
    }
    private func previewNobilityHeal(target:Commander,nobility:Int)->Int{
        let record=NativePlayerProfile.princessIDs.contains(target.id) ? princessOverrides.princesses[String(target.id)] : generalOverrides.generals[String(target.id)]
        let cap=max(0,record?.nobilityHealCap ?? generalOverrides.global.nobilityHealCap), maxLevel=max(1,generalOverrides.global.nobilityMaxLevel)
        return Int((Double(cap * max(0,min(maxLevel,nobility))) / Double(maxLevel)).rounded())
    }

    private func renderEquipmentShell(){
        let G=NativeOriginalFormGeometryCore.Regroup.self
        if let frame=sprite("image_ui_hd","common_lineframe_bold.png"){place(frame,G.equipmentGroup,3);root.addChild(frame)}else{let n=shape(G.equipmentGroup,.clear,ui(126,118,106));n.zPosition=3;root.addChild(n)}
        if let title=sprite("image_ui_hd","infomarker_board.png"){place(title,G.equipmentTitle,3.2);root.addChild(title)}
        label(strings["text_equipitem"] ?? "装备",G.equipmentTitle,6.5,ui(82,75,65),4)
        if let top=sprite("image_ui_hd","pattern_reoganizion.png"){place(top,G.equipmentTopPattern,3.3);root.addChild(top)}
        if let bottom=sprite("image_ui_hd","pattern_reoganizion.png"){placeFlippedY(bottom,G.equipmentBottomPattern,3.3);root.addChild(bottom)}
        if let line=sprite("image_ui_hd","common_line_hor.png"){place(line,G.equipmentTopSplit,3.4);root.addChild(line)}
        if let line=sprite("image_ui_hd","common_line_hor.png"){place(line,G.equipmentBottomSplit,3.4);root.addChild(line)}
    }

    private func renderMainEquipment(_ source:Commander){
        renderEquipmentShell()
        let pair=NativeHeadquartersManagementCore.equipmentPair(profile:profile,commander:source), G=NativeOriginalFormGeometryCore.Regroup.self
        for i in 0..<2{let r=G.equipmentSlots[i];guard pair.indices.contains(i),let iid=pair[i],let it=items[String(iid)] ?? items.values.first(where:{$0.id == iid}) else{label(strings["text_empty"] ?? "无",r,5.1,ui(115,103,84),4);continue};if let icon=itemNode(it){place(icon,.init(x:r.origin.x+1.5,y:r.origin.y+1.5,width:42,height:42),4);root.addChild(icon)}}
    }

    private func renderList(){
        listCrop.removeFromParent();listContent.removeAllChildren()
        let mask=SKShapeNode(rect:CGRect(x:listViewport.origin.x,y:-(listViewport.origin.y+listViewport.size.height),width:listViewport.size.width,height:listViewport.size.height));mask.fillColor = .white;mask.strokeColor = .clear;listCrop.maskNode=mask;listCrop.zPosition=5;root.addChild(listCrop);listCrop.addChild(listContent)
        for(i,id)in sources.enumerated(){guard let c=commanders[id]else{continue};let r=NativeRect(x:listViewport.origin.x+Double(i)*(cardW+gap)-scroll,y:listViewport.origin.y,width:cardW,height:98);drawCommander(c,rect:r,parent:listContent,selected:sourceID==id)}
    }
    public override func touchesBegan(_ t:Set<UITouch>,with e:UIEvent?){guard !confirm,let t=t.first else{return};let p=pt(t.location(in:self));startX=p.x;startScroll=scroll;dragging=contains(listViewport,p);dragged=false}
    public override func touchesMoved(_ t:Set<UITouch>,with e:UIEvent?){guard dragging,let t=t.first else{return};let p=pt(t.location(in:self));let d=startX-p.x;if abs(d)>3{dragged=true};let maxS=max(0,Double(sources.count)*(cardW+gap)-gap-listViewport.size.width);scroll=min(max(0,startScroll+d),maxS);renderList()}
    public override func touchesEnded(_ t:Set<UITouch>,with e:UIEvent?){guard let t=t.first else{return};let p=pt(t.location(in:self));if confirm{if contains(confirmRect,p){commit();return};if contains(cancelRect,p){confirm=false;overlay.removeAllChildren();return};return};defer{dragging=false;dragged=false};if contains(backRect,p){backHandler?();return};if dragged{return};if contains(commitRect,p),sourceID != nil{confirm=true;renderConfirm();return};if let id=sourceAt(p){sourceID=id;render()}}
    private func renderConfirm(){overlay.removeAllChildren();let dim=shape(.init(x:0,y:0,width:568,height:320),UIColor(white:0,alpha:0.35),.clear);dim.zPosition=50;overlay.addChild(dim);let b=shape(NativeOriginalFormGeometryCore.RegroupConfirm.screenFrame,ui(224,217,204),ui(105,98,87));b.zPosition=51;overlay.addChild(b);label(strings["title_notice"] ?? "注  意",.init(x:NativeOriginalFormGeometryCore.RegroupConfirm.screenFrame.origin.x,y:NativeOriginalFormGeometryCore.RegroupConfirm.screenFrame.origin.y+16,width:NativeOriginalFormGeometryCore.RegroupConfirm.screenFrame.size.width,height:25),10,ui(73,67,58),52,parent:overlay);label(strings["text_regroupnotice"] ?? "被整编的将领和物品会消失",NativeOriginalFormGeometryCore.RegroupConfirm.tips,6.2,ui(118,55,46),52,parent:overlay);label(strings["text_regroup"] ?? "确定要整编吗?",NativeOriginalFormGeometryCore.RegroupConfirm.info,7,ui(75,69,61),52,parent:overlay);if let board=sprite("image_ui_hd","gray_board.png"){place(board,NativeOriginalFormGeometryCore.RegroupConfirm.board,51.5);overlay.addChild(board)};if let top=sprite("image_ui_hd","common_boldline.png"){place(top,NativeOriginalFormGeometryCore.RegroupConfirm.topSplit,52);overlay.addChild(top)};if let bottom=sprite("image_ui_hd","common_boldline.png"){place(bottom,NativeOriginalFormGeometryCore.RegroupConfirm.bottomSplit,52);overlay.addChild(bottom)};if let sid=sourceID,let source=commanders[sid]{renderConfirmCommander(source);renderConfirmEquipment(source)};button(confirmRect,strings["btn_confirm"] ?? "确认",true);button(cancelRect,strings["btn_cancel"] ?? "取消",true)}
    private func renderConfirmCommander(_ source:Commander){let g=NativePlayerProfileCore.generalGrowthState(profile:profile,raw:source);if let p=portrait(source.id){place(p,NativeOriginalFormGeometryCore.RegroupConfirm.commanderPortrait,53);overlay.addChild(p);let border=shape(NativeOriginalFormGeometryCore.RegroupConfirm.commanderPortrait,.clear,ui(119,105,79));border.zPosition=53.2;overlay.addChild(border)};label(strings["name_\(source.name)"] ?? source.name,NativeOriginalFormGeometryCore.RegroupConfirm.commanderName,6.3,ui(70,64,56),54,parent:overlay);label("军\(g.rank) · 爵\(g.nobility)",NativeOriginalFormGeometryCore.RegroupConfirm.commanderGrowth,5.3,ui(84,76,66),54,parent:overlay)}
    private func renderConfirmEquipment(_ source:Commander){let G=NativeOriginalFormGeometryCore.RegroupConfirm;if let frame=sprite("image_ui_hd","common_lineframe_bold.png"){place(frame,G.equipment,52.3);overlay.addChild(frame)}else{let frame=shape(G.equipment,.clear,ui(126,118,106));frame.zPosition=52.3;overlay.addChild(frame)};if let title=sprite("image_ui_hd","infomarker_board.png"){place(title,G.equipmentTitle,52.5);overlay.addChild(title)};label(strings["text_equipitem"] ?? "装备",G.equipmentTitle,6.2,ui(82,75,65),53,parent:overlay);if let top=sprite("image_ui_hd","pattern_reoganizion.png"){place(top,G.equipmentTopPattern,52.6);overlay.addChild(top)};if let bottom=sprite("image_ui_hd","pattern_reoganizion.png"){placeFlippedY(bottom,G.equipmentBottomPattern,52.6);overlay.addChild(bottom)};if let line=sprite("image_ui_hd","common_line_hor.png"){place(line,G.equipmentTopSplit,52.7);overlay.addChild(line)};if let line=sprite("image_ui_hd","common_line_hor.png"){place(line,G.equipmentBottomSplit,52.7);overlay.addChild(line)};let pair=NativeHeadquartersManagementCore.equipmentPair(profile:profile,commander:source);for i in 0..<2{let r=G.equipmentSlots[i];guard pair.indices.contains(i),let iid=pair[i],let it=items[String(iid)] ?? items.values.first(where:{$0.id == iid}) else{label(strings["text_empty"] ?? "无",r,5.1,ui(115,103,84),53.5,parent:overlay);continue};if let icon=itemNode(it){place(icon,.init(x:r.origin.x+1.5,y:r.origin.y+1.5,width:42,height:42),53.4);overlay.addChild(icon)}}}
    private func button(_ r:NativeRect,_ text:String,_ blue:Bool){if let b=sprite("image_ui_hd",blue ? "btn_common_blue.png":"btn_common_green.png"){place(b,r,53);overlay.addChild(b)};label(text,r,7,.white,54,parent:overlay)}
    private func commit(){guard let sid=sourceID,let target=commanders[targetID],let source=commanders[sid]else{return};let r=NativeHeadquartersManagementCore.regroup(profile:&profile,target:target,source:source,generalOverrides:generalOverrides,princessOverrides:princessOverrides);if r.ok{profileDidChangeHandler?(profile);statusHandler?("整编完成：\(source.name) → \(target.name)");completedHandler?()}else{confirm=false;overlay.removeAllChildren();statusHandler?("整编失败")}}
    private func sourceAt(_ p:NativePoint)->Int?{guard contains(listViewport,p)else{return nil};for(i,id)in sources.enumerated(){let r=NativeRect(x:listViewport.origin.x+Double(i)*(cardW+gap)-scroll,y:listViewport.origin.y,width:cardW,height:98);if contains(r,p){return id}};return nil}
    private func portrait(_ id:Int)->SKSpriteNode?{guard let raw=portraits[String(id)]else{return nil};let f=URL(fileURLWithPath:raw).lastPathComponent;guard let im=UIImage(contentsOfFile:store.url("Portraits",f).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:im))}
    private func texture(_ f:String)->SKSpriteNode?{guard let im=UIImage(contentsOfFile:store.url("Textures",f).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:im))}
    private func sprite(_ folder:String,_ f:String)->SKSpriteNode?{guard let im=UIImage(contentsOfFile:store.url("Sprites/\(folder)",f).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:im))}
    private func itemNode(_ item:NativeItemEffectDefinition)->SKSpriteNode?{let f=item.name.replacingOccurrences(of:" ",with:"_")+".png";guard let im=UIImage(contentsOfFile:store.url("Items",f).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:im))}
    private func shape(_ r:NativeRect,_ fill:UIColor,_ stroke:UIColor)->SKShapeNode{let n=SKShapeNode(rect:CGRect(x:r.origin.x,y:-(r.origin.y+r.size.height),width:r.size.width,height:r.size.height));n.fillColor=fill;n.strokeColor=stroke;n.lineWidth=1;return n}
    private func place(_ n:SKSpriteNode,_ r:NativeRect,_ z:CGFloat){n.anchorPoint=CGPoint(x:0,y:1);n.position=CGPoint(x:r.origin.x,y:-r.origin.y);n.size=CGSize(width:r.size.width,height:r.size.height);n.zPosition=z}
    private func placeFlippedY(_ n:SKSpriteNode,_ r:NativeRect,_ z:CGFloat){n.anchorPoint=CGPoint(x:0,y:1);n.position=CGPoint(x:r.origin.x,y:-(r.origin.y+r.size.height));n.size=CGSize(width:r.size.width,height:r.size.height);n.yScale = -1;n.zPosition=z}
    private func label(_ s:String,_ r:NativeRect,_ fs:CGFloat,_ c:UIColor,_ z:CGFloat,parent:SKNode?=nil,lines:Int=1){if lines>1||s.contains("\n"){let a=s.split(separator:"\n",omittingEmptySubsequences:false);let ct=max(1,min(lines,a.count));let h=r.size.height/Double(ct);for i in 0..<ct{label(String(a[i]),.init(x:r.origin.x,y:r.origin.y+Double(i)*h,width:r.size.width,height:h),fs,c,z,parent:parent)};return};let n=SKLabelNode(fontNamed:"PingFangSC-Semibold");n.text=s;n.fontSize=fs;n.fontColor=c;n.verticalAlignmentMode = .center;n.horizontalAlignmentMode = .center;n.position=CGPoint(x:r.origin.x+r.size.width/2,y:-(r.origin.y+r.size.height/2));n.zPosition=z;(parent ?? root).addChild(n)}
    private func pt(_ p:CGPoint)->NativePoint{.init(x:p.x,y:320-p.y)};private func contains(_ r:NativeRect,_ p:NativePoint)->Bool{p.x>=r.origin.x&&p.y>=r.origin.y&&p.x<=r.origin.x+r.size.width&&p.y<=r.origin.y+r.size.height};private func ui(_ r:CGFloat,_ g:CGFloat,_ b:CGFloat,_ a:CGFloat=255)->UIColor{UIColor(red:r/255,green:g/255,blue:b/255,alpha:a/255)}
}
#endif
