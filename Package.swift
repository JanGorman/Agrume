// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Agrume",
    platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(name: "Agrume", targets: ["Agrume"])
    ],
    dependencies: [
        .package(url: "https://github.com/kirualex/SwiftyGif", .upToNextMajor(from: "5.0.0"))
    ],
    targets: [
        .target(name: "Agrume", dependencies: ["SwiftyGif"], path: "./Agrume")
    ]
)
