import Foundation
import KametiDomain
import Supabase

/// Supabase Realtime (migration `realtime`): one channel listening to every table
/// the app shows. The server applies RLS per listener, so only rows the user
/// may read arrive. A change only says which kameti moved; screens reload.
public actor SupabaseLiveUpdates: LiveUpdatesRepository {
    private static let tables = ["kametis", "members", "slots", "shares", "payments", "payouts", "notifications"]

    private let client: SupabaseClient
    private var channel: RealtimeChannelV2?
    private var subscriptions: [RealtimeSubscription] = []

    public init(client: SupabaseClient) { self.client = client }

    public func start(onChange: @escaping @Sendable (LiveChange) -> Void) async {
        guard channel == nil else { return }
        let channel = client.channel("kameti-live")
        subscriptions = Self.tables.map { table in
            channel.onPostgresChange(AnyAction.self, schema: "public", table: table) { action in
                onChange(LiveChange(table: table, kametiId: Self.kametiId(in: action, table: table)))
            }
        }
        self.channel = channel
        do {
            try await channel.subscribeWithError()
        } catch {
            // Offline or not allowed: screens still refresh on open and on pull.
            await stop()
        }
    }

    public func stop() async {
        subscriptions = []
        if let channel { await client.removeChannel(channel) }
        channel = nil
    }

    private static func kametiId(in action: AnyAction, table: String) -> String? {
        let row: [String: AnyJSON] = switch action {
        case .insert(let insert): insert.record
        case .update(let update): update.record
        case .delete(let delete): delete.oldRecord
        }
        return (table == "kametis" ? row["id"] : row["kameti_id"])?.stringValue
    }
}
