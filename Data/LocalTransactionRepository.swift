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
            return try decoder.decode([Transaction].self, from: data)
        } catch {
            return []
        }
    }

    func replaceAll(with transactions: [Transaction]) async throws {
        let data = try encoder.encode(transactions)
        try data.write(to: fileURL, options: .atomic)
    }

    func clear() async throws {
        guard FileManager.default.fileExists(atPath: fileURL.path()) else {
            return
        }

        try FileManager.default.removeItem(at: fileURL)
    }
}
