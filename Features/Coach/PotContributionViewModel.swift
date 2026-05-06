import Foundation
import Observation

@MainActor
@Observable
final class PotContributionViewModel: Identifiable {
    @ObservationIgnored let id = UUID()
    @ObservationIgnored private let goalRepository: any GoalRepository
    @ObservationIgnored private let onContributed: () -> Void

    let goal: Goal
    var amountText: String = ""
    var isSaving: Bool = false
    var validationMessage: String?

    init(
        goal: Goal,
        goalRepository: some GoalRepository,
        onContributed: @escaping () -> Void = {}
    ) {
        self.goal = goal
        self.goalRepository = goalRepository
        self.onContributed = onContributed
    }

    var canSave: Bool {
        !isSaving && (Double(amountText) ?? 0) > 0
    }

    func updateAmount(_ value: String) {
        amountText = value.sanitisedAmount
    }

    func save() async -> Bool {
        guard let amount = Double(amountText), amount > 0 else {
            validationMessage = "Enter an amount."
            return false
        }

        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await goalRepository.contribute(amount: amount, to: goal.id)
            onContributed()
            return true
        } catch {
            validationMessage = "Couldn't add to pot. Try again."
            return false
        }
    }
}
