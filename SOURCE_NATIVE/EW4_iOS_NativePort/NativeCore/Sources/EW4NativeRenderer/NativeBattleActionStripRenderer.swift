#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

public enum NativeBattleActionID: String, CaseIterable, Sendable {
    case items
    case buyship
    case buildDefense
    case buildFortress
    case training
    case generals
    case generalInfo
    case info
    case trade
    case shop
    case bar
    case upgrade
    case city
    case factory
    case stable
    case dock

    var tutorialAlias: String {
        switch self {
        case .items: return "btn_item"
        case .buyship: return "btn_ship"
        case .buildDefense: return "btn_defense"
        case .buildFortress: return "btn_fortress"
        case .training: return "btn_training"
        case .generals: return "btn_general"
        case .generalInfo: return "btn_generalinfo"
        case .info: return "btn_info"
        case .trade: return "btn_trading"
        case .shop: return "btn_shop"
        case .bar: return "btn_bar"
        case .upgrade: return "btn_upgrade"
        case .city: return "btn_city"
        case .factory: return "btn_factory"
        case .stable: return "btn_stable"
        case .dock: return "btn_dock"
        }
    }

    var asset: (folder: String, file: String) {
        switch self {
        case .items: return ("image_recruit_hd3", "button_items.png")
        case .buyship: return ("image_recruit_hd", "button_buyship.png")
        case .buildDefense: return ("image_recruit_hd", "button_builddefense.png")
        case .buildFortress: return ("image_recruit_hd", "button_buildfortress.png")
        case .training: return ("image_recruit_hd3", "button_training.png")
        case .generals: return ("image_recruit_hd3", "button_generals.png")
        case .generalInfo: return ("image_recruit_hd", "button_info.png")
        case .info: return ("image_recruit_hd", "button_info.png")
        case .trade: return ("image_recruit_hd2", "button_trade.png")
        case .shop: return ("image_recruit_hd", "button_shop.png")
        case .bar: return ("image_recruit_hd2", "button_bar.png")
        case .upgrade: return ("image_recruit_hd", "button_buildupgrade.png")
        case .city: return ("image_recruit_hd", "button_city.png")
        case .factory: return ("image_recruit_hd3", "button_factory.png")
        case .stable: return ("image_recruit_hd3", "button_stable.png")
        case .dock: return ("image_recruit_hd3", "button_dock.png")
        }
    }
}

public struct NativeBattleActionButton: Equatable, Sendable {
    public let id: NativeBattleActionID
    public let enabled: Bool
    public init(_ id: NativeBattleActionID, enabled: Bool = true) { self.id = id; self.enabled = enabled }
}

@MainActor
final class NativeBattleActionStripRenderer {
    private weak var parent: SKNode?
    private let store: NativeResourceStore
    private var root: SKNode?
    private var rects: [NativeBattleActionID: NativeRect] = [:]
    private var enabled: [NativeBattleActionID: Bool] = [:]

    init(parent: SKNode, store: NativeResourceStore) {
        self.parent = parent
        self.store = store
    }

    func hide() {
        root?.removeFromParent()
        root = nil
        rects.removeAll()
        enabled.removeAll()
    }

    func rect(for alias: String) -> NativeRect? {
        rects.first(where: { $0.key.tutorialAlias == alias })?.value
    }

    func action(at point: NativePoint) -> NativeBattleActionID? {
        for (id, rect) in rects where enabled[id] == true && contains(rect, point) { return id }
        return nil
    }

    func show(_ buttons: [NativeBattleActionButton]) {
        hide()
        guard let parent, !buttons.isEmpty else { return }
        let root = SKNode()
        root.position = CGPoint(x: 0, y: EW4LogicalSpace.height)
        root.zPosition = 1_150
        let width = 32.0
        let height = 33.0
        let gap = 1.0
        let total = Double(buttons.count) * width + Double(max(0, buttons.count - 1)) * gap
        let startX = (EW4LogicalSpace.width - total) / 2.0
        let y = EW4LogicalSpace.height - height - 2.0
        for (index, button) in buttons.enumerated() {
            let x = startX + Double(index) * (width + gap)
            let rect = NativeRect(x: x, y: y, width: width, height: height)
            rects[button.id] = rect
            enabled[button.id] = button.enabled
            let asset = button.id.asset
            if let node = sprite(asset.folder, asset.file) {
                place(node, rect, z: 2)
                node.alpha = button.enabled ? 1.0 : 0.38
                root.addChild(node)
            } else {
                let fallback = SKShapeNode(rect: CGRect(x: x, y: -(y + height), width: width, height: height))
                fallback.fillColor = UIColor(white: 0.18, alpha: button.enabled ? 0.95 : 0.4)
                fallback.strokeColor = UIColor(white: 0.65, alpha: 0.8)
                fallback.lineWidth = 1
                fallback.zPosition = 1
                root.addChild(fallback)
            }
        }
        parent.addChild(root)
        self.root = root
    }

    private func sprite(_ folder: String, _ file: String) -> SKSpriteNode? {
        guard let image = UIImage(contentsOfFile: store.url("Sprites/\(folder)", file).path)?.cgImage else { return nil }
        return SKSpriteNode(texture: SKTexture(cgImage: image))
    }

    private func place(_ node: SKSpriteNode, _ rect: NativeRect, z: CGFloat) {
        node.anchorPoint = CGPoint(x: 0, y: 1)
        node.position = CGPoint(x: rect.origin.x, y: -rect.origin.y)
        node.size = CGSize(width: rect.size.width, height: rect.size.height)
        node.zPosition = z
    }

    private func contains(_ rect: NativeRect, _ point: NativePoint) -> Bool {
        point.x >= rect.origin.x && point.y >= rect.origin.y && point.x <= rect.origin.x + rect.size.width && point.y <= rect.origin.y + rect.size.height
    }
}
#endif
