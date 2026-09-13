#if canImport(SpriteKit) && canImport(UIKit)
import SpriteKit
import UIKit
import EW4NativeCore

public struct BILERasterizedFrame {
    public let texture: SKTexture
    public let bounds: NativeRect
}

public final class BILEFrameRasterizer {
    public init() {}

    // UIKit's renderer uses a top-left/Y-down drawing space, matching recovered BILE coordinates.
    public func frame(bile: CompactBILE, itemIndex: Int, frame: Int, atlas: CGImage) throws -> BILERasterizedFrame {
        let primitives = try bile.flatten(itemIndex: itemIndex, frame: frame)
        let bounds = try bile.frameBounds(itemIndex: itemIndex, frame: frame)
        let size = CGSize(width: max(1, ceil(bounds.size.width)), height: max(1, ceil(bounds.size.height)))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            let cg = context.cgContext
            cg.translateBy(x: CGFloat(-bounds.origin.x), y: CGFloat(-bounds.origin.y))
            for primitive in primitives {
                let r = primitive.image
                let cropRect = CGRect(x: r.x, y: r.y, width: r.w, height: r.h).integral
                guard let crop = atlas.cropping(to: cropRect) else { continue }
                let m = primitive.transform
                cg.saveGState()
                cg.setAlpha(CGFloat(primitive.alpha))
                cg.concatenate(CGAffineTransform(a: m.a, b: m.b, c: m.c, d: m.d, tx: m.tx, ty: m.ty))
                UIImage(cgImage: crop).draw(in: CGRect(x: 0, y: 0, width: r.w, height: r.h))
                cg.restoreGState()
            }
        }
        guard let cgImage = image.cgImage else { throw CocoaError(.coderInvalidValue) }
        return BILERasterizedFrame(texture: SKTexture(cgImage: cgImage), bounds: bounds)
    }
}
#endif
