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
    func connect(provider: BankProvider) async throws -> [Transaction]
}

enum BankConnectionError: LocalizedError {
    case userCancelled

    var errorDescription: String? {
        "The bank connection was cancelled."
    }
}

/// # BankAccountConnector
///
/// **What it is** — the concrete service that drives a single "connect my
/// bank" attempt end to end. It is the code behind the `BankConnectionService`
/// box in the Sprint 1–2 diagrams; in the implementation that one box is split
/// into `BackendAuthClient` (talks to our backend), `TrueLayerAuthService`
/// (drives the system OAuth sheet) and this type, which orchestrates the two.
///
/// **What it does** — given a chosen `BankProvider` it:
/// 1. short-circuits to canned data for the demo provider so the app is
///    reviewable without real bank credentials;
/// 2. asks the backend to start a TrueLayer auth session;
/// 3. hands the auth URL to `ASWebAuthenticationSession` and waits for the
///    redirect back into the app;
/// 4. parses the callback URL, turning every failure mode (user cancel, API
///    error, failed status, missing session) into a typed Swift error;
/// 5. fetches the imported transactions for that session and re-stamps them
///    with a local connection ID before returning them.
///
/// **Why it exists** — it hides OAuth, URL parsing and backend specifics behind
/// the small `BankConnecting` protocol so `HomeViewModel` only ever sees
/// "give me a provider, get back transactions or an error." That seam keeps the
/// view layer testable and lets the whole connection stack be swapped for a
/// mock in previews and unit tests.
@MainActor
final class BankAccountConnector: BankConnecting {
    private let authClient: BackendAuthClient
    private let authService = TrueLayerAuthService()

    init(authClient: BackendAuthClient) {
        self.authClient = authClient
    }

    func connect(provider: BankProvider) async throws -> [Transaction] {
        if provider.isDemo {
            // Tiny artificial delay so the importing banner is visible — the
            // demo otherwise feels suspiciously instant.
            try? await Task.sleep(for: .milliseconds(400))
            let txs = DemoTransactionFactory.makeTransactions()
            return txs.map { stamping($0, with: provider.id) }
        }

        let startResponse = try await authClient.startAuth(providerID: provider.truelayerProviderID)

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
        return importResult.transactions.map { stamping($0, with: provider.id) }
    }

    /// Re-stamps each transaction with the local connection ID and namespaces
    /// its `id` so the same mock-bank payload connected under multiple
    /// providers produces distinct rows instead of colliding on the backend's
    /// `<account_id>:<txn_id>` key.
    private func stamping(_ transaction: Transaction, with localProviderID: String) -> Transaction {
        Transaction(
            id: "\(localProviderID)|\(transaction.id)",
            date: transaction.date,
            description: transaction.description,
            merchantName: transaction.merchantName,
            amount: transaction.amount,
            currencyCode: transaction.currencyCode,
            source: transaction.source,
            category: transaction.category,
            bankConnectionID: localProviderID
        )
    }
}
