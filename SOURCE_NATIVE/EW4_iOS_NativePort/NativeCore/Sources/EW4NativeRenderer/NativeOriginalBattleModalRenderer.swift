#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

final class NativeOriginalBattleModalRenderer {
    private weak var parent: SKNode?
    private let store: NativeResourceStore
    private let spriteManifest: [String: SpriteManifestEntry]
    private let strings: [String: String]
    private var root: SKNode?

    init(parent: SKNode, store: NativeResourceStore, spriteManifest: [String: SpriteManifestEntry]) {
        self.parent = parent; self.store = store; self.spriteManifest = spriteManifest; self.strings = (try? store.stringsCN()) ?? [:]
    }

    func hide() { root?.removeFromParent(); root = nil }

    func showPause(round: Int) {
        hide(); guard let parent else { return }
        let screen = NativeOriginalFormGeometryCore.Pause.screenFrame
        let root = modalRoot(screen: screen, title: strings["title_pause"] ?? "暂 停", closeRect: NativeOriginalFormGeometryCore.Pause.closeButton)
        for (x, flip) in [(23.0, false), (142.0, true)] {
            if let deco = imageNode("pattern_save.png") {
                deco.anchorPoint = CGPoint(x: 0, y: 1); deco.position = CGPoint(x: x, y: -40); deco.size = CGSize(width: 25, height: 8)
                deco.xScale = flip ? -1 : 1; deco.zPosition = 4; root.addChild(deco)
            }
        }
        addText(strings["text_round_word"] ?? "回合", x: 50, y: 35, size: 9, root: root)
        addText(String(round), x: 102.5, y: 36, size: 9, align: .center, root: root)
        for y in NativeOriginalFormGeometryCore.Pause.separatorY { addImage("common_line_hor.png", rect: NativeRect(x: 20, y: y, width: 126, height: 1), root: root, z: 3) }
        addButton(strings["btn_save"] ?? "保存", rect: NativeOriginalFormGeometryCore.Pause.saveButton, root: root)
        addButton(strings["btn_option"] ?? "设定", rect: NativeOriginalFormGeometryCore.Pause.optionButton, root: root)
        addButton(strings["btn_restart"] ?? "重新开始", rect: NativeOriginalFormGeometryCore.Pause.restartButton, root: root)
        addButton(strings["btn_exit"] ?? "退出", rect: NativeOriginalFormGeometryCore.Pause.exitButton, root: root)
        addImage("pattern_reoganizion.png", rect: NativeRect(x: 44.5, y: 249, width: 77, height: 23), root: root, z: 4, flipY: true)
        parent.addChild(root); self.root = root
    }

    func showRoundTurn(_ content: NativeRoundTurnContent) {
        hide(); guard let parent else { return }
        let screen = NativeOriginalFormGeometryCore.RoundTurn.screenFrame
        let root = modalRoot(screen: screen, title: strings["title_roundturn"] ?? "你的回合", closeRect: NativeOriginalFormGeometryCore.RoundTurn.closeButton)

        for rect in NativeOriginalFormGeometryCore.RoundTurn.verticalLines {
            addImage("common_line_ver.png", rect: rect, root: root, z: 3)
        }
        for rect in NativeOriginalFormGeometryCore.RoundTurn.horizontalLines {
            addImage("common_line_hor.png", rect: rect, root: root, z: 3)
        }
        addImage("common_line_hor.png", rect: NativeRect(x: 4, y: 45, width: 100, height: 1), root: root, z: 3)
        addImage("common_line_hor.png", rect: NativeRect(x: 111, y: 45, width: 97, height: 1), root: root, z: 3)
        addImage("common_line_hor.png", rect: NativeRect(x: 217, y: 45, width: 100, height: 1), root: root, z: 3)

        addText(strings["text_economy"] ?? "经济", x: 54, y: 30, size: 8, align: .center, root: root)
        addText(strings["text_round"] ?? "回合", x: 159.5, y: 30, size: 8, align: .center, root: root)
        addText(strings["text_foodsuply"] ?? "食物补给", x: 267, y: 30, size: 8, align: .center, root: root)

        addImage("marker_money.png", rect: NativeOriginalFormGeometryCore.RoundTurn.moneyIcon, root: root, z: 4)
        addText(String(content.money), x: NativeOriginalFormGeometryCore.RoundTurn.moneyValue.x, y: NativeOriginalFormGeometryCore.RoundTurn.moneyValue.y, size: 8, root: root)
        addImage("marker_industry.png", rect: NativeOriginalFormGeometryCore.RoundTurn.industryIcon, root: root, z: 4)
        addText(String(content.industry), x: NativeOriginalFormGeometryCore.RoundTurn.industryValue.x, y: NativeOriginalFormGeometryCore.RoundTurn.industryValue.y, size: 8, root: root)

        addText(String(content.round), x: 136, y: 55, size: 14, align: .center, root: root)
        addImage("star_board.png", rect: NativeOriginalFormGeometryCore.RoundTurn.starBoard, root: root, z: 4)
        addText(String(content.bestRound), x: NativeOriginalFormGeometryCore.RoundTurn.bestValue.x, y: NativeOriginalFormGeometryCore.RoundTurn.bestValue.y, size: 8, root: root)
        addText(String(content.winRound), x: NativeOriginalFormGeometryCore.RoundTurn.winValue.x, y: NativeOriginalFormGeometryCore.RoundTurn.winValue.y, size: 8, root: root)

        addImage("food_add.png", rect: NativeOriginalFormGeometryCore.RoundTurn.foodAddIcon, root: root, z: 4)
        addText(String(content.foodAdd), x: NativeOriginalFormGeometryCore.RoundTurn.foodAddValue.x, y: NativeOriginalFormGeometryCore.RoundTurn.foodAddValue.y, size: 8, root: root)
        addImage("food_reduce.png", rect: NativeOriginalFormGeometryCore.RoundTurn.foodDelIcon, root: root, z: 4)
        addText(String(content.foodDel), x: NativeOriginalFormGeometryCore.RoundTurn.foodDelValue.x, y: NativeOriginalFormGeometryCore.RoundTurn.foodDelValue.y, size: 8, root: root)

        if content.generals.isEmpty {
            addText("本回合无参战将领", x: 160, y: 130, size: 7, align: .center, root: root, color: UIColor(red: 118/255, green: 107/255, blue: 89/255, alpha: 1))
        } else {
            for (index, general) in content.generals.enumerated() {
                let x = 11.0 + Double(index) * 49.0
                if let portrait = portraitNode(commanderName: general.name) {
                    portrait.anchorPoint = CGPoint(x: 0, y: 1)
                    portrait.position = CGPoint(x: x + 2.5, y: -107)
                    portrait.size = CGSize(width: 40, height: 40)
                    portrait.zPosition = 4
                    root.addChild(portrait)
                }
                addText(general.name, x: x + 22.5, y: 149, size: 6, align: .center, root: root)
            }
        }

        parent.addChild(root); self.root = root
    }

    func showSave(mode: NativeSavePanelMode, slots: [NativeSaveSlotDisplay]) {
        hide(); guard let parent else { return }
        let screen = NativeOriginalFormGeometryCore.Save.screenFrame
        let title = mode == .save ? (strings["title_savegame"] ?? "保存游戏") : (strings["title_loadgame"] ?? "载入游戏")
        let root = modalRoot(screen: screen, title: title, closeRect: NativeOriginalFormGeometryCore.Save.closeButton)
        addText(strings["text_autosave"] ?? "自动保存", x: 176, y: 26, size: 8, align: .center, root: root, color: UIColor(red: 102/255, green: 91/255, blue: 73/255, alpha: 1))
        let bySlot = Dictionary(uniqueKeysWithValues: slots.map { ($0.slot, $0) })
        drawSaveSlot(bySlot[.autosave] ?? NativeSaveSlotDisplay(slot: .autosave), rect: NativeOriginalFormGeometryCore.Save.autosaveSlot, mode: mode, autosave: true, root: root)
        for (i, rect) in NativeOriginalFormGeometryCore.Save.manualSlots.enumerated() {
            let slot = NativeBattleSaveSlot.manual(i + 1)
            drawSaveSlot(bySlot[slot] ?? NativeSaveSlotDisplay(slot: slot), rect: rect, mode: mode, autosave: false, root: root)
        }
        parent.addChild(root); self.root = root
    }

    private func drawSaveSlot(_ display: NativeSaveSlotDisplay, rect: NativeRect, mode: NativeSavePanelMode, autosave: Bool, root: SKNode) {
        let fill = SKShapeNode(rect: CGRect(x: rect.origin.x, y: -(rect.origin.y + rect.size.height), width: rect.size.width, height: rect.size.height))
        fill.fillColor = autosave ? UIColor(red: 216/255, green: 208/255, blue: 190/255, alpha: 1) : UIColor(red: 227/255, green: 216/255, blue: 191/255, alpha: 1)
        fill.strokeColor = UIColor(red: 123/255, green: 107/255, blue: 78/255, alpha: 1); fill.lineWidth = 1; fill.zPosition = 2; root.addChild(fill)
        addImage("general_nameboard.png", rect: NativeRect(x: rect.origin.x, y: rect.origin.y, width: 114, height: 23), root: root, z: 3)
        addText(display.empty ? (strings["text_empty"] ?? "无") : display.title, x: rect.origin.x + 57, y: rect.origin.y + 2, size: 8, align: .center, root: root, color: UIColor(red: 238/255, green: 231/255, blue: 215/255, alpha: 1))
        if !display.empty {
            let date = Self.dateString(display.savedAt)
            addText(date, x: rect.origin.x + 4, y: rect.origin.y + (autosave ? 30 : 25), size: 6.5, root: root)
            if !display.countryCode.isEmpty, let entry = spriteManifest[display.countryCode + "1.png"] {
                let w = min(51.0, entry.w), h = min(30.0, entry.h)
                addImage(display.countryCode + "1.png", rect: NativeRect(x: rect.origin.x + (114 - w)/2, y: rect.origin.y + (autosave ? 53 : 47), width: w, height: h), root: root, z: 4)
            }
        }
        let actionVisible = mode == .save ? !autosave : !display.empty
        if actionVisible {
            let local = autosave ? NativeOriginalFormGeometryCore.Save.autosaveOK : NativeOriginalFormGeometryCore.Save.manualOK
            addImage("button_ok_gray_noshadow.png", rect: NativeRect(x: rect.origin.x + local.origin.x, y: rect.origin.y + local.origin.y, width: 30, height: 30), root: root, z: 5)
        }
    }

    private func modalRoot(screen: NativeRect, title: String, closeRect: NativeRect) -> SKNode {
        let root = SKNode(); root.position = CGPoint(x: screen.origin.x, y: EW4LogicalSpace.height - screen.origin.y); root.zPosition = 22_000
        let shade = SKShapeNode(rect: CGRect(x: -screen.origin.x, y: -(EW4LogicalSpace.height - screen.origin.y), width: EW4LogicalSpace.width, height: EW4LogicalSpace.height))
        shade.fillColor = UIColor(white: 0, alpha: 0.53); shade.strokeColor = .clear; shade.zPosition = -2; root.addChild(shade)
        let panel = SKShapeNode(rect: CGRect(x: 0, y: -screen.size.height, width: screen.size.width, height: screen.size.height))
        panel.fillColor = UIColor(red: 238/255, green: 230/255, blue: 212/255, alpha: 1); panel.strokeColor = UIColor(red: 110/255, green: 98/255, blue: 79/255, alpha: 1); panel.lineWidth = 2; panel.zPosition = 0; root.addChild(panel)
        addText(title, x: screen.size.width / 2, y: 4, size: 12, align: .center, root: root, color: UIColor(red: 75/255, green: 68/255, blue: 56/255, alpha: 1))
        addImage("button_close.png", rect: closeRect, root: root, z: 8)
        return root
    }

    private func addButton(_ text: String, rect: NativeRect, root: SKNode) {
        addImage("btn_common_blue.png", rect: rect, root: root, z: 3)
        let label = SKLabelNode(fontNamed: "PingFangSC-Semibold"); label.text = text; label.fontSize = 10; label.fontColor = UIColor(red: 247/255, green: 241/255, blue: 225/255, alpha: 1); label.horizontalAlignmentMode = .center; label.verticalAlignmentMode = .center; label.position = CGPoint(x: rect.origin.x + rect.size.width/2, y: -(rect.origin.y + rect.size.height/2)); label.zPosition = 4; root.addChild(label)
    }

    private func addText(_ text: String, x: Double, y: Double, size: CGFloat, align: SKLabelHorizontalAlignmentMode = .left, root: SKNode, color: UIColor = UIColor(white: 64/255, alpha: 1)) {
        let label = SKLabelNode(fontNamed: "PingFangSC-Regular"); label.text = text; label.fontSize = size; label.fontColor = color; label.horizontalAlignmentMode = align; label.verticalAlignmentMode = .top; label.position = CGPoint(x: x, y: -y); label.zPosition = 5; root.addChild(label)
    }

    private func addImage(_ key: String, rect: NativeRect, root: SKNode, z: CGFloat, flipY: Bool = false) {
        guard let node = imageNode(key) else { return }; node.anchorPoint = CGPoint(x: 0, y: 1); node.position = CGPoint(x: rect.origin.x, y: -rect.origin.y); node.size = CGSize(width: rect.size.width, height: rect.size.height); node.zPosition = z; if flipY { node.yScale = -1 }; root.addChild(node)
    }

    private func imageNode(_ key: String) -> SKSpriteNode? {
        guard let entry = spriteManifest[key] else { return nil }; let url = store.spriteURL(manifestPath: entry.file); guard let image = UIImage(contentsOfFile: url.path)?.cgImage else { return nil }; return SKSpriteNode(texture: SKTexture(cgImage: image))
    }


    private func portraitNode(commanderName: String) -> SKSpriteNode? {
        guard !commanderName.isEmpty else { return nil }
        let url = store.url("Portraits", commanderName + ".webp")
        guard let image = UIImage(contentsOfFile: url.path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private static func dateString(_ milliseconds: Int64) -> String {
        guard milliseconds > 0 else { return "" }
        let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN"); f.dateFormat = "MM/dd HH:mm"
        return f.string(from: Date(timeIntervalSince1970: Double(milliseconds) / 1000))
    }
}
#endif
