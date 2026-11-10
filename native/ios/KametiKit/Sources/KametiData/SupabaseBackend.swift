import Foundation
import KametiCore
import Supabase

/// Builds the one `SupabaseClient` the app uses. Rows decode with
/// `KametiJSON` (snake_case keys, date-only columns, ISO timestamps).
public enum KametiBackend {
    public static func makeClient(url: URL, publishableKey: String) -> SupabaseClient {
        SupabaseClient(
            supabaseURL: url,
            supabaseKey: publishableKey,
            options: SupabaseClientOptions(
                db: .init(decoder: KametiJSON.makeDecoder()),
                auth: .init(emitLocalSessionAsInitialSession: true)
            )
        )
    }
}
