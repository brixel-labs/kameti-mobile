import Foundation
import KametiCore
import KametiDomain
import Synchronization

/// The demo's Inbox updates: a few things that happened to the demo account,
/// kept in memory so "mark read" and preferences behave as on the backend.
final class SampleNotificationsRepository: NotificationsRepository {
    private struct State {
        var items: [AppNotification]
        var preferences = NotificationPreferences()
        var tokens: Set<String> = []
    }

    private let state: Mutex<State>

    init(now: Date) {
        let hour: TimeInterval = 3600
        state = Mutex(State(items: [
            AppNotification(id: "n1", kametiId: "family", kind: "payment", category: "payments", title: "Payment recorded",
                            body: "Rs 2,50,000 from Ali Raza · Family kameti", createdAt: now - hour),
            AppNotification(id: "n2", kametiId: "office", kind: "joined", category: "invites", title: "Omar Farooq joined",
                            body: "Office kameti", createdAt: now - 5 * hour),
            AppNotification(id: "n3", kametiId: "friends", kind: "declined", category: "invites", title: "Zara declined the invite",
                            body: "Friends kameti · you can invite them again", readAt: now - 20 * hour, createdAt: now - 26 * hour),
            AppNotification(id: "n4", kametiId: "cousins", kind: "payout_soon", category: "payments", title: "Your payout is next month",
                            body: "Rs 6,00,000 in December · Cousins kameti", readAt: now - 40 * hour, createdAt: now - 50 * hour),
        ]))
    }

    func notifications(limit: Int) async throws(Failure) -> [AppNotification] {
        state.withLock { Array($0.items.sorted { $0.createdAt > $1.createdAt }.prefix(limit)) }
    }

    func markRead(ids: [String]?) async throws(Failure) {
        state.withLock { s in
            s.items = s.items.map { item in
                (ids == nil || ids!.contains(item.id)) && item.isUnread ? item.markedRead(at: Date()) : item
            }
        }
    }

    func registerDevice(token: String, platform: String) async throws(Failure) { _ = state.withLock { $0.tokens.insert(token) } }
    func unregisterDevice(token: String) async throws(Failure) { _ = state.withLock { $0.tokens.remove(token) } }
    func preferences(userId: String) async throws(Failure) -> NotificationPreferences { state.withLock { $0.preferences } }
    func updatePreferences(userId: String, _ preferences: NotificationPreferences) async throws(Failure) {
        state.withLock { $0.preferences = preferences }
    }
}
