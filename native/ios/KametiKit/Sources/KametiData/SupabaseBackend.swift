import Foundation
import KametiCore
import KametiDomain
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

extension KametiBackend {
    /// The real dependencies: every repository on one Supabase client. Social
    /// sign-in sheets are injected so this module never links their SDKs.
    public static func makeDependencies(
        url: URL,
        publishableKey: String,
        google: (any ProviderCredentialSource)? = nil,
        apple: (any ProviderCredentialSource)? = nil,
        clock: KametiClock = KametiClock()
    ) -> KametiDependencies {
        let client = makeClient(url: url, publishableKey: publishableKey)
        return KametiDependencies(
            kametis: SupabaseKametiRepository(client: client),
            ledger: SupabaseLedgerRepository(client: client),
            payments: SupabasePaymentsRepository(client: client),
            invites: SupabaseInvitesRepository(client: client),
            audit: SupabaseAuditRepository(client: client),
            profiles: SupabaseProfileRepository(client: client),
            contacts: SupabaseContactsRepository(client: client),
            auth: SupabaseAuthRepository(client: client, google: google, apple: apple),
            notes: SupabaseNotesRepository(client: client),
            account: SupabaseAccountRepository(client: client),
            notifications: SupabaseNotificationsRepository(client: client),
            live: SupabaseLiveUpdates(client: client),
            clock: clock
        )
    }
}
