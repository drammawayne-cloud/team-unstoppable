// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "TeamUnstoppableCore",
    products: [.library(name: "UnstoppableCore", targets: ["UnstoppableCore"])],
    targets: [
        .target(name: "UnstoppableCore", path: "TeamUnstoppable/Core"),
        .testTarget(name: "UnstoppableCoreTests", dependencies: ["UnstoppableCore"], path: "Tests")
    ]
)
