// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EmergencyReady",
    platforms: [.iOS(.v16)],
    dependencies: [
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            from: "11.0.0"
        )
    ],
    targets: [
        .target(
            name: "EmergencyReady",
            dependencies: [
                .product(name: "FirebaseAuth",      package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ],
            path: "EmergencyReady",
            exclude: ["Info.plist", "SETUP.md", "VIVA_NOTES.md", "Firebase"],
            resources: [
                .process("Resources/EmergencyData.json"),
                .process("Assets.xcassets")
            ]
        )
    ]
)
