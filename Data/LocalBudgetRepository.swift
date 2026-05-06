import Foundation

actor LocalBudgetRepository: BudgetRepository {
    private let fileURL = URL.documentsDirectory.appending(path: "budgets.json")
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder
        self.decoder = JSONDecoder()
    }

    func fetch() async -> BudgetBook {
        guard FileManager.default.fileExists(atPath: fileURL.path()) else {
            return BudgetBook()
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(BudgetBook.self, from: data)
        } catch {
            try? FileManager.default.removeItem(at: fileURL)
            return BudgetBook()
        }
    }

    func save(_ book: BudgetBook) async throws {
        let data = try encoder.encode(book)
        try data.write(to: fileURL, options: .atomic)
    }

    func setLimit(_ amount: Double?, for category: TransactionCategory, currencyCode: String) async throws {
        var book = await fetch()
        if let amount, amount > 0 {
            book.byCategory[category] = Budget(
                category: category,
                monthlyMax: amount,
                currencyCode: currencyCode
            )
        } else {
            book.byCategory.removeValue(forKey: category)
        }
        try await save(book)
    }
}
