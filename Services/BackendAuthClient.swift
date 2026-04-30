//
//  BackendAuthClient.swift
//  Bujet
//
//  Created by Zachary Beck on 19/03/2026.
//

import Foundation

struct BackendAuthClient {
    let baseURL: URL

    func startAuth(providerID: String) async throws -> AuthStartResponse {
        var request = URLRequest(url: baseURL.appending(path: "auth/start"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(AuthStartRequest(providerID: providerID))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BackendImportError.serverError("Failed to start auth flow.")
        }

        let decoder = JSONDecoder()
        return try decoder.decode(AuthStartResponse.self, from: data)
    }

    func fetchImportResult(sessionID: String) async throws -> ImportResultResponse {
        let requestURL = baseURL
            .appending(path: "imports")
            .appending(path: "result")
            .appending(path: sessionID)

        let (data, response) = try await URLSession.shared.data(from: requestURL)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendImportError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard (200...299).contains(httpResponse.statusCode) else {
            let backendError = try? decoder.decode(BackendErrorBody.self, from: data)
            throw BackendImportError.serverError(
                backendError?.message ?? "Failed to retrieve import result."
            )
        }

        return try decoder.decode(ImportResultResponse.self, from: data)
    }
}

struct AuthStartRequest: Encodable {
    let providerID: String

    private enum CodingKeys: String, CodingKey {
        case providerID = "provider_id"
    }
}

struct AuthStartResponse: Decodable {
    let sessionID: String
    let authURL: URL
}

struct ImportResultResponse: Decodable {
    let importedCount: Int
    let transactions: [Transaction]
}

struct BackendErrorBody: Decodable {
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
