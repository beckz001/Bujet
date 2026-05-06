import Foundation

/// String-template fallback that the rest of the app uses verbatim when Apple
/// Intelligence is unavailable. Built first so the app demos end-to-end on any
/// device, then `FoundationModelsNarrativeService` swaps in for free.
struct TemplateNarrativeService: LLMNarrativeService {
    private let calendar: Calendar
    private let now: () -> Date

    init(calendar: Calendar = .current, now: @escaping () -> Date = Date.init) {
        self.calendar = calendar
        self.now = now
    }

    func generateInterventionNarrative(
        facts: SpendingFacts,
        impact: ImpactSummary
    ) async throws -> InterventionNarrative {
        let category = impact.category.displayName.lowercased()
        let formatter = currencyFormatter(currencyCode: impact.currencyCode)

        let narrative: String
        let action: SuggestedAction

        switch impact.severity {
        case .overBudget:
            let overPct = Int(impact.percentOverBudget ?? 0)
            let limit = formatter.string(from: NSNumber(value: impact.budgetLimit ?? 0)) ?? ""
            narrative = "Heads up — this would put you about \(overPct)% over your \(category) budget of \(limit) this month. You've already spent \(formatter.string(from: NSNumber(value: impact.monthSpendBefore)) ?? "") on \(category). Worth parking?"
            action = .wait

        case .approachingLimit:
            let used = Int(impact.percentOfBudgetUsed ?? 0)
            let daysLeft = daysRemainingInMonth()
            narrative = "This would put your \(category) spend at \(used)% of your monthly cap with \(daysLeft) days still to go. Is this one a planned buy or an in-the-moment thing?"
            action = .wait

        case .withinBudget:
            if let goal = goalContextSuffix(facts: facts, formatter: formatter, amount: impact.amount) {
                narrative = "You'd still be comfortably within your \(category) budget. \(goal)"
                action = .addToWishlistPot
            } else {
                narrative = "You'd still be comfortably within your \(category) budget. If this feels intentional, go for it."
                action = .buyNow
            }

        case .noBudget:
            if let baselinePct = impact.percentAboveBaseline, baselinePct >= 15 {
                let baseline = formatter.string(from: NSNumber(value: impact.baselineMonthlyAverage ?? 0)) ?? ""
                narrative = "This would be a \(Int(baselinePct))% step up from your typical \(category) month (\(baseline)). Sit with it for 24 hours and see if it still feels right."
                action = .wait
            } else if let goal = goalContextSuffix(facts: facts, formatter: formatter, amount: impact.amount) {
                narrative = "This looks like normal \(category) spending for you. \(goal)"
                action = .addToWishlistPot
            } else {
                narrative = "This looks like normal \(category) spending for you. No flags here."
                action = .buyNow
            }
        }

        return InterventionNarrative(
            narrative: narrative,
            suggestedAction: action,
            source: .template
        )
    }

    // MARK: - Helpers

    private func goalContextSuffix(
        facts: SpendingFacts,
        formatter: NumberFormatter,
        amount: Double
    ) -> String? {
        guard let topGoal = facts.activeGoals
            .filter({ !$0.isComplete })
            .min(by: { $0.remaining < $1.remaining })
        else { return nil }
        let saved = formatter.string(from: NSNumber(value: amount)) ?? ""
        return "Saving \(saved) toward your '\(topGoal.name)' pot would close \(Int(min(100, (amount / max(topGoal.targetAmount, 1)) * 100)))% of what's left."
    }

    private func daysRemainingInMonth() -> Int {
        guard let end = calendar.dateInterval(of: .month, for: now())?.end else { return 0 }
        return max(0, calendar.dateComponents([.day], from: now(), to: end).day ?? 0)
    }

    private func currencyFormatter(currencyCode: String) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        f.maximumFractionDigits = 0
        return f
    }
}
