// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "keyboard-clean",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "keyboard-clean", targets: ["keyboard-clean"])
    ],
    targets: [
        .executableTarget(
            name: "keyboard-clean",
            linkerSettings: [
                .linkedFramework("ApplicationServices")
            ]
        )
    ]
)
