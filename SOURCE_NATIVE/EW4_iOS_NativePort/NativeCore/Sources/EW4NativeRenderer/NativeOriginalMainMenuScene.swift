#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

public final class NativeOriginalMainMenuScene: SKScene {
    public var actionHandler: ((NativeOriginalMainMenuAction) -> Void)?
    public var achievementHandler: (() -> Void)?

    private let store: NativeResourceStore
    private let root = SKNode()

    public init(store: NativeResourceStore) {
        self.store = store
        super.init(size: CGSize(width: EW4LogicalSpace.width, height: EW4LogicalSpace.height))
        scaleMode = .aspectFit
        anchorPoint = CGPoint(x: 0, y: 0)
        backgroundColor = .black
        root.position = CGPoint(x: 0, y: EW4LogicalSpace.height)
        addChild(root)
        render()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func render() {
        if let bg = textureNode("mainmenu_wide.png") {
            place(bg, NativeRect(x: 0, y: 0, width: 568, height: 320), z: 0)
            root.addChild(bg)
        }
        if let title = textureNode("title_hd.png") {
            place(title, NativeOriginalMainMenuCore.title, z: 2)
            root.addChild(title)
        }
        for (index, rect) in NativeOriginalMainMenuCore.buttons.enumerated() {
            if let button = directSprite("image_ui_hd", "button_mainmenu.png") {
                place(button, rect, z: 4)
                root.addChild(button)
            }
            addLabel(NativeOriginalMainMenuCore.labels[index], rect: rect, size: 15, z: 5)
        }
        let bottom: [(NativeRect, String)] = [
            (NativeOriginalMainMenuCore.homepage, "button_homepage.png"),
            (NativeOriginalMainMenuCore.achievement, "button_achievement.png"),
            (NativeOriginalMainMenuCore.email, "button_email.png"),
        ]
        for (rect, file) in bottom {
            if let node = directSprite("image_ui_hd", file) {
                place(node, rect, z: 4)
                root.addChild(node)
            }
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let p = touch.location(in: self)
        let point = NativePoint(x: p.x, y: EW4LogicalSpace.height - p.y)
        if let action = NativeOriginalMainMenuCore.action(at: point) {
            actionHandler?(action)
            return
        }
        if NativeOriginalMainMenuCore.achievementHit(at: point) { achievementHandler?() }
    }

    private func textureNode(_ file: String) -> SKSpriteNode? {
        guard let image = UIImage(contentsOfFile: store.url("Textures", file).path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func directSprite(_ folder: String, _ file: String) -> SKSpriteNode? {
        guard let image = UIImage(contentsOfFile: store.url("Sprites/\(folder)", file).path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func place(_ node: SKSpriteNode, _ rect: NativeRect, z: CGFloat) {
        node.anchorPoint = CGPoint(x: 0, y: 1)
        node.position = CGPoint(x: rect.origin.x, y: -rect.origin.y)
        node.size = CGSize(width: rect.size.width, height: rect.size.height)
        node.zPosition = z
    }

    private func addLabel(_ text: String, rect: NativeRect, size: CGFloat, z: CGFloat) {
        let label = SKLabelNode(fontNamed: "PingFangSC-Semibold")
        label.text = text
        label.fontSize = size
        label.fontColor = UIColor(red: 244 / 255, green: 238 / 255, blue: 224 / 255, alpha: 1)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: rect.origin.x + rect.size.width / 2, y: -(rect.origin.y + rect.size.height / 2))
        label.zPosition = z
        root.addChild(label)
    }
}
#endif
