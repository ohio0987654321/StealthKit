// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftBrowser",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "SwiftBrowser", targets: ["SwiftBrowser"])
    ],
    targets: [
        .executableTarget(
            name: "SwiftBrowser",
            dependencies: []
        )
    ]
)
