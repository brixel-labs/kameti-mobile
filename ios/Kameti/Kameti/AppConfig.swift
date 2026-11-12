import Foundation

/// Backend settings from `KametiConfig.json`, a copy of `env/<flavor>.json`
/// (`ios/scripts/use-env.sh dev|prod`). The file is gitignored; only
/// public values live in it (the Supabase publishable key is public by design).
struct AppConfig: Decodable {
    let flavor: String?
    let supabaseURL: URL
    let supabasePublishableKey: String
    let googleWebClientID: String?
    let googleIOSClientID: String?

    enum CodingKeys: String, CodingKey {
        case flavor = "FLAVOR"
        case supabaseURL = "SUPABASE_URL"
        case supabasePublishableKey = "SUPABASE_PUBLISHABLE_KEY"
        case googleWebClientID = "GOOGLE_WEB_CLIENT_ID"
        case googleIOSClientID = "GOOGLE_IOS_CLIENT_ID"
    }

    /// The demo build runs on sample data and is always signed in. Debug builds
    /// only: a release build never runs on sample data.
    var isDemo: Bool { Self.isDebugBuild && flavor == "demo" }

    /// The dev build shows the seeded test-account buttons (local Supabase only).
    /// Debug builds only, and only when the config says so explicitly.
    var isDev: Bool { Self.isDebugBuild && flavor == "dev" }

    static var isDebugBuild: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    /// `nil` when the file is missing or unreadable.
    static func load(from bundle: Bundle = .main) -> AppConfig? {
        guard let url = bundle.url(forResource: "KametiConfig", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        guard let config = try? JSONDecoder().decode(AppConfig.self, from: data) else { return nil }
        // A release build must point at a real backend: a demo or local config
        // (left over from development) shows the "configuration missing" screen
        // instead of a broken app.
        if !isDebugBuild, config.flavor == "demo" || ["localhost", "127.0.0.1"].contains(config.supabaseURL.host() ?? "") {
            return nil
        }
        return config
    }
}
