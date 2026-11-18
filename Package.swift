// swift-tools-version: 5.9
import PackageDescription

var products: [Product] = [
    .library(name: "LiveryCore", targets: ["LiveryCore"]),
]

var targets: [Target] = [
    .target(name: "LiveryCore"),
    .testTarget(name: "LiveryCoreTests", dependencies: ["LiveryCore"]),
]

#if os(macOS)
products.append(.library(name: "LiveryKit", targets: ["LiveryKit"]))
targets.append(.target(name: "LiveryKit", dependencies: ["LiveryCore"]))
targets.append(.testTarget(name: "LiveryKitTests", dependencies: ["LiveryKit"]))
#endif

let package = Package(
    name: "Livery",
    platforms: [.macOS(.v13)],
    products: products,
    targets: targets
)
