import Foundation

/// Pure aggregation functions over a transaction list. No view or storage
/// dependencies — easy to unit test. Spend-only: credits are excluded so the
/// "Where it went" numbers represent outgoing money.
struct TransactionInsights {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// Debit transactions whose date falls within the calendar month containing `month`.
    func transactions(in month: Date, from all: [Transaction]) -> [Transaction] {
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }
        return all.filter { $0.isDebit && interval.contains($0.date) }
    }

    /// Total spend (positive value) in the month.
    func totalAmount(in month: Date, from all: [Transaction]) -> Double {
        transactions(in: month, from: all).reduce(0) { $0 + abs($1.amount) }
    }

    /// Debit transactions in the month for a category.
    func transactions(
        in month: Date,
        for category: TransactionCategory,
        from all: [Transaction]
    ) -> [Transaction] {
        transactions(in: month, from: all).filter { $0.category == category }
    }

    /// Total category spend (positive value) in the month.
    func totalAmount(
        in month: Date,
        for category: TransactionCategory,
        from all: [Transaction]
    ) -> Double {
        transactions(in: month, for: category, from: all).reduce(0) { $0 + abs($1.amount) }
    }

    /// Share of the month's spend attributable to the category, 0...100.
    func percentage(
        of category: TransactionCategory,
        in month: Date,
        from all: [Transaction]
    ) -> Double {
        let total = totalAmount(in: month, from: all)
        guard total > 0 else { return 0 }
        return totalAmount(in: month, for: category, from: all) / total * 100
    }

    func count(
        for category: TransactionCategory,
        in month: Date,
        from all: [Transaction]
    ) -> Int {
        transactions(in: month, for: category, from: all).count
    }

    /// Distinct calendar-month start dates that contain at least one debit,
    /// sorted most recent first.
    func monthsContainingTransactions(from all: [Transaction]) -> [Date] {
        let starts = all
            .filter(\.isDebit)
            .compactMap { calendar.dateInterval(of: .month, for: $0.date)?.start }
        return Array(Set(starts)).sorted(by: >)
    }

    /// Groups a category's transactions by day within the month, sorted newest day first.
    func transactionsGroupedByDay(
        in month: Date,
        for category: TransactionCategory,
        from all: [Transaction]
    ) -> [(day: Date, transactions: [Transaction])] {
        let entries = transactions(in: month, for: category, from: all)
        let grouped = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
        return grouped
            .map { (day: $0.key, transactions: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }
}
