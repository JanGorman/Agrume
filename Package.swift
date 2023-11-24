// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Agrume",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "Agrume",
            targets: ["Agrume"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/kirualex/SwiftyGif", .upToNextMajor(from: "5.4.0"))
    ],
    targets: [
        .target(
            name: "Agrume",
            dependencies: ["SwiftyGif"],
            path: "./Agrume"
        )
    ]
)
