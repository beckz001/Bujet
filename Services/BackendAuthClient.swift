//
//  BackendAuthClient.swift
//  Bujet
//
//  Created by Zachary Beck on 19/03/2026.
//

import Foundation

struct BackendAuthClient {
    let baseURL: URL

    func startAuth() async throws -> AuthStartResponse {
        var request = URLRequest(url: baseURL.appending(path: "auth/start"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

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

struct AuthStartResponse: Decodable {
    let sessionID: String
    let authURL: URL
}

struct ImportResultResponse: Decodable {
    let importedCount: Int
    let transactions: [Transaction]
}
