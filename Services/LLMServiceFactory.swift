import Foundation

/// Returns the appropriate `LLMNarrativeService` implementation at startup.
/// In Phase 1A this only wires up the template fallback; the
/// `FoundationModelsNarrativeService` path is added in Phase 1D and selected
/// here based on `SystemLanguageModel.default.availability`.
enum LLMServiceFactory {
    static func make() -> any LLMNarrativeService {
        // TODO (Phase 1D): if iOS 26+ and SystemLanguageModel availability == .available,
        // return FoundationModelsNarrativeService() instead.
        return TemplateNarrativeService()
    }
}
