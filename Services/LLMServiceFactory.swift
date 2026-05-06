import Foundation
import FoundationModels
import os

/// Returns the appropriate `LLMNarrativeService` implementation. We pick
/// `FoundationModelsNarrativeService` when the on-device model reports as
/// `.available`, otherwise fall back to `TemplateNarrativeService`. The
/// rest of the app is oblivious — both implementations satisfy the same
/// protocol contract.
///
/// Selection happens **per call** (not once at startup) so that if Apple
/// Intelligence finishes downloading or is enabled while the app is open,
/// the LLM kicks in on the very next reflect — no app restart needed.
enum LLMServiceFactory {
    static func make() -> any LLMNarrativeService {
        DynamicNarrativeService()
    }
}

private struct DynamicNarrativeService: LLMNarrativeService {
    private static let logger = Logger(subsystem: "com.bujet", category: "LLM")

    func generateInterventionNarrative(
        facts: SpendingFacts,
        impact: ImpactSummary
    ) async throws -> InterventionNarrative {
        let availability = SystemLanguageModel.default.availability
        Self.logger.info("FoundationModels availability: \(String(describing: availability), privacy: .public)")

        if case .available = availability {
            return try await FoundationModelsNarrativeService()
                .generateInterventionNarrative(facts: facts, impact: impact)
        }
        Self.logger.info("Falling back to TemplateNarrativeService.")
        return try await TemplateNarrativeService()
            .generateInterventionNarrative(facts: facts, impact: impact)
    }
}
