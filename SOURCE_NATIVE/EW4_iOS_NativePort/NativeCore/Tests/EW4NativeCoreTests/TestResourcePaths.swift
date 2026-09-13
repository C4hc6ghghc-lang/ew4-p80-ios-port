import Foundation

enum TestResourcePaths {
    static var projectRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // EW4NativeCoreTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // NativeCore
            .deletingLastPathComponent() // EW4_iOS_NativePort
    }

    static var resources: URL {
        projectRoot.appendingPathComponent("Resources", isDirectory: true)
    }

    static func data(_ name: String) -> URL {
        resources.appendingPathComponent("Data", isDirectory: true).appendingPathComponent(name)
    }
}
