//
//  LocalTransactionRepository.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//
import Foundation

/// # LocalTransactionRepository
///
/// **What it is** — the on-device persistence layer for the user's
/// transactions, and the concrete implementation of the `TransactionRepository`
/// protocol that the rest of the app depends on.
///
/// **What it does** — reads and writes the full transaction list as a single
/// JSON file in the app's Documents directory. It exposes a small, intent-named
/// API (`fetchAll`, `add`, `replaceImported`, `clear(source:)`) rather than raw
/// file access, sorts results newest-first, and distinguishes `.manual` entries
/// the user typed from `.imported` ones pulled from a bank so a re-import can
/// replace imported rows without wiping manual ones. On a decode failure (e.g.
/// the stored schema predates a new field) it self-heals by clearing the file
/// instead of crashing.
///
/// **Why it exists** — Bujet is privacy-first and offline-capable, so financial
/// data never leaves the device; a flat JSON file keeps the coursework
/// reviewable with no database or server dependency. It's an `actor` so all
/// reads and writes are serialised, preventing data races when imports,
/// manual edits and the intervention flow touch storage concurrently.
/// Hiding all of this behind the protocol means callers (view models, use
/// cases) are decoupled from *how* transactions are stored and could be pointed
/// at SwiftData or a server later with no change to them.
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
