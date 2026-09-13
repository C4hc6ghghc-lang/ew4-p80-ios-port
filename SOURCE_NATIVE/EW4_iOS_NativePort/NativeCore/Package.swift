// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EW4NativeCore",
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(name: "EW4NativeCore", targets: ["EW4NativeCore"]),
        .library(name: "EW4NativeRenderer", targets: ["EW4NativeRenderer"]),
        .executable(name: "EW4NativeAudit", targets: ["EW4NativeAudit"])
    ],
    targets: [
        .target(name: "EW4NativeCore"),
        .target(name: "EW4NativeRenderer", dependencies: ["EW4NativeCore"]),
        .executableTarget(name: "EW4NativeAudit", dependencies: ["EW4NativeCore"]),
        .testTarget(name: "EW4NativeCoreTests", dependencies: ["EW4NativeCore"])
    ]
)
