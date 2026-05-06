import Foundation

/// Single source of truth for assembling `SpendingFacts` from the underlying
/// repositories. Used by both the Pause & Reflect flow and the weekly insights
/// pipeline so they share the same numerical view of the user.
struct SpendingContextProvider: Sendable {
    let transactionRepository: any TransactionRepository
    let budgetRepository: any BudgetRepository
    let goalRepository: any GoalRepository
    let interventionLogRepository: any InterventionLogRepository

    private let calendar: Calendar
    private let baselineMonthCount: Int

    init(
        transactionRepository: some TransactionRepository,
        budgetRepository: some BudgetRepository,
        goalRepository: some GoalRepository,
        interventionLogRepository: some InterventionLogRepository,
        calendar: Calendar = .current,
        baselineMonthCount: Int = 6
    ) {
        self.transactionRepository = transactionRepository
        self.budgetRepository = budgetRepository
        self.goalRepository = goalRepository
        self.interventionLogRepository = interventionLogRepository
        self.calendar = calendar
        self.baselineMonthCount = baselineMonthCount
    }

    func makeFacts(for proposal: InterventionProposal?, now: Date = .now) async -> SpendingFacts {
        async let transactions = transactionRepository.fetchAll()
        async let book = budgetRepository.fetch()
        async let goals = goalRepository.fetchAll()
        async let saved = interventionLogRepository.moneySavedByPausing()

        let txs = await transactions
        let budgets = await book
        let allGoals = await goals
        let moneySaved = await saved

        let monthSpend = monthSpendByCategory(transactions: txs, month: now)
        let baseline = baselineByCategory(transactions: txs, now: now)

        let recent: [Transaction]
        if let proposal {
            recent = txs
                .filter { $0.isDebit && $0.category == proposal.category }
                .sorted { $0.date > $1.date }
                .prefix(5)
                .map { $0 }
        } else {
            recent = []
        }

        let activeGoals = allGoals.filter { !$0.isComplete }

        return SpendingFacts(
            proposal: proposal,
            monthSpendByCategory: monthSpend,
            baselineMonthlyAverageByCategory: baseline,
            budgetByCategory: budgets.byCategory.mapValues(\.monthlyMax),
            activeGoals: activeGoals,
            recentSimilarTransactions: recent,
            moneySavedByPausing: moneySaved,
            currencyCode: txs.first?.currencyCode ?? proposal?.currencyCode ?? "GBP"
        )
    }

    // MARK: - Numerical aggregations

    private func monthSpendByCategory(
        transactions: [Transaction],
        month: Date
    ) -> [TransactionCategory: Double] {
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [:] }
        var totals: [TransactionCategory: Double] = [:]
        for tx in transactions where tx.isDebit && interval.contains(tx.date) {
            totals[tx.category, default: 0] += abs(tx.amount)
        }
        return totals
    }

    /// Mean monthly spend per category over the previous `baselineMonthCount`
    /// fully completed months (excluding the current month).
    private func baselineByCategory(
        transactions: [Transaction],
        now: Date
    ) -> [TransactionCategory: Double] {
        guard let currentStart = calendar.dateInterval(of: .month, for: now)?.start,
              let earliestStart = calendar.date(byAdding: .month, value: -baselineMonthCount, to: currentStart)
        else { return [:] }

        var monthlyTotals: [TransactionCategory: [Double]] = [:]
        for offset in 1...baselineMonthCount {
            guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: currentStart),
                  let interval = calendar.dateInterval(of: .month, for: monthStart),
                  monthStart >= earliestStart
            else { continue }

            var totals: [TransactionCategory: Double] = [:]
            for tx in transactions where tx.isDebit && interval.contains(tx.date) {
                totals[tx.category, default: 0] += abs(tx.amount)
            }
            for (category, amount) in totals {
                monthlyTotals[category, default: []].append(amount)
            }
        }

        return monthlyTotals.mapValues { values in
            values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        }
    }

    // MARK: - Impact summary

    /// Deterministic impact summary for a Pause & Reflect proposal. Pure
    /// arithmetic — no LLM involvement.
    func makeImpactSummary(
        proposal: InterventionProposal,
        facts: SpendingFacts
    ) -> ImpactSummary {
        let category = proposal.category
        let before = facts.monthSpendByCategory[category] ?? 0
        let after = before + proposal.amount
        let limit = facts.budgetByCategory[category]
        let baseline = facts.baselineMonthlyAverageByCategory[category]

        let severity: ImpactSummary.Severity
        if let limit, limit > 0 {
            if after > limit {
                severity = .overBudget
            } else if after >= limit * 0.8 {
                severity = .approachingLimit
            } else {
                severity = .withinBudget
            }
        } else {
            severity = .noBudget
        }

        return ImpactSummary(
            category: category,
            amount: proposal.amount,
            currencyCode: proposal.currencyCode,
            monthSpendBefore: before,
            monthSpendAfter: after,
            budgetLimit: limit,
            baselineMonthlyAverage: baseline,
            severity: severity
        )
    }
}
