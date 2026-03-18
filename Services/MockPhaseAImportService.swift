//
//  MockPhaseAImportService.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//
import Foundation

struct MockPhaseAImportService: PhaseAImportService {
    func importTransactions(using authCode: String) async throws -> [Transaction] {
        let trimmedCode = authCode.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedCode.isEmpty else {
            throw ImportError.emptyCode
        }

        guard let url = Bundle.main.url(forResource: "SampleTransactions", withExtension: "json") else {
            throw ImportError.missingFixtureFile
        }

        let data = try Data(contentsOf: url)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode([Transaction].self, from: data)
        } catch {
            throw ImportError.invalidFixtureData
        }
    }
}

