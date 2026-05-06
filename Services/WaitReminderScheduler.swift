import Foundation
import UserNotifications

/// Schedules a single local notification for a Pause & Reflect wait. In DEBUG
/// builds the delay is collapsed to ~5 seconds so the demo can show the
/// notification firing live regardless of which option (24h / 7d / EOM) the
/// user picked. In release the chosen duration is honoured exactly.
struct WaitReminderScheduler: Sendable {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }

    func schedule(
        for proposal: InterventionProposal,
        duration: InterventionWaitDuration,
        now: Date = .now,
        calendar: Calendar = .current
    ) async {
        guard await requestAuthorizationIfNeeded() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Still want \(proposal.itemDescription)?"
        content.body = "You paused on a \(formattedAmount(proposal)) \(proposal.category.displayName.lowercased()) buy. If it's still right, go for it — if not, that's a save."
        content.sound = .default

        let interval = triggerInterval(
            duration: duration,
            now: now,
            calendar: calendar
        )

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "wait-\(proposal.id.uuidString)",
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    private func triggerInterval(
        duration: InterventionWaitDuration,
        now: Date,
        calendar: Calendar
    ) -> TimeInterval {
        #if DEBUG
        return 5
        #else
        let target = duration.reminderDate(from: now, calendar: calendar)
        return max(1, target.timeIntervalSince(now))
        #endif
    }

    private func formattedAmount(_ proposal: InterventionProposal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = proposal.currencyCode
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: proposal.amount)) ?? "\(proposal.amount)"
    }
}
