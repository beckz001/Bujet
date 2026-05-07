import Foundation
import UserNotifications

/// Foreground presentation + tap handler for Pause & Reflect wait reminders.
///
/// `willPresent` makes the banner visible while the app is active (iOS would
/// otherwise suppress it). `didReceive` fires when the user taps the
/// notification: we decode the proposal out of `userInfo` and hand it to the
/// `WaitReminderRouter` so `MainTabView` can reopen the reflect sheet
/// pre-filled.
final class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let router: WaitReminderRouter

    init(router: WaitReminderRouter) {
        self.router = router
        super.init()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        defer { completionHandler() }

        guard
            let kind = userInfo[WaitReminderUserInfoKey.kind] as? String,
            kind == WaitReminderUserInfoKey.kindWaitReminder,
            let proposal = Self.proposal(from: userInfo)
        else { return }

        Task { @MainActor in
            router.pendingProposal = proposal
        }
    }

    private static func proposal(from userInfo: [AnyHashable: Any]) -> InterventionProposal? {
        guard
            let idString = userInfo[WaitReminderUserInfoKey.proposalID] as? String,
            let id = UUID(uuidString: idString),
            let amount = userInfo[WaitReminderUserInfoKey.amount] as? Double,
            let itemDescription = userInfo[WaitReminderUserInfoKey.itemDescription] as? String,
            let categoryRaw = userInfo[WaitReminderUserInfoKey.category] as? String,
            let category = TransactionCategory(rawValue: categoryRaw),
            let currencyCode = userInfo[WaitReminderUserInfoKey.currencyCode] as? String
        else { return nil }

        return InterventionProposal(
            id: id,
            amount: amount,
            itemDescription: itemDescription,
            category: category,
            currencyCode: currencyCode
        )
    }
}
