import Foundation
import Observation

@MainActor
@Observable
final class CoachViewModel {
    @ObservationIgnored private let goalRepository: any GoalRepository
    @ObservationIgnored private let interventionLogRepository: any InterventionLogRepository
    @ObservationIgnored private let transactionRepository: any TransactionRepository

    var goals: [Goal] = []
    var pendingWaits: [InterventionLog] = []
    var moneySavedByPausing: Double = 0
    var currencyCode: String = "GBP"

    init(
        goalRepository: some GoalRepository,
        interventionLogRepository: some InterventionLogRepository,
        transactionRepository: some TransactionRepository
    ) {
        self.goalRepository = goalRepository
        self.interventionLogRepository = interventionLogRepository
        self.transactionRepository = transactionRepository
    }

    func load() async {
        async let goalList = goalRepository.fetchAll()
        async let pending = interventionLogRepository.fetchPendingWaits()
        async let saved = interventionLogRepository.moneySavedByPausing()
        goals = await goalList
        pendingWaits = await pending
        moneySavedByPausing = await saved
        if let firstCurrency = goals.first?.currencyCode {
            currencyCode = firstCurrency
        } else if let firstWait = pendingWaits.first {
            currencyCode = firstWait.currencyCode
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
