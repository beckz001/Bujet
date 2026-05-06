import Foundation
import Observation

@MainActor
@Observable
final class BudgetsViewModel: Identifiable {
    @ObservationIgnored let id = UUID()
    @ObservationIgnored private let budgetRepository: any BudgetRepository
    @ObservationIgnored private let onSaved: () -> Void

    /// Editable text per category. Empty string == no limit. Validated on save.
    var drafts: [TransactionCategory: String] = [:]
    var currencyCode: String = "GBP"
    var isSaving: Bool = false
    var validationMessage: String?

    init(
        budgetRepository: some BudgetRepository,
        currencyCode: String = "GBP",
        onSaved: @escaping () -> Void = {}
    ) {
        self.budgetRepository = budgetRepository
        self.currencyCode = currencyCode
        self.onSaved = onSaved
        for category in TransactionCategory.allCases {
            drafts[category] = ""
        }
    }

    func load() async {
        let book = await budgetRepository.fetch()
        var next: [TransactionCategory: String] = [:]
        for category in TransactionCategory.allCases {
            if let limit = book.limit(for: category) {
                next[category] = formatAmount(limit)
            } else {
                next[category] = ""
            }
        }
        drafts = next
    }

    func binding(for category: TransactionCategory) -> String {
        drafts[category] ?? ""
    }

    func update(_ value: String, for category: TransactionCategory) {
        drafts[category] = value.sanitisedAmount
    }

    func clearAll() {
        for category in TransactionCategory.allCases {
            drafts[category] = ""
        }
    }

    var hasAnyValue: Bool {
        drafts.values.contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    func save() async -> Bool {
        validationMessage = nil
        var book = BudgetBook()
        for category in TransactionCategory.allCases {
            let raw = drafts[category]?.trimmingCharacters(in: .whitespaces) ?? ""
            if raw.isEmpty { continue }
            guard let amount = Double(raw), amount > 0 else {
                validationMessage = "Enter a valid amount for \(category.displayName)."
                return false
            }
            book.byCategory[category] = Budget(
                category: category,
                monthlyMax: amount,
                currencyCode: currencyCode
            )
        }

        isSaving = true
        defer { isSaving = false }
        do {
            try await budgetRepository.save(book)
            onSaved()
            return true
        } catch {
            validationMessage = "Couldn't save budgets. Try again."
            return false
        }
    }

    private func formatAmount(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.2f", value)
    }
}
