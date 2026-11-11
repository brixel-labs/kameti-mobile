import Foundation
import KametiCore
import KametiDomain
import Supabase

/// Account deletion: `account_deletion_check()` says what would happen, and
/// the `delete-account` Edge Function does it (data first, then the sign-in).
public final class SupabaseAccountRepository: AccountRepository {
    private let client: SupabaseClient

    public init(client: SupabaseClient) { self.client = client }

    public func deletionCheck() async throws(Failure) -> AccountDeletionCheck {
        try await run { try await client.rpc("account_deletion_check").execute().value }
    }

    public func deleteAccount() async throws(Failure) {
        do {
            try await client.functions.invoke("delete-account", options: FunctionInvokeOptions(body: ["confirm": true]))
        } catch FunctionsError.httpError(_, let data) {
            // The function answers {"error": "<code>"}; show its message.
            let code = (try? JSONDecoder().decode([String: JSONValue].self, from: data))?["error"]?.stringValue ?? "delete_failed"
            throw Failure.server(code: code, detail: nil)
        } catch {
            throw Failure(mapping: error)
        }
    }
}
