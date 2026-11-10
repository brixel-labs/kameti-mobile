import Foundation

/// Backend settings from `KametiConfig.json`, a copy of the Flutter env file
/// (`native/ios/scripts/use-env.sh dev|prod`). The file is gitignored; only
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

    /// The demo build runs on sample data and is always signed in.
    var isDemo: Bool { flavor == "demo" }

    /// The dev build shows the seeded test-account buttons (local Supabase only).
    var isDev: Bool { (flavor ?? "dev") == "dev" }

    /// `nil` when the file is missing or unreadable.
    static func load(from bundle: Bundle = .main) -> AppConfig? {
        guard let url = bundle.url(forResource: "KametiConfig", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode(AppConfig.self, from: data)
    }
}
