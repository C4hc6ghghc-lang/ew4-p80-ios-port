#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

/// Original battle-context `SceneDeployGeneral` / `form_deploygeneral` renderer.
/// The same outer form is used by HQ, but this renderer owns only battle assignment.
@MainActor
final class NativeOriginalBattleGeneralDeploymentRenderer {
    enum Action: Equatable {
        case close
        case select(Int)
        case confirm
        case princess
        case academy
        case shop
        case princessSelect(Int)
        case princessClose
        case none
    }

    private weak var parent: SKNode?
    private let store: NativeResourceStore
    private let portraits: [String:String]
    private let strings: [String:String]
    private var root: SKNode?
    private var commanders: [Int:Commander] = [:]
    private var eligibleIDs: [Int] = []
    private var generalIDs: [Int] = []
    private var selectedID: Int?
    private var deployedCount = 0
    private var scroll = 0.0
    private var princessVisible = false
    private var generalRects: [Int:NativeRect] = [:]
    private var princessGoRects: [Int:NativeRect] = [:]
    private var interactionStart: NativePoint?
    private var interactionScrollStart = 0.0
    private var interactionDragged = false

    private let screen = NativeRect(x:0,y:0,width:568,height:320)
    private let princessCloseRect = NativeRect(x:501,y:2,width:25,height:25)

    init(parent:SKNode, store:NativeResourceStore, portraits:[String:String]) {
        self.parent=parent
        self.store=store
        self.portraits=portraits
        self.strings=(try? store.stringsCN()) ?? [:]
    }

    var isVisible: Bool { root != nil }
    var isPrincessVisible: Bool { princessVisible }

    func hide(){
        root?.removeFromParent();root=nil
        generalRects.removeAll();princessGoRects.removeAll()
        interactionStart=nil;interactionDragged=false
        princessVisible=false
    }

    func rect(alias:String,row:Int?=nil)->NativeRect?{
        if alias == "grid_general", let row, generalIDs.indices.contains(row) { return generalRects[generalIDs[row]] }
        if alias == "winbtn_back" { return NativeHeadquartersCore.backButton }
        if alias == "btn_done" || alias == "btn_deploy" { return NativeHeadquartersCore.deployButton }
        if alias == "btn_princess" { return NativeHeadquartersCore.princessButton }
        if alias == "btn_college" { return NativeHeadquartersCore.academyButton }
        if alias == "btn_shop" { return NativeHeadquartersCore.shopButton }
        return nil
    }

    func show(ids:[Int], commanders:[Int:Commander], selectedID:Int?, deployedCount:Int){
        self.eligibleIDs=ids
        self.generalIDs=ids.filter { !NativePlayerProfile.princessIDs.contains($0) }
        self.commanders=commanders
        self.selectedID=selectedID
        self.deployedCount=max(0,deployedCount)
        self.scroll=NativeHeadquartersCore.clampedScroll(scroll,count:generalIDs.count)
        render()
    }

    func select(_ id:Int){
        guard eligibleIDs.contains(id) else{return}
        selectedID=id
        princessVisible=false
        render()
    }

    func openPrincess(){ princessVisible=true; render() }
    func closePrincess(){ princessVisible=false; render() }

    func beginInteraction(at point:NativePoint){
        guard !princessVisible, contains(NativeHeadquartersCore.generalGrid,point) else{return}
        interactionStart=point;interactionScrollStart=scroll;interactionDragged=false
    }

    @discardableResult
    func moveInteraction(to point:NativePoint)->Bool{
        guard let start=interactionStart,!princessVisible else{return false}
        let dy=point.y-start.y
        if abs(dy)>3 { interactionDragged=true }
        guard interactionDragged else{return false}
        scroll=NativeHeadquartersCore.clampedScroll(interactionScrollStart-dy,count:generalIDs.count)
        render()
        interactionStart=start
        return true
    }

    /// Returns true when a completed drag consumed the gesture.
    func endInteraction(at point:NativePoint)->Bool{
        defer { interactionStart=nil;interactionDragged=false }
        return interactionDragged
    }

    func action(at point:NativePoint)->Action{
        if princessVisible {
            if contains(princessCloseRect,point){return .princessClose}
            for (id,r) in princessGoRects where contains(r,point){ return .princessSelect(id) }
            return .none
        }
        if contains(NativeHeadquartersCore.backButton,point){return .close}
        if contains(NativeHeadquartersCore.princessButton,point){return .princess}
        if contains(NativeHeadquartersCore.academyButton,point){return .academy}
        if contains(NativeHeadquartersCore.shopButton,point){return .shop}
        if contains(NativeHeadquartersCore.deployButton,point){return .confirm}
        guard contains(NativeHeadquartersCore.generalGrid,point) else{return .none}
        for (id, r) in generalRects where contains(r, point) && intersects(r, NativeHeadquartersCore.generalGrid) { return .select(id) }
        return .none
    }

    private func render(){
        root?.removeFromParent();generalRects.removeAll();princessGoRects.removeAll()
        guard let parent else{return}
        let root=SKNode();root.position=CGPoint(x:0,y:EW4LogicalSpace.height);root.zPosition=25_000
        let dim=SKShapeNode(rect:CGRect(x:0,y:-320,width:568,height:320));dim.fillColor=UIColor(white:0,alpha:0.30);dim.strokeColor = .clear;root.addChild(dim)
        if let bg=sprite("image_menu_hd","campaign_wide.png"){place(bg,screen,0);root.addChild(bg)}else{root.addChild(shape(screen,fill:ui(219,212,198),stroke:ui(100,91,77)))}

        label(strings["title_deploygeneral"] ?? "指挥部",NativeRect(x:190,y:4,width:188,height:24),12,ui(75,68,57),9,root)
        addTopButton(NativeHeadquartersCore.princessButton,title:strings["btn_princess"] ?? "公主",green:true,enabled:true,root:root)
        addShopButton(root)
        addTopButton(NativeHeadquartersCore.academyButton,title:strings["btn_college"] ?? "军事学院",green:true,enabled:true,root:root)

        if let count=sprite("image_ui_hd","generalnumber.png"){place(count,NativeHeadquartersCore.countIcon,6);root.addChild(count)}
        label("\(deployedCount)",NativeRect(x:290,y:43,width:40,height:21),8,ui(64,64,64),7,root)
        addLine(NativeRect(x:0,y:73,width:568,height:1),root:root)
        addLine(NativeRect(x:0,y:298,width:568,height:1),root:root)
        if let p=sprite("image_ui_hd","pattern_bg_bottom.png"){place(p,NativeRect(x:220,y:303,width:128,height:13),3);root.addChild(p)}
        addLine(NativeRect(x:0,y:316,width:568,height:4),root:root)

        renderGeneralGrid(root)
        addBackButton(root)
        addDeployButton(root)
        if princessVisible { renderPrincessPanel(root) }
        parent.addChild(root);self.root=root
    }

    private func renderGeneralGrid(_ root:SKNode){
        let grid=NativeHeadquartersCore.generalGrid
        let crop=SKCropNode();crop.position=CGPoint(x:grid.origin.x,y:-(grid.origin.y+grid.size.height));crop.zPosition=5
        let mask=SKShapeNode(rect:CGRect(x:0,y:0,width:grid.size.width,height:grid.size.height));mask.fillColor = .white;mask.strokeColor = .clear;crop.maskNode=mask
        let content=SKNode();content.position=CGPoint(x:-grid.origin.x,y:grid.origin.y+grid.size.height);crop.addChild(content)
        for (index,id) in generalIDs.enumerated(){
            guard let c=commanders[id] else{continue}
            let r=NativeHeadquartersCore.cardRect(index:index,scroll:scroll);generalRects[id]=r
            renderCommanderCard(id:id,commander:c,rect:r,selected:id==selectedID,parent:content)
        }
        root.addChild(crop)
    }

    private func renderCommanderCard(id:Int,commander:Commander,rect:NativeRect,selected:Bool,parent:SKNode){
        if let portrait=portrait(id){place(portrait,NativeRect(x:rect.origin.x+3,y:rect.origin.y+2,width:72,height:72),2);parent.addChild(portrait)}
        if let board=sprite("image_ui_hd","general_nameboard.png"){place(board,NativeRect(x:rect.origin.x+1.5,y:rect.origin.y+72,width:75,height:15),3);parent.addChild(board)}
        label(commander.name,NativeRect(x:rect.origin.x,y:rect.origin.y+72,width:78,height:15),6.2,ui(73,67,58),4,parent)
        label(stars(commander.star),NativeRect(x:rect.origin.x,y:rect.origin.y+87,width:78,height:10),5.5,ui(180,119,27),4,parent)
        if selected,let sel=sprite("image_ui_hd","item_selected_ex.png"){place(sel,NativeRect(x:rect.origin.x,y:rect.origin.y,width:78,height:98),6);parent.addChild(sel)}
    }

    private func renderPrincessPanel(_ root:SKNode){
        let panel=NativeHeadquartersCore.princessPanel
        let dim=SKShapeNode(rect:CGRect(x:0,y:-320,width:568,height:320));dim.fillColor=UIColor(white:0,alpha:0.33);dim.strokeColor = .clear;dim.zPosition=40;root.addChild(dim)
        if let bg=sprite("image_ui_hd","Board_Shop.png"){place(bg,panel,41);root.addChild(bg)}else{let n=shape(panel,fill:ui(225,218,204),stroke:ui(92,83,70));n.zPosition=41;root.addChild(n)}
        label(strings["title_princess"] ?? "公　主",NativeRect(x:panel.origin.x+135,y:panel.origin.y+3,width:198,height:24),12,ui(75,68,57),43,root)
        if let close=sprite("image_ui_hd","button_close.png"){place(close,princessCloseRect,45);root.addChild(close)}
        for (index,id) in NativeHeadquartersCore.princessOrder.enumerated(){
            guard let c=commanders[id] else{continue}
            let card=NativeHeadquartersCore.princessRect(index:index)
            if let p=portrait(id){place(p,NativeRect(x:card.origin.x+3,y:card.origin.y,width:72,height:78),43);root.addChild(p)}
            if let board=sprite("image_ui_hd","general_nameboard.png"){place(board,NativeRect(x:card.origin.x+1.5,y:card.origin.y+79,width:75,height:15),44);root.addChild(board)}
            label(c.name,NativeRect(x:card.origin.x,y:card.origin.y+79,width:78,height:15),6.2,ui(73,67,58),45,root)
            let go=NativeRect(x:panel.origin.x+[60.0,158.0,256.0,354.0][index%4],y:panel.origin.y+(index<4 ? 135.0:264.0),width:55,height:22)
            princessGoRects[id]=go
            let enabled=eligibleIDs.contains(id)
            if let b=sprite("image_ui_hd","button_confirm_blue.png"){place(b,go,44);b.alpha=enabled ? 1:0.42;root.addChild(b)}
            label(enabled ? (strings["btn_gobattle"] ?? "出征") : "已出征",go,6.5,ui(246,236,212),45,root)
        }
    }

    private func addTopButton(_ rect:NativeRect,title:String,green:Bool,enabled:Bool,root:SKNode){
        if let b=sprite("image_ui_hd",green ? "btn_common_green.png":"btn_common_blue.png"){place(b,rect,5);b.alpha=enabled ? 1:0.42;root.addChild(b)}
        label(title,rect,7,ui(246,236,212),6,root)
    }
    private func addShopButton(_ root:SKNode){
        let r=NativeHeadquartersCore.shopButton
        if let b=sprite("image_ui_hd","btn_common_blue.png"){place(b,r,5);b.alpha=0.42;root.addChild(b)}
        if let icon=sprite("image_ui_hd","image_shop.png"){place(icon,NativeRect(x:r.origin.x+25,y:r.origin.y+12,width:20,height:20),6);icon.alpha=0.5;root.addChild(icon)}
    }
    private func addBackButton(_ root:SKNode){
        let r=NativeHeadquartersCore.backButton
        if let b=sprite("image_ui_hd","button_back.png"){place(b,r,7);root.addChild(b)}
    }
    private func addDeployButton(_ root:SKNode){
        let r=NativeHeadquartersCore.deployButton
        if let b=sprite("image_ui_hd","button_confirm_blue.png"){place(b,r,7);b.alpha=selectedID == nil ? 0.42:1;root.addChild(b)}
        label(strings["btn_deploy"] ?? "出征",NativeRect(x:r.origin.x,y:r.origin.y,width:53,height:22),6.8,ui(246,236,212),8,root)
    }
    private func addLine(_ r:NativeRect,root:SKNode){if let line=sprite("image_ui_hd","common_boldline.png"){place(line,r,4);root.addChild(line)}}

    private func portrait(_ id:Int)->SKSpriteNode?{guard let raw=portraits[String(id)] else{return nil};let file=URL(fileURLWithPath:raw).lastPathComponent;guard let image=UIImage(contentsOfFile:store.url("Portraits",file).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:image))}
    private func sprite(_ folder:String,_ file:String)->SKSpriteNode?{guard let image=UIImage(contentsOfFile:store.url("Sprites/\(folder)",file).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:image))}
    private func shape(_ r:NativeRect,fill:UIColor,stroke:UIColor)->SKShapeNode{let n=SKShapeNode(rect:CGRect(x:r.origin.x,y:-(r.origin.y+r.size.height),width:r.size.width,height:r.size.height));n.fillColor=fill;n.strokeColor=stroke;n.lineWidth=1;return n}
    private func place(_ n:SKSpriteNode,_ r:NativeRect,_ z:CGFloat){n.anchorPoint=CGPoint(x:0,y:1);n.position=CGPoint(x:r.origin.x,y:-r.origin.y);n.size=CGSize(width:r.size.width,height:r.size.height);n.zPosition=z}
    private func label(_ s:String,_ r:NativeRect,_ fs:CGFloat,_ c:UIColor,_ z:CGFloat,_ parent:SKNode){let n=SKLabelNode(fontNamed:"PingFangSC-Semibold");n.text=s;n.fontSize=fs;n.fontColor=c;n.horizontalAlignmentMode = .center;n.verticalAlignmentMode = .center;n.position=CGPoint(x:r.origin.x+r.size.width/2,y:-(r.origin.y+r.size.height/2));n.zPosition=z;parent.addChild(n)}
    private func stars(_ value:Int)->String{String(repeating:"★",count:max(0,min(9,value)))}
    private func contains(_ r:NativeRect,_ p:NativePoint)->Bool{p.x>=r.origin.x&&p.y>=r.origin.y&&p.x<=r.origin.x+r.size.width&&p.y<=r.origin.y+r.size.height}
    private func intersects(_ a:NativeRect,_ b:NativeRect)->Bool{let ax=a.origin.x+a.size.width,ay=a.origin.y+a.size.height,bx=b.origin.x+b.size.width,by=b.origin.y+b.size.height;return a.origin.x<bx&&ax>b.origin.x&&a.origin.y<by&&ay>b.origin.y}
    private func ui(_ r:CGFloat,_ g:CGFloat,_ b:CGFloat,_ a:CGFloat=255)->UIColor{UIColor(red:r/255,green:g/255,blue:b/255,alpha:a/255)}
}
#endif
