#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

public final class NativeOriginalOptionsScene: SKScene {
    public var cancelHandler: (() -> Void)?
    public var commitHandler: ((NativePlayerProfile, NativeOptionsSettings) -> Void)?
    public var soundEffectHandler: ((String) -> Void)?
    public private(set) var profile: NativePlayerProfile

    private let store: NativeResourceStore
    private let strings: [String:String]
    private let root = SKNode()
    private var draft: NativeOptionsSettings

    public init(store: NativeResourceStore, profile: NativePlayerProfile) {
        self.store = store
        self.strings = (try? store.stringsCN()) ?? [:]
        self.profile = profile
        self.draft = NativeOptionsCore.settings(from: profile)
        super.init(size: CGSize(width: EW4LogicalSpace.width, height: EW4LogicalSpace.height))
        scaleMode = .aspectFit; anchorPoint = .zero; backgroundColor = .black
        root.position = CGPoint(x: 0, y: EW4LogicalSpace.height); addChild(root); render()
    }
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func render() {
        root.removeAllChildren()
        if let bg = textureNode("campaign_wide.png") { place(bg, .init(x:0,y:0,width:568,height:320), 0); root.addChild(bg) }
        let f = NativeOptionsCore.screenFrame
        let shade = shape(.init(x:0,y:0,width:568,height:320), fill: ui(0,0,0,90), stroke: .clear); shade.zPosition=1; root.addChild(shade)
        if let board = sprite("image_ui_hd", "form_back.png") { place(board, f, 2); root.addChild(board) }
        else { let p=shape(f, fill:ui(235,226,207), stroke:ui(105,94,76)); p.zPosition=2; root.addChild(p) }
        label(strings["title_option"] ?? "游戏设定", .init(x:f.origin.x,y:f.origin.y+4,width:f.size.width,height:24), 11, ui(78,69,56), 5)
        if let close=sprite("image_ui_hd","button_close.png"){place(close,NativeOptionsCore.closeButton,8);root.addChild(close)}

        label(strings["name_music"] ?? "音  乐", .init(x:136,y:86,width:80,height:20), 9, ui(76,69,58), 5)
        label(strings["name_sound"] ?? "音  效", .init(x:310,y:86,width:80,height:20), 9, ui(76,69,58), 5)
        drawTrack(NativeOptionsCore.musicTrack, value:draft.backgroundVolume)
        drawTrack(NativeOptionsCore.soundTrack, value:draft.soundEffectVolume)
        label(strings["name_gamespeed"] ?? "游戏速度", .init(x:136,y:174,width:80,height:20), 9, ui(76,69,58), 5)
        if let bar=sprite("image_ui_hd","speed_bar.png"){place(bar,.init(x:309,y:175,width:110,height:18),4);root.addChild(bar)}
        for (i,r) in NativeOptionsCore.speedButtons.enumerated() {
            if let brick=sprite("image_ui_hd","speed_brick.png"){ place(brick,r, draft.gameSpeed == i + 1 ? 7 : 5); brick.alpha = draft.gameSpeed == i + 1 ? 1 : 0.45; root.addChild(brick) }
        }
        label(strings["name_showgrid"] ?? "地图网格", .init(x:136,y:229,width:100,height:20), 9, ui(76,69,58), 5)
        if let box=sprite("image_ui_hd",draft.showGrids ? "grid_box_tick.png":"grid_box.png"){place(box,NativeOptionsCore.gridButton,6);root.addChild(box)}
        if let ok=sprite("image_ui_hd","button_ok_gray_noshadow.png"){place(ok,NativeOptionsCore.okButton,8);root.addChild(ok)}
    }

    private func drawTrack(_ rect: NativeRect, value: Int) {
        if let bar=sprite("image_ui_hd","volume_bar.png"){place(bar,rect,4);root.addChild(bar)}
        let x = rect.origin.x + rect.size.width * CGFloat(value) / 100
        if let knob=sprite("image_ui_hd","slider_press.png"){place(knob,.init(x:Double(x)-6,y:rect.origin.y-1,width:12,height:20),6);root.addChild(knob)}
    }

    public override func touchesEnded(_ touches:Set<UITouch>, with event:UIEvent?) {
        guard let t=touches.first else{return}; let p=nativePoint(t.location(in:self))
        if contains(NativeOptionsCore.closeButton,p){ soundEffectHandler?("sfx_cancel.wav"); cancelHandler?(); return }
        if contains(NativeOptionsCore.okButton,p){ var updated=profile; NativeOptionsCore.apply(draft,to:&updated); profile=updated; soundEffectHandler?("sfx_click.wav"); commitHandler?(updated,draft); return }
        if contains(NativeOptionsCore.musicTrack,p){ draft.backgroundVolume=NativeOptionsCore.sliderPercent(atX:p.x,track:NativeOptionsCore.musicTrack); soundEffectHandler?("sfx_slide.wav"); render(); return }
        if contains(NativeOptionsCore.soundTrack,p){ draft.soundEffectVolume=NativeOptionsCore.sliderPercent(atX:p.x,track:NativeOptionsCore.soundTrack); soundEffectHandler?("sfx_slide.wav"); render(); return }
        for (i,r) in NativeOptionsCore.speedButtons.enumerated() where contains(r,p){ draft.gameSpeed=i+1; soundEffectHandler?("sfx_click.wav"); render(); return }
        if contains(NativeOptionsCore.gridButton,p){ draft.showGrids.toggle(); soundEffectHandler?("sfx_click.wav"); render(); return }
    }

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
