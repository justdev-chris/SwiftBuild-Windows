// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .executable(
            name: "MyApp",
            targets: ["MyApp"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MyApp", 
            dependencies: [],
            path: "Sources",
            resources: [
                .process("Resources")  // Points to App/Resources
            ]
        )
    ]
)
