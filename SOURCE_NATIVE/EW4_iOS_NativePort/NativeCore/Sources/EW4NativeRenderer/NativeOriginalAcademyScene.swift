#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

public final class NativeOriginalAcademyScene: SKScene {
    public var backHandler: (() -> Void)?
    public var profileDidChangeHandler: ((NativePlayerProfile) -> Void)?
    public var statusHandler: ((String) -> Void)?
    public private(set) var profile: NativePlayerProfile

    private let store: NativeResourceStore
    private let commanders: [Int: Commander]
    private let portraits: [String: String]
    private let items: NativeItemEffectCatalog
    private let strings: [String:String]
    private let root = SKNode()
    private var tierKey: String
    private var selectedID: Int?
    private var acquiredID: Int?
    private var detailID: Int?

    private let backRect = NativeRect(x: 0, y: 275, width: 45, height: 45)
    private let tabRects: [String: NativeRect] = [
        "6": .init(x: 51, y: 36, width: 152, height: 55),
        "4": .init(x: 207, y: 36, width: 152, height: 55),
        "2": .init(x: 363, y: 36, width: 152, height: 55)
    ]
    private let refreshRect = NativeRect(x: 234, y: 257, width: 100, height: 40)

    public init(store: NativeResourceStore, profile: NativePlayerProfile) throws {
        self.store = store; self.commanders = try store.commanders(); self.portraits = try store.portraitManifest(); self.items = try store.items(); self.strings = try store.stringsCN()
        var normalized = profile; _ = NativeAcademyCore.ensurePools(profile: &normalized, commanders: self.commanders)
        self.profile = normalized
        if case .string(let key) = normalized.document["academyPool"], NativeAcademyCore.tierOrder.contains(key) { self.tierKey = key } else { self.tierKey = "6" }
        super.init(size: CGSize(width: EW4LogicalSpace.width, height: EW4LogicalSpace.height))
        scaleMode = .aspectFit; anchorPoint = .zero; backgroundColor = .black; root.position = CGPoint(x: 0, y: EW4LogicalSpace.height); addChild(root); render()
    }
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func candidates() -> [Int?] { NativeAcademyCore.decodePools(profile.document["academyCandidatesByPool"])[tierKey] ?? [] }

    private func render() {
        root.removeAllChildren()
        if let bg=textureNode("campaign_wide.png"){place(bg,.init(x:0,y:0,width:568,height:320),0);root.addChild(bg)}
        if let back=sprite("image_ui_hd","button_back.png"){place(back,backRect,10);root.addChild(back)}
        label(strings["title_buygeneral"] ?? "军事学院", .init(x: 0, y: 4, width: 568, height: 23), 11, ui(235,226,211), 10)
        if let medal=sprite("image_ui_hd","medals.png"){place(medal,.init(x:474,y:6,width:14,height:14),10);root.addChild(medal)}
        let earned = completionCurrency()
        label(String(earned.medals),.init(x:488,y:5,width:38,height:16),7,ui(235,226,211),10)
        if let badge=sprite("image_ui_hd","badges.png"){place(badge,.init(x:526,y:6,width:14,height:14),10);root.addChild(badge)}
        label(String(earned.badges),.init(x:540,y:5,width:25,height:16),7,ui(235,226,211),10)
        if let line=sprite("image_ui_hd","common_line_hor.png"){place(line,.init(x:0,y:27,width:568,height:1),3);root.addChild(line)}

        for key in NativeAcademyCore.tierOrder { if let rect=tabRects[key], let tab=sprite("image_ui_hd","button_general_\(key).png"){place(tab,rect,5);root.addChild(tab)} }
        if let check=sprite("image_ui_hd","button_lottery_generals.png"), let rect=tabRects[tierKey]{place(check,.init(x:rect.origin.x-5,y:36,width:158,height:58),6);root.addChild(check)}
        if let gray = sprite("image_ui_hd", "gray_board.png") { place(gray, .init(x: 0, y: 93, width: 568, height: 152), 2); gray.alpha = 0.40; root.addChild(gray) }
        if let frame = sprite("image_ui_hd", "framebox_thin.png") { place(frame, .init(x: 0, y: 93, width: 568, height: 152), 3); root.addChild(frame) }
        for (x, flip) in [(110.0, true), (206.0, false), (362.0, true), (458.0, false)] {
            if let deco = sprite("image_ui_hd", "pattern_getgeneral_2_1.png") {
                place(deco, .init(x: x - (flip ? 57.6 : 0), y: 128, width: 57.6, height: 41.6), 3)
                if flip { deco.xScale = -1 }
                deco.alpha = 0.92; root.addChild(deco)
            }
        }
        renderCandidates()
        if let refresh=sprite("image_ui_hd","btn_common_blue.png"){place(refresh,refreshRect,5);root.addChild(refresh)}
        for x in [249.0, 275.0, 302.0] { if let r = sprite("image_ui_hd", "button_refresh.png") { place(r, .init(x: x, y: 269, width: 18, height: 18), 6); root.addChild(r) } }
        if let pct = sprite("image_ui_hd", "gray_board.png") { place(pct, .init(x: 244, y: 266, width: 80, height: 22), 7); root.addChild(pct) }
        label("100%", .init(x: 244, y: 266, width: 80, height: 22), 8, ui(79,75,67), 8)
        for (x, flip) in [(220.0, true), (347.0, false)] { if let deco = sprite("image_ui_hd", "pattern_getgeneral_2_1.png") { place(deco, .init(x: x - (flip ? 36 : 0), y: 265, width: 36, height: 26), 3); if flip { deco.xScale = -1 }; deco.alpha = 0.8; root.addChild(deco) } }
        if let bottom=sprite("image_ui_hd","pattern_bg_bottom.png"){place(bottom,.init(x:234,y:303,width:100,height:17),4);root.addChild(bottom)}
        if let line=sprite("image_ui_hd","common_boldline.png"){place(line,.init(x:0,y:316,width:568,height:4),3);root.addChild(line)}
        if let id=acquiredID { renderAcquiredOverlay(id) }
        if let id=detailID { renderGeneralDetailOverlay(id) }
        statusHandler?("Military Academy · tier \(tierKey)")
    }

    private func renderCandidates() {
        let row = candidates()
        for (index, maybeID) in row.enumerated() {
            let rect = cardRect(index)
            guard let id=maybeID, let c=commanders[id] else { continue }
            if let p=portraitNode(id){place(p,.init(x:rect.origin.x,y:rect.origin.y,width:78,height:78),4);root.addChild(p)}
            let name=shape(.init(x:rect.origin.x,y:rect.origin.y+78,width:78,height:20),fill:ui(105,101,94),stroke:.clear);name.zPosition=4;root.addChild(name)
            label(c.name,.init(x:rect.origin.x,y:rect.origin.y+78,width:78,height:20),7,ui(247,244,237),5)
            if let info=sprite("image_ui_hd","button_generalinfo_blue.png"){place(info,infoRect(index),7);root.addChild(info)}
            if selectedID == id { if let sel=sprite("image_ui_hd","item_selected_ex.png"){place(sel,.init(x:rect.origin.x-2,y:rect.origin.y-2,width:82,height:102),8);root.addChild(sel)}; renderBuyPair(index:index, commander:c) }
        }
    }

    private func renderBuyPair(index:Int, commander:Commander) {
        let card=cardRect(index), left=max(4,min(449,card.origin.x+39-57.5)), y=211.0
        let medalPrice=NativeAcademyCore.medalPrice(commander), badgePrice=NativeAcademyCore.badgePrice(commander)
        if medalPrice>0 { if let b=sprite("image_ui_hd","btn_common_green.png"){place(b,.init(x:left,y:y,width:55,height:32),9);root.addChild(b)}; if let i=sprite("image_ui_hd","medals.png"){place(i,.init(x:left+6,y:y+8,width:11,height:11),10);root.addChild(i)}; label("\(medalPrice)",.init(x:left+15,y:y,width:39,height:32),6,ui(246,238,223),10) }
        if badgePrice>0 { if let b=sprite("image_ui_hd","btn_common_red.png"){place(b,.init(x:left+60,y:y,width:55,height:32),9);root.addChild(b)}; if let i=sprite("image_ui_hd","badges.png"){place(i,.init(x:left+66,y:y+8,width:11,height:11),10);root.addChild(i)}; label("\(badgePrice)",.init(x:left+75,y:y,width:39,height:32),6,ui(246,238,223),10) }
    }

    public override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent?){guard let t=touches.first else{return};let p=nativePoint(t.location(in:self));if detailID != nil {detailID=nil;render();return};if acquiredID != nil {acquiredID=nil;render();return};if contains(backRect,p){backHandler?();return};for (key,rect) in tabRects where contains(rect,p){tierKey=key;selectedID=nil;profile.document["academyPool"] = .string(key);profileDidChangeHandler?(profile);render();return};if contains(refreshRect,p){_ = NativeAcademyCore.refresh(profile:&profile,commanders:commanders,tier:tierKey);selectedID=nil;profileDidChangeHandler?(profile);render();return};for (index,id) in candidates().enumerated(){guard let id else{continue};if contains(infoRect(index),p){detailID=id;render();return};let rect=cardRect(index);if contains(rect,p){selectedID=id;render();return}};guard let id=selectedID,let c=commanders[id] else{return};let idx=candidates().firstIndex(where:{$0==id}) ?? 0;let left=max(4,min(449,cardRect(idx).origin.x+39-57.5));if NativeAcademyCore.medalPrice(c)>0 && contains(.init(x:left,y:211,width:55,height:32),p){acquire(id,currency:"medal");return};if NativeAcademyCore.badgePrice(c)>0 && contains(.init(x:left+60,y:211,width:55,height:32),p){acquire(id,currency:"badge")}}

    private func acquire(_ id:Int,currency:String){if NativeAcademyCore.acquire(profile:&profile,commanders:commanders,tier:tierKey,commanderID:id,currency:currency){selectedID=nil;acquiredID=id;profileDidChangeHandler?(profile);statusHandler?("Acquired general \(commanders[id]?.name ?? "#\(id)")");render()}}
    private func renderAcquiredOverlay(_ id:Int){
        let dim=shape(.init(x:0,y:0,width:568,height:320),fill:ui(0,0,0,115),stroke:.clear);dim.zPosition=50;root.addChild(dim)
        let panel=shape(.init(x:208,y:68,width:152,height:184),fill:ui(238,230,212),stroke:ui(110,98,79));panel.zPosition=51;panel.lineWidth=2;root.addChild(panel)
        label(strings["title_generaltips"] ?? "获得将军",.init(x:208,y:72,width:152,height:22),10,ui(75,68,56),53)
        if let board=sprite("image_ui_hd","board_smallgenerals.png"){place(board,.init(x:244,y:110,width:78,height:98),52);root.addChild(board)}
        if let p=portraitNode(id){place(p,.init(x:253,y:117,width:60,height:62),53);root.addChild(p)}
        label(commanders[id]?.name ?? "",.init(x:246,y:183,width:74,height:15),7,ui(67,59,49),54)
        if let split=sprite("image_ui_hd","common_boldline.png"){place(split,.init(x:208,y:221,width:152,height:1),53);root.addChild(split)}
        if let bottom=sprite("image_ui_hd","pattern_gotgeneral.png"){place(bottom,.init(x:234,y:228,width:100,height:18),53);root.addChild(bottom)}
        if let ok=sprite("image_ui_hd","button_confirm_green.png"){place(ok,.init(x:322,y:234,width:48,height:28),54);root.addChild(ok)}
    }
    private func renderGeneralDetailOverlay(_ id:Int){
        guard let c=commanders[id] else{return}
        let dim=shape(.init(x:0,y:0,width:568,height:320),fill:ui(0,0,0,120),stroke:.clear);dim.zPosition=60;root.addChild(dim)
        NativeOriginalGeneralInfoSurface.render(parent: root, store: store, portraits: portraits, strings: strings, items: items, commander: c, z: 61)
        if let close=sprite("image_ui_hd","button_close.png"){place(close,.init(x:478,y:43,width:25,height:25),70);root.addChild(close)}
    }
    private func completionCurrency() -> (medals: Int, badges: Int) {
        guard case .object(let earned) = profile.document["campaignCompletionEarned"] else { return (0, 0) }
        func value(_ key: String) -> Int {
            if case .int(let n) = earned[key] { return max(0, n) }
            if case .double(let n) = earned[key] { return max(0, Int(n)) }
            return 0
        }
        return (value("medals"), value("badges"))
    }
    private func infoRect(_ index:Int)->NativeRect{let r=cardRect(index);return .init(x:r.origin.x+56,y:r.origin.y+2,width:20,height:20)}
    private func cardRect(_ index:Int)->NativeRect{.init(x:25+Double(index)*(78+10.2),y:110,width:78,height:98)}
    private func portraitNode(_ id:Int)->SKSpriteNode?{guard let raw=portraits[String(id)] else{return nil};let file=URL(fileURLWithPath:raw).lastPathComponent;guard let image=UIImage(contentsOfFile:store.url("Portraits",file).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:image))}
    private func textureNode(_ f:String)->SKSpriteNode?{guard let i=UIImage(contentsOfFile:store.url("Textures",f).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:i))}
    private func sprite(_ folder:String,_ file:String)->SKSpriteNode?{guard let i=UIImage(contentsOfFile:store.url("Sprites/\(folder)",file).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:i))}
    private func shape(_ r:NativeRect,fill:UIColor,stroke:UIColor)->SKShapeNode{let n=SKShapeNode(rect:CGRect(x:r.origin.x,y:-(r.origin.y+r.size.height),width:r.size.width,height:r.size.height));n.fillColor=fill;n.strokeColor=stroke;n.lineWidth=1;return n}
    private func place(_ n:SKSpriteNode,_ r:NativeRect,_ z:CGFloat){n.anchorPoint=CGPoint(x:0,y:1);n.position=CGPoint(x:r.origin.x,y:-r.origin.y);n.size=CGSize(width:r.size.width,height:r.size.height);n.zPosition=z}
    private func label(_ t:String,_ r:NativeRect,_ s:CGFloat,_ c:UIColor,_ z:CGFloat){let n=SKLabelNode(fontNamed:"PingFangSC-Semibold");n.text=t;n.fontSize=s;n.fontColor=c;n.horizontalAlignmentMode = .center;n.verticalAlignmentMode = .center;n.position=CGPoint(x:r.origin.x+r.size.width/2,y:-(r.origin.y+r.size.height/2));n.zPosition=z;root.addChild(n)}
    private func nativePoint(_ p:CGPoint)->NativePoint{.init(x:p.x,y:EW4LogicalSpace.height-p.y)}
    private func contains(_ r:NativeRect,_ p:NativePoint)->Bool{p.x>=r.origin.x&&p.y>=r.origin.y&&p.x<=r.origin.x+r.size.width&&p.y<=r.origin.y+r.size.height}
    private func ui(_ r:CGFloat,_ g:CGFloat,_ b:CGFloat,_ a:CGFloat=255)->UIColor{UIColor(red:r/255,green:g/255,blue:b/255,alpha:a/255)}
}
#endif
