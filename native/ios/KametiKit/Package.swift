// swift-tools-version: 6.2
import PackageDescription

// KametiKit holds all of the native iOS app's code except the thin app
// target. Layers depend inward only:
//
//   Features -> KametiUI, KametiDomain          (never KametiData)
//   KametiData -> KametiDomain, KametiCore      (supabase-swift lives here)
//   KametiDomain -> KametiCore                  (models + repository protocols)
//
// The app target is the one place that wires KametiData into the features.
let package = Package(
    name: "KametiKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "KametiCore", targets: ["KametiCore"]),
        .library(name: "KametiDomain", targets: ["KametiDomain"]),
        .library(name: "KametiUI", targets: ["KametiUI"]),
    ],
    targets: [
        .target(name: "KametiCore"),
        .target(name: "KametiDomain", dependencies: ["KametiCore"]),
        // Design system: tokens are generated from native/design-tokens/tokens.json.
        .target(
            name: "KametiUI",
            dependencies: ["KametiCore"],
            resources: [.process("Resources")]
        ),
        .testTarget(name: "KametiCoreTests", dependencies: ["KametiCore"]),
        .testTarget(name: "KametiUITests", dependencies: ["KametiUI", "KametiCore"]),
        .testTarget(
            name: "KametiDomainTests",
            dependencies: ["KametiDomain", "KametiCore"]
        ),
    ]
)
