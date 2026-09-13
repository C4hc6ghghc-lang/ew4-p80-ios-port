#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

/// Screen-space renderer for original form_stageintro. Coordinates are the
/// recovered XML/P39 logical pixels and never inherit world camera transforms.
@MainActor
final class NativeOriginalStageIntroRenderer {
    private weak var parent: SKNode?
    private let store: NativeResourceStore
    private let spriteManifest: [String: SpriteManifestEntry]
    private let commanders: [Int: Commander]
    private let strings: [String: String]
    private var root: SKNode?

    init(parent: SKNode, store: NativeResourceStore, spriteManifest: [String: SpriteManifestEntry], commanders: [Int: Commander]) {
        self.parent = parent
        self.store = store
        self.spriteManifest = spriteManifest
        self.commanders = commanders
        self.strings = (try? store.stringsCN()) ?? [:]
    }

    func hide() { root?.removeFromParent(); root = nil }

    func show(_ content: NativeStageIntroContent) {
        hide()
        guard let parent else { return }
        let screen = NativeOriginalFormGeometryCore.StageIntro.screenFrame
        let root = SKNode()
        root.name = "native-original-stageintro"
        root.position = CGPoint(x: screen.origin.x, y: EW4LogicalSpace.height - screen.origin.y)
        root.zPosition = 21_000

        let panel = SKShapeNode(rect: CGRect(x: 0, y: -screen.size.height, width: screen.size.width, height: screen.size.height))
        panel.fillColor = UIColor(red: 233/255, green: 228/255, blue: 218/255, alpha: 1)
        panel.strokeColor = UIColor(red: 119/255, green: 112/255, blue: 100/255, alpha: 1)
        panel.lineWidth = 1
        panel.zPosition = 0
        root.addChild(panel)

        let header = SKShapeNode(rect: CGRect(x: 0, y: -28, width: 360, height: 28))
        header.fillColor = UIColor(red: 215/255, green: 207/255, blue: 193/255, alpha: 1)
        header.strokeColor = UIColor(red: 129/255, green: 119/255, blue: 105/255, alpha: 1)
        header.lineWidth = 1
        header.zPosition = 1
        root.addChild(header)

        if let commanderID = content.commanderID,
           let commander = commanders[commanderID],
           let portrait = portraitNode(commanderName: commander.name) {
            place(portrait, rect: NativeRect(x: 2, y: 30, width: 78, height: 78), z: 3)
            root.addChild(portrait)
        }
        if let board = imageNode("general_nameboard.png") {
            place(board, rect: NativeRect(x: 2, y: 108, width: 78, height: 20), z: 4)
            root.addChild(board)
        }
        let commanderName = label(content.commanderName, size: 7, weight: .semibold, color: UIColor(red: 238/255, green: 229/255, blue: 213/255, alpha: 1))
        commanderName.horizontalAlignmentMode = .center
        commanderName.verticalAlignmentMode = .center
        commanderName.position = CGPoint(x: 41, y: -118)
        commanderName.zPosition = 5
        root.addChild(commanderName)

        addStretchFrame(key: "common_lineframe.png", rect: NativeOriginalFormGeometryCore.StageIntro.description, root: root, z: 2)
        let desc = label(content.description, size: 7, weight: .regular, color: UIColor(white: 64/255, alpha: 1))
        desc.name = "native-stageintro-description"
        desc.horizontalAlignmentMode = .left
        desc.verticalAlignmentMode = .top
        desc.numberOfLines = 0
        desc.preferredMaxLayoutWidth = 269
        desc.lineBreakMode = .byWordWrapping
        desc.position = CGPoint(x: 86, y: -33)
        desc.zPosition = 4
        root.addChild(desc)

        addCondition(root: root, x: 0, title: strings["text_victory"] ?? "胜利", rounds: content.victoryRounds)
        addCondition(root: root, x: 180, title: strings["text_bestvic"] ?? "重大胜利", rounds: content.bestVictoryRounds)

        if let ornament = imageNode("pattern_stage_intro.png") {
            place(ornament, rect: NativeRect(x: 164, y: 195, width: 31.5, height: 18), z: 4)
            root.addChild(ornament)
        }
        if let close = imageNode("button_close.png") {
            close.name = "native-stageintro-close"
            place(close, rect: NativeOriginalFormGeometryCore.StageIntro.closeButton, z: 8)
            root.addChild(close)
        }

        parent.addChild(root)
        self.root = root
    }

    private func addCondition(root: SKNode, x: Double, title: String, rounds: Int) {
        let rect = NativeRect(x: x, y: 130, width: 180, height: 60)
        addStretchFrame(key: "common_lineframe.png", rect: rect, root: root, z: 2)
        if let marker = imageNode("Board_generalinfomarker.png") {
            place(marker, rect: NativeRect(x: x, y: 130, width: 180, height: 18), z: 3)
            root.addChild(marker)
        }
        let titleNode = label(title, size: 7, weight: .semibold, color: UIColor(red: 238/255, green: 229/255, blue: 213/255, alpha: 1))
        titleNode.horizontalAlignmentMode = .center
        titleNode.verticalAlignmentMode = .center
        titleNode.position = CGPoint(x: x + 90, y: -139)
        titleNode.zPosition = 4
        root.addChild(titleNode)

        let number = label(String(rounds), size: 15, weight: .bold, color: UIColor(white: 64/255, alpha: 1))
        number.horizontalAlignmentMode = .center
        number.verticalAlignmentMode = .top
        number.position = CGPoint(x: x + 90, y: -160)
        number.zPosition = 4
        root.addChild(number)

        let round = label(strings["text_round_word"] ?? "回合", size: 7, weight: .regular, color: UIColor(white: 64/255, alpha: 1))
        round.horizontalAlignmentMode = .left
        round.verticalAlignmentMode = .top
        round.position = CGPoint(x: x + 108, y: -163)
        round.zPosition = 4
        root.addChild(round)
    }

    private enum FontWeight { case regular, semibold, bold }
    private func label(_ text: String, size: CGFloat, weight: FontWeight, color: UIColor) -> SKLabelNode {
        let font: String
        switch weight { case .regular: font = "PingFangSC-Regular"; case .semibold: font = "PingFangSC-Semibold"; case .bold: font = "PingFangSC-Semibold" }
        let node = SKLabelNode(fontNamed: font)
        node.text = text
        node.fontSize = size
        node.fontColor = color
        return node
    }

    private func addStretchFrame(key: String, rect: NativeRect, root: SKNode, z: CGFloat) {
        guard let node = imageNode(key) else { return }
        place(node, rect: rect, z: z)
        root.addChild(node)
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
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func place(_ node: SKSpriteNode, rect: NativeRect, z: CGFloat) {
        node.anchorPoint = CGPoint(x: 0, y: 1)
        node.position = CGPoint(x: rect.origin.x, y: -rect.origin.y)
        node.size = CGSize(width: rect.size.width, height: rect.size.height)
        node.zPosition = z
    }
}
#endif
