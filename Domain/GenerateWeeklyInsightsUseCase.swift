import Foundation

/// Orchestrates the weekly insights pipeline:
///   1. Build deterministic `WeeklyFacts` from the repos.
///   2. Run every registered `InsightAnalyser` over the facts (pure Swift —
///      this is where every number is computed).
///   3. Rank candidates by severity and cap to `maxInsights`.
///   4. Ask the narrative service to rephrase each candidate's prose. The
///      LLM never sees raw transactions or computes anything; it only
///      polishes the pre-built `templateNarrative`.
///
/// If the narrative service is unavailable or fails, the candidate's
/// `templateNarrative` is used verbatim — the deterministic side keeps
/// working unchanged.
struct GenerateWeeklyInsightsUseCase: Sendable {
    let contextProvider: SpendingContextProvider
    let analysers: [any InsightAnalyser]
    let narrativeService: any LLMNarrativeService
    let maxInsights: Int

    init(
        contextProvider: SpendingContextProvider,
        analysers: [any InsightAnalyser],
        narrativeService: some LLMNarrativeService,
        maxInsights: Int = 3
    ) {
        self.contextProvider = contextProvider
        self.analysers = analysers
        self.narrativeService = narrativeService
        self.maxInsights = maxInsights
    }

    func run(now: Date = .now) async -> [Insight] {
        let facts = await contextProvider.makeWeeklyFacts(now: now)
        let candidates = analysers
            .flatMap { $0.analyse(facts: facts) }
            .sorted { $0.severity > $1.severity }
            .prefix(maxInsights)

        var insights: [Insight] = []
        for candidate in candidates {
            let result = await dressCandidate(candidate)
            insights.append(result)
        }
        return insights
    }

    private func dressCandidate(_ candidate: InsightCandidate) async -> Insight {
        do {
            let narrative = try await narrativeService.generateInsightNarrative(
                candidate: candidate
            )
            return Insight(candidate: candidate, narrative: narrative.narrative, source: narrative.source)
        } catch {
            return Insight(
                candidate: candidate,
                narrative: candidate.templateNarrative,
                source: .template
            )
        }
    }
}
