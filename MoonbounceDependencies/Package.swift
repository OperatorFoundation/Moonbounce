// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MoonbounceDependencies",
    platforms: [.macOS(.v11)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "MoonbounceDependencies",
            targets: ["MoonbounceDependencies"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.11"),
         .package(url: "https://github.com/OperatorFoundation/Shapeshifter-Swift-Transports", from: "2.3.23"),
         .package(url: "https://github.com/OperatorFoundation/Datable", from: "3.0.4"),
         .package(url: "https://github.com/OperatorFoundation/SwiftQueue.git", from: "0.0.3")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "MoonbounceDependencies",
            dependencies: ["ZIPFoundation", "Datable", .product(name: "Replicant", package: "Shapeshifter-Swift-Transports"), .product(name: "Flow", package: "Shapeshifter-Swift-Transports"), "SwiftQueue"]),
        .testTarget(
            name: "MoonbounceDependenciesTests",
            dependencies: ["MoonbounceDependencies"]),
    ],
    swiftLanguageVersions: [.v5]
)
