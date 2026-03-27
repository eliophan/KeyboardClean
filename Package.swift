// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "cleaning-keyboard",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "cleaning-keyboard", targets: ["cleaning-keyboard"])
    ],
    targets: [
        .executableTarget(
            name: "cleaning-keyboard",
            linkerSettings: [
                .linkedFramework("ApplicationServices")
            ]
        )
    ]
)
