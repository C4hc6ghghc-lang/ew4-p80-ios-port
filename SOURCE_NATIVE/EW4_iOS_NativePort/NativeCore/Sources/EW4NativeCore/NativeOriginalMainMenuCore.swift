import Foundation

public enum NativeOriginalMainMenuAction: Int, Equatable, Sendable {
    case campaign = 0
    case conquest = 1
    case tutorial = 2
    case headquarters = 3
    case options = 4
}

/// Frozen 568x320 main-menu geometry from the mature P39/original shell.
public enum NativeOriginalMainMenuCore {
    public static let title = NativeRect(x: 20, y: 15, width: 380, height: 96)
    public static let buttons: [NativeRect] = [
        NativeRect(x: 435, y: 115, width: 134, height: 33),
        NativeRect(x: 435, y: 153, width: 134, height: 33),
        NativeRect(x: 435, y: 191, width: 134, height: 33),
        NativeRect(x: 435, y: 229, width: 134, height: 33),
        NativeRect(x: 435, y: 267, width: 134, height: 33),
    ]
    public static let labels = ["战　役", "征　服", "教　程", "指挥部", "设　定"]
    public static let homepage = NativeRect(x: 0, y: 287, width: 33, height: 33)
    public static let achievement = NativeRect(x: 35, y: 287, width: 33, height: 33)
    public static let email = NativeRect(x: 70, y: 287, width: 33, height: 33)

    public static func action(at point: NativePoint) -> NativeOriginalMainMenuAction? {
        for (index, rect) in buttons.enumerated() where contains(rect, point) {
            return NativeOriginalMainMenuAction(rawValue: index)
        }
        return nil
    }

    public static func achievementHit(at point: NativePoint) -> Bool { contains(achievement, point) }

    private static func contains(_ rect: NativeRect, _ point: NativePoint) -> Bool {
        point.x >= rect.origin.x && point.x <= rect.origin.x + rect.size.width &&
        point.y >= rect.origin.y && point.y <= rect.origin.y + rect.size.height
    }
}
