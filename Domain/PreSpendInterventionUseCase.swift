import Foundation

/// Final, presentation-ready bundle handed to the UI after the user submits a
/// proposal. ImpactSummary is computed in Swift; narrative + suggestedAction
/// come from the LLM (or template fallback). Numbers never originate from the
/// LLM, by construction.
struct InterventionDecision: Hashable, Sendable {
    let proposal: InterventionProposal
    let impact: ImpactSummary
    let narrative: String
    let suggestedAction: SuggestedAction
}

/// Orchestrates the Pause & Reflect flow:
///   1. Build `SpendingFacts` from the repos.
///   2. Compute the deterministic `ImpactSummary` in Swift.
///   3. Ask the narrative service for prose + suggested action.
///   4. Return a single `InterventionDecision` for the UI.
///
/// Persisting the user's choice (Buy / Wait / Pot) is a *separate* concern —
/// see `recordDecision(...)` — so the use case stays cleanly testable and the
/// presentation layer drives when the log happens.
struct PreSpendInterventionUseCase: Sendable {
    let contextProvider: SpendingContextProvider
    let narrativeService: any LLMNarrativeService
    let interventionLogRepository: any InterventionLogRepository

    init(
        contextProvider: SpendingContextProvider,
        narrativeService: some LLMNarrativeService,
        interventionLogRepository: some InterventionLogRepository
    ) {
        self.contextProvider = contextProvider
        self.narrativeService = narrativeService
        self.interventionLogRepository = interventionLogRepository
    }

    func evaluate(_ proposal: InterventionProposal) async throws -> InterventionDecision {
        let facts = await contextProvider.makeFacts(for: proposal)
        let impact = contextProvider.makeImpactSummary(proposal: proposal, facts: facts)
        let narrative = try await narrativeService.generateInterventionNarrative(
            facts: facts,
            impact: impact
        )
        return InterventionDecision(
            proposal: proposal,
            impact: impact,
            narrative: narrative.narrative,
            suggestedAction: narrative.suggestedAction
        )
    }

    /// Persists the user's chosen action. Pots/wait scheduling are wired by
    /// the caller — this function only writes the audit log entry.
    func recordDecision(
        for decision: InterventionDecision,
        action: InterventionAction
    ) async throws {
        let log = InterventionLog(
            proposalID: decision.proposal.id,
            amount: decision.proposal.amount,
            itemDescription: decision.proposal.itemDescription,
            category: decision.proposal.category,
            currencyCode: decision.proposal.currencyCode,
            action: action
        )
        try await interventionLogRepository.append(log)
    }
}
