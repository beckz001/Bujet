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

/// Pure narrative output produced by the LLM (or the template fallback).
/// Numbers are *not* part of this — they live in the deterministic
/// `ImpactSummary`. Annotated `@Generable` in `FoundationModelsNarrativeService`.
struct InterventionNarrative: Hashable, Sendable {
    /// 1–3 short sentences. Personal, second-person, no fabricated numbers.
    var narrative: String
    /// Which of the three actions the model recommends. UI uses this only as
    /// a soft hint — the user always makes the final choice.
    var suggestedAction: SuggestedAction
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
}
