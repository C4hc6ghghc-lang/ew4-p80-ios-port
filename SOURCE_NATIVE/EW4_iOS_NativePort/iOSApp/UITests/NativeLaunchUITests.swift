import XCTest
import UIKit

final class NativeLaunchUITests: XCTestCase {
    @MainActor
    func testMainMenuAndModeNavigationRender() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        for (mode, logicalY) in [("campaign", 131.5), ("conquest", 169.5)] {
            app.launch()
            sleep(5)
            let main = try capture(app, name: "main-menu-\(mode)")
            let surface = app.otherElements["native.game.surface"]
            if surface.exists {
                XCTAssertEqual(surface.value as? String, "NativeOriginalMainMenuScene")
            }
            let frame = app.windows.firstMatch.frame
            XCTAssertGreaterThan(frame.width, frame.height, "Game must be landscape")
            let scale = min(frame.width / 568, frame.height / 320)
            let x = (frame.width - 568 * scale) / 2 + 502 * scale
            let y = (frame.height - 320 * scale) / 2 + logicalY * scale
            app.windows.firstMatch.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: x, dy: y)).tap()
            sleep(3)
            let modePixels = try capture(app, name: "\(mode)-selection")
            if surface.exists {
                XCTAssertEqual(surface.value as? String, "NativeOriginalOuterMenuScene")
            }
            let changed = zip(main, modePixels).filter { abs(Int($0) - Int($1)) > 24 }.count
            XCTAssertGreaterThan(Double(changed) / Double(main.count), 0.05,
                                 "Tapping \(mode) must visibly change the main menu")
            app.terminate()
        }
    }

    @MainActor
    private func capture(_ app: XCUIApplication, name: String) throws -> [UInt8] {
        XCTAssertEqual(app.state, .runningForeground)
        // Application-scoped captures can crop a rotated simulator's buffer.
        // Capture the physical screen, while separately asserting the app is active.
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        let image = try XCTUnwrap(screenshot.image.cgImage)
        var pixels = [UInt8](repeating: 0, count: 64 * 64 * 4)
        try pixels.withUnsafeMutableBytes { raw in
            let context = try XCTUnwrap(CGContext(data: raw.baseAddress, width: 64, height: 64,
                bitsPerComponent: 8, bytesPerRow: 256, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: 64, height: 64))
        }
        let lit = stride(from: 0, to: pixels.count, by: 4).filter {
            max(pixels[$0], max(pixels[$0 + 1], pixels[$0 + 2])) > 40
        }.count
        XCTAssertGreaterThan(Double(lit) / 4096, 0.40,
                             "\(name) is black or almost empty; process survival is insufficient")
        return pixels
    }
}
