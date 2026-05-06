import Foundation
import UserNotifications

/// Foreground presentation handler. iOS suppresses banners by default when
/// the app is active; this delegate makes Pause & Reflect wait reminders
/// visible during the demo.
final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}
