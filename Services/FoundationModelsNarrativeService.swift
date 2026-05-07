import Foundation
import FoundationModels

/// On-device LLM implementation. Selected by `LLMServiceFactory` when
/// `SystemLanguageModel` reports `.available` — otherwise the template
/// fallback is used and this file is never instantiated.
///
/// Two architectural notes:
/// - The LLM never does maths. The prompt embeds pre-computed numbers
///   from `SpendingFacts` / `ImpactSummary`, and the model is instructed to
///   use only those. Numerical hallucination is therefore impossible by
///   construction — the model has no source of new numbers.
/// - All FoundationModels coupling lives in this file. The shared `Domain`
///   types stay clean; we translate to/from `@Generable` DTOs internally.
struct FoundationModelsNarrativeService: LLMNarrativeService {
    private let fallback: any LLMNarrativeService

    init(fallback: some LLMNarrativeService = TemplateNarrativeService()) {
        self.fallback = fallback
    }

    func generateInterventionNarrative(
        facts: SpendingFacts,
        impact: ImpactSummary
    ) async throws -> InterventionNarrative {
        do {
            let session = LanguageModelSession(instructions: Self.instructions)
            let prompt = Self.makePrompt(facts: facts, impact: impact)
            let response = try await session.respond(
                to: prompt,
                generating: GeneratedInterventionNarrative.self
            )
            return InterventionNarrative(
                narrative: response.content.narrative,
                suggestedAction: response.content.suggestedAction.toDomain,
                source: .onDeviceLLM
            )
        } catch {
            // Content filter, rate limit, model-not-ready race — never surface
            // an error to the user. The template fallback always returns
            // something sensible.
            return try await fallback.generateInterventionNarrative(
                facts: facts,
                impact: impact
            )
        }
    }

    func generateInsightNarrative(
        candidate: InsightCandidate
    ) async throws -> InsightNarrative {
        do {
            let session = LanguageModelSession(instructions: Self.insightInstructions)
            let prompt = Self.makeInsightPrompt(candidate: candidate)
            let response = try await session.respond(
                to: prompt,
                generating: GeneratedInsightNarrative.self
            )
            return InsightNarrative(
                narrative: response.content.narrative,
                source: .onDeviceLLM
            )
        } catch {
            return try await fallback.generateInsightNarrative(candidate: candidate)
        }
    }

    // MARK: - Prompt

    private static let instructions: String = """
    You are a kind, non-judgemental personal finance coach inside the Bujet app.
    The user is pausing before a discretionary purchase. Your job is to help
    them reflect, not to tell them what to do.

    Rules:
    - Use ONLY the facts in the prompt. Never invent merchants, percentages,
      or amounts. Numbers must be exactly as given.
    - Write 1 to 3 short sentences. Second person. Warm, curious, never
      preachy.
    - Reference one specific number from the prompt to make it concrete.
    - End by handing the decision back to the user.
    - Do not begin sentences with the user's name, "Hey", or exclamation
      marks.
    - Then choose a suggestedAction that fits the financial situation.
    """

    private static func makePrompt(
        facts: SpendingFacts,
        impact: ImpactSummary
    ) -> String {
        guard let proposal = facts.proposal else {
            return "Reflect kindly on the user's spending."
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = impact.currencyCode
        formatter.maximumFractionDigits = 0
        func fmt(_ d: Double) -> String {
            formatter.string(from: NSNumber(value: d)) ?? "\(d)"
        }

        var lines: [String] = []
        lines.append("Considering: \(proposal.itemDescription)")
        lines.append("Amount: \(fmt(proposal.amount))")
        lines.append("Category: \(impact.category.displayName)")
        lines.append("This month so far in \(impact.category.displayName.lowercased()): \(fmt(impact.monthSpendBefore))")
        lines.append("Projected after the purchase: \(fmt(impact.monthSpendAfter))")

        switch impact.severity {
        case .overBudget:
            if let limit = impact.budgetLimit {
                lines.append("\(impact.category.displayName) monthly budget: \(fmt(limit))")
            }
            if let pct = impact.percentOverBudget {
                lines.append("This would be about \(Int(pct))% over the budget.")
            }
        case .approachingLimit:
            if let limit = impact.budgetLimit {
                lines.append("\(impact.category.displayName) monthly budget: \(fmt(limit))")
            }
            if let used = impact.percentOfBudgetUsed {
                lines.append("This would consume about \(Int(used))% of the monthly cap.")
            }
        case .withinBudget:
            if let limit = impact.budgetLimit {
                lines.append("\(impact.category.displayName) monthly budget: \(fmt(limit))")
            }
            if let used = impact.percentOfBudgetUsed {
                lines.append("This would use about \(Int(used))% of the cap — comfortably within.")
            }
        case .noBudget:
            lines.append("No \(impact.category.displayName.lowercased()) budget set.")
            if let baseline = impact.baselineMonthlyAverage {
                lines.append("Typical month for this category: \(fmt(baseline))")
            }
            if let pct = impact.percentAboveBaseline {
                lines.append("This would be about \(Int(pct))% above the typical month.")
            }
        }

        if let topGoal = facts.activeGoals.min(by: { $0.remaining < $1.remaining }) {
            lines.append("Closest active goal: '\(topGoal.name)', \(fmt(topGoal.remaining)) left of \(fmt(topGoal.targetAmount)).")
        }

        if facts.moneySavedByPausing > 0 {
            lines.append("Money the user has saved by pausing on previous impulses: \(fmt(facts.moneySavedByPausing)).")
        }

        lines.append("")
        lines.append("Write a 1–3 sentence reflection and pick a suggestedAction.")

        return lines.joined(separator: "\n")
    }

    private static let insightInstructions: String = """
    You are a kind, non-judgemental personal finance coach inside the Bujet
    app. The user is reviewing a weekly insight derived from their own
    spending. Your job is to rephrase a pre-written observation in your own
    words — warmer, more personal, but factually identical.

    Rules:
    - Use ONLY the numbers and merchants from the prompt. Never invent any.
    - Write 1 to 2 short sentences in the second person.
    - Stay observational, not prescriptive — no "you should" instructions.
    - Do not begin with "Hey", an exclamation mark, or the user's name.
    """

    private static func makeInsightPrompt(candidate: InsightCandidate) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = candidate.currencyCode
        formatter.maximumFractionDigits = 2
        func fmt(_ d: Double) -> String {
            formatter.string(from: NSNumber(value: d)) ?? "\(d)"
        }

        var lines: [String] = []
        lines.append("Insight type: \(candidate.kind.rawValue)")
        if let category = candidate.category {
            lines.append("Category: \(category.displayName)")
        }
        if let merchant = candidate.merchantHint {
            lines.append("Merchant: \(merchant)")
        }
        lines.append("Period: \(candidate.periodLabel)")
        lines.append("Headline number: \(fmt(candidate.primaryAmount))")
        if candidate.comparisonAmount > 0 {
            lines.append("Comparison number: \(fmt(candidate.comparisonAmount))")
        }
        if candidate.occurrenceCount > 0 {
            lines.append("Occurrences: \(candidate.occurrenceCount)")
        }
        lines.append("")
        lines.append("Pre-written observation (rephrase this faithfully):")
        lines.append(candidate.templateNarrative)
        return lines.joined(separator: "\n")
    }
}

// MARK: - @Generable DTOs

/// LLM-side schema. Stays in this file so `@Generable` (and the
/// `FoundationModels` import) doesn't leak into the Domain layer.
@Generable
private struct GeneratedInterventionNarrative {
    @Guide(description: "1 to 3 short sentences in second person. Reference one concrete number from the facts in the prompt. Do not invent numbers, merchants, or percentages.")
    let narrative: String

    @Guide(description: "Recommended next step for the user — buy now, wait, or save toward it as a wishlist pot. Pick the one that best fits the situation.")
    let suggestedAction: GeneratedSuggestedAction
}

@Generable
private struct GeneratedInsightNarrative {
    @Guide(description: "1 to 2 short sentences in the second person, observational tone. Use only the numbers, percentages, and merchants supplied in the prompt — invent nothing.")
    let narrative: String
}

@Generable
private enum GeneratedSuggestedAction {
    case buyNow
    case wait
    case addToWishlistPot

    var toDomain: SuggestedAction {
        switch self {
        case .buyNow:           .buyNow
        case .wait:             .wait
        case .addToWishlistPot: .addToWishlistPot
        }
    }
}
