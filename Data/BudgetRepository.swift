import Foundation

protocol BudgetRepository: Sendable {
    func fetch() async -> BudgetBook
    func save(_ book: BudgetBook) async throws
    func setLimit(_ amount: Double?, for category: TransactionCategory, currencyCode: String) async throws
}
