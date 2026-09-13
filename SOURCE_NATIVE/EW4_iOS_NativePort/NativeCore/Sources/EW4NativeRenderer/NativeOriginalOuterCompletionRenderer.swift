#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

/// Original `form_complete` renderer. Campaign completion, Asia Challenge and
/// Conquest summary all reuse the same recovered 346x190 surface.
@MainActor
final class NativeOriginalOuterCompletionRenderer {
    private weak var parent: SKNode?
    private let store: NativeResourceStore
    private let spriteManifest: [String: SpriteManifestEntry]
    private let strings: [String: String]
    private var root: SKNode?

    init(parent: SKNode, store: NativeResourceStore, spriteManifest: [String: SpriteManifestEntry], strings: [String: String]) {
        self.parent = parent; self.store = store; self.spriteManifest = spriteManifest; self.strings = strings
    }

    func hide() { root?.removeFromParent(); root = nil }

    func showCampaignComplete(_ content: NativeCampaignCompleteContent) {
        let root = modalRoot(title: strings["title_campaign_victory"] ?? "战役胜利")
        if let picture = textureNode("Textures", content.reward.image) {
            place(picture, NativeOriginalOuterShellCore.Complete.Campaign.picture, 3); root.addChild(picture)
        }
        addLine(y: 147, root: root); addLine(y: 186, root: root)
        addText(strings["text_award"] ?? "奖励", NativeOriginalOuterShellCore.Complete.Campaign.awardText, 7, root)
        addIconAndValue("medals.png", value: content.reward.medal, icon: NativeOriginalOuterShellCore.Complete.Campaign.medal, valueRect: NativeOriginalOuterShellCore.Complete.Campaign.medalValue, root: root)
        addIconAndValue("badges.png", value: content.reward.badge, icon: NativeOriginalOuterShellCore.Complete.Campaign.badge, valueRect: NativeOriginalOuterShellCore.Complete.Campaign.badgeValue, root: root)
        addIconAndValue("button_refresh.png", value: content.reward.score, icon: NativeOriginalOuterShellCore.Complete.Campaign.score, valueRect: NativeOriginalOuterShellCore.Complete.Campaign.scoreValue, root: root)
        addOK(NativeOriginalOuterShellCore.Complete.Campaign.ok, root: root)
        present(root)
    }

    func showChallenge(_ content: NativeConquestChallengeContent) {
        let root = modalRoot(title: strings["title_challenge"] ?? "挑战")
        if let picture = textureNode("Textures", "conquest_asia.png") {
            place(picture, NativeOriginalOuterShellCore.Complete.Challenge.picture, 3); root.addChild(picture)
        }
        addText(strings["desc_challenge"] ?? "阁下，是否要挑战亚洲？", NativeOriginalOuterShellCore.Complete.Challenge.description, 7, root, center: true)
        addLine(y: 135, root: root); addLine(y: 186, root: root)
        if let flower = imageNode("pattern_stage_intro.png") {
            place(flower, NativeRect(x: 123, y: NativeOriginalOuterShellCore.Complete.Challenge.flowerY, width: 100, height: 18), 3); root.addChild(flower)
        }
        addButton(strings["btn_chal_asia"] ?? "征服亚洲", NativeOriginalOuterShellCore.Complete.Challenge.asia, "btn_common_green.png", root)
        addButton(strings[content.homeButtonStringKey] ?? (content.homeButtonStringKey == "btn_chal_amer" ? "统治美洲" : "统治欧洲"), NativeOriginalOuterShellCore.Complete.Challenge.home, "btn_common_blue.png", root)
        present(root)
    }

    func showConquestSummary(_ content: NativeConquestSummaryContent) {
        let root = modalRoot(title: strings["title_conquest_victory"] ?? "胜利征服")
        if let battle = textureNode("Textures", "tex_conquest_\(content.scenario.textureYear).png") {
            place(battle, NativeOriginalOuterShellCore.Complete.Conquest.battle, 3); root.addChild(battle)
        }
        let archiveKey = content.result.kind == "europe" ? "button_rule_europa.png" : "button_rule_\(content.result.kind).png"
        if let archive = imageNode(archiveKey) {
            place(archive, NativeOriginalOuterShellCore.Complete.Conquest.archive, 3); root.addChild(archive)
        }
        addText(strings["text_rule"] ?? "统治", NativeOriginalOuterShellCore.Complete.Conquest.ruleTitle, 7, root, center: true)
        addRuleDigits(content.result.storedValue ?? content.result.value, root: root)
        addText(strings["text_year"] ?? "年", NativeOriginalOuterShellCore.Complete.Conquest.years, 7, root)
        addText(strings["text_round"] ?? "回合", NativeOriginalOuterShellCore.Complete.Conquest.roundTitle, 7, root, center: true)
        addText(String(content.round), NativeOriginalOuterShellCore.Complete.Conquest.roundValue, 9, root, center: true)
        addText(strings["text_gain"] ?? "获得", NativeOriginalOuterShellCore.Complete.Conquest.medalTitle, 7, root)
        if let medal = imageNode("medals.png") { place(medal, NativeOriginalOuterShellCore.Complete.Conquest.medal, 4); root.addChild(medal) }
        addText(String(content.collectedMedal), NativeOriginalOuterShellCore.Complete.Conquest.medalValue, 7, root)
        addLine(y: 135, root: root); addLine(y: 186, root: root)
        addVertical(x: 115, root: root); addVertical(x: 231, root: root)
        addOK(NativeOriginalOuterShellCore.Complete.Conquest.ok, root: root)
        present(root)
    }

    private func present(_ node: SKNode) { hide(); parent?.addChild(node); root = node }

    private func modalRoot(title: String) -> SKNode {
        let screen = NativeOriginalOuterShellCore.Complete.screenFrame
        let root = SKNode(); root.position = CGPoint(x: screen.origin.x, y: EW4LogicalSpace.height - screen.origin.y); root.zPosition = 24_000
        let shade = SKShapeNode(rect: CGRect(x: -screen.origin.x, y: -(EW4LogicalSpace.height - screen.origin.y), width: EW4LogicalSpace.width, height: EW4LogicalSpace.height))
        shade.fillColor = UIColor(white: 0, alpha: 0.53); shade.strokeColor = .clear; shade.zPosition = -2; root.addChild(shade)
        let panel = SKShapeNode(rect: CGRect(x: 0, y: -190, width: 346, height: 190)); panel.fillColor = UIColor(red: 217/255, green: 207/255, blue: 177/255, alpha: 1); panel.strokeColor = UIColor(red: 112/255, green: 100/255, blue: 78/255, alpha: 1); panel.lineWidth = 1; root.addChild(panel)
        addText(title, NativeRect(x: 0, y: 4, width: 346, height: 18), 10, root, center: true, semibold: true)
        return root
    }

    private func addRuleDigits(_ value: Int, root: SKNode) {
        let v = max(0, min(999, value)); let s = String(format: "%03d", v); var x = 237.0
        for (i, ch) in s.enumerated() {
            if (i == 0 && v < 100) || (i == 1 && v < 10) { continue }
            if let digit = imageNode("rule_\(ch).png") { place(digit, NativeRect(x: x, y: 155, width: 20, height: 26), 4); root.addChild(digit) }
            x += 20
        }
    }

    private func addIconAndValue(_ key: String, value: Int, icon: NativeRect, valueRect: NativeRect, root: SKNode) {
        if let node = imageNode(key) {
            place(node, icon, 4)
            root.addChild(node)
        }
        addText(String(value), valueRect, 7, root)
    }

    private func addOK(_ rect: NativeRect, root: SKNode) {
        if let node = imageNode("button_confrim.png") ?? imageNode("new_confirm.png") {
            place(node, rect, 5)
            root.addChild(node)
        }
    }

    private func addButton(_ title: String, _ rect: NativeRect, _ key: String, _ root: SKNode) {
        if let node = imageNode(key) {
            place(node, rect, 5)
            root.addChild(node)
        }
        addText(title, rect, 8, root, center: true, semibold: true, light: true, vertical: true)
    }

    private func addLine(y: Double, root: SKNode) {
        let node = SKShapeNode(rect: CGRect(x: 0, y: -y, width: 346, height: 1))
        node.fillColor = UIColor(white: 0.5, alpha: 0.65)
        node.strokeColor = .clear
        node.zPosition = 2
        root.addChild(node)
    }

    private func addVertical(x: Double, root: SKNode) {
        let node = SKShapeNode(rect: CGRect(x: x, y: -185, width: 1, height: 48))
        node.fillColor = UIColor(white: 0.55, alpha: 0.7)
        node.strokeColor = .clear
        node.zPosition = 2
        root.addChild(node)
    }

    private func addText(
        _ text: String,
        _ rect: NativeRect,
        _ size: CGFloat,
        _ root: SKNode,
        center: Bool = false,
        semibold: Bool = false,
        light: Bool = false,
        vertical: Bool = false
    ) {
        let label = SKLabelNode(fontNamed: semibold ? "PingFangSC-Semibold" : "PingFangSC-Regular")
        label.text = text
        label.fontSize = size
        label.fontColor = light
            ? UIColor(red: 238 / 255, green: 229 / 255, blue: 213 / 255, alpha: 1)
            : UIColor(white: 64 / 255, alpha: 1)
        label.horizontalAlignmentMode = center ? .center : .left
        label.verticalAlignmentMode = vertical ? .center : .top
        label.position = CGPoint(
            x: center ? rect.origin.x + rect.size.width / 2 : rect.origin.x,
            y: -(vertical ? rect.origin.y + rect.size.height / 2 : rect.origin.y)
        )
        label.zPosition = 6
        root.addChild(label)
    }

    private func imageNode(_ key: String) -> SKSpriteNode? {
        guard let entry = spriteManifest[key],
              let image = UIImage(contentsOfFile: store.spriteURL(manifestPath: entry.file).path)?.cgImage else {
            return nil
        }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func textureNode(_ folder: String, _ file: String) -> SKSpriteNode? {
        guard let image = UIImage(contentsOfFile: store.url(folder, file).path)?.cgImage else {
            return nil
        }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func place(_ node: SKSpriteNode, _ rect: NativeRect, _ z: CGFloat) {
        node.anchorPoint = CGPoint(x: 0, y: 1)
        node.position = CGPoint(x: rect.origin.x, y: -rect.origin.y)
        node.size = CGSize(width: rect.size.width, height: rect.size.height)
        node.zPosition = z
    }
}
#endif
