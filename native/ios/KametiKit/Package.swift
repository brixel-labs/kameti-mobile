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
        .library(name: "KametiData", targets: ["KametiData"]),
    ],
    dependencies: [
        // Official Supabase SDK: auth, PostgREST, RPC and edge functions.
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.55.0"),
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
        // Supabase-backed implementations of the repository protocols. Only
        // the app target links this; features depend on KametiDomain.
        .target(
            name: "KametiData",
            dependencies: [
                "KametiCore", "KametiDomain",
                .product(name: "Supabase", package: "supabase-swift"),
            ]
        ),
        .testTarget(name: "KametiCoreTests", dependencies: ["KametiCore"]),
        .testTarget(
            name: "KametiDataTests",
            dependencies: [
                "KametiData", "KametiDomain", "KametiCore",
                .product(name: "Supabase", package: "supabase-swift"),
            ]
        ),
        .testTarget(name: "KametiUITests", dependencies: ["KametiUI", "KametiCore"]),
        .testTarget(
            name: "KametiDomainTests",
            dependencies: ["KametiDomain", "KametiCore"]
        ),
    ]
)
