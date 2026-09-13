import Foundation

public struct NativePoint: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}

public struct NativeSize: Equatable, Sendable {
    public var width: Double
    public var height: Double
    public init(width: Double, height: Double) { self.width = width; self.height = height }
}

public struct NativeRect: Equatable, Sendable {
    public var origin: NativePoint
    public var size: NativeSize
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.origin = .init(x: x, y: y)
        self.size = .init(width: width, height: height)
    }
    public func contains(_ point: NativePoint) -> Bool {
        point.x >= origin.x && point.x <= origin.x + size.width &&
        point.y >= origin.y && point.y <= origin.y + size.height
    }
}

public struct HexCell: Equatable, Hashable, Sendable {
    public var q: Int
    public var r: Int
    public init(q: Int, r: Int) { self.q = q; self.r = r }
}

public enum EW4LogicalSpace {
    public static let width = 568.0
    public static let height = 320.0
    public static let center = NativePoint(x: 284, y: 160)
}

public enum NativeHexGeometry {
    public static let geometryID = "native-odd-r-64x54-v1"
    public static let colStep = 64
    public static let rowStep = 54
    public static let halfWidth = 32
    public static let halfHeight = 36
    public static let centerYOffset = -18
    public static let cornerHeight = 18

    @inline(__always) private static func trunc(_ value: Double) -> Int { Int(value.rounded(.towardZero)) }
    @inline(__always) private static func truncDiv(_ a: Int, _ b: Int) -> Int { Int(Double(a) / Double(b)) }

    public static func cellCenter(_ cell: HexCell) -> NativePoint {
        NativePoint(
            x: Double(cell.q * colStep + ((cell.r & 1) != 0 ? halfWidth : 0)),
            y: Double(cell.r * rowStep + centerYOffset)
        )
    }

    public static func cellRect(_ cell: HexCell) -> NativeRect {
        let c = cellCenter(cell)
        return NativeRect(x: c.x - Double(halfWidth), y: c.y - Double(halfHeight), width: Double(colStep), height: Double(halfHeight * 2))
    }

    public static func worldToCell(x wx: Double, y wy: Double) -> HexCell {
        let ix = trunc(wx + Double(halfWidth))
        let iy = trunc(wy + Double(rowStep))
        var r = truncDiv(iy, rowStep)
        var q: Int
        let baseX: Int
        if (r & 1) != 0 {
            q = truncDiv(ix - halfWidth, colStep)
            baseX = q * colStep + halfWidth
        } else {
            q = truncDiv(ix, colStep)
            baseX = q * colStep
        }
        let dy = iy - r * rowStep
        if dy < cornerHeight {
            let hx = ix - baseX
            let threshold = colStep * (cornerHeight - dy)
            if hx < halfWidth {
                if 36 * hx < threshold {
                    if (r & 1) == 0 { q -= 1 }
                    r -= 1
                }
            } else if 36 * (colStep - hx) < threshold {
                if (r & 1) != 0 { q += 1 }
                r -= 1
            }
        }
        return HexCell(q: q, r: r)
    }

    public static func battlePixelOrigin(originX: Int, originY: Int) -> NativePoint {
        NativePoint(
            x: Double(originX * colStep - ((originY & 1) != 0 ? 0 : halfWidth)),
            y: Double((originY - 1) * rowStep)
        )
    }

    public static func neighbors(of c: HexCell) -> [HexCell] {
        let q = c.q, r = c.r
        let pairs: [(Int, Int)] = (r & 1) != 0
            ? [(q+1,r),(q+1,r+1),(q,r+1),(q-1,r),(q,r-1),(q+1,r-1)]
            : [(q+1,r),(q,r+1),(q-1,r+1),(q-1,r),(q-1,r-1),(q,r-1)]
        return pairs.map { HexCell(q: $0.0, r: $0.1) }
    }

    private static func oddrCube(_ c: HexCell) -> (Int, Int, Int) {
        let x = c.q - (c.r - (c.r & 1)) / 2
        let z = c.r
        let y = -x - z
        return (x, y, z)
    }

    public static func distance(_ a: HexCell, _ b: HexCell) -> Int {
        let A = oddrCube(a), B = oddrCube(b)
        return max(abs(A.0-B.0), abs(A.1-B.1), abs(A.2-B.2))
    }
}
