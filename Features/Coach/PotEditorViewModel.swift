import Foundation
import Observation

/// Drives the create-a-pot sheet (manual creation path from the Coach tab).
@MainActor
@Observable
final class PotEditorViewModel: Identifiable {
    @ObservationIgnored let id = UUID()
    @ObservationIgnored private let goalRepository: any GoalRepository
    @ObservationIgnored private let onSaved: () -> Void

    var name: String = ""
    var targetAmountText: String = ""
    var notesText: String = ""
    var currencyCode: String = "GBP"
    var isSaving: Bool = false
    var validationMessage: String?

    init(
        goalRepository: some GoalRepository,
        currencyCode: String = "GBP",
        onSaved: @escaping () -> Void = {}
    ) {
        self.goalRepository = goalRepository
        self.currencyCode = currencyCode
        self.onSaved = onSaved
    }

    var canSave: Bool {
        !isSaving
        && !name.trimmingCharacters(in: .whitespaces).isEmpty
        && (Double(targetAmountText) ?? 0) > 0
    }

    func updateAmount(_ value: String) {
        targetAmountText = value.sanitisedAmount
    }

    func save() async -> Bool {
        validationMessage = nil
        guard let target = Double(targetAmountText), target > 0 else {
            validationMessage = "Enter a target amount."
            return false
        }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            validationMessage = "Name your pot."
            return false
        }
        let trimmedNotes = notesText.trimmingCharacters(in: .whitespaces)

        let goal = Goal(
            name: trimmedName,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            targetAmount: target,
            currencyCode: currencyCode
        )

        isSaving = true
        defer { isSaving = false }

        do {
            try await goalRepository.upsert(goal)
            onSaved()
            return true
        } catch {
            validationMessage = "Couldn't save pot. Try again."
            return false
        }
    }
}
