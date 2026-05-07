import Foundation

/// Single insight produced by one of the deterministic analysers. Every
/// numeric field is computed in pure Swift — the LLM's job is *only* to
/// rephrase `templateNarrative` into something more personal. This keeps
/// numerical hallucination architecturally impossible.
struct InsightCandidate: Hashable, Sendable, Identifiable {
    enum Kind: String, Hashable, Sendable, Codable {
        /// Last week's spend in a category meaningfully exceeded the
        /// personal baseline.
        case overspend
        /// Several small charges with the same merchant in the past week.
        case recurringSmall
    }

    let id: UUID
    let kind: Kind
    let category: TransactionCategory?
    let merchantHint: String?
    /// Headline figure for the card — total spend, total of small charges, etc.
    let primaryAmount: Double
    /// Reference figure — baseline / typical avg / per-charge mean — used by
    /// the narrative to give the headline meaning.
    let comparisonAmount: Double
    let occurrenceCount: Int
    let currencyCode: String
    let periodLabel: String
    /// 0…1 ranking score; analysers fill this in so the use case can sort.
    let severity: Double
    /// Pre-rendered card title. Always shown verbatim (LLM never touches it).
    let headline: String
    /// Pre-rendered prose used by `TemplateNarrativeService` and as the
    /// fallback if the LLM call fails for any reason.
    let templateNarrative: String

    init(
        id: UUID = UUID(),
        kind: Kind,
        category: TransactionCategory? = nil,
        merchantHint: String? = nil,
        primaryAmount: Double,
        comparisonAmount: Double,
        occurrenceCount: Int = 0,
        currencyCode: String,
        periodLabel: String = "this week",
        severity: Double,
        headline: String,
        templateNarrative: String
    ) {
        self.id = id
        self.kind = kind
        self.category = category
        self.merchantHint = merchantHint
        self.primaryAmount = primaryAmount
        self.comparisonAmount = comparisonAmount
        self.occurrenceCount = occurrenceCount
        self.currencyCode = currencyCode
        self.periodLabel = periodLabel
        self.severity = severity
        self.headline = headline
        self.templateNarrative = templateNarrative
    }
}

/// Final, presentation-ready insight handed to the UI. Combines the
/// deterministic candidate (numbers + headline) with whatever prose the
/// narrative service produced.
struct Insight: Hashable, Sendable, Identifiable {
    var id: UUID { candidate.id }
    let candidate: InsightCandidate
    let narrative: String
    let source: NarrativeSource
}

/// Pure-numerical context handed to every `InsightAnalyser`. Mirrors the
/// pattern used by `SpendingFacts` for the intervention flow.
struct WeeklyFacts: Hashable, Sendable {
    /// The "this week" window — typically the last 7 days, calendar-anchored.
    let weekInterval: DateInterval
    /// Transactions inside `weekInterval`.
    let weekTransactions: [Transaction]
    /// Total debit spend in the week, by category.
    let weeklySpendByCategory: [TransactionCategory: Double]
    /// Average weekly spend per category over the previous N completed weeks
    /// (excludes the current week).
    let weeklyBaselineByCategory: [TransactionCategory: Double]
    /// Currency carried along for formatting.
    let currencyCode: String
}

/// Deterministic analyser. Implementations must be pure functions of
/// `WeeklyFacts` — no I/O, no clocks, no randomness. Async is reserved for
/// the eventual LLM step that follows analysis.
protocol InsightAnalyser: Sendable {
    func analyse(facts: WeeklyFacts) -> [InsightCandidate]
}
