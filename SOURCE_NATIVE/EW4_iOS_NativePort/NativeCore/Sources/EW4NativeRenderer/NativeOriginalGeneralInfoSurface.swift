#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

@MainActor
enum NativeOriginalGeneralInfoSurface {
    static func render(
        parent: SKNode,
        store: NativeResourceStore,
        portraits: [String:String],
        strings: [String:String],
        items: NativeItemEffectCatalog,
        commander raw: Commander,
        effective: NativeEffectiveCommander? = nil,
        z: CGFloat = 0
    ) {
        let form = NativeRect(x:64,y:52,width:440,height:217)
        addFrame(parent, form, fill: ui(238,230,212), stroke: ui(105,93,74), z: z)
        addLabel(strings["title_generalinfo"] ?? "信  息", .init(x:64,y:55,width:440,height:22), 10, ui(72,63,51), z+2, parent)

        let portraitRect = NativeRect(x:66,y:82,width:78,height:98)
        addFrame(parent, portraitRect, fill: ui(221,213,197), stroke: ui(118,106,88), z: z+1)
        if let p = portrait(store:store, portraits:portraits, id:raw.id) { place(p,.init(x:70,y:86,width:70,height:72),z+2); parent.addChild(p) }
        addLabel(strings["name_\(raw.name)"] ?? raw.name,.init(x:68,y:158,width:74,height:18),7,ui(70,61,50),z+3,parent)

        let itemBox = NativeRect(x:146,y:82,width:194,height:74)
        addSpriteFrame(parent, store:store, rect:itemBox, z:z+1)
        addLabel(strings["text_equipitem"] ?? "装备",.init(x:149,y:83,width:100,height:16),6.5,ui(100,100,100),z+2,parent,alignment:.left)
        let equipped = effective?.equippedItemIDs ?? [raw.item1,raw.item2].compactMap{$0}.filter{$0 >= 0}
        for i in 0..<2 {
            let r=NativeRect(x:151+Double(i)*52,y:105,width:48,height:42)
            addFrame(parent,r,fill:ui(226,218,202),stroke:ui(153,141,120),z:z+2)
            if equipped.indices.contains(i), let it=items[String(equipped[i])] {
                addLabel(strings["name_\(it.name)"] ?? it.name,r,5.2,ui(72,63,51),z+3,parent)
            } else { addLabel(strings["text_empty"] ?? "无",r,5.2,ui(115,103,84),z+3,parent) }
        }
        addButton(parent,store:store,file:"btn_common_org.png",title:strings["btn_regroup"] ?? "整编",rect:.init(x:253,y:85,width:83,height:33),z:z+2,enabled:false)
        addButton(parent,store:store,file:"btn_common_blue.png",title:strings["btn_item"] ?? "物品",rect:.init(x:253,y:120,width:83,height:33),z:z+2,enabled:false)

        let skillBox=NativeRect(x:342,y:82,width:160,height:74)
        addSpriteFrame(parent,store:store,rect:skillBox,z:z+1)
        let skills=(effective?.skillIDs ?? raw.skillIDs).sorted()
        for row in 0..<4 {
            if row>0 { addLine(parent,store:store,rect:.init(x:342,y:82+Double(row)*19,width:160,height:1),z:z+2) }
            let text: String
            if skills.indices.contains(row) { text = strings[String(format:"name_skill_%02d",skills[row]+1)] ?? "技能 \(skills[row])" }
            else { text = strings["text_empty"] ?? "无" }
            addLabel(text,.init(x:346,y:84+Double(row)*18,width:152,height:16),5.7,ui(72,63,51),z+3,parent,alignment:.left)
        }

        let infoBox=NativeRect(x:66,y:182,width:78,height:85)
        addSpriteFrame(parent,store:store,rect:infoBox,z:z+1)
        let rank=effective?.rankLevel ?? raw.rank
        let nobility=effective?.nobilityLevel ?? raw.nobilityrank
        addLabel("军衔 \(rank)",.init(x:70,y:188,width:52,height:16),5.7,ui(70,61,50),z+3,parent,alignment:.left)
        if let hp=icon(store,"marker_hp_dark.png"){place(hp,.init(x:115,y:190,width:13,height:13),z+3);parent.addChild(hp)}
        addLabel(String(effective?.rankHPBonus ?? 0),.init(x:100,y:204,width:35,height:13),5.5,ui(64,64,64),z+3,parent)
        addLine(parent,store:store,rect:.init(x:66,y:225,width:78,height:1),z:z+2)
        addLabel("爵位 \(nobility)",.init(x:70,y:232,width:52,height:16),5.7,ui(70,61,50),z+3,parent,alignment:.left)
        if let heal=icon(store,"marker_recover_dark.png"){place(heal,.init(x:115,y:233,width:13,height:13),z+3);parent.addChild(heal)}
        addLabel(String(effective?.nobilityHealCap ?? 0),.init(x:100,y:247,width:35,height:13),5.5,ui(64,64,64),z+3,parent)

        let values=NativeRect(x:146,y:158,width:356,height:109)
        addSpriteFrame(parent,store:store,rect:values,z:z+1)
        for row in 1..<4 { addLine(parent,store:store,rect:.init(x:146,y:158+Double(row)*27.5,width:356,height:1),z:z+2) }
        let vals:[(String,Int)] = [
            (strings["btn_infantry"] ?? "步兵",effective?.infantry ?? raw.infantry),
            (strings["btn_cavalry"] ?? "骑兵",effective?.cavalry ?? raw.cavalry),
            (strings["btn_artillery"] ?? "炮兵",effective?.artillery ?? raw.artillery),
            (strings["btn_navy"] ?? "海军",effective?.warship ?? raw.warship),
            (strings["btn_fortress"] ?? "要塞",effective?.fort ?? raw.fort),
            ("商业",effective?.business ?? raw.business),("行军",effective?.movement ?? raw.movement),("训练",effective?.training ?? raw.training)
        ]
        for i in 0..<8 {
            let col=i/4,row=i%4
            let x=150+Double(col)*178,y=161+Double(row)*27.5
            addLabel(vals[i].0,.init(x:x,y:y,width:70,height:22),6,ui(78,68,55),z+3,parent,alignment:.left)
            addLabel(String(vals[i].1),.init(x:x+115,y:y,width:42,height:22),7,ui(65,57,47),z+3,parent)
        }
    }

    private static func addSpriteFrame(_ parent:SKNode,store:NativeResourceStore,rect:NativeRect,z:CGFloat){
        if let n=icon(store,"common_lineframe_bold.png"){place(n,rect,z);parent.addChild(n)} else {addFrame(parent,rect,fill:.clear,stroke:ui(120,108,90),z:z)}
    }
    private static func addLine(_ parent:SKNode,store:NativeResourceStore,rect:NativeRect,z:CGFloat){if let n=icon(store,"common_line_hor.png"){place(n,rect,z);parent.addChild(n)}}
    private static func addButton(_ parent:SKNode,store:NativeResourceStore,file:String,title:String,rect:NativeRect,z:CGFloat,enabled:Bool){if let n=icon(store,file){place(n,rect,z);n.alpha=enabled ? 1:0.42;parent.addChild(n)};addLabel(title,rect,6.2,.white,z+1,parent)}
    private static func portrait(store:NativeResourceStore,portraits:[String:String],id:Int)->SKSpriteNode?{guard let raw=portraits[String(id)]else{return nil};let f=URL(fileURLWithPath:raw).lastPathComponent;guard let im=UIImage(contentsOfFile:store.url("Portraits",f).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:im))}
    private static func icon(_ store:NativeResourceStore,_ file:String)->SKSpriteNode?{guard let im=UIImage(contentsOfFile:store.url("Sprites/image_ui_hd",file).path)?.cgImage else{return nil};return SKSpriteNode(texture:SKTexture(cgImage:im))}
    private static func addFrame(_ parent:SKNode,_ r:NativeRect,fill:UIColor,stroke:UIColor,z:CGFloat){let n=SKShapeNode(rect:CGRect(x:r.origin.x,y:-(r.origin.y+r.size.height),width:r.size.width,height:r.size.height));n.fillColor=fill;n.strokeColor=stroke;n.lineWidth=1;n.zPosition=z;parent.addChild(n)}
    private static func place(_ n:SKSpriteNode,_ r:NativeRect,_ z:CGFloat){n.anchorPoint=CGPoint(x:0,y:1);n.position=CGPoint(x:r.origin.x,y:-r.origin.y);n.size=CGSize(width:r.size.width,height:r.size.height);n.zPosition=z}
    private static func addLabel(_ t:String,_ r:NativeRect,_ s:CGFloat,_ c:UIColor,_ z:CGFloat,_ parent:SKNode,alignment:SKLabelHorizontalAlignmentMode = .center){let n=SKLabelNode(fontNamed:"PingFangSC-Semibold");n.text=t;n.fontSize=s;n.fontColor=c;n.horizontalAlignmentMode=alignment;n.verticalAlignmentMode = .center;n.position=CGPoint(x:alignment == .left ? r.origin.x:r.origin.x+r.size.width/2,y:-(r.origin.y+r.size.height/2));n.zPosition=z;parent.addChild(n)}
    private static func ui(_ r:CGFloat,_ g:CGFloat,_ b:CGFloat,_ a:CGFloat=255)->UIColor{UIColor(red:r/255,green:g/255,blue:b/255,alpha:a/255)}
}
#endif
