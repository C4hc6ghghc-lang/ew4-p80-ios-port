#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

public final class NativeOriginalAchievementScene: SKScene {
    public var backHandler: (() -> Void)?
    public var soundEffectHandler: ((String) -> Void)?
    public var statusHandler: ((String) -> Void)?

    private let store: NativeResourceStore
    private let profile: NativePlayerProfile
    private let commanders: [Int: Commander]
    private let portraits: [String: String]
    private let strings: [String: String]
    private let root = SKNode()
    private let listCrop = SKCropNode()
    private let listContent = SKNode()
    private var listScroll = 0.0
    private var dragStartX = 0.0
    private var scrollStart = 0.0
    private var draggingList = false
    private typealias G = NativeOriginalFormGeometryCore.Achievement

    public init(store: NativeResourceStore, profile: NativePlayerProfile) throws {
        self.store = store
        self.profile = profile
        self.commanders = try store.commanders()
        self.portraits = try store.portraitManifest()
        self.strings = (try? store.stringsCN()) ?? [:]
        super.init(size: CGSize(width: 568, height: 320))
        scaleMode = .aspectFit; anchorPoint = .zero; backgroundColor = .black
        root.position = CGPoint(x: 0, y: 320); addChild(root); render()
    }
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var vm: NativeAchievementViewModel { NativeAchievementCore.viewModel(profile: profile, commanders: commanders) }
    private var maxScroll: Double { max(0, Double(vm.generalIDs.count) * (G.generalItemWidth + G.generalInterval) - G.generalList.size.width) }

    private func render() {
        root.removeAllChildren()
        if let bg = textureNode("campaign_wide.png") { place(bg, .init(x:0,y:0,width:568,height:320), 0); root.addChild(bg) }
        if let back = sprite("image_ui_hd", "button_back.png") { place(back, G.backButton, 20); root.addChild(back) }
        label(strings["title_achivement"] ?? "成  就", .init(x: 200, y: 2, width: 168, height: 24), 12, ui(72,64,52), 8)
        if let b = sprite("image_ui_hd","button_champion.png") { place(b,G.championButton,5);root.addChild(b) }
        if let b = sprite("image_ui_hd","button_rank.png") { place(b,G.rankingButton,5);root.addChild(b) }
        if let star = sprite("image_ui_hd","stage_star.png") { placeAspectFit(star,G.stageStarIcon,5);root.addChild(star) }
        let data = vm
        label("\(data.stageStarsEarned)/\(data.stageStarsMax)",G.stageStarText,8,ui(64,64,64),6,.left)
        renderSummary(data.military, rect:G.militaryGroup, military:true)
        renderSummary(data.nobility, rect:G.nobilityGroup, military:false)
        renderContinent(index:0,key:"europe",title:strings["text2_european"] ?? "欧洲",icon:"button_rule_europa.png",data:data.continents["europe"]!)
        renderContinent(index:1,key:"america",title:strings["text2_american"] ?? "美洲",icon:"button_rule_america.png",data:data.continents["america"]!)
        renderContinent(index:2,key:"asia",title:strings["text2_asia"] ?? "亚洲",icon:"button_rule_asia.png",data:data.continents["asia"]!)
        if let line=sprite("image_ui_hd","common_line_hor.png"){place(line,.init(x:0,y:217,width:568,height:2),4);root.addChild(line)}
        if let line=sprite("image_ui_hd","common_line_hor.png"){place(line,.init(x:0,y:300,width:568,height:2),4);root.addChild(line)}
        if let pattern=sprite("image_ui_hd","pattern_bg_bottom.png"){placeAspectFit(pattern,.init(x:230,y:303,width:108,height:14),4);root.addChild(pattern)}
        renderGeneralList(data.generalIDs)
    }

    private func renderSummary(_ summary: NativeAchievementStatSummary, rect: NativeRect, military: Bool) {
        if let board=sprite("image_ui_hd","board_rankclass.png"){place(board,rect,5);root.addChild(board)}
        if let marker=sprite("image_ui_hd",military ? "marker_rank.png":"marker_class.png"){placeAspectFit(marker,.init(x:rect.origin.x+7,y:rect.origin.y+2,width:30,height:24),6);root.addChild(marker)}
        label("Lv \(summary.level)",.init(x:rect.origin.x+5,y:rect.origin.y+25,width:55,height:13),6,ui(64,64,64),7,.left)
        label(String(summary.score),.init(x:rect.origin.x+43,y:rect.origin.y+8,width:70,height:17),8,ui(64,64,64),7,.left)
    }

    private func renderContinent(index:Int,key:String,title:String,icon:String,data:NativeAchievementContinent) {
        let x = G.continentOrigins[index]
        if let p=sprite("image_ui_hd","pattern_save.png"){placeAspectFit(p,.init(x:x-10,y:74,width:35,height:11),4);root.addChild(p)}
        if let p=sprite("image_ui_hd","pattern_save.png"){placeAspectFit(p,.init(x:x+109,y:74,width:35,height:11),4);p.xScale = -abs(p.xScale);root.addChild(p)}
        label(title,.init(x:x+12,y:67,width:75,height:16),8,ui(64,64,64),5)
        if let i=sprite("image_ui_hd",icon){placeAspectFit(i,.init(x:x,y:85,width:88,height:96),5);root.addChild(i)}
        let slots=[x+22,x+42,x+62]
        let digits=data.digits.suffix(3)
        let start=3-digits.count
        for (j,d) in digits.enumerated(){if let n=sprite("image_ui_hd","rule_\(d).png"){placeAspectFit(n,.init(x:slots[start+j],y:189,width:18,height:18),6);root.addChild(n)}}
        label(strings["text2_rule"] ?? "统治",.init(x:x-11,y:199,width:50,height:16),7,ui(64,64,64),6,.left)
        label(strings["text2_year"] ?? "年",.init(x:x+82,y:199,width:26,height:16),7,ui(64,64,64),6,.left)
    }

    private func renderGeneralList(_ ids:[Int]) {
        listCrop.removeFromParent(); listCrop.removeAllChildren(); listContent.removeAllChildren()
        let r=G.generalList
        let mask=SKShapeNode(rect:CGRect(x:r.origin.x,y:-(r.origin.y+r.size.height),width:r.size.width,height:r.size.height));mask.fillColor = .white;mask.strokeColor = .clear
        listCrop.maskNode=mask;listCrop.zPosition=7;root.addChild(listCrop);listCrop.addChild(listContent)
        listContent.position=CGPoint(x:-listScroll,y:0)
        for (index,id) in ids.enumerated(){guard let c=commanders[id] else{continue};let x=r.origin.x+Double(index)*(G.generalItemWidth+G.generalInterval);let card=NativeRect(x:x,y:r.origin.y,width:G.generalItemWidth,height:73.5)
            if let frame=sprite("image_ui_hd","board_smallgenerals.png"){place(frame,card,1);listContent.addChild(frame)}
            if let p=portraitNode(id:id){place(p,.init(x:x+5,y:r.origin.y+4,width:G.generalItemWidth-10,height:52),2);listContent.addChild(p)}
            addLabel(c.name,.init(x:x,y:r.origin.y+58,width:G.generalItemWidth,height:12),6,ui(64,58,50),3,parent:listContent)
        }
    }

    public override func touchesBegan(_ touches:Set<UITouch>,with event:UIEvent?){guard let t=touches.first else{return};let p=nativePoint(t.location(in:self));if contains(G.generalList,p){draggingList=true;dragStartX=p.x;scrollStart=listScroll}}
    public override func touchesMoved(_ touches:Set<UITouch>,with event:UIEvent?){guard draggingList,let t=touches.first else{return};let p=nativePoint(t.location(in:self));listScroll=min(maxScroll,max(0,scrollStart+(dragStartX-p.x)));render()}
    public override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent?){guard let t=touches.first else{return};let p=nativePoint(t.location(in:self));let wasDragging=draggingList;draggingList=false;if wasDragging{return};if contains(G.backButton,p){backHandler?();return};if contains(G.championButton,p)||contains(G.rankingButton,p){soundEffectHandler?("sfx_select.wav");statusHandler?("PORT_ONLY：联网成就服务未启用");return}}
    public override func touchesCancelled(_ touches:Set<UITouch>,with event:UIEvent?){draggingList=false}

    private func portraitNode(id:Int)->SKSpriteNode?{guard let raw=portraits[String(id)] else{return nil};let file=URL(fileURLWithPath:raw).lastPathComponent;guard let image=UIImage(contentsOfFile:store.url("Portraits",file).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:image))}
    private func textureNode(_ file:String)->SKSpriteNode?{guard let image=UIImage(contentsOfFile:store.url("Textures",file).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:image))}
    private func sprite(_ folder:String,_ file:String)->SKSpriteNode?{guard let image=UIImage(contentsOfFile:store.url("Sprites/\(folder)",file).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:image))}
    private func place(_ n:SKSpriteNode,_ r:NativeRect,_ z:CGFloat){n.anchorPoint=CGPoint(x:0,y:1);n.position=CGPoint(x:r.origin.x,y:-r.origin.y);n.size=CGSize(width:r.size.width,height:r.size.height);n.zPosition=z}
    private func placeAspectFit(_ n:SKSpriteNode,_ r:NativeRect,_ z:CGFloat){let s=n.texture?.size() ?? .init(width:1,height:1);let k=min(CGFloat(r.size.width)/max(1,s.width),CGFloat(r.size.height)/max(1,s.height));n.anchorPoint=CGPoint(x:0.5,y:0.5);n.size=CGSize(width:s.width*k,height:s.height*k);n.position=CGPoint(x:r.origin.x+r.size.width/2,y:-(r.origin.y+r.size.height/2));n.zPosition=z}
    private func label(_ t:String,_ r:NativeRect,_ s:CGFloat,_ c:UIColor,_ z:CGFloat,_ a:SKLabelHorizontalAlignmentMode = .center){addLabel(t,r,s,c,z,a,parent:root)}
    private func addLabel(_ t:String,_ r:NativeRect,_ s:CGFloat,_ c:UIColor,_ z:CGFloat,_ a:SKLabelHorizontalAlignmentMode = .center,parent:SKNode){let n=SKLabelNode(fontNamed:"PingFangSC-Semibold");n.text=t;n.fontSize=s;n.fontColor=c;n.horizontalAlignmentMode=a;n.verticalAlignmentMode = .center;n.position=CGPoint(x:a == .left ? r.origin.x : r.origin.x+r.size.width/2,y:-(r.origin.y+r.size.height/2));n.zPosition=z;parent.addChild(n)}
    private func nativePoint(_ p:CGPoint)->NativePoint{.init(x:p.x,y:320-p.y)}
    private func contains(_ r:NativeRect,_ p:NativePoint)->Bool{p.x>=r.origin.x&&p.y>=r.origin.y&&p.x<=r.origin.x+r.size.width&&p.y<=r.origin.y+r.size.height}
    private func ui(_ r:CGFloat,_ g:CGFloat,_ b:CGFloat,_ a:CGFloat=255)->UIColor{UIColor(red:r/255,green:g/255,blue:b/255,alpha:a/255)}
}

public enum NativeClaimReward: Equatable, Sendable {
    case medals(Int)
    case item(file: String, count: Int)
}

/// Original `form_claim` visual shell. It is intentionally reusable and is not
/// attached to Achievement without native evidence for a local claim trigger.
public final class NativeOriginalClaimScene: SKScene {
    public var confirmHandler: (() -> Void)?
    private let store: NativeResourceStore
    private let strings: [String: String]
    private let reward: NativeClaimReward
    private let root = SKNode()
    private typealias G = NativeOriginalFormGeometryCore.Achievement

    public init(store: NativeResourceStore, reward: NativeClaimReward) throws {
        self.store = store
        self.reward = reward
        self.strings = (try? store.stringsCN()) ?? [:]
        super.init(size: CGSize(width: 568, height: 320))
        scaleMode = .aspectFit
        anchorPoint = .zero
        backgroundColor = .clear
        root.position = CGPoint(x: 0, y: 320)
        addChild(root)
        render()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func render() {
        let dim = SKShapeNode(rect: CGRect(x: 0, y: -320, width: 568, height: 320))
        dim.fillColor = UIColor(white: 0, alpha: 0.35)
        dim.strokeColor = .clear
        root.addChild(dim)

        let panel = SKShapeNode(rect: CGRect(
            x: G.claimFrame.origin.x,
            y: -(G.claimFrame.origin.y + G.claimFrame.size.height),
            width: G.claimFrame.size.width,
            height: G.claimFrame.size.height
        ))
        panel.fillColor = UIColor(red: 0.92, green: 0.88, blue: 0.78, alpha: 1)
        panel.strokeColor = .darkGray
        root.addChild(panel)
        addLabel(strings["video_reward"] ?? "获得", NativeRect(x: 184, y: 112, width: 200, height: 20), 9)

        switch reward {
        case .medals(let value):
            if let node = sprite("medals.png") {
                place(node, NativeRect(x: 261, y: 150, width: 18, height: 18))
                root.addChild(node)
            }
            addLabel(String(value), NativeRect(x: 278, y: 151, width: 40, height: 16), 8)
        case .item(let file, let count):
            if let node = item(file) {
                place(node, NativeRect(x: 261, y: 145, width: 45, height: 45))
                root.addChild(node)
            }
            addLabel(String(count), NativeRect(x: 263, y: 176, width: 30, height: 12), 7)
        }

        if let ok = sprite("button_confirm_blue.png") {
            place(ok, G.claimOK)
            root.addChild(ok)
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let point = NativePoint(x: location.x, y: 320 - location.y)
        let rect = G.claimOK
        if point.x >= rect.origin.x && point.x <= rect.origin.x + rect.size.width && point.y >= rect.origin.y && point.y <= rect.origin.y + rect.size.height {
            confirmHandler?()
        }
    }

    private func sprite(_ file: String) -> SKSpriteNode? {
        guard let image = UIImage(contentsOfFile: store.url("Sprites/image_ui_hd", file).path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func item(_ file: String) -> SKSpriteNode? {
        guard let image = UIImage(contentsOfFile: store.url("Items", file).path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func place(_ node: SKSpriteNode, _ rect: NativeRect) {
        node.anchorPoint = CGPoint(x: 0, y: 1)
        node.position = CGPoint(x: rect.origin.x, y: -rect.origin.y)
        node.size = CGSize(width: rect.size.width, height: rect.size.height)
        node.zPosition = 3
    }

    private func addLabel(_ text: String, _ rect: NativeRect, _ size: CGFloat) {
        let node = SKLabelNode(fontNamed: "PingFangSC-Semibold")
        node.text = text
        node.fontSize = size
        node.fontColor = .darkGray
        node.verticalAlignmentMode = .center
        node.position = CGPoint(x: rect.origin.x + rect.size.width / 2, y: -(rect.origin.y + rect.size.height / 2))
        node.zPosition = 4
        root.addChild(node)
    }
}
#endif
