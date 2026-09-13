#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

public final class NativeOriginalTutorialScene: SKScene {
    public var backHandler: (() -> Void)?
    public var launchHandler: ((String) -> Void)?
    public var soundEffectHandler: ((String) -> Void)?
    private let store: NativeResourceStore
    private let strings: [String:String]
    private let root=SKNode()
    private var noticeVisible=false
    private var noticeScroll=0.0
    private var noticeDragStartY=0.0
    private var noticeDragStartScroll=0.0
    private var draggingNoticeContent=false
    private var draggingNoticeScrollbar=false
    private let backRect=NativeRect(x:0,y:275,width:45,height:45)
    private let basicRect=NativeOriginalFormGeometryCore.Tutorial.basicButton
    private let advancedRect=NativeOriginalFormGeometryCore.Tutorial.classicButton
    private let noticeRect=NativeOriginalFormGeometryCore.Tutorial.noticeButton
    private let noticePanel=NativeOriginalFormGeometryCore.Tutorial.playNoticeFrame
    private let noticeViewport=NativeOriginalFormGeometryCore.Tutorial.playNoticeViewport
    private let noticeScrollbarTrack=NativeOriginalFormGeometryCore.Tutorial.playNoticeScrollbarTrack
    private let noticeCloseRect=NativeOriginalFormGeometryCore.Tutorial.playNoticeCloseButton

    public init(store: NativeResourceStore) throws {
        self.store=store; self.strings=try store.stringsCN()
        super.init(size:CGSize(width:568,height:320));scaleMode = .aspectFit;anchorPoint = .zero;backgroundColor = .black;root.position=CGPoint(x:0,y:320);addChild(root);render()
    }
    @available(*, unavailable) required init?(coder:NSCoder){fatalError("init(coder:) has not been implemented")}
    private var noticeLines:[String]{NativeOriginalPlayNoticeCore.lines(from: strings["html_notice"] ?? "")}
    private func render(){
        root.removeAllChildren();if let bg=textureNode("campaign_wide.png"){place(bg,.init(x:0,y:0,width:568,height:320),0);root.addChild(bg)}
        if let back=sprite("image_ui_hd","button_back.png"){place(back,backRect,10);root.addChild(back)}
        let panel=shape(NativeOriginalFormGeometryCore.Tutorial.screenFrame,fill:ui(234,224,204,245),stroke:ui(97,84,64));panel.zPosition=2;root.addChild(panel)
        label(strings["title_tutorials"] ?? "教  程",.init(x:159,y:66,width:250,height:24),12,ui(69,61,50),5)
        button(basicRect,strings["btn_basic"] ?? "基础教程");button(advancedRect,strings["btn_classic"] ?? "高级教程");button(noticeRect,strings["btn_notice"] ?? "如何游戏")
        if noticeVisible { renderNotice() }
    }
    private func button(_ r:NativeRect,_ text:String){if let b=sprite("image_ui_hd","btn_common_green.png"){place(b,r,5);root.addChild(b)};label(text,r,9,ui(247,244,237),6)}
    private func renderNotice(){
        let dim=shape(.init(x:0,y:0,width:568,height:320),fill:ui(0,0,0,100),stroke:.clear);dim.zPosition=20;root.addChild(dim)
        let p=shape(noticePanel,fill:ui(239,231,214),stroke:ui(93,80,61));p.zPosition=21;root.addChild(p)
        label(strings["title_playnotice"] ?? "玩法说明",.init(x:84,y:52,width:400,height:24),11,ui(72,62,49),23)
        if let frame=sprite("image_ui_hd","common_lineframe_bold.png"){place(frame,noticeViewport,22);root.addChild(frame)}

        let crop=SKCropNode();crop.zPosition=23
        let mask=SKShapeNode(rect:CGRect(x:noticeViewport.origin.x,y:-(noticeViewport.origin.y+noticeViewport.size.height),width:noticeViewport.size.width,height:noticeViewport.size.height));mask.fillColor = .white;mask.strokeColor = .clear;crop.maskNode=mask
        let content=SKNode();content.position=CGPoint(x:0,y:noticeScroll);crop.addChild(content)
        for (i,line) in noticeLines.enumerated(){
            let n=SKLabelNode(fontNamed:"PingFangSC-Regular");n.text=line;n.fontSize=7;n.fontColor=ui(80,80,80);n.horizontalAlignmentMode = .left;n.verticalAlignmentMode = .center;n.position=CGPoint(x:noticeViewport.origin.x+7,y:-(noticeViewport.origin.y+10+Double(i)*NativeOriginalPlayNoticeCore.rowSpacing));n.zPosition=23;content.addChild(n)
        }
        root.addChild(crop)

        if let track=sprite("image_ui_hd","scrollbar_gray.png"){place(track,noticeScrollbarTrack,24);root.addChild(track)}
        let lines=noticeLines.count
        let thumbH=NativeOriginalPlayNoticeCore.thumbHeight(lineCount:lines)
        let thumbY=noticeScrollbarTrack.origin.y+NativeOriginalPlayNoticeCore.thumbOffset(scroll:noticeScroll,lineCount:lines)
        if let thumb=sprite("image_ui_hd","scrollbar_darkgray.png"){place(thumb,.init(x:noticeScrollbarTrack.origin.x,y:thumbY,width:noticeScrollbarTrack.size.width,height:thumbH),25);root.addChild(thumb)}
        if let c=sprite("image_ui_hd","button_close.png"){place(c,noticeCloseRect,26);root.addChild(c)}
    }
    public override func touchesBegan(_ touches:Set<UITouch>,with event:UIEvent?){
        guard noticeVisible,let t=touches.first else{return};let p=nativePoint(t.location(in:self));noticeDragStartY=p.y;noticeDragStartScroll=noticeScroll;draggingNoticeScrollbar=contains(noticeScrollbarTrack,p);draggingNoticeContent=!draggingNoticeScrollbar && contains(noticeViewport,p)
    }
    public override func touchesMoved(_ touches:Set<UITouch>,with event:UIEvent?){
        guard noticeVisible,let t=touches.first else{return};let p=nativePoint(t.location(in:self));let count=noticeLines.count
        if draggingNoticeScrollbar {
            let maxS=NativeOriginalPlayNoticeCore.maxScroll(lineCount:count);let travel=noticeViewport.size.height-NativeOriginalPlayNoticeCore.thumbHeight(lineCount:count)
            let delta=p.y-noticeDragStartY;noticeScroll=travel>0 ? NativeOriginalPlayNoticeCore.clampedScroll(noticeDragStartScroll+delta*maxS/travel,lineCount:count) : 0;render()
        } else if draggingNoticeContent {
            let delta=noticeDragStartY-p.y;noticeScroll=NativeOriginalPlayNoticeCore.clampedScroll(noticeDragStartScroll+delta,lineCount:count);render()
        }
    }
    public override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent?){
        guard let t=touches.first else{return};let p=nativePoint(t.location(in:self))
        if noticeVisible {
            draggingNoticeContent=false;draggingNoticeScrollbar=false
            if contains(noticeCloseRect,p){noticeVisible=false;noticeScroll=0;soundEffectHandler?("sfx_cancel.wav");render()}
            return
        }
        if contains(backRect,p){backHandler?();return};if contains(basicRect,p){soundEffectHandler?("sfx_click.wav");launchHandler?("tutorials1.btl");return};if contains(advancedRect,p){soundEffectHandler?("sfx_click.wav");launchHandler?("tutorials2.btl");return};if contains(noticeRect,p){noticeVisible=true;noticeScroll=0;soundEffectHandler?("sfx_pop.wav");render();return}
    }
    public override func touchesCancelled(_ touches:Set<UITouch>,with event:UIEvent?){draggingNoticeContent=false;draggingNoticeScrollbar=false}
    private func textureNode(_ f:String)->SKSpriteNode?{guard let i=UIImage(contentsOfFile:store.url("Textures",f).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:i))}
    private func sprite(_ folder:String,_ file:String)->SKSpriteNode?{guard let i=UIImage(contentsOfFile:store.url("Sprites/\(folder)",file).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:i))}
    private func shape(_ r:NativeRect,fill:UIColor,stroke:UIColor)->SKShapeNode{let n=SKShapeNode(rect:CGRect(x:r.origin.x,y:-(r.origin.y+r.size.height),width:r.size.width,height:r.size.height));n.fillColor=fill;n.strokeColor=stroke;n.lineWidth=1;return n}
    private func place(_ n:SKSpriteNode,_ r:NativeRect,_ z:CGFloat){n.anchorPoint=CGPoint(x:0,y:1);n.position=CGPoint(x:r.origin.x,y:-r.origin.y);n.size=CGSize(width:r.size.width,height:r.size.height);n.zPosition=z}
    private func label(_ t:String,_ r:NativeRect,_ s:CGFloat,_ c:UIColor,_ z:CGFloat){let n=SKLabelNode(fontNamed:"PingFangSC-Semibold");n.text=t;n.fontSize=s;n.fontColor=c;n.horizontalAlignmentMode = .center;n.verticalAlignmentMode = .center;n.position=CGPoint(x:r.origin.x+r.size.width/2,y:-(r.origin.y+r.size.height/2));n.zPosition=z;root.addChild(n)}
    private func nativePoint(_ p:CGPoint)->NativePoint{.init(x:p.x,y:320-p.y)}
    private func contains(_ r:NativeRect,_ p:NativePoint)->Bool{p.x>=r.origin.x&&p.y>=r.origin.y&&p.x<=r.origin.x+r.size.width&&p.y<=r.origin.y+r.size.height}
    private func ui(_ r:CGFloat,_ g:CGFloat,_ b:CGFloat,_ a:CGFloat=255)->UIColor{UIColor(red:r/255,green:g/255,blue:b/255,alpha:a/255)}
}
#endif
