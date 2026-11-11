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
        var remindedToday: Set<String> = []
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

    /// The family kameti's members who owe in the demo; Hira has no app.
    func reminderTargets(kametiId: String) async throws(Failure) -> ReminderTargets {
        let reminded = state.withLock { $0.remindedToday }
        return ReminderTargets(dueDay: 10, members: [
            .init(memberId: "f4", name: "Omar Farooq", owed: Money(250_000), hasApp: true, remindedToday: reminded.contains("f4")),
            .init(memberId: "f6", name: "Faisal Iqbal", owed: Money(250_000), hasApp: true, remindedToday: reminded.contains("f6")),
            .init(memberId: "f5", name: "Hira Malik", owed: Money(125_000), hasApp: false, phone: "0300 1234567"),
        ])
    }

    /// One owner reminder per member per day, like send_reminder_broadcast.
    func sendReminder(kametiId: String, message: String?, memberIds: [String]?) async throws(Failure) -> ReminderResult {
        let names = ["f4": "Omar Farooq", "f6": "Faisal Iqbal"]
        return try state.withLock { s throws(Failure) in
            let wanted = memberIds ?? ["f4", "f6"]
            let skipped = wanted.filter { s.remindedToday.contains($0) }
            let sending = wanted.filter { !s.remindedToday.contains($0) }
            guard !sending.isEmpty else { throw Failure.server(code: skipped.isEmpty ? "nobody_to_remind" : "already_reminded_today", detail: nil) }
            s.remindedToday.formUnion(sending)
            return ReminderResult(sent: sending.count, skipped: skipped.compactMap { names[$0] })
        }
    }
}
