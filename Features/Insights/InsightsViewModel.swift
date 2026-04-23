import Foundation
import Observation

@MainActor
@Observable
final class InsightsViewModel {
    @ObservationIgnored private let transactionRepository: any TransactionRepository
    @ObservationIgnored private let insights = TransactionInsights()
    @ObservationIgnored private let calendar = Calendar.current

    var transactions: [Transaction] = []
    var selectedMonth: Date = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now

    init(transactionRepository: some TransactionRepository) {
        self.transactionRepository = transactionRepository
    }

    // MARK: - Lifecycle

    func loadTransactions() async {
        transactions = await transactionRepository.fetchAll()
        if !availableMonths.contains(selectedMonth) {
            selectedMonth = availableMonths.first ?? selectedMonth
        }
    }

    func refresh() async {
        await loadTransactions()
    }

    // MARK: - Month picker

    /// Months with at least one transaction, plus the current month, sorted newest first.
    var availableMonths: [Date] {
        let monthsWithData = insights.monthsContainingTransactions(from: transactions)
        let currentMonth = calendar.dateInterval(of: .month, for: .now)?.start ?? .now
        if monthsWithData.contains(currentMonth) {
            return monthsWithData
        }
        return ([currentMonth] + monthsWithData).sorted(by: >)
    }

    // MARK: - Derived display data

    var monthTotal: Double {
        insights.totalAmount(in: selectedMonth, from: transactions)
    }

    func total(for category: TransactionCategory) -> Double {
        insights.totalAmount(in: selectedMonth, for: category, from: transactions)
    }

    func percentage(for category: TransactionCategory) -> Double {
        insights.percentage(of: category, in: selectedMonth, from: transactions)
    }

    func count(for category: TransactionCategory) -> Int {
        insights.count(for: category, in: selectedMonth, from: transactions)
    }

    var currencyCode: String {
        transactions.first?.currencyCode ?? Locale.current.currency?.identifier ?? "GBP"
    }
}
