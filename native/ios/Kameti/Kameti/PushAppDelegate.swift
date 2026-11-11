import FeatureShell
import FirebaseCore
import FirebaseMessaging
import UIKit
import UserNotifications

/// Push plumbing that needs the app itself: Firebase, the APNs token, and
/// what happens when a notification arrives or is tapped. Everything the
/// screens need goes through `PushCenter`.
final class PushAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(
        _ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        // GoogleService-Info.plist is git-ignored: without it the app runs, just without push.
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
            Messaging.messaging().delegate = self
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        guard FirebaseApp.app() != nil else { return }
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        print("Push: APNs registration failed: \(error.localizedDescription)")
    }

    // MARK: MessagingDelegate

    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Task { @MainActor in PushCenter.shared.fcmToken = fcmToken }
    }

    // MARK: UNUserNotificationCenterDelegate

    /// In the foreground, still show the banner. The completion-handler form
    /// (called back on the main thread): the async form finishes off the main
    /// thread and UIKit aborts.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping @Sendable (UNNotificationPresentationOptions) -> Void
    ) {
        DispatchQueue.main.async { completionHandler([.banner, .list, .sound, .badge]) }
    }

    /// A tapped notification: hand it to PushCenter, then tell iOS we're done.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping @Sendable () -> Void
    ) {
        let info = response.notification.request.content.userInfo
        let kind = info["kind"] as? String ?? ""
        let kametiId = info["kameti_id"] as? String
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                PushCenter.shared.handleTap(userInfo: ["kind": kind, "kameti_id": kametiId as Any])
            }
            completionHandler()
        }
    }
}
