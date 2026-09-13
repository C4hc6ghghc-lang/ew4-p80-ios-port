#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

/// SpriteKit renderer for the mature P39/original EW4 Talk form. It lives in
/// screen-space `formLayer`, never in the zooming/panning world layer.
@MainActor
final class NativeOriginalTalkRenderer {
    private weak var parent: SKNode?
    private let store: NativeResourceStore
    private let spriteManifest: [String: SpriteManifestEntry]
    private let commanders: [Int: Commander]
    private var root: SKNode?

    init(parent: SKNode, store: NativeResourceStore, spriteManifest: [String: SpriteManifestEntry], commanders: [Int: Commander]) {
        self.parent = parent
        self.store = store
        self.spriteManifest = spriteManifest
        self.commanders = commanders
    }

    func hide() {
        root?.removeFromParent()
        root = nil
    }

    func showSystem(text: String) {
        hide()
        guard let parent else { return }
        let frame = NativeOriginalFormGeometryCore.Talk.leftFrame
        let container = SKNode()
        container.name = "native-original-talk-system"
        container.position = CGPoint(x: frame.origin.x, y: EW4LogicalSpace.height - frame.origin.y)
        container.zPosition = 20_000

        if let board = imageNode("board_dialog_ex.png") {
            board.anchorPoint = CGPoint(x: 0, y: 1)
            board.position = .zero
            board.size = CGSize(width: frame.size.width, height: frame.size.height)
            board.zPosition = 0
            container.addChild(board)
        }

        let textRect = NativeOriginalFormGeometryCore.Talk.systemContent
        let body = SKLabelNode(fontNamed: "PingFangSC-Regular")
        body.name = "native-talk-system-text"
        body.text = text
        body.fontSize = 8
        body.fontColor = UIColor(white: 64.0 / 255.0, alpha: 1)
        body.horizontalAlignmentMode = .left
        body.verticalAlignmentMode = .top
        body.numberOfLines = 0
        body.preferredMaxLayoutWidth = textRect.size.width
        body.lineBreakMode = .byWordWrapping
        body.position = CGPoint(x: textRect.origin.x, y: -textRect.origin.y)
        body.zPosition = 3
        container.addChild(body)

        if let arrow = imageNode("gray_board_dialoguearrow.png") {
            let rect = NativeOriginalFormGeometryCore.Talk.nextLeft
            place(arrow, rect: rect, z: 4)
            let pulse = SKAction.sequence([
                SKAction.moveBy(x: 0, y: -2, duration: 0.35),
                SKAction.moveBy(x: 0, y: 2, duration: 0.35),
            ])
            arrow.run(.repeatForever(pulse), withKey: "native-talk-pulse")
            container.addChild(arrow)
        }

        parent.addChild(container)
        root = container
    }

    func show(_ event: NativeBattleScriptEvent) {
        hide()
        guard let parent else { return }
        let dialogue = event.dialogue
        let isLeft = dialogue?.left == true
        let frame = isLeft ? NativeOriginalFormGeometryCore.Talk.leftFrame : NativeOriginalFormGeometryCore.Talk.rightFrame
        let container = SKNode()
        container.name = "native-original-talk"
        container.position = CGPoint(x: frame.origin.x, y: EW4LogicalSpace.height - frame.origin.y)
        container.zPosition = 20_000

        if let board = imageNode("board_dialog_ex.png") {
            board.anchorPoint = CGPoint(x: 0, y: 1)
            board.position = .zero
            board.size = CGSize(width: frame.size.width, height: frame.size.height)
            board.zPosition = 0
            container.addChild(board)
        }

        if let commanderID = dialogue?.commanderID,
           let commander = commanders[commanderID],
           let portrait = portraitNode(commanderName: commander.name) {
            let rect = isLeft ? NativeOriginalFormGeometryCore.Talk.portraitLeft : NativeOriginalFormGeometryCore.Talk.portraitRight
            place(portrait, rect: rect, z: 2)
            container.addChild(portrait)
        }

        let content = isLeft ? NativeOriginalFormGeometryCore.Talk.contentLeft : NativeOriginalFormGeometryCore.Talk.contentRight
        let nameRect = offset(NativeOriginalFormGeometryCore.Talk.nameInContent, by: content.origin)
        let textRect = offset(NativeOriginalFormGeometryCore.Talk.textInContent, by: content.origin)

        let name = SKLabelNode(fontNamed: "PingFangSC-Semibold")
        name.name = "native-talk-name"
        name.text = commanderDisplayName(dialogue?.commanderID)
        name.fontSize = 9
        name.fontColor = UIColor(white: 100.0 / 255.0, alpha: 1)
        name.horizontalAlignmentMode = .left
        name.verticalAlignmentMode = .top
        name.position = CGPoint(x: nameRect.origin.x, y: -nameRect.origin.y)
        name.zPosition = 3
        container.addChild(name)

        let body = SKLabelNode(fontNamed: "PingFangSC-Regular")
        body.name = "native-talk-text"
        body.text = dialogue?.text ?? ""
        body.fontSize = 8
        body.fontColor = UIColor(white: 64.0 / 255.0, alpha: 1)
        body.horizontalAlignmentMode = .left
        body.verticalAlignmentMode = .top
        body.numberOfLines = 0
        body.preferredMaxLayoutWidth = textRect.size.width
        body.lineBreakMode = .byWordWrapping
        body.position = CGPoint(x: textRect.origin.x, y: -textRect.origin.y)
        body.zPosition = 3
        container.addChild(body)

        if let arrow = imageNode("gray_board_dialoguearrow.png") {
            let rect = isLeft ? NativeOriginalFormGeometryCore.Talk.nextLeft : NativeOriginalFormGeometryCore.Talk.nextRight
            place(arrow, rect: rect, z: 4)
            let pulse = SKAction.sequence([
                SKAction.moveBy(x: 0, y: -2, duration: 0.35),
                SKAction.moveBy(x: 0, y: 2, duration: 0.35),
            ])
            arrow.run(.repeatForever(pulse), withKey: "native-talk-pulse")
            container.addChild(arrow)
        }

        parent.addChild(container)
        root = container
    }

    private func commanderDisplayName(_ id: Int?) -> String {
        guard let id else { return "" }
        return commanders[id]?.name ?? "将领 \(id)"
    }

    private func imageNode(_ key: String) -> SKSpriteNode? {
        guard let entry = spriteManifest[key] else { return nil }
        let url = store.spriteURL(manifestPath: entry.file)
        guard let image = UIImage(contentsOfFile: url.path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func portraitNode(commanderName: String) -> SKSpriteNode? {
        let url = store.url("Portraits", commanderName + ".webp")
        guard let image = UIImage(contentsOfFile: url.path)?.cgImage else { return nil }
        let node = SKSpriteNode(texture: SKTexture(cgImage: image))
        return node
    }

    private func place(_ node: SKSpriteNode, rect: NativeRect, z: CGFloat) {
        node.anchorPoint = CGPoint(x: 0, y: 1)
        node.position = CGPoint(x: rect.origin.x, y: -rect.origin.y)
        node.size = CGSize(width: rect.size.width, height: rect.size.height)
        node.zPosition = z
    }

    private func offset(_ rect: NativeRect, by point: NativePoint) -> NativeRect {
        NativeRect(x: point.x + rect.origin.x, y: point.y + rect.origin.y, width: rect.size.width, height: rect.size.height)
    }
}
#endif
