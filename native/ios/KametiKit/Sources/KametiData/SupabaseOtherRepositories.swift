import Foundation
import KametiCore
import KametiDomain
import Supabase

public final class SupabaseAuditRepository: AuditRepository {
    private let client: SupabaseClient

    public init(client: SupabaseClient) { self.client = client }

    public func audit(kametiId: String, limit: Int) async throws(Failure) -> [AuditEntry] {
        try await run {
            try await client.from("audit_log").select()
                .eq("kameti_id", value: kametiId)
                .order("at", ascending: false)
                .limit(limit)
                .execute().value
        }
    }
}

public final class SupabaseProfileRepository: ProfileRepository {
    private let client: SupabaseClient

    public init(client: SupabaseClient) { self.client = client }

    public func myProfile(userId: String) async throws(Failure) -> Profile {
        try await run {
            try await client.from("profiles").select().eq("id", value: userId).single().execute().value
        }
    }

    public func updateDisplayName(userId: String, _ name: String) async throws(Failure) -> Profile {
        try await run {
            try await client.from("profiles").update(["display_name": name]).eq("id", value: userId).select().single().execute().value
        }
    }
}

public final class SupabaseContactsRepository: ContactsRepository {
    private let client: SupabaseClient

    public init(client: SupabaseClient) { self.client = client }

    public func contacts() async throws(Failure) -> [Contact] {
        try await run { try await client.from("contacts").select().order("name").execute().value }
    }
}
