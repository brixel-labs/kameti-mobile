import Foundation
import KametiCore
import KametiDomain
import Supabase

/// Notifications through migration `notifications`: the inbox is a plain
/// select (RLS shows only mine); devices and read marks go through RPCs;
/// preferences are the `notify_*` columns of my profile.
public final class SupabaseNotificationsRepository: NotificationsRepository {
    private let client: SupabaseClient

    public init(client: SupabaseClient) { self.client = client }

    public func notifications(limit: Int) async throws(Failure) -> [AppNotification] {
        try await run {
            try await client.from("notifications").select(AppNotification.columns)
                .order("created_at", ascending: false).limit(limit).execute().value
        }
    }

    public func markRead(ids: [String]?) async throws(Failure) {
        let params: [String: JSONValue] = ["p_ids": ids.map { .array($0.map { .string($0) }) } ?? .null]
        try await run { _ = try await client.rpc("mark_notifications_read", params: params).execute() }
    }

    public func registerDevice(token: String, platform: String) async throws(Failure) {
        try await run {
            _ = try await client.rpc("register_device", params: ["p_token": JSONValue.string(token), "p_platform": .string(platform)]).execute()
        }
    }

    public func unregisterDevice(token: String) async throws(Failure) {
        try await run { _ = try await client.rpc("unregister_device", params: ["p_token": JSONValue.string(token)]).execute() }
    }

    public func preferences(userId: String) async throws(Failure) -> NotificationPreferences {
        try await run {
            try await client.from("profiles").select(NotificationPreferences.columns).eq("id", value: userId).single().execute().value
        }
    }

    public func updatePreferences(userId: String, _ preferences: NotificationPreferences) async throws(Failure) {
        try await run {
            _ = try await client.from("profiles").update([
                "notify_reminders": preferences.notifyReminders, "notify_payments": preferences.notifyPayments,
                "notify_invites": preferences.notifyInvites, "notify_changes": preferences.notifyChanges,
            ]).eq("id", value: userId).execute()
        }
    }
}
