import Foundation
import Observation

@MainActor
@Observable
final class CoachViewModel {
    @ObservationIgnored private let goalRepository: any GoalRepository
    @ObservationIgnored private let interventionLogRepository: any InterventionLogRepository
    @ObservationIgnored private let transactionRepository: any TransactionRepository
    @ObservationIgnored private let weeklyInsightsUseCase: GenerateWeeklyInsightsUseCase

    var goals: [Goal] = []
    var pendingWaits: [InterventionLog] = []
    /// Sum of skipped-wait amounts for the current calendar month. Resets on
    /// the 1st so the figure always reflects fresh, recent restraint instead
    /// of an ever-growing all-time total.
    var moneySavedByPausing: Double = 0
    var currencyCode: String = "GBP"
    var insights: [Insight] = []
    var isLoadingInsights: Bool = false

    /// Number of 7-day windows away from the current trailing week. `0` is the
    /// week ending today; `-1` is the previous 7-day window, etc. The forward
    /// (`>`) button is disabled when this hits `0` so the user can't peek into
    /// the future.
    var weekOffset: Int = 0

    @ObservationIgnored private let calendar = Calendar.current

    init(
        goalRepository: some GoalRepository,
        interventionLogRepository: some InterventionLogRepository,
        transactionRepository: some TransactionRepository,
        weeklyInsightsUseCase: GenerateWeeklyInsightsUseCase
    ) {
        self.goalRepository = goalRepository
        self.interventionLogRepository = interventionLogRepository
        self.transactionRepository = transactionRepository
        self.weeklyInsightsUseCase = weeklyInsightsUseCase
    }

    func load() async {
        let monthInterval = calendar.dateInterval(of: .month, for: .now)
            ?? DateInterval(start: .now, duration: 0)
        async let goalList = goalRepository.fetchAll()
        async let pending = interventionLogRepository.fetchPendingWaits()
        async let saved = interventionLogRepository.moneySavedByPausing(in: monthInterval)
        goals = await goalList
        pendingWaits = await pending
        moneySavedByPausing = await saved
        if let firstCurrency = goals.first?.currencyCode {
            currencyCode = firstCurrency
        } else if let firstWait = pendingWaits.first {
            currencyCode = firstWait.currencyCode
        }
        await loadInsights()
    }

    func loadInsights() async {
        isLoadingInsights = true
        insights = await weeklyInsightsUseCase.run(now: weekReferenceDate)
        isLoadingInsights = false
    }

    func goToPreviousWeek() async {
        weekOffset -= 1
        await loadInsights()
    }

    func goToNextWeek() async {
        guard canGoToNextWeek else { return }
        weekOffset += 1
        await loadInsights()
    }

    var canGoToNextWeek: Bool { weekOffset < 0 }

    /// Reference date passed into the insights pipeline — defines the *end* of
    /// the trailing 7-day window the analysers operate on.
    private var weekReferenceDate: Date {
        calendar.date(byAdding: .day, value: weekOffset * 7, to: .now) ?? .now
    }

    /// Inclusive-feeling label for the currently-selected week, e.g. "7 – 14 May".
    /// Cross-month windows show the month on both ends ("29 Apr – 5 May").
    var weekRangeLabel: String {
        let end = weekReferenceDate
        guard let start = calendar.date(byAdding: .day, value: -7, to: end) else {
            return ""
        }
        let dayMonth = DateFormatter()
        dayMonth.dateFormat = "d MMM"
        let dayOnly = DateFormatter()
        dayOnly.dateFormat = "d"

        let sameMonth = calendar.isDate(start, equalTo: end, toGranularity: .month)
        if sameMonth {
            return "\(dayOnly.string(from: start)) – \(dayMonth.string(from: end))"
        } else {
            return "\(dayMonth.string(from: start)) – \(dayMonth.string(from: end))"
        }
    }

    func refresh() async { await load() }

    func contribute(amount: Double, to goal: Goal) async {
        _ = try? await goalRepository.contribute(amount: amount, to: goal.id)
        await load()
    }

    func delete(_ goal: Goal) async {
        try? await goalRepository.delete(id: goal.id)
        await load()
    }

    #if DEBUG
    /// Wipes the entire intervention log so the saved-by-pausing card and
    /// any pending waits go back to zero. DEBUG-only, intended for demos.
    func resetInterventionLog() async {
        try? await interventionLogRepository.clearAll()
        await load()
    }
    #endif

    /// Resolve a pending wait. Skipped → contributes to the saved-by-pausing
    /// total. Purchased → records a Transaction so the user's spending
    /// reflects what they actually did.
    func resolveWait(_ log: InterventionLog, as outcome: WaitOutcome) async {
        try? await interventionLogRepository.resolveWait(id: log.id, outcome: outcome)
        if outcome == .purchased {
            let transaction = Transaction(
                id: "intervention-\(log.proposalID.uuidString)",
                date: .now,
                description: log.itemDescription,
                merchantName: log.itemDescription,
                amount: -abs(log.amount),
                currencyCode: log.currencyCode,
                source: .manual,
                category: log.category
            )
            try? await transactionRepository.add([transaction])
        }
        await load()
    }
}
