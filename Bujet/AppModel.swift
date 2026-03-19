//
//  AppModel.swift
//  Bujet
//
//  Created by Zachary Beck on 18/03/2026.
//
import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    private let transactionRepository: any TransactionRepository
    private let importService: any PhaseAImportService
    private let authClient: BackendAuthClient
    private let authService = TrueLayerAuthService()

    var selectedTab: AppTab = .home
    var connectionState: BankConnectionState = .notConnected
    var pastedAuthCode = ""
    var transactions: [Transaction] = []
    var isImporting = false
    var alertMessage: String?

    init(
        transactionRepository: some TransactionRepository,
        importService: some PhaseAImportService,
        authClient: BackendAuthClient
    ) {
        self.transactionRepository = transactionRepository
        self.importService = importService
        self.authClient = authClient
    }

    func loadTransactions() async {
        transactions = await transactionRepository.fetchAll()
    }

    func startTrueLayerFlow() async {
        isImporting = true
        connectionState = .importing

        do {
            let startResponse = try await authClient.startAuth()

            authService.start(authURL: startResponse.authURL) { [weak self] result in
                guard let self else { return }

                Task {
                    defer {
                        self.isImporting = false
                    }

                    do {
                        let callbackURL = try result.get()

                        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                              let sessionID = components.queryItems?.first(where: { $0.name == "session_id" })?.value,
                              let status = components.queryItems?.first(where: { $0.name == "status" })?.value else {
                            throw AuthFlowError.invalidCallback
                        }

                        if status == "failed" {
                            let message = components.queryItems?.first(where: { $0.name == "message" })?.value
                            throw BackendImportError.serverError(message ?? "Authentication failed.")
                        }

                        let importResult = try await self.authClient.fetchImportResult(sessionID: sessionID)
                        try await self.transactionRepository.replaceAll(with: importResult.transactions)
                        self.transactions = await self.transactionRepository.fetchAll()
                        self.connectionState = .connected(importedCount: self.transactions.count)
                        self.selectedTab = .transactions
                    } catch {
                        self.connectionState = .failed(error.localizedDescription)
                        self.alertMessage = error.localizedDescription
                    }
                }
            }
        } catch {
            connectionState = .failed(error.localizedDescription)
            alertMessage = error.localizedDescription
            isImporting = false
        }
    }

    // Keep this temporarily as a debug/manual fallback.
    func importTransactionsFromPastedCode() async {
        let trimmedCode = pastedAuthCode.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedCode.isEmpty else {
            alertMessage = "Paste the TrueLayer authentication code first."
            connectionState = .failed("No authentication code was provided.")
            return
        }

        isImporting = true
        connectionState = .importing

        do {
            let importedTransactions = try await importService.importTransactions(using: trimmedCode)
            try await transactionRepository.replaceAll(with: importedTransactions)
            transactions = await transactionRepository.fetchAll()
            connectionState = .connected(importedCount: transactions.count)
            pastedAuthCode = ""
        } catch {
            connectionState = .failed(error.localizedDescription)
            alertMessage = error.localizedDescription
        }

        isImporting = false
    }

    func clearTransactions() async {
        do {
            try await transactionRepository.clear()
            transactions = await transactionRepository.fetchAll()
            connectionState = .notConnected
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}
