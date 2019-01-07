// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MoonbounceDependencies",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "MoonbounceDependencies",
            targets: ["MoonbounceDependencies"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.6"),
         .package(url: "https://github.com/OperatorFoundation/Shapeshifter-Swift-Transports", from: "0.3.10"),
         .package(url: "https://github.com/Bouke/INI", from: "1.2.0"),
         .package(url: "https://github.com/OperatorFoundation/Datable", from: "1.0.5"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "MoonbounceDependencies",
            dependencies: ["ZIPFoundation", "INI", "Datable", "Replicant"]),
        .testTarget(
            name: "MoonbounceDependenciesTests",
            dependencies: ["MoonbounceDependencies"]),
    ]
)
