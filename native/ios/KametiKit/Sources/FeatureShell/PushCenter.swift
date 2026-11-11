import Foundation
import Observation
import UIKit
import UserNotifications

/// A notification the user tapped, waiting for the app to open it.
public struct PushTap: Equatable, Sendable {
    public let kind: String
    public let kametiId: String?
}

/// The app's push state, shared between the app target (Firebase, the app
/// delegate) and the screens: permission, this phone's FCM token, and taps.
@MainActor
@Observable
public final class PushCenter {
    public static let shared = PushCenter()

    public private(set) var status: UNAuthorizationStatus = .notDetermined
    /// This phone's FCM registration token, set by the app target.
    public var fcmToken: String? {
        didSet { if fcmToken != oldValue { onToken?(fcmToken) } }
    }
    /// The last tapped notification, cleared once it's opened.
    public var pendingTap: PushTap?

    /// Called with the new token (MainTabView saves it for the signed-in account).
    var onToken: ((String?) -> Void)?

    private static let askedKey = "kameti.push.asked"

    /// Whether the in-app "Know when it matters" prompt was already shown.
    public var hasAsked: Bool {
        get { UserDefaults.standard.bool(forKey: Self.askedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.askedKey) }
    }

    public var isAllowed: Bool { status == .authorized || status == .provisional || status == .ephemeral }

    public func refreshStatus() async {
        status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Shows the system prompt (once per install), then registers for pushes.
    @discardableResult
    public func requestPermission() async -> Bool {
        hasAsked = true
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        await refreshStatus()
        if granted { UIApplication.shared.registerForRemoteNotifications() }
        return granted
    }

    /// Already allowed: make sure APNs (and so Firebase) has this phone.
    public func registerIfAllowed() async {
        await refreshStatus()
        if isAllowed { UIApplication.shared.registerForRemoteNotifications() }
    }

    /// From the app delegate when a notification is tapped.
    public func handleTap(userInfo: [AnyHashable: Any]) {
        pendingTap = PushTap(kind: userInfo["kind"] as? String ?? "", kametiId: userInfo["kameti_id"] as? String)
    }

    /// The app icon badge: unread items in the Inbox.
    public func setBadge(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }
}
