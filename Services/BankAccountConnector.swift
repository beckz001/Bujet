//
//  BankAccountConnector.swift
//  Bujet
//
//  Created by Zachary Beck on 19/04/2026.
//

import Foundation
import AuthenticationServices

/// Abstraction over the full bank-connection flow so `HomeViewModel` stays
/// ignorant of OAuth, URL parsing, and backend specifics.
@MainActor
protocol BankConnecting: AnyObject {
    func connect() async throws -> [Transaction]
}

enum BankConnectionError: LocalizedError {
    case userCancelled

    var errorDescription: String? {
        "The bank connection was cancelled."
    }
}

/// Orchestrates the TrueLayer OAuth handshake and backend import fetch,
/// returning the raw transaction list on success.
@MainActor
final class BankAccountConnector: BankConnecting {
    private let authClient: BackendAuthClient
    private let authService = TrueLayerAuthService()

    init(authClient: BackendAuthClient) {
        self.authClient = authClient
    }

    func connect() async throws -> [Transaction] {
        let startResponse = try await authClient.startAuth()

        let callbackURL: URL
        do {
            callbackURL = try await authService.authenticate(authURL: startResponse.authURL)
        } catch {
            if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                throw BankConnectionError.userCancelled
            }
            throw error
        }

        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
            throw AuthFlowError.invalidCallback
        }
        let queryItems = components.queryItems ?? []

        if let payload = TrueLayerAPIErrorParser.parse(queryItems: queryItems) {
            throw TrueLayerAuthError.apiError(payload)
        }

        if queryItems.first(where: { $0.name == "status" })?.value == "failed" {
            let message = queryItems.first(where: { $0.name == "message" })?.value
            throw BackendImportError.serverError(message ?? "Authentication failed.")
        }

        guard let sessionID = queryItems.first(where: { $0.name == "session_id" })?.value else {
            throw AuthFlowError.invalidCallback
        }

        let importResult = try await authClient.fetchImportResult(sessionID: sessionID)
        return importResult.transactions
    }
}
