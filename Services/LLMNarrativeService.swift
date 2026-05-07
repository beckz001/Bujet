import Foundation

/// What the LLM is allowed to recommend after seeing the facts. Maps onto the
/// three buttons in the Pause & Reflect sheet.
enum SuggestedAction: String, Codable, Hashable, Sendable {
    case buyNow
    case wait
    case addToWishlistPot

    var displayHint: String {
        switch self {
        case .buyNow:           "Buy now"
        case .wait:             "Sleep on it"
        case .addToWishlistPot: "Save toward it"
        }
    }
}

/// Where a generated narrative came from. Useful for the demo so the
/// presenter can point to whether the on-device model fired or the template
/// fallback was used.
enum NarrativeSource: String, Codable, Hashable, Sendable {
    case onDeviceLLM
    case template

    var displayLabel: String {
        switch self {
        case .onDeviceLLM: "On-device AI"
        case .template:    "Coach"
        }
    }
}

/// Pure narrative output produced by the LLM (or the template fallback).
/// Numbers are *not* part of this — they live in the deterministic
/// `ImpactSummary`.
struct InterventionNarrative: Hashable, Sendable {
    /// 1–3 short sentences. Personal, second-person, no fabricated numbers.
    var narrative: String
    /// Which of the three actions the model recommends. UI uses this only as
    /// a soft hint — the user always makes the final choice.
    var suggestedAction: SuggestedAction
    /// Engine that produced this narrative. Defaults to `.template` so
    /// existing call sites stay unaffected.
    var source: NarrativeSource = .template
}

/// Pure narrative output for a weekly insight. Same shape as
/// `InterventionNarrative` minus the suggested-action — insights are
/// observational, not prescriptive.
struct InsightNarrative: Hashable, Sendable {
    var narrative: String
    var source: NarrativeSource = .template
}

/// Boundary that the rest of the app talks to. Two implementations:
/// `TemplateNarrativeService` (string templates, always available) and
/// `FoundationModelsNarrativeService` (real on-device LLM, iOS 26+ with
/// Apple Intelligence). `LLMServiceFactory` picks the right one at runtime.
protocol LLMNarrativeService: Sendable {
    func generateInterventionNarrative(
        facts: SpendingFacts,
        impact: ImpactSummary
    ) async throws -> InterventionNarrative

    func generateInsightNarrative(
        candidate: InsightCandidate
    ) async throws -> InsightNarrative
}
