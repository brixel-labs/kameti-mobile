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
}
