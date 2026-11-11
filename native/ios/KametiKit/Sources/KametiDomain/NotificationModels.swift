import Foundation
import KametiCore

/// Row of `public.notifications`: one thing that happened, for one person
/// (FR-83, FR-86). The Inbox's Updates list; also what was pushed.
public struct AppNotification: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let kametiId: String?
    /// e.g. `payment`, `payout`, `joined`, `join_request`, `invite`.
    public let kind: String
    /// `reminders`, `payments`, `invites`, `changes` or `broadcast`.
    public let category: String
    public let title: String
    public let body: String
    public let readAt: Date?
    public let createdAt: Date

    public init(
        id: String, kametiId: String? = nil, kind: String, category: String, title: String, body: String,
        readAt: Date? = nil, createdAt: Date
    ) {
        self.id = id; self.kametiId = kametiId; self.kind = kind; self.category = category
        self.title = title; self.body = body; self.readAt = readAt; self.createdAt = createdAt
    }

    public var isUnread: Bool { readAt == nil }

    /// Whether tapping it should open its kameti. Not for an invitation (not
    /// joined yet), a join request (answered from the Inbox) or a declined
    /// join (that person can't see the kameti).
    public var opensKameti: Bool { Self.opensKameti(kind: kind) && kametiId != nil }

    public static func opensKameti(kind: String) -> Bool {
        !["invite", "join_request", "join_declined"].contains(kind)
    }

    /// The same notification, marked read now.
    public func markedRead(at date: Date) -> AppNotification {
        AppNotification(id: id, kametiId: kametiId, kind: kind, category: category, title: title, body: body, readAt: date, createdAt: createdAt)
    }

    /// Columns the app reads (the table has more, for the push sender).
    public static let columns = "id, kameti_id, kind, category, title, body, read_at, created_at"
}

/// What the user wants pushed (FR-85). Everything still reaches the Inbox.
public struct NotificationPreferences: Codable, Hashable, Sendable {
    public var notifyReminders: Bool
    public var notifyPayments: Bool
    public var notifyInvites: Bool
    public var notifyChanges: Bool

    public init(notifyReminders: Bool = true, notifyPayments: Bool = true, notifyInvites: Bool = true, notifyChanges: Bool = true) {
        self.notifyReminders = notifyReminders; self.notifyPayments = notifyPayments
        self.notifyInvites = notifyInvites; self.notifyChanges = notifyChanges
    }

    public static let columns = "notify_reminders, notify_payments, notify_invites, notify_changes"
}

/// Who an owner's reminder would reach (`reminder_targets`, FR-82, FR-84).
public struct ReminderTargets: Codable, Hashable, Sendable {
    public struct Member: Codable, Hashable, Identifiable, Sendable {
        public let memberId: String
        public let name: String
        public let owed: Money
        /// Joined the app: gets the push. Otherwise remind on WhatsApp.
        public let hasApp: Bool
        /// The owner already reminded them today (one owner reminder a day each).
        public let remindedToday: Bool
        public let phone: String?
        public var id: String { memberId }

        public init(memberId: String, name: String, owed: Money, hasApp: Bool, remindedToday: Bool = false, phone: String? = nil) {
            self.memberId = memberId; self.name = name; self.owed = owed; self.hasApp = hasApp
            self.remindedToday = remindedToday; self.phone = phone
        }
    }

    public let dueDay: Int
    public let members: [Member]

    public init(dueDay: Int, members: [Member]) {
        self.dueDay = dueDay; self.members = members
    }
}

/// What a reminder did: how many got it, and who was skipped (already reminded today).
public struct ReminderResult: Codable, Hashable, Sendable {
    public let sent: Int
    public let skipped: [String]

    public init(sent: Int, skipped: [String] = []) { self.sent = sent; self.skipped = skipped }
}

/// The signed-in user's notifications, devices and preferences.
public protocol NotificationsRepository: Sendable {
    /// Newest first.
    func notifications(limit: Int) async throws(Failure) -> [AppNotification]
    /// Marks these read, or every unread one when `ids` is nil.
    func markRead(ids: [String]?) async throws(Failure)
    /// Saves this phone's push token for the signed-in account.
    func registerDevice(token: String, platform: String) async throws(Failure)
    func unregisterDevice(token: String) async throws(Failure)
    func preferences(userId: String) async throws(Failure) -> NotificationPreferences
    func updatePreferences(userId: String, _ preferences: NotificationPreferences) async throws(Failure)
    /// Owner only: who owes now, with and without the app.
    func reminderTargets(kametiId: String) async throws(Failure) -> ReminderTargets
    /// Owner only: pushes a reminder; each member gets at most one a day from the owner.
    func sendReminder(kametiId: String, message: String?, memberIds: [String]?) async throws(Failure) -> ReminderResult
}

/// For builds without notifications: nothing to show, nothing to send.
public struct UnavailableNotificationsRepository: NotificationsRepository {
    public init() {}
    public func notifications(limit: Int) async throws(Failure) -> [AppNotification] { [] }
    public func markRead(ids: [String]?) async throws(Failure) {}
    public func registerDevice(token: String, platform: String) async throws(Failure) {}
    public func unregisterDevice(token: String) async throws(Failure) {}
    public func preferences(userId: String) async throws(Failure) -> NotificationPreferences { NotificationPreferences() }
    public func updatePreferences(userId: String, _ preferences: NotificationPreferences) async throws(Failure) {}
    public func reminderTargets(kametiId: String) async throws(Failure) -> ReminderTargets { ReminderTargets(dueDay: 10, members: []) }
    public func sendReminder(kametiId: String, message: String?, memberIds: [String]?) async throws(Failure) -> ReminderResult { ReminderResult(sent: 0) }
}
