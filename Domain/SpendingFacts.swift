import Foundation

/// Pre-computed numerical context handed to the LLM. The LLM never recomputes
/// these values — its sole job is to write prose around them. This makes
/// numerical hallucination architecturally impossible.
struct SpendingFacts: Hashable, Codable {
    /// The proposal these facts are computed for (nil for weekly insight runs).
    var proposal: InterventionProposal?

    /// Spend so far in the calendar month, by category.
    var monthSpendByCategory: [TransactionCategory: Double]

    /// Personal 6-month average monthly spend, by category.
    var baselineMonthlyAverageByCategory: [TransactionCategory: Double]

    /// Per-category monthly cap if set.
    var budgetByCategory: [TransactionCategory: Double]

    /// All active goals/pots.
    var activeGoals: [Goal]

    /// Recent transactions in the proposal's category, newest first, capped.
    var recentSimilarTransactions: [Transaction]

    /// Money saved by pausing — sum of `amount` on `InterventionLog`s where
    /// the user later declined after a wait.
    var moneySavedByPausing: Double

    /// Currency code carried along for formatting.
    var currencyCode: String

    init(
        proposal: InterventionProposal? = nil,
        monthSpendByCategory: [TransactionCategory: Double] = [:],
        baselineMonthlyAverageByCategory: [TransactionCategory: Double] = [:],
        budgetByCategory: [TransactionCategory: Double] = [:],
        activeGoals: [Goal] = [],
        recentSimilarTransactions: [Transaction] = [],
        moneySavedByPausing: Double = 0,
        currencyCode: String = "GBP"
    ) {
        self.proposal = proposal
        self.monthSpendByCategory = monthSpendByCategory
        self.baselineMonthlyAverageByCategory = baselineMonthlyAverageByCategory
        self.budgetByCategory = budgetByCategory
        self.activeGoals = activeGoals
        self.recentSimilarTransactions = recentSimilarTransactions
        self.moneySavedByPausing = moneySavedByPausing
        self.currencyCode = currencyCode
    }
}

/// Deterministic, Swift-computed impact summary. Surfaced in the Pause & Reflect
/// sheet directly (top section) and also passed to the LLM as additional context
/// for narrative phrasing.
struct ImpactSummary: Hashable, Codable {
    enum Severity: String, Codable, Hashable {
        /// Budget set, projected spend stays comfortably within.
        case withinBudget
        /// Budget set, projected spend ≥ 80% of cap.
        case approachingLimit
        /// Budget set, projected spend exceeds cap.
        case overBudget
        /// No budget set — falls back to baseline framing.
        case noBudget
    }

    let category: TransactionCategory
    let amount: Double
    let currencyCode: String
    let monthSpendBefore: Double
    let monthSpendAfter: Double
    let budgetLimit: Double?
    let baselineMonthlyAverage: Double?
    let severity: Severity

    /// Percentage over the budget cap if `severity == .overBudget`, else nil.
    var percentOverBudget: Double? {
        guard let limit = budgetLimit, limit > 0, monthSpendAfter > limit else { return nil }
        return ((monthSpendAfter - limit) / limit) * 100
    }

    /// Percentage of the budget cap consumed by the projected spend, 0–100+.
    /// nil when no budget is set.
    var percentOfBudgetUsed: Double? {
        guard let limit = budgetLimit, limit > 0 else { return nil }
        return (monthSpendAfter / limit) * 100
    }

    /// Percentage above the personal baseline, if baseline is known and exceeded.
    var percentAboveBaseline: Double? {
        guard let baseline = baselineMonthlyAverage, baseline > 0,
              monthSpendAfter > baseline else { return nil }
        return ((monthSpendAfter - baseline) / baseline) * 100
    }
}
