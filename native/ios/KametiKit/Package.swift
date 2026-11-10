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
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "KametiCore", targets: ["KametiCore"]),
        .library(name: "KametiDomain", targets: ["KametiDomain"]),
    ],
    targets: [
        .target(name: "KametiCore"),
        .target(name: "KametiDomain", dependencies: ["KametiCore"]),
        .testTarget(name: "KametiCoreTests", dependencies: ["KametiCore"]),
        .testTarget(
            name: "KametiDomainTests",
            dependencies: ["KametiDomain", "KametiCore"]
        ),
    ]
)
