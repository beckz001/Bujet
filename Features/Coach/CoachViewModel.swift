import Foundation
import Observation

@MainActor
@Observable
final class CoachViewModel {
    @ObservationIgnored private let goalRepository: any GoalRepository
    @ObservationIgnored private let interventionLogRepository: any InterventionLogRepository

    var goals: [Goal] = []
    var moneySavedByPausing: Double = 0
    var currencyCode: String = "GBP"

    init(
        goalRepository: some GoalRepository,
        interventionLogRepository: some InterventionLogRepository
    ) {
        self.goalRepository = goalRepository
        self.interventionLogRepository = interventionLogRepository
    }

    func load() async {
        async let goalList = goalRepository.fetchAll()
        async let saved = interventionLogRepository.moneySavedByPausing()
        goals = await goalList
        moneySavedByPausing = await saved
        if let firstCurrency = goals.first?.currencyCode {
            currencyCode = firstCurrency
        }
    }

    func refresh() async { await load() }

    var pots: [Goal] { goals.filter(\.isPot) }
    var plainGoals: [Goal] { goals.filter { !$0.isPot } }

    func contribute(amount: Double, to goal: Goal) async {
        _ = try? await goalRepository.contribute(amount: amount, to: goal.id)
        await load()
    }

    func delete(_ goal: Goal) async {
        try? await goalRepository.delete(id: goal.id)
        await load()
    }
}
