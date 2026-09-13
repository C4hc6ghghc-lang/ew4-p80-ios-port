#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

/// Native binding for original `form_generalupgrade` (325x185).
/// Original medal prices are displayed; player-side infinite-medal policy means
/// upgrades never decrement a currency balance.
public final class NativeOriginalGeneralUpgradeScene: SKScene {
    public var backHandler: (() -> Void)?
    public var profileDidChangeHandler: ((NativePlayerProfile) -> Void)?
    public var statusHandler: ((String) -> Void)?
    public var soundEffectHandler: ((String) -> Void)?
    public private(set) var profile: NativePlayerProfile

    private let store: NativeResourceStore
    private let commander: Commander
    private let portraits: [String:String]
    private let strings: [String:String]
    private let generalOverrides: NativePlayerGeneralOverrides
    private let princessOverrides: NativePlayerPrincessOverrides
    private let root = SKNode()
    private typealias G = NativeOriginalFormGeometryCore.GeneralUpgrade

    public init(store: NativeResourceStore, profile: NativePlayerProfile, commanderID: Int) throws {
        self.store = store
        self.profile = profile
        let commanders = try store.commanders()
        guard let commander = commanders[commanderID], profile.ownedCommanderIDs.contains(commanderID) else {
            throw NSError(domain: "NativeGeneralUpgrade", code: 1, userInfo: [NSLocalizedDescriptionKey:"Commander unavailable"])
        }
        self.commander = commander
        self.portraits = try store.portraitManifest()
        self.strings = (try? store.stringsCN()) ?? [:]
        self.generalOverrides = try store.playerGeneralOverrides()
        self.princessOverrides = try store.playerPrincessOverrides()
        super.init(size: CGSize(width: EW4LogicalSpace.width, height: EW4LogicalSpace.height))
        scaleMode = .aspectFit; anchorPoint = CGPoint(x:0,y:0); backgroundColor = .black
        root.position = CGPoint(x:0,y:EW4LogicalSpace.height); addChild(root); render()
    }
    @available(*, unavailable) required init?(coder aDecoder:NSCoder){ fatalError("init(coder:) has not been implemented") }

    private func render() {
        root.removeAllChildren()
        if let bg=textureNode("campaign_wide.png"){place(bg,.init(x:0,y:0,width:568,height:320),0);root.addChild(bg)}
        let dim=shape(.init(x:0,y:0,width:568,height:320),fill:UIColor(white:0,alpha:0.35),stroke:.clear);dim.zPosition=1;root.addChild(dim)
        if let board=sprite("image_ui_hd","form_back.png"){place(board,G.screenFrame,2);root.addChild(board)}
        else {let b=shape(G.screenFrame,fill:ui(222,216,203),stroke:ui(111,104,92));b.zPosition=2;root.addChild(b)}
        label(strings["title_upgrade"] ?? "升  级",.init(x:G.screenFrame.origin.x,y:G.screenFrame.origin.y+4,width:G.screenFrame.size.width,height:22),9,ui(75,69,61),4)
        if let close=sprite("image_ui_hd","button_close.png"){place(close,G.closeButton,8);root.addChild(close)}
        renderCommander()
        renderUpgradeGroups()
        if let pattern=sprite("image_ui_hd","pattern_stage_intro.png"){placeAspectFit(pattern,G.bottomPattern,3);root.addChild(pattern)}
    }

    private func renderCommander(){
        let r=G.commander
        if let p=portraitNode(id:commander.id){place(p,.init(x:r.origin.x+3,y:r.origin.y,width:72,height:72),5);root.addChild(p)}
        if let name=sprite("image_ui_hd","general_nameboard.png"){place(name,.init(x:r.origin.x,y:r.origin.y+72,width:78,height:15),5.2);root.addChild(name)}
        label(commander.name,.init(x:r.origin.x,y:r.origin.y+72,width:78,height:15),6.2,ui(73,67,58),6)
        let growth=NativePlayerProfileCore.generalGrowthState(profile:profile,raw:commander)
        label("军\(growth.rank) · 爵\(growth.nobility)",.init(x:r.origin.x,y:r.origin.y+87,width:78,height:11),5.2,ui(82,75,65),6)
    }

    private func renderUpgradeGroups(){
        let snap=NativeGeneralUpgradeCore.snapshot(profile:profile,commander:commander)
        renderGroup(rect:G.militaryGroup,kind:.military,snapshot:snap)
        renderGroup(rect:G.nobilityGroup,kind:.nobility,snapshot:snap)
        renderFullGroup(snapshot:snap)
    }

    private func renderGroup(rect:NativeRect, kind:NativeGeneralUpgradeKind, snapshot:NativeGeneralUpgradeSnapshot){
        if let frame=sprite("image_ui_hd","gray_board.png"){place(frame,rect,4);root.addChild(frame)}
        else {let b=shape(rect,fill:UIColor(white:0.9,alpha:0.25),stroke:ui(145,136,122));b.zPosition=4;root.addChild(b)}
        let military = kind == .military
        let currentLevel = military ? snapshot.growth.rank : snapshot.growth.nobility
        let nextLevel = military ? snapshot.nextMilitaryLevel : snapshot.nextNobilityLevel
        let full = military ? snapshot.militaryFull : snapshot.nobilityFull
        let currentEffective = effective(rank:snapshot.growth.rank,nobility:snapshot.growth.nobility)
        let nextEffective = effective(rank:military ? nextLevel : snapshot.growth.rank,nobility:military ? snapshot.growth.nobility : nextLevel)
        let fromRank=NativeRect(x:rect.origin.x+7,y:rect.origin.y+9,width:33,height:24)
        let fromMarker=NativeRect(x:rect.origin.x+40,y:rect.origin.y+10,width:17,height:17)
        let fromText=NativeRect(x:rect.origin.x+28,y:rect.origin.y+25,width:36,height:12)
        let arrow=NativeRect(x:rect.origin.x+83,y:rect.origin.y+5,width:42,height:39)
        let toRank=NativeRect(x:rect.origin.x+100,y:rect.origin.y+9,width:33,height:24)
        let toMarker=NativeRect(x:rect.origin.x+132,y:rect.origin.y+10,width:17,height:17)
        let toText=NativeRect(x:rect.origin.x+120,y:rect.origin.y+25,width:36,height:12)
        if currentLevel > 0, let icon=sprite("image_ui_hd", military ? "rank_\(min(14,currentLevel)).png" : "class_\(min(9,currentLevel)).png"){placeAspectFit(icon,fromRank,5);root.addChild(icon)}
        if nextLevel > 0, let icon=sprite("image_ui_hd", military ? "rank_\(min(14,nextLevel)).png" : "class_\(min(9,nextLevel)).png"){placeAspectFit(icon,toRank,5);root.addChild(icon)}
        if let marker=sprite("image_ui_hd",military ? "marker_hp_dark.png":"marker_recover_dark.png"){placeAspectFit(marker,fromMarker,5);root.addChild(marker)}
        if let marker=sprite("image_ui_hd",military ? "marker_hp_dark.png":"marker_recover_dark.png"){placeAspectFit(marker,toMarker,5);root.addChild(marker)}
        let fromValue = military ? currentEffective.rankHPBonus : heal(effective:currentEffective)
        let toValue = military ? nextEffective.rankHPBonus : heal(effective:nextEffective)
        label("+\(fromValue)",fromText,5.2,ui(64,64,64),6);label(full ? "MAX" : "+\(toValue)",toText,5.2,ui(64,64,64),6)
        if let a=sprite("image_ui_hd","arrow_reoganizion.png"){placeAspectFit(a,arrow,5);a.xScale = -abs(a.xScale);root.addChild(a)}
        let button = military ? G.militaryButton : G.nobilityButton
        renderCostButton(button,cost: military ? snapshot.militaryCost : snapshot.nobilityCost,blue:true,disabled:full)
    }

    private func renderFullGroup(snapshot:NativeGeneralUpgradeSnapshot){
        let rect=G.fullGroup
        if let frame=sprite("image_ui_hd","gray_board.png"){place(frame,rect,4);root.addChild(frame)}
        let military=NativeRect(x:rect.origin.x+4,y:rect.origin.y+9,width:30,height:25)
        let nobility=NativeRect(x:rect.origin.x+34,y:rect.origin.y+9,width:30,height:25)
        if let rank=sprite("image_ui_hd","rank_14.png"){placeAspectFit(rank,military,5);root.addChild(rank)}
        if let noble=sprite("image_ui_hd","class_9.png"){placeAspectFit(noble,nobility,5);root.addChild(noble)}
        if let a=sprite("image_ui_hd","arrow_reoganizion.png"){placeAspectFit(a,.init(x:rect.origin.x+83,y:rect.origin.y+5,width:42,height:39),5);a.xScale = -abs(a.xScale);root.addChild(a)}
        if let max=sprite("image_ui_hd","marker_max_2.png"){placeAspectFit(max,.init(x:rect.origin.x+100,y:rect.origin.y+9,width:50,height:28),5);root.addChild(max)}
        renderCostButton(G.allButton,cost:snapshot.allFullCost,blue:false,disabled:snapshot.allFull)
    }

    private func renderCostButton(_ rect:NativeRect,cost:Int,blue:Bool,disabled:Bool){
        let file=blue ? "btn_common_blue.png" : "btn_common_green.png"
        if let b=sprite("image_ui_hd",file){place(b,rect,6);b.alpha=disabled ? 0.4 : 1;root.addChild(b)}
        if let medal=sprite("image_ui_hd","medals.png"){placeAspectFit(medal,.init(x:rect.origin.x+10,y:rect.origin.y+6,width:14,height:18),7);medal.alpha=disabled ? 0.4 : 1;root.addChild(medal)}
        label(disabled ? "0" : String(cost),.init(x:rect.origin.x+25,y:rect.origin.y+7,width:40,height:16),6,blue ? ui(235,230,215) : ui(64,64,64),8)
    }

    public override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent?){
        guard let t=touches.first else{return};let p=nativePoint(t.location(in:self))
        if contains(G.closeButton,p){backHandler?();return}
        if contains(G.militaryButton,p){upgrade(.military);return}
        if contains(G.nobilityButton,p){upgrade(.nobility);return}
        if contains(G.allButton,p){upgrade(.all);return}
    }

    private func upgrade(_ kind:NativeGeneralUpgradeKind){
        guard NativeGeneralUpgradeCore.apply(profile:&profile,commander:commander,kind:kind) else { statusHandler?("已达到最高等级"); return }
        profileDidChangeHandler?(profile)
        soundEffectHandler?("sfx_lvup2.wav")
        switch kind { case .military: statusHandler?("军衔提升"); case .nobility: statusHandler?("爵位提升"); case .all: statusHandler?("将领等级已升满") }
        render()
    }

    private func effective(rank:Int,nobility:Int)->NativeEffectiveCommander{
        var copy=profile;let key=String(commander.id)
        NativePlayerProfileCore.setIntMapValue(&copy,key:"rank",nestedKey:key,value:rank)
        NativePlayerProfileCore.setIntMapValue(&copy,key:"nobility",nestedKey:key,value:nobility)
        return NativePlayerProfileCore.effectiveCommander(raw:commander,playerControlled:true,profile:copy,generalOverrides:generalOverrides,princessOverrides:princessOverrides)
    }
    private func heal(effective:NativeEffectiveCommander)->Int{NativeRoundSettlementCore.nobilityHeal(level:effective.nobilityLevel,cap:effective.nobilityHealCap,maxLevel:max(1,generalOverrides.global.nobilityMaxLevel))}
    private func portraitNode(id:Int)->SKSpriteNode?{guard let raw=portraits[String(id)] else{return nil};let file=URL(fileURLWithPath:raw).lastPathComponent;guard let image=UIImage(contentsOfFile:store.url("Portraits",file).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:image))}
    private func textureNode(_ file:String)->SKSpriteNode?{guard let image=UIImage(contentsOfFile:store.url("Textures",file).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:image))}
    private func sprite(_ folder:String,_ file:String)->SKSpriteNode?{guard let image=UIImage(contentsOfFile:store.url("Sprites/\(folder)",file).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:image))}
    private func shape(_ r:NativeRect,fill:UIColor,stroke:UIColor)->SKShapeNode{let n=SKShapeNode(rect:CGRect(x:r.origin.x,y:-(r.origin.y+r.size.height),width:r.size.width,height:r.size.height));n.fillColor=fill;n.strokeColor=stroke;n.lineWidth=1;return n}
    private func place(_ n:SKSpriteNode,_ r:NativeRect,_ z:CGFloat){n.anchorPoint=CGPoint(x:0,y:1);n.position=CGPoint(x:r.origin.x,y:-r.origin.y);n.size=CGSize(width:r.size.width,height:r.size.height);n.zPosition=z}
    private func placeAspectFit(_ n:SKSpriteNode,_ r:NativeRect,_ z:CGFloat){let s=n.texture?.size() ?? .zero;guard s.width>0&&s.height>0 else{place(n,r,z);return};let scale=min(CGFloat(r.size.width)/s.width,CGFloat(r.size.height)/s.height),w=s.width*scale,h=s.height*scale;n.anchorPoint=CGPoint(x:0,y:1);n.position=CGPoint(x:r.origin.x+(r.size.width-Double(w))/2,y:-(r.origin.y+(r.size.height-Double(h))/2));n.size=CGSize(width:w,height:h);n.zPosition=z}
    private func label(_ text:String,_ r:NativeRect,_ size:CGFloat,_ color:UIColor,_ z:CGFloat){let n=SKLabelNode(fontNamed:"PingFangSC-Semibold");n.text=text;n.fontSize=size;n.fontColor=color;n.horizontalAlignmentMode = .center;n.verticalAlignmentMode = .center;n.position=CGPoint(x:r.origin.x+r.size.width/2,y:-(r.origin.y+r.size.height/2));n.zPosition=z;root.addChild(n)}
    private func nativePoint(_ p:CGPoint)->NativePoint{.init(x:p.x,y:EW4LogicalSpace.height-p.y)}
    private func contains(_ r:NativeRect,_ p:NativePoint)->Bool{p.x>=r.origin.x&&p.y>=r.origin.y&&p.x<=r.origin.x+r.size.width&&p.y<=r.origin.y+r.size.height}
    private func ui(_ r:CGFloat,_ g:CGFloat,_ b:CGFloat,_ a:CGFloat=255)->UIColor{UIColor(red:r/255,green:g/255,blue:b/255,alpha:a/255)}
}
#endif
