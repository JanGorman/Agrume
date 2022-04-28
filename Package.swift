// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Agrume",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "Agrume", targets: ["Agrume"])
    ],
    dependencies: [
        .package(url: "https://github.com/SDWebImage/SDWebImageWebPCoder", .upToNextMajor(from: "0.8.4"))
    ],
    targets: [
        .target(name: "Agrume", dependencies: ["SDWebImageWebPCoder"], path: "./Agrume")
    ]
)
