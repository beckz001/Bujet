//
//  MockPhaseAImportService.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//
import Foundation

struct BackendImportService: PhaseAImportService {
    let baseURL: URL

    func importTransactions(using authCode: String) async throws -> [Transaction] {
        let trimmedCode = authCode.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedCode.isEmpty else {
            throw ImportError.emptyCode
        }

        var request = URLRequest(url: baseURL.appending(path: "imports/truelayer"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let requestBody = ImportRequestBody(authCode: trimmedCode)
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendImportError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if (200...299).contains(httpResponse.statusCode) {
            let payload = try decoder.decode(ImportResponseBody.self, from: data)
            return payload.transactions
        } else {
            let backendError = try? decoder.decode(BackendErrorBody.self, from: data)
            throw BackendImportError.serverError(
                backendError?.message ?? "Backend request failed with status \(httpResponse.statusCode)."
            )
        }
    }
}

private struct ImportRequestBody: Encodable {
    let authCode: String
}

private struct ImportResponseBody: Decodable {
    let importedCount: Int
    let transactions: [Transaction]
}

private struct BackendErrorBody: Decodable {
    let error: String
    let message: String
}

enum BackendImportError: LocalizedError {
    case invalidResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The backend returned an invalid response."
        case .serverError(let message):
            message
        }
    }
}

