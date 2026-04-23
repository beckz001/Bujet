import Foundation
import Observation

@MainActor
@Observable
final class CategoryDetailViewModel {
    let category: TransactionCategory
    let month: Date
    let currencyCode: String

    @ObservationIgnored private let insights = TransactionInsights()
    @ObservationIgnored private let transactions: [Transaction]

    init(
        category: TransactionCategory,
        month: Date,
        transactions: [Transaction],
        currencyCode: String
    ) {
        self.category = category
        self.month = month
        self.transactions = transactions
        self.currencyCode = currencyCode
    }

    var totalSpend: Double {
        insights.totalAmount(in: month, for: category, from: transactions)
    }

    var groupedByDay: [DayGroup] {
        insights
            .transactionsGroupedByDay(in: month, for: category, from: transactions)
            .map { DayGroup(day: $0.day, transactions: $0.transactions) }
    }

    struct DayGroup: Identifiable {
        let day: Date
        let transactions: [Transaction]
        var id: Date { day }
    }
}
