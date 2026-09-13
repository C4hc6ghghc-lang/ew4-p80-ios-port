import Foundation

public enum NativeOriginalPlayNoticeCore {
    public static let rowSpacing = 20.0
    public static let viewportHeight = 186.0
    public static let scrollbarWidth = 4.0

    public static func lines(from html: String) -> [String] {
        html
            .replacingOccurrences(of: "<br />", with: "\n")
            .replacingOccurrences(of: "<br/>", with: "\n")
            .replacingOccurrences(of: "<br>", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)
    }

    public static func contentHeight(lineCount: Int) -> Double {
        Double(max(0, lineCount)) * rowSpacing
    }

    public static func maxScroll(lineCount: Int) -> Double {
        max(0, contentHeight(lineCount: lineCount) - viewportHeight)
    }

    public static func clampedScroll(_ value: Double, lineCount: Int) -> Double {
        min(max(0, value), maxScroll(lineCount: lineCount))
    }

    public static func thumbHeight(lineCount: Int) -> Double {
        let content = contentHeight(lineCount: lineCount)
        guard content > viewportHeight else { return viewportHeight }
        return max(12, viewportHeight * viewportHeight / content)
    }

    public static func thumbOffset(scroll: Double, lineCount: Int) -> Double {
        let maxS = maxScroll(lineCount: lineCount)
        guard maxS > 0 else { return 0 }
        let travel = viewportHeight - thumbHeight(lineCount: lineCount)
        return travel * clampedScroll(scroll, lineCount: lineCount) / maxS
    }
}
