import Foundation

/// Surfaces categories where the user spent meaningfully more this week than
/// their personal weekly baseline. The "meaningful" thresholds are picked to
/// avoid flagging tiny noise on small categories (e.g. £3 over a £5 baseline).
struct OverspendAnalyser: InsightAnalyser {
    /// Flag only when current spend ≥ baseline × this multiplier.
    private let multiplierThreshold: Double = 1.4
    /// Absolute floor on the excess — avoids "you're £4 over baseline" noise.
    private let minimumExcessAmount: Double = 15

    func analyse(facts: WeeklyFacts) -> [InsightCandidate] {
        var out: [InsightCandidate] = []
        for (category, spend) in facts.weeklySpendByCategory {
            let baseline = facts.weeklyBaselineByCategory[category] ?? 0
            let candidate = candidate(
                category: category,
                spend: spend,
                baseline: baseline,
                currencyCode: facts.currencyCode
            )
            if let candidate { out.append(candidate) }
        }
        return out
    }

    private func candidate(
        category: TransactionCategory,
        spend: Double,
        baseline: Double,
        currencyCode: String
    ) -> InsightCandidate? {
        let formatter = currencyFormatter(currencyCode: currencyCode)
        let formattedSpend = formatter.string(from: NSNumber(value: spend)) ?? "\(spend)"
        let categoryLabel = category.displayName.lowercased()

        if baseline > 0 {
            let excess = spend - baseline
            guard spend >= baseline * multiplierThreshold,
                  excess >= minimumExcessAmount
            else { return nil }
            let pct = Int((excess / baseline) * 100)
            let formattedBaseline = formatter.string(from: NSNumber(value: baseline)) ?? "\(baseline)"
            let severity = min(1, excess / max(baseline, 1))
            return InsightCandidate(
                kind: .overspend,
                category: category,
                primaryAmount: spend,
                comparisonAmount: baseline,
                currencyCode: currencyCode,
                severity: severity,
                headline: "\(category.displayName) up \(pct)% this week",
                templateNarrative: "You spent \(formattedSpend) on \(categoryLabel) in the last 7 days — about \(pct)% above your usual \(formattedBaseline). Anything driving the change?"
            )
        }

        // New category for the user — no baseline yet. Flag only if the spend
        // is non-trivial so we don't draw attention to a single £4 charge.
        guard spend >= 50 else { return nil }
        return InsightCandidate(
            kind: .overspend,
            category: category,
            primaryAmount: spend,
            comparisonAmount: 0,
            currencyCode: currencyCode,
            severity: min(1, spend / 200),
            headline: "New \(categoryLabel) spend this week",
            templateNarrative: "\(formattedSpend) on \(categoryLabel) is new for you — no recent baseline to compare against. Worth keeping an eye on."
        )
    }

    private func currencyFormatter(currencyCode: String) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        f.maximumFractionDigits = 0
        return f
    }
}
