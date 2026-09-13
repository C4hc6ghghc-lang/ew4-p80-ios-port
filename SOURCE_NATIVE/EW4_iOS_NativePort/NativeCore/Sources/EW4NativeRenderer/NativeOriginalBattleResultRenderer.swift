#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

/// Original-EW4 result surfaces in fixed 568×320 screen space. These nodes
/// never inherit world camera/LOD transforms.
@MainActor
final class NativeOriginalBattleResultRenderer {
    private weak var parent: SKNode?
    private let store: NativeResourceStore
    private let spriteManifest: [String: SpriteManifestEntry]
    private let commanders: [Int: Commander]
    private let strings: [String: String]
    private var root: SKNode?
    private var victoryTextRoot: SKNode?

    init(
        parent: SKNode,
        store: NativeResourceStore,
        spriteManifest: [String: SpriteManifestEntry],
        commanders: [Int: Commander],
        strings: [String: String]
    ) {
        self.parent = parent
        self.store = store
        self.spriteManifest = spriteManifest
        self.commanders = commanders
        self.strings = strings
    }

    func hide() {
        root?.removeFromParent()
        root = nil
        victoryTextRoot?.removeAllActions()
        victoryTextRoot?.removeFromParent()
        victoryTextRoot = nil
    }

    func show(_ content: NativeOriginalBattleResultContent) {
        root?.removeFromParent()
        root = nil
        guard let parent else { return }
        let node = content.kind == .victory ? makeVictory(content) : makeFailure(content)
        parent.addChild(node)
        root = node
    }

    func showVictoryText(completion: @escaping () -> Void) {
        victoryTextRoot?.removeAllActions()
        victoryTextRoot?.removeFromParent()
        guard let parent else { completion(); return }

        let root = SKNode()
        root.name = "native-original-victorytext"
        root.zPosition = 23_000

        let shade = SKShapeNode(rect: CGRect(x: 0, y: 0, width: EW4LogicalSpace.width, height: EW4LogicalSpace.height))
        shade.fillColor = UIColor(white: 0, alpha: 0.38)
        shade.strokeColor = .clear
        root.addChild(shade)

        if let back = imageNode("board_victory.png") {
            placeScreen(back, rect: NativeOriginalFormGeometryCore.VictoryText.backdrop, z: 2)
            root.addChild(back)
        }
        if let word = textureNode(folder: "Textures", file: "tex_victory.png") {
            let rect = NativeOriginalFormGeometryCore.VictoryText.word
            placeScreen(word, rect: rect, z: 3)
            word.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            word.position = CGPoint(x: rect.origin.x + rect.size.width / 2, y: EW4LogicalSpace.height - rect.origin.y - rect.size.height / 2)
            word.alpha = 0
            word.setScale(0.72)
            let fadeIn = SKAction.group([.fadeAlpha(to: 1, duration: 0.54), .scale(to: 1.03, duration: 0.54)])
            let settle = SKAction.scale(to: 1.0, duration: 0.5)
            let hold = SKAction.wait(forDuration: 2.47)
            let fadeOut = SKAction.fadeOut(withDuration: 0.99)
            word.run(.sequence([fadeIn, settle, hold, fadeOut]))
            root.addChild(word)
        }

        parent.addChild(root)
        victoryTextRoot = root
        let wait = SKAction.wait(forDuration: NativeOriginalFormGeometryCore.VictoryText.durationMilliseconds / 1000)
        root.run(.sequence([wait, .run { [weak self] in
            self?.victoryTextRoot?.removeFromParent()
            self?.victoryTextRoot = nil
            completion()
        }]))
    }

    private func makeVictory(_ content: NativeOriginalBattleResultContent) -> SKNode {
        let screen = NativeOriginalFormGeometryCore.Victory.screenFrame
        let root = modalRoot(screen: screen, title: strings["title_victory"] ?? "胜  利")
        root.name = "native-original-victory"

        addLine(x: 240, y: 27, width: 1, height: 63, root: root)
        addLine(x: 0, y: 90, width: 346, height: 1, root: root)
        addLine(x: 240, y: 47, width: 106, height: 1, root: root)
        addLine(x: 0, y: 158, width: 346, height: 1, root: root)
        addLine(x: 0, y: 206, width: 346, height: 1, root: root)

        addText(content.battleName, rect: NativeOriginalFormGeometryCore.Victory.battleName, size: 8, align: .center, root: root, weight: .semibold)
        addText(strings["text_round"] ?? "回合", rect: NativeOriginalFormGeometryCore.Victory.roundLabel, size: 7, align: .center, root: root)
        addText(String(content.round), rect: NativeOriginalFormGeometryCore.Victory.roundValue, size: 14, align: .center, root: root, weight: .semibold)

        if let board = imageNode("star_board.png") {
            place(board, rect: NativeOriginalFormGeometryCore.Victory.starLevel, z: 3)
            root.addChild(board)
        }
        addText(content.limits.valid ? String(content.limits.win) : "-", rect: NativeRect(x: 324, y: 38, width: 20, height: 12), size: 7, align: .left, root: root)
        addText(content.limits.valid ? String(content.limits.best) : "-", rect: NativeRect(x: 324, y: 69, width: 20, height: 12), size: 7, align: .left, root: root)

        for i in 0..<5 {
            let key = i < content.score ? "star_middle.png" : "diffcult_1.png"
            if let star = imageNode(key) {
                place(star, rect: NativeRect(x: 85 + Double(i * 14), y: 47, width: 13, height: 13), z: 4)
                root.addChild(star)
            }
        }

        addText(strings["text_award"] ?? "奖励", rect: NativeOriginalFormGeometryCore.Victory.awardLabel, size: 7, align: .right, root: root)
        if let medal = imageNode("medals.png") { place(medal, rect: NativeOriginalFormGeometryCore.Victory.awardMedal, z: 4); root.addChild(medal) }
        addText(String(content.awardMedal), rect: NativeOriginalFormGeometryCore.Victory.awardValue, size: 8, align: .left, root: root, weight: .semibold)
        addText(strings["text_gain"] ?? "获得", rect: NativeOriginalFormGeometryCore.Victory.gainLabel, size: 7, align: .right, root: root)
        if let medal = imageNode("medals.png") { place(medal, rect: NativeOriginalFormGeometryCore.Victory.gainMedal, z: 4); root.addChild(medal) }
        addText(String(content.collectedMedal), rect: NativeOriginalFormGeometryCore.Victory.gainValue, size: 8, align: .left, root: root, weight: .semibold)

        addGenerals(content.generalIDs, root: root)
        addButton(strings["btn_continue"] ?? "继续", rect: NativeOriginalFormGeometryCore.Victory.continueButton, key: "btn_common_green.png", root: root)
        addButton(strings["btn_exit"] ?? "退出", rect: NativeOriginalFormGeometryCore.Victory.exitButton, key: "btn_common_blue.png", root: root)
        if let ornament = imageNode("pattern_stage_intro.png") {
            place(ornament, rect: NativeRect(x: 157, y: NativeOriginalFormGeometryCore.Victory.ornamentY, width: 31.5, height: 18), z: 3)
            root.addChild(ornament)
        }
        return root
    }

    private func makeFailure(_ content: NativeOriginalBattleResultContent) -> SKNode {
        let screen = NativeOriginalFormGeometryCore.Failure.screenFrame
        let root = modalRoot(screen: screen, title: strings["title_failure"] ?? "失  败")
        root.name = "native-original-failure"
        let common = NativeOriginalFormGeometryCore.Failure.common
        addFrame(common, root: root)
        if let deco = imageNode("pattern_save.png") {
            place(deco, rect: NativeRect(x: 35, y: 80, width: 20, height: 12), z: 3)
            root.addChild(deco)
        }
        if let deco = imageNode("pattern_save.png") {
            place(deco, rect: NativeRect(x: 96, y: 80, width: 20, height: 12), z: 3)
            deco.xScale = -abs(deco.xScale)
            root.addChild(deco)
        }
        if !content.playerCountryCode.isEmpty, let flag = imageNode(content.playerCountryCode + "1.png") {
            place(flag, rect: NativeOriginalFormGeometryCore.Failure.flag, z: 4)
            root.addChild(flag)
        }
        if let nameboard = imageNode("Board_generalinfomarker.png") {
            place(nameboard, rect: NativeRect(x: 33, y: 105, width: 85, height: 20), z: 3)
            root.addChild(nameboard)
        }
        addText(content.playerCountryName, rect: NativeOriginalFormGeometryCore.Failure.countryName, size: 7, align: .center, root: root, weight: .semibold, light: true)
        addLine(x: 0, y: 153, width: 151, height: 1, root: root, bold: true)
        if let ornament = imageNode("pattern_stage_intro.png") {
            place(ornament, rect: NativeRect(x: 60, y: NativeOriginalFormGeometryCore.Failure.ornamentY, width: 31.5, height: 18), z: 3)
            root.addChild(ornament)
        }
        if let ok = imageNode("button_ok_gray_noshadow.png") {
            place(ok, rect: NativeOriginalFormGeometryCore.Failure.okButton, z: 5)
            root.addChild(ok)
        }
        return root
    }

    private func addGenerals(_ ids: [Int], root: SKNode) {
        for slot in 0..<6 {
            let x = 13.0 + Double(slot) * 53.3
            guard slot < ids.count, let commander = commanders[ids[slot]] else {
                let empty = SKShapeNode(rect: CGRect(x: x + 8, y: -(103), width: 35, height: 35))
                empty.strokeColor = UIColor(red: 154/255, green: 144/255, blue: 122/255, alpha: 0.22)
                empty.lineWidth = 1
                empty.zPosition = 2
                root.addChild(empty)
                continue
            }
            if let portrait = portraitNode(commanderName: commander.name) {
                place(portrait, rect: NativeRect(x: x + 5, y: 96, width: 42, height: 48), z: 3)
                root.addChild(portrait)
            }
            if let board = imageNode("general_nameboard.png") {
                place(board, rect: NativeRect(x: x, y: 141, width: 52, height: 13), z: 4)
                root.addChild(board)
            }
            let name = strings["name_\(commander.name)"] ?? commander.name
            addText(name, rect: NativeRect(x: x + 1, y: 142, width: 50, height: 10), size: 6, align: .center, root: root, weight: .regular, light: true)
        }
    }

    private enum FontWeight { case regular, semibold }

    private func modalRoot(screen: NativeRect, title: String) -> SKNode {
        let root = SKNode()
        root.position = CGPoint(x: screen.origin.x, y: EW4LogicalSpace.height - screen.origin.y)
        root.zPosition = 22_000
        let shade = SKShapeNode(rect: CGRect(x: -screen.origin.x, y: -(EW4LogicalSpace.height - screen.origin.y), width: EW4LogicalSpace.width, height: EW4LogicalSpace.height))
        shade.fillColor = UIColor(white: 0, alpha: 0.53)
        shade.strokeColor = .clear
        shade.zPosition = -2
        root.addChild(shade)
        let panel = SKShapeNode(rect: CGRect(x: 0, y: -screen.size.height, width: screen.size.width, height: screen.size.height))
        panel.fillColor = UIColor(red: 222/255, green: 216/255, blue: 203/255, alpha: 1)
        panel.strokeColor = UIColor(red: 113/255, green: 106/255, blue: 93/255, alpha: 1)
        panel.lineWidth = 1
        root.addChild(panel)
        let header = SKShapeNode(rect: CGRect(x: 0, y: -27, width: screen.size.width, height: 27))
        header.fillColor = UIColor(red: 222/255, green: 216/255, blue: 203/255, alpha: 1)
        header.strokeColor = UIColor(red: 129/255, green: 119/255, blue: 105/255, alpha: 1)
        header.lineWidth = 1
        header.zPosition = 1
        root.addChild(header)
        addText(title, rect: NativeRect(x: 0, y: 4, width: screen.size.width, height: 20), size: 10, align: .center, root: root, weight: .semibold)
        return root
    }

    private func addButton(_ title: String, rect: NativeRect, key: String, root: SKNode) {
        if let button = imageNode(key) { place(button, rect: rect, z: 5); root.addChild(button) }
        addText(title, rect: rect, size: 8, align: .center, root: root, weight: .semibold, light: true, verticalCenter: true)
    }

    private func addFrame(_ rect: NativeRect, root: SKNode) {
        let node = SKShapeNode(rect: CGRect(x: rect.origin.x, y: -(rect.origin.y + rect.size.height), width: rect.size.width, height: rect.size.height))
        node.fillColor = .clear
        node.strokeColor = UIColor(red: 129/255, green: 119/255, blue: 105/255, alpha: 1)
        node.lineWidth = 1
        node.zPosition = 2
        root.addChild(node)
    }

    private func addLine(x: Double, y: Double, width: Double, height: Double, root: SKNode, bold: Bool = false) {
        let line = SKShapeNode(rect: CGRect(x: x, y: -(y + height), width: width, height: max(1, height)))
        line.fillColor = UIColor(red: 145/255, green: 135/255, blue: 120/255, alpha: 0.9)
        line.strokeColor = .clear
        line.zPosition = 2
        if bold { line.lineWidth = 2 }
        root.addChild(line)
    }

    private func addText(
        _ text: String,
        rect: NativeRect,
        size: CGFloat,
        align: SKLabelHorizontalAlignmentMode,
        root: SKNode,
        weight: FontWeight = .regular,
        light: Bool = false,
        verticalCenter: Bool = false
    ) {
        let font: String
        switch weight {
        case .regular: font = "PingFangSC-Regular"
        case .semibold: font = "PingFangSC-Semibold"
        }
        let label = SKLabelNode(fontNamed: font)
        label.text = text
        label.fontSize = size
        label.fontColor = light ? UIColor(red: 238/255, green: 229/255, blue: 213/255, alpha: 1) : UIColor(white: 64/255, alpha: 1)
        label.horizontalAlignmentMode = align
        label.verticalAlignmentMode = verticalCenter ? .center : .top
        let x: Double
        switch align {
        case .center: x = rect.origin.x + rect.size.width / 2
        case .right: x = rect.origin.x + rect.size.width
        default: x = rect.origin.x
        }
        let y = verticalCenter ? rect.origin.y + rect.size.height / 2 : rect.origin.y
        label.position = CGPoint(x: x, y: -y)
        label.zPosition = 6
        root.addChild(label)
    }

    private func imageNode(_ key: String) -> SKSpriteNode? {
        guard let entry = spriteManifest[key] else { return nil }
        let url = store.spriteURL(manifestPath: entry.file)
        guard let image = UIImage(contentsOfFile: url.path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func textureNode(folder: String, file: String) -> SKSpriteNode? {
        guard let image = UIImage(contentsOfFile: store.url(folder, file).path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func portraitNode(commanderName: String) -> SKSpriteNode? {
        guard let image = UIImage(contentsOfFile: store.url("Portraits", commanderName + ".webp").path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func place(_ node: SKSpriteNode, rect: NativeRect, z: CGFloat) {
        node.anchorPoint = CGPoint(x: 0, y: 1)
        node.position = CGPoint(x: rect.origin.x, y: -rect.origin.y)
        node.size = CGSize(width: rect.size.width, height: rect.size.height)
        node.zPosition = z
    }

    private func placeScreen(_ node: SKSpriteNode, rect: NativeRect, z: CGFloat) {
        node.anchorPoint = CGPoint(x: 0, y: 1)
        node.position = CGPoint(x: rect.origin.x, y: EW4LogicalSpace.height - rect.origin.y)
        node.size = CGSize(width: rect.size.width, height: rect.size.height)
        node.zPosition = z
    }
}
#endif
