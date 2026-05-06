import Foundation

/// What the user proposed to spend, before any decision is made.
struct InterventionProposal: Identifiable, Codable, Hashable {
    let id: UUID
    var amount: Double
    var itemDescription: String
    var category: TransactionCategory
    var currencyCode: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        amount: Double,
        itemDescription: String,
        category: TransactionCategory,
        currencyCode: String = "GBP",
        createdAt: Date = .now
    ) {
        self.id = id
        self.amount = amount
        self.itemDescription = itemDescription
        self.category = category
        self.currencyCode = currencyCode
        self.createdAt = createdAt
    }
}

enum InterventionWaitDuration: String, Codable, CaseIterable, Identifiable {
    case oneDay
    case sevenDays
    case endOfMonth

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oneDay:      "24 hours"
        case .sevenDays:   "7 days"
        case .endOfMonth:  "End of month"
        }
    }

    func reminderDate(from start: Date = .now, calendar: Calendar = .current) -> Date {
        switch self {
        case .oneDay:
            return calendar.date(byAdding: .day, value: 1, to: start) ?? start
        case .sevenDays:
            return calendar.date(byAdding: .day, value: 7, to: start) ?? start
        case .endOfMonth:
            return calendar.dateInterval(of: .month, for: start)?.end ?? start
        }
    }
}

enum InterventionAction: Codable, Hashable {
    case buyNow
    case wait(InterventionWaitDuration)
    case addToPot(goalID: UUID)

    var analyticsLabel: String {
        switch self {
        case .buyNow:    "buy_now"
        case .wait:      "wait"
        case .addToPot:  "add_to_pot"
        }
    }
}

/// How the user eventually resolved a `.wait` decision after the snooze
/// period elapsed. Only meaningful when `action` is `.wait`.
enum WaitOutcome: String, Codable, Hashable, Sendable {
    /// User decided NOT to buy — the amount feeds "money saved by pausing".
    case skipped
    /// User went ahead and bought — a real `Transaction` is written when
    /// the resolution lands.
    case purchased
}

/// Persisted record of a completed intervention. Drives the
/// "money saved by pausing" stat shown in the Coach tab.
struct InterventionLog: Identifiable, Codable, Hashable {
    let id: UUID
    let proposalID: UUID
    var amount: Double
    var itemDescription: String
    var category: TransactionCategory
    var currencyCode: String
    var action: InterventionAction
    var decidedAt: Date

    /// Set when the user resolves a wait. Nil while the wait is still pending
    /// (or when the action wasn't a wait in the first place).
    var waitOutcome: WaitOutcome?

    init(
        id: UUID = UUID(),
        proposalID: UUID,
        amount: Double,
        itemDescription: String,
        category: TransactionCategory,
        currencyCode: String = "GBP",
        action: InterventionAction,
        decidedAt: Date = .now,
        waitOutcome: WaitOutcome? = nil
    ) {
        self.id = id
        self.proposalID = proposalID
        self.amount = amount
        self.itemDescription = itemDescription
        self.category = category
        self.currencyCode = currencyCode
        self.action = action
        self.decidedAt = decidedAt
        self.waitOutcome = waitOutcome
    }

    var isPendingWait: Bool {
        if case .wait = action, waitOutcome == nil { return true }
        return false
    }
}
