import Foundation

/// Per-category monthly spending cap. Stored as a flat dictionary keyed by
/// category so we can persist the entire user's budget in a single JSON file.
struct Budget: Codable, Hashable {
    var category: TransactionCategory
    var monthlyMax: Double
    var currencyCode: String

    init(category: TransactionCategory, monthlyMax: Double, currencyCode: String = "GBP") {
        self.category = category
        self.monthlyMax = monthlyMax
        self.currencyCode = currencyCode
    }
}

/// Snapshot of all category budgets for the user. A category absent from
/// `byCategory` is treated as "no budget set".
struct BudgetBook: Codable, Hashable {
    var byCategory: [TransactionCategory: Budget]

    init(byCategory: [TransactionCategory: Budget] = [:]) {
        self.byCategory = byCategory
    }

    func limit(for category: TransactionCategory) -> Double? {
        byCategory[category]?.monthlyMax
    }

    func hasLimit(for category: TransactionCategory) -> Bool {
        limit(for: category) != nil
    }
}
