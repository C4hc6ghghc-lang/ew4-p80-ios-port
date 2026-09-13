import Foundation
import Testing
@testable import EW4NativeCore

struct NativeTutorialCoreTests {
    @Test func recoveredTutorialScriptsRemainExactAndRunnableThroughWaitStates() throws {
        let data = try Data(contentsOf: TestResourcePaths.data("native_tutorial_scripts.json"))
        let catalog = try JSONDecoder().decode(NativeTutorialCatalog.self, from: data)
        #expect(catalog.mapWidth == 79)
        #expect(catalog.scripts["tutorials1.btl"]?.commandCount == 138)
        #expect(catalog.scripts["tutorials2.btl"]?.commandCount == 135)
        #expect(catalog.scripts.values.reduce(0) { $0 + $1.commands.count } == 273)
        #expect(catalog.scripts["tutorials1.btl"]?.sha256 == "a158053ac7b61d07aa4b1f8f15fbcd7568a130e4b7f5a9dc4876891e60ad6d41")
        #expect(catalog.scripts["tutorials2.btl"]?.sha256 == "9b8e568b68c045b3e83ee71d43e6f84ffd6dc8b8f2794c63e6974741c15141fc")

        var runner = NativeTutorialRunner(commands: catalog.scripts["tutorials1.btl"]!.commands, mapWidth: catalog.mapWidth)
        let initial = runner.start()
        #expect(initial.contains(.seed(100)))
        #expect(initial.contains(.showText(1)))
        #expect(runner.wait == .touch)
        let second = runner.notifyTouch()
        #expect(second.contains(.showText(2)))
        #expect(runner.wait == .touch)
    }

    @Test func areaMathAndRowSensitiveUIWaitMatchMatureController() {
        let commands = [
            NativeTutorialCommand(name: "wait area", id: 2783, x: nil, y: nil, w: nil, h: nil, row: nil, string: nil),
            NativeTutorialCommand(name: "wait ui", id: nil, x: nil, y: nil, w: nil, h: nil, row: 2, string: "lbox_unit"),
            NativeTutorialCommand(name: "exit", id: nil, x: nil, y: nil, w: nil, h: nil, row: nil, string: nil),
        ]
        var runner = NativeTutorialRunner(commands: commands)
        _ = runner.start()
        #expect(runner.areaCell(2783) == HexCell(q: 18, r: 35))
        #expect(runner.notifyArea(q: 18, r: 35).isEmpty)
        #expect(runner.wait == .ui(name: "lbox_unit", row: 2))
        #expect(runner.notifyUI("lbox_unit", row: 1).isEmpty)
        #expect(runner.notifyUI("lbox_unit", row: 2) == [.exit])
        #expect(runner.done)
    }
}
