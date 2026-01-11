// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MCP-FingerString",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v1),
    ],
    products: [
        .executable(
            name: "mcp-fingerstring",
            targets: ["MCPServer"]
        ),
    ],
    dependencies: [
        // MCP Swift SDK
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.10.0"),
        // Swift Service Lifecycle for graceful shutdown
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.3.0"),
        // Swift Logging
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.6.2"),
        .package(url: "https://github.com/mredig/SwiftPizzaSnips.git", from: "0.5.0"),
        .package(url: "https://github.com/mredig/FingerString.git", from: "0.0.5"),
    ],
    targets: [
		.target(
			name: "MCPServerLib",
			dependencies: [
				.product(name: "MCP", package: "swift-sdk"),
				"SwiftPizzaSnips",
				.product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
				.product(name: "Logging", package: "swift-log"),
				.product(name: "FingerStringLib", package: "FingerString"),
			],
			swiftSettings: [
				.enableUpcomingFeature("StrictConcurrency")
			]
		),
        .executableTarget(
            name: "MCPServer",
            dependencies: [
				"MCPServerLib",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/MCPServer",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "MCPServerTests",
            dependencies: [
				.targetItem(name: "MCPServerLib", condition: nil),
                .product(name: "MCP", package: "swift-sdk"),
            ],
            path: "Tests/MCPServerTests"
        ),
    ]
)
