// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Headroom",
    platforms: [
        .iOS(.v13),
        // Headroom is an iOS library, but the test suite runs on macOS via `swift test`.
        // Swift Testing's @Test macro requires a macOS 10.15+ deployment target.
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "Headroom",
            targets: ["Headroom"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/devicekit/DeviceKit.git", from: "5.8.0"),
    ],
    targets: [
        .target(
            name: "Headroom",
            dependencies: [
                .product(name: "DeviceKit", package: "DeviceKit"),
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        ),
        .testTarget(
            name: "HeadroomTests",
            dependencies: ["Headroom"]
        ),
    ]
)
