//
//  LocalTransactionRepository.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//
import Foundation

actor LocalTransactionRepository: TransactionRepository {
    private let fileURL = URL.documentsDirectory.appending(path: "transactions.json")
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let categoriser: any TransactionCategorising

    init(categoriser: any TransactionCategorising = SmartTransactionCategoriser()) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        self.categoriser = categoriser
    }

    func fetchAll() async -> [Transaction] {
        guard FileManager.default.fileExists(atPath: fileURL.path()) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let transactions = try decoder.decode([Transaction].self, from: data)
            return transactions.sorted { $0.date > $1.date }
        } catch {
            // Wipe on schema mismatch (e.g. first launch after adding `source` field)
            try? FileManager.default.removeItem(at: fileURL)
            return []
        }
    }

    func replaceImported(with imports: [Transaction]) async throws {
        let manual = await fetchAll().filter { $0.source == .manual }
        let categorised = await applyCategoriser(to: imports)
        try await replaceAll(with: manual + categorised)
    }

    func add(_ transactions: [Transaction]) async throws {
        var existing = await fetchAll()
        let categorised = await applyCategoriser(to: transactions)
        existing.append(contentsOf: categorised)
        try await replaceAll(with: existing)
    }

    func clear(source: TransactionSource) async throws {
        let kept = await fetchAll().filter { $0.source != source }
        if kept.isEmpty {
            try? FileManager.default.removeItem(at: fileURL)
        } else {
            try await replaceAll(with: kept)
        }
    }

    private func replaceAll(with transactions: [Transaction]) async throws {
        let data = try encoder.encode(transactions)
        try data.write(to: fileURL, options: .atomic)
    }

    // Manual transactions keep the user-picked category. Imported transactions
    // get re-classified by the ML categoriser, which falls back to the keyword
    // matcher on unsupported devices.
    private func applyCategoriser(to transactions: [Transaction]) async -> [Transaction] {
        let imported = transactions.enumerated().filter { $0.element.source == .imported }
        guard !imported.isEmpty else { return transactions }

        let inputs = imported.map { _, t in
            CategorisationInput(id: t.id, merchant: t.merchantName, description: t.description)
        }
        let map = await categoriser.categorise(inputs)

        var result = transactions
        for (index, original) in imported {
            guard let category = map[original.id], category != original.category else { continue }
            result[index] = Transaction(
                id: original.id,
                date: original.date,
                description: original.description,
                merchantName: original.merchantName,
                amount: original.amount,
                currencyCode: original.currencyCode,
                source: original.source,
                category: category
            )
        }
        return result
    }
}
