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

    init() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
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
        try await replaceAll(with: manual + imports)
    }

    func add(_ transactions: [Transaction]) async throws {
        var existing = await fetchAll()
        existing.append(contentsOf: transactions)
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
}
